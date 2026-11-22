import type { Socket } from 'socket.io';
import { getIO } from '../config/socket';
import logger from '../utils/logger';
import { ChatService } from '../services/chatService';
import { AppError } from '../utils/AppError';

const MESSAGE_RATE_LIMIT = 30;
const RATE_WINDOW_MS = 10_000;

interface RateBucket {
    count: number;
    resetAt: number;
}

const rateBuckets = new Map<string, RateBucket>();

function allowSend(socketId: string): boolean {
    const now = Date.now();
    const bucket = rateBuckets.get(socketId);
    if (!bucket || bucket.resetAt < now) {
        rateBuckets.set(socketId, { count: 1, resetAt: now + RATE_WINDOW_MS });
        return true;
    }
    if (bucket.count >= MESSAGE_RATE_LIMIT) return false;
    bucket.count += 1;
    return true;
}

type AckCallback = (response: { ok: boolean; error?: string; data?: unknown }) => void;
type SocketLike = { emit: (event: string, payload: unknown) => void };

export const registerChatHandlers = (socket: Socket) => {
    const userId = socket.data.userId as string;

    void ChatService.flushPendingMessages(userId, socket as unknown as SocketLike);

    socket.on('chat:join', async (payload: { conversationId: string }, ack?: AckCallback) => {
        try {
            await ChatService.assertMembership(userId, payload.conversationId);
            socket.join(`chat:${payload.conversationId}`);
            ack?.({ ok: true });
        } catch (error) {
            ack?.({ ok: false, error: error instanceof AppError ? error.message : 'Cannot join chat' });
        }
    });

    socket.on(
        'chat:typing',
        async (payload: { conversationId: string; isTyping: boolean }) => {
            try {
                await ChatService.assertMembership(userId, payload.conversationId);
                socket.to(`chat:${payload.conversationId}`).emit('chat:typing', {
                    conversationId: payload.conversationId,
                    userId,
                    isTyping: !!payload.isTyping,
                });
            } catch (error) {
                logger.warn('chat:typing failed:', error instanceof Error ? error.message : error);
            }
        }
    );

    socket.on('chat:send', async (payload: { conversationId: string; content: string }, ack?: AckCallback) => {
        if (!allowSend(socket.id)) {
            ack?.({ ok: false, error: 'Sending too fast. Slow down.' });
            return;
        }

        try {
            const { message, recipientIds } = await ChatService.sendMessage(
                userId,
                payload.conversationId,
                String(payload.content ?? '')
            );

            ack?.({ ok: true, data: message });

            socket.join(`chat:${payload.conversationId}`);
            socket.to(`chat:${payload.conversationId}`).emit('chat:new_message', {
                ...message,
                createdAt: message.createdAt.toISOString(),
            });

            for (const recipientId of recipientIds) {
                getIO()
                    ?.to(`user:${recipientId}`)
                    .emit('chat:refresh_conversations', { conversationId: payload.conversationId });
            }
        } catch (error) {
            const messageText =
                error instanceof AppError ? error.message : 'Failed to send message';
            logger.warn('chat:send failed:', error instanceof Error ? error.message : error);
            ack?.({ ok: false, error: messageText });
        }
    });

    socket.on('chat:read', async (payload: { conversationId: string }) => {
        try {
            await ChatService.markChatRead(userId, payload.conversationId);
            socket.to(`chat:${payload.conversationId}`).emit('chat:read_receipt', {
                conversationId: payload.conversationId,
                userId,
                readAt: new Date().toISOString(),
            });
        } catch (error) {
            logger.warn('chat:read failed:', error instanceof Error ? error.message : error);
        }
    });
};
