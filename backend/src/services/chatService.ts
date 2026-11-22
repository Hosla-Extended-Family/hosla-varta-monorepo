import prisma from '../config/database';
import redis from '../config/redis';
import { AppError } from '../utils/AppError';
import { ErrorCode } from '../utils/errorCodes';
import { ConversationType, MessageStatusType } from '@prisma/client';
import { isUserOnline } from '../config/socket';
import { notificationService } from './notificationService';
import { TextFilterService } from './textFilterService';
import logger from '../utils/logger';
const MAX_MESSAGE_LENGTH = 4000;
const PENDING_TTL_SECONDS = 48 * 60 * 60;

const pendingKey = (userId: string) => `chat:pending:${userId}`;

const conversationMemberSelect = {
    select: {
        userId: true,
        user: { select: { id: true, name: true, profilePicUrl: true } },
    },
};

export interface ChatMessagePayload {
    id: string;
    conversationId: string;
    senderId: string;
    content: string | null;
    createdAt: Date;
}

export class ChatService {
    static async assertMembership(userId: string, conversationId: string) {
        const member = await prisma.conversationMember.findUnique({
            where: {
                conversationId_userId: { conversationId, userId },
            },
        });
        if (!member) {
            throw new AppError(ErrorCode.FORBIDDEN, 'You are not a participant of this chat', 403);
        }
    }

    static async getOrCreateDirectChat(userId: string, friendId: string) {
        if (userId === friendId) {
            throw new AppError(ErrorCode.VALIDATION_ERROR, 'Cannot start a chat with yourself');
        }

        const friendship = await prisma.friendship.findFirst({
            where: {
                status: 'ACCEPTED',
                OR: [
                    { requesterId: userId, receiverId: friendId },
                    { requesterId: friendId, receiverId: userId },
                ],
            },
        });

        if (!friendship) {
            throw new AppError(ErrorCode.FORBIDDEN, 'You can only chat with accepted friends', 403);
        }

        const existing = await this.findExistingDirectChat(userId, friendId);

        if (existing) {
            return this.getConversationForUser(existing.id, userId);
        }

        const pairKey = [userId, friendId].sort().join(':');

        return prisma.$transaction(async (tx) => {
            await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${pairKey}))`;

            const existingInLock = await this.findExistingDirectChat(userId, friendId);
            if (existingInLock) {
                return this.getConversationForUser(existingInLock.id, userId);
            }

            const created = await tx.conversation.create({
                data: {
                    type: ConversationType.DIRECT,
                    members: {
                        create: [{ userId }, { userId: friendId }],
                    },
                },
            });

            return this.getConversationForUser(created.id, userId);
        });
    }

    private static async findExistingDirectChat(userId: string, friendId: string) {
        const myDirectConversations = await prisma.conversation.findMany({
            where: {
                type: ConversationType.DIRECT,
                members: { some: { userId } },
            },
            include: { members: { select: { userId: true } } },
        });

        return myDirectConversations.find(
            (c) =>
                c.members.length === 2 &&
                c.members.some((m) => m.userId === friendId)
        );
    }

    static async listChats(userId: string) {
        const memberships = await prisma.conversation.findMany({
            where: {
                type: ConversationType.DIRECT,
                members: { some: { userId } },
            },
            include: {
                members: conversationMemberSelect,
                messages: {
                    orderBy: { createdAt: 'desc' },
                    take: 1,
                    select: {
                        id: true,
                        senderId: true,
                        content: true,
                        createdAt: true,
                        isDeleted: true,
                    },
                },
            },
            orderBy: { updatedAt: 'desc' },
        });

        const result = await Promise.all(
            memberships.map(async (conversation) => {
                const other = conversation.members.find((m) => m.userId !== userId);
                const unreadCount = await prisma.message.count({
                    where: {
                        conversationId: conversation.id,
                        senderId: { not: userId },
                        isDeleted: false,
                        statuses: {
                            none: { userId, status: MessageStatusType.READ },
                        },
                    },
                });

                return {
                    id: conversation.id,
                    type: conversation.type,
                    name: other?.user.name ?? 'Unknown',
                    photoUrl: other?.user.profilePicUrl ?? null,
                    participants: conversation.members.map((m) => ({
                        id: m.user.id,
                        name: m.user.name,
                        profilePicUrl: m.user.profilePicUrl,
                    })),
                    lastMessage: conversation.messages[0]
                        ? {
                              id: conversation.messages[0].id,
                              senderId: conversation.messages[0].senderId,
                              createdAt: conversation.messages[0].createdAt,
                          }
                        : null,
                    unreadCount,
                    updatedAt: conversation.updatedAt,
                };
            })
        );

        return result;
    }

    static async getConversationForUser(conversationId: string, userId: string) {
        await this.assertMembership(userId, conversationId);

        const conversation = await prisma.conversation.findUnique({
            where: { id: conversationId },
            include: { members: conversationMemberSelect },
        });
        if (!conversation) {
            throw new AppError(ErrorCode.NOT_FOUND, 'Chat not found');
        }

        const other = conversation.members.find((m) => m.userId !== userId);

        return {
            id: conversation.id,
            type: conversation.type,
            name: other?.user.name ?? 'Unknown',
            photoUrl: other?.user.profilePicUrl ?? null,
            participants: conversation.members.map((m) => ({
                id: m.user.id,
                name: m.user.name,
                profilePicUrl: m.user.profilePicUrl,
            })),
            unreadCount: 0,
            updatedAt: conversation.updatedAt,
        };
    }

    static async getMessages(userId: string, conversationId: string, page: number, limit: number) {
        await this.assertMembership(userId, conversationId);

        const messages = await prisma.message.findMany({
            where: { conversationId, isDeleted: false },
            orderBy: { createdAt: 'desc' },
            skip: (page - 1) * limit,
            take: limit,
            select: {
                id: true,
                conversationId: true,
                senderId: true,
                content: true,
                createdAt: true,
            },
        });

        return {
            messages: messages.reverse(),
            page,
            limit,
            hasMore: messages.length === limit,
        };
    }

    static async sendMessage(userId: string, conversationId: string, rawContent: string): Promise<{
        message: ChatMessagePayload;
        recipientIds: string[];
    }> {
        await this.assertMembership(userId, conversationId);

        const content = rawContent.trim();
        if (!content) {
            throw new AppError(ErrorCode.VALIDATION_ERROR, 'Message cannot be empty');
        }
        if (content.length > MAX_MESSAGE_LENGTH) {
            throw new AppError(
                ErrorCode.VALIDATION_ERROR,
                `Message too long (max ${MAX_MESSAGE_LENGTH} characters)`
            );
        }

        try {
            const filterResult = await TextFilterService.checkContent(content);
            if (!filterResult.isAllowed) {
                throw new AppError(ErrorCode.VALIDATION_ERROR, 'Message contains blocked content');
            }
        } catch (error) {
            if (error instanceof AppError) throw error;
        }

        const message = await prisma.message.create({
            data: {
                conversationId,
                senderId: userId,
                content: null,
            },
            select: {
                id: true,
                conversationId: true,
                senderId: true,
                createdAt: true,
            },
        });

        const members = await prisma.conversationMember.findMany({
            where: { conversationId },
            select: { userId: true },
        });

        await prisma.$transaction(
            members
                .filter((m) => m.userId !== userId)
                .map((m) =>
                    prisma.messageStatus.upsert({
                        where: {
                            messageId_userId: { messageId: message.id, userId: m.userId },
                        },
                        update: {},
                        create: {
                            messageId: message.id,
                            userId: m.userId,
                            status: MessageStatusType.SENT,
                        },
                    })
                )
        );

        const recipientIds = members.filter((m) => m.userId !== userId).map((m) => m.userId);

        const relayPayload = {
            id: message.id,
            conversationId: message.conversationId,
            senderId: message.senderId,
            content,
            createdAt: message.createdAt,
        };

        for (const recipientId of recipientIds) {
            if (!isUserOnline(recipientId)) {
                await this.queuePendingDelivery(recipientId, relayPayload);
                await this.pushOfflineNotification(recipientId, userId);
            }
        }

        return { message: relayPayload, recipientIds };
    }

    /**
     * Content is never persisted in the DB. Offline recipients get the full
     * payload queued in Redis with a TTL; if it is not delivered in time the
     * message content is lost (metadata remains for ordering/read state).
     */
    private static async queuePendingDelivery(
        recipientId: string,
        payload: ChatMessagePayload
    ) {
        try {
            const key = pendingKey(recipientId);
            await redis.rpush(key, JSON.stringify(payload));
            await redis.expire(key, PENDING_TTL_SECONDS);
        } catch (error) {
            logger.warn('Failed to queue pending chat delivery:', error);
        }
    }

    /** Flushes undelivered message payloads to a just-connected socket. */
    static async flushPendingMessages(
        userId: string,
        socket: { emit: (event: string, payload: unknown) => void }
    ) {
        try {
            const key = pendingKey(userId);
            const items = await redis.lrange(key, 0, -1);
            if (!items.length) return;

            for (const raw of items) {
                try {
                    socket.emit('chat:new_message', JSON.parse(raw));
                } catch (error) {
                    logger.warn('Bad pending payload skipped');
                }
            }
            await redis.del(key);
        } catch (error) {
            logger.warn('Failed to flush pending chat delivery:', error);
        }
    }

    private static async pushOfflineNotification(recipientId: string, senderId: string) {
        try {
            const [sender, devices] = await Promise.all([
                prisma.user.findUnique({ where: { id: senderId }, select: { name: true } }),
                prisma.device.findMany({ where: { userId: recipientId }, select: { fcmToken: true } }),
            ]);
            const tokens = devices
                .map((d) => d.fcmToken)
                .filter((t) => t.length > 40 && !['web_token', 'no_fcm_token'].includes(t));
            if (tokens.length === 0) return;

            await notificationService.sendMulticast(
                tokens,
                'New Message',
                `${sender?.name ?? 'Someone'} sent you a message`,
                { type: 'NEW_MESSAGE', senderId }
            );
        } catch (error) {
            // Non-fatal
        }
    }

    static async markChatRead(userId: string, conversationId: string) {
        await this.assertMembership(userId, conversationId);

        const updated = await prisma.messageStatus.updateMany({
            where: {
                userId,
                status: { not: MessageStatusType.READ },
                message: {
                    conversationId,
                    senderId: { not: userId },
                    isDeleted: false,
                },
            },
            data: { status: MessageStatusType.READ },
        });

        return { updated: updated.count };
    }
}
