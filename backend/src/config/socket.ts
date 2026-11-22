import { Server as SocketServer, Socket } from 'socket.io';
import type { Server as HttpServer } from 'http';
import jwt from 'jsonwebtoken';
import config from './index';
import prisma from './database';
import logger from '../utils/logger';

let io: SocketServer | null = null;

const onlineUsers = new Map<string, Set<string>>();

export const initSocket = (httpServer: HttpServer): SocketServer => {
    io = new SocketServer(httpServer, {
        cors: {
            origin: config.env === 'development' ? '*' : [config.app.url],
            credentials: true,
        },
        maxHttpBufferSize: 1e4,
        pingTimeout: 30000,
    });

    io.use(async (socket, next) => {
        try {
            const token =
                (socket.handshake.auth?.token as string) ||
                (socket.handshake.headers.authorization || '').replace('Bearer ', '');

            if (!token) {
                return next(new Error('Authentication required'));
            }

            const payload = jwt.verify(token, config.jwt.accessSecret) as { sub?: string };
            if (!payload.sub) {
                return next(new Error('Invalid token'));
            }

            const user = await prisma.user.findUnique({
                where: { id: payload.sub },
                select: { id: true, name: true, isActive: true, isDeleted: true },
            });

            if (!user || user.isDeleted || !user.isActive) {
                return next(new Error('User not found or deactivated'));
            }

            socket.data.userId = user.id;
            socket.data.userName = user.name;
            next();
        } catch (error) {
            logger.warn('Socket auth failed:', error instanceof Error ? error.message : error);
            next(new Error('Invalid token'));
        }
    });

    io.on('connection', (socket: Socket) => {
        const userId = socket.data.userId as string;

        const sockets = onlineUsers.get(userId) || new Set<string>();
        const wasOffline = sockets.size === 0;
        sockets.add(socket.id);
        onlineUsers.set(userId, sockets);

        socket.join(`user:${userId}`);
        logger.info(`Socket connected: user=${userId} socket=${socket.id}`);

        if (wasOffline) {
            io?.emit('presence:update', { userId, isOnline: true });
        }

        socket.on('disconnect', () => {
            const set = onlineUsers.get(userId);
            if (set) {
                set.delete(socket.id);
                if (set.size === 0) {
                    onlineUsers.delete(userId);
                    io?.emit('presence:update', { userId, isOnline: false });
                }
            }
            logger.info(`Socket disconnected: user=${userId} socket=${socket.id}`);
        });

        socket.emit('connected', { userId });
    });

    logger.info('Socket.IO initialized');
    return io;
};

export const getIO = (): SocketServer => {
    if (!io) {
        throw new Error('Socket.IO not initialized');
    }
    return io;
};

export const isSocketReady = () => io !== null;

export const isUserOnline = (userId: string) => onlineUsers.has(userId);

export const getOnlineUserIds = () => Array.from(onlineUsers.keys());
