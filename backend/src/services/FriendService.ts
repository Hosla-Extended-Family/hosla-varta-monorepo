import { FriendRepository } from '../repositories/FriendRepository';
import prisma from '../config/database';
import { AppError } from '../utils/AppError';
import { ErrorCode } from '../utils/errorCodes';
import { FriendshipStatus, Prisma } from '@prisma/client';
import redis from '../config/redis';
import logger from '../utils/logger';
import { notificationService } from './notificationService';

const friendRepository = new FriendRepository();

const RESEND_COOLDOWN_MS = 24 * 60 * 60 * 1000;
const RESEND_COOLDOWN_KEY_PREFIX = 'friendreq:rejectcooldown';
const PLACEHOLDER_FCM_TOKENS = new Set(['web_token', 'no_fcm_token']);

function isRealFcmToken(token: string) {
    return token.length > 40 && !PLACEHOLDER_FCM_TOKENS.has(token);
}

export class FriendService {
    private static cooldownKey(requesterId: string, receiverId: string) {
        return `${RESEND_COOLDOWN_KEY_PREFIX}:${requesterId}:${receiverId}`;
    }

    private static async setResendCooldown(requesterId: string, receiverId: string) {
        try {
            await redis.set(
                this.cooldownKey(requesterId, receiverId),
                '1',
                'PX',
                RESEND_COOLDOWN_MS
            );
        } catch (error) {
            logger.warn('Failed to set friend request resend cooldown:', error);
        }
    }

    private static async hasResendCooldown(requesterId: string, receiverId: string) {
        try {
            return (await redis.exists(this.cooldownKey(requesterId, receiverId))) === 1;
        } catch (error) {
            logger.warn('Failed to read friend request resend cooldown:', error);
            return false;
        }
    }

    private static async notifyUser(
        userId: string,
        title: string,
        body: string,
        data: Record<string, string>
    ) {
        try {
            const devices = await prisma.device.findMany({ where: { userId } });
            const tokens = devices.map((d) => d.fcmToken).filter(isRealFcmToken);
            if (tokens.length === 0) return;
            await notificationService.sendMulticast(tokens, title, body, data);
        } catch (error) {
            logger.warn('Failed to send friend notification:', error);
        }
    }

    private static async getUserName(userId: string) {
        const user = await prisma.user.findUnique({
            where: { id: userId },
            select: { name: true },
        });
        return user?.name || 'Someone';
    }

    private static async notifyFriendRequest(requesterId: string, receiverId: string, friendshipId: string) {
        const name = await this.getUserName(requesterId);
        await this.notifyUser(receiverId, 'New Friend Request', `${name} sent you a friend request`, {
            type: 'FRIEND_REQUEST',
            friendshipId,
        });
    }

    static async sendRequest(requesterId: string, receiverId: string) {
        if (requesterId === receiverId) {
            throw new AppError(ErrorCode.VALIDATION_ERROR, 'Cannot send friend request to self');
        }

        const receiver = await prisma.user.findUnique({ where: { id: receiverId } });
        if (!receiver) {
            throw new AppError(ErrorCode.NOT_FOUND, 'User not found');
        }

        const blocked = await prisma.blockedUser.findFirst({
            where: {
                OR: [
                    { blockerId: requesterId, blockedId: receiverId },
                    { blockerId: receiverId, blockedId: requesterId },
                ],
            },
        });

        if (blocked) {
            throw new AppError(ErrorCode.FORBIDDEN, 'Cannot send request (blocked)');
        }

        const rows = await friendRepository.getFriendshipsBetween(requesterId, receiverId);

        const accepted = rows.find((r) => r.status === FriendshipStatus.ACCEPTED);
        if (accepted) {
            throw new AppError(ErrorCode.CONFLICT, 'Already friends');
        }

        const pending = rows.find((r) => r.status === FriendshipStatus.PENDING);
        if (pending) {
            if (pending.requesterId === requesterId) {
                throw new AppError(ErrorCode.CONFLICT, 'Friend request already sent');
            }
            return this.acceptRequest(requesterId, pending.id);
        }

        const rejected = rows.find((r) => r.status === FriendshipStatus.REJECTED);
        if (rejected) {
            if (rejected.requesterId === requesterId) {
                const coolingDown = await this.hasResendCooldown(requesterId, receiverId);
                if (coolingDown) {
                    throw new AppError(
                        ErrorCode.RATE_LIMITED,
                        'You were rejected recently. Please wait before sending another request'
                    );
                }
                const result = await friendRepository.resetToPending(rejected.id);
                await friendRepository.deleteStaleBetween(requesterId, receiverId, rejected.id);
                await this.notifyFriendRequest(requesterId, receiverId, rejected.id);
                return result;
            }

            try {
                const result = await friendRepository.redirectRequest(
                    rejected.id,
                    requesterId,
                    receiverId
                );
                await friendRepository.deleteStaleBetween(requesterId, receiverId, rejected.id);
                await this.notifyFriendRequest(requesterId, receiverId, result.id);
                return result;
            } catch (error) {
                if (
                    error instanceof Prisma.PrismaClientKnownRequestError &&
                    error.code === 'P2002'
                ) {
                    throw new AppError(ErrorCode.CONFLICT, 'Friend request already sent');
                }
                throw error;
            }
        }

        try {
            const result = await friendRepository.createRequest(requesterId, receiverId);
            await friendRepository.deleteStaleBetween(requesterId, receiverId, result.id);
            await this.notifyFriendRequest(requesterId, receiverId, result.id);
            return result;
        } catch (error) {
            if (
                error instanceof Prisma.PrismaClientKnownRequestError &&
                error.code === 'P2002'
            ) {
                throw new AppError(ErrorCode.CONFLICT, 'Friend request already sent');
            }
            throw error;
        }
    }

    static async acceptRequest(userId: string, friendshipId: string) {
        const friendship = await friendRepository.getFriendshipById(friendshipId);
        if (!friendship) {
            throw new AppError(ErrorCode.NOT_FOUND, 'Friend request not found');
        }

        if (friendship.receiverId !== userId) {
            throw new AppError(ErrorCode.FORBIDDEN, 'Only receiver can accept request');
        }

        if (friendship.status === FriendshipStatus.ACCEPTED) {
            return friendship;
        }

        if (friendship.status !== FriendshipStatus.PENDING) {
            throw new AppError(ErrorCode.VALIDATION_ERROR, 'Request is not pending');
        }

        const result = await friendRepository.acceptRequest(friendshipId);
        await this.notifyUser(
            friendship.requesterId,
            'Friend Request Accepted',
            `${friendship.receiver.name} accepted your friend request`,
            {
                type: 'FRIEND_REQUEST_ACCEPTED',
                friendshipId,
            }
        );
        return result;
    }

    static async rejectRequest(userId: string, friendshipId: string) {
        const friendship = await friendRepository.getFriendshipById(friendshipId);
        if (!friendship) {
            throw new AppError(ErrorCode.NOT_FOUND, 'Friend request not found');
        }

        if (friendship.receiverId !== userId) {
            throw new AppError(ErrorCode.FORBIDDEN, 'Only receiver can reject request');
        }

        if (friendship.status !== FriendshipStatus.PENDING) {
            throw new AppError(ErrorCode.VALIDATION_ERROR, 'Request is not pending');
        }

        const result = await friendRepository.rejectRequest(friendshipId);
        await this.setResendCooldown(friendship.requesterId, friendship.receiverId);
        return result;
    }

    static async cancelRequest(userId: string, friendshipId: string) {
        const friendship = await friendRepository.getFriendshipById(friendshipId);
        if (!friendship) {
            throw new AppError(ErrorCode.NOT_FOUND, 'Friend request not found');
        }

        if (friendship.requesterId !== userId) {
            throw new AppError(ErrorCode.FORBIDDEN, 'Only sender can cancel request');
        }

        if (friendship.status !== FriendshipStatus.PENDING) {
            throw new AppError(ErrorCode.VALIDATION_ERROR, 'Request is not pending');
        }

        return friendRepository.deleteById(friendshipId);
    }

    static async removeFriend(userId: string, friendshipId: string) {
        const friendship = await friendRepository.getFriendshipById(friendshipId);
        if (!friendship) {
            throw new AppError(ErrorCode.NOT_FOUND, 'Friendship not found');
        }

        if (friendship.requesterId !== userId && friendship.receiverId !== userId) {
            throw new AppError(ErrorCode.FORBIDDEN, 'Not authorized');
        }

        if (friendship.status === FriendshipStatus.ACCEPTED) {
            return friendRepository.removeFriend(friendship.requesterId, friendship.receiverId);
        }

        if (friendship.status === FriendshipStatus.PENDING) {
            if (friendship.requesterId === userId) {
                return friendRepository.deleteById(friendshipId);
            }
            throw new AppError(
                ErrorCode.VALIDATION_ERROR,
                'Use the reject endpoint to decline a pending request'
            );
        }

        throw new AppError(
            ErrorCode.VALIDATION_ERROR,
            'Friendship is not active. Use cancel or reject for pending requests'
        );
    }

    static async listFriends(userId: string) {
        return friendRepository.listFriends(userId);
    }

    static async listRequests(userId: string) {
        return friendRepository.listPendingRequests(userId);
    }
}
