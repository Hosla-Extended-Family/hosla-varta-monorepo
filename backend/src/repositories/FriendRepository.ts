import prisma from '../config/database';
import { FriendshipStatus } from '@prisma/client';

const userSelect = {
    select: {
        id: true,
        name: true,
        profilePicUrl: true,
    },
};

export class FriendRepository {
    async createRequest(requesterId: string, receiverId: string) {
        return prisma.friendship.create({
            data: {
                requesterId,
                receiverId,
                status: FriendshipStatus.PENDING,
            },
        });
    }

    async getFriendship(user1Id: string, user2Id: string) {
        return prisma.friendship.findFirst({
            where: {
                OR: [
                    { requesterId: user1Id, receiverId: user2Id },
                    { requesterId: user2Id, receiverId: user1Id },
                ],
            },
            orderBy: { createdAt: 'desc' },
        });
    }

    async getFriendshipsBetween(user1Id: string, user2Id: string) {
        return prisma.friendship.findMany({
            where: {
                OR: [
                    { requesterId: user1Id, receiverId: user2Id },
                    { requesterId: user2Id, receiverId: user1Id },
                ],
            },
            orderBy: { createdAt: 'desc' },
        });
    }

    async getFriendshipById(id: string) {
        return prisma.friendship.findUnique({
            where: { id },
            include: {
                requester: { ...userSelect },
                receiver: { ...userSelect },
            },
        });
    }

    async acceptRequest(friendshipId: string) {
        return prisma.friendship.update({
            where: { id: friendshipId },
            data: {
                status: FriendshipStatus.ACCEPTED,
                acceptedAt: new Date(),
            },
            include: {
                requester: { ...userSelect },
                receiver: { ...userSelect },
            },
        });
    }

    async redirectRequest(friendshipId: string, newRequesterId: string, newReceiverId: string) {
        return prisma.friendship.update({
            where: { id: friendshipId },
            data: {
                requesterId: newRequesterId,
                receiverId: newReceiverId,
                status: FriendshipStatus.PENDING,
                acceptedAt: null,
                createdAt: new Date(),
            },
        });
    }

    async deleteStaleBetween(user1Id: string, user2Id: string, keepId: string) {
        await prisma.friendship.deleteMany({
            where: {
                OR: [
                    { requesterId: user1Id, receiverId: user2Id },
                    { requesterId: user2Id, receiverId: user1Id },
                ],
                NOT: { id: keepId },
            },
        });
    }

    async resetToPending(friendshipId: string) {
        return prisma.friendship.update({
            where: { id: friendshipId },
            data: {
                status: FriendshipStatus.PENDING,
                acceptedAt: null,
                createdAt: new Date(),
            },
        });
    }

    async rejectRequest(friendshipId: string) {
        return prisma.friendship.update({
            where: { id: friendshipId },
            data: { status: FriendshipStatus.REJECTED },
        });
    }

    async deleteById(id: string) {
        return prisma.friendship.delete({ where: { id } });
    }

    async removeFriend(user1Id: string, user2Id: string) {
        await prisma.$transaction(async (tx) => {
            await tx.friendship.deleteMany({
                where: {
                    OR: [
                        { requesterId: user1Id, receiverId: user2Id },
                        { requesterId: user2Id, receiverId: user1Id },
                    ],
                },
            });
        });
    }

    async listFriends(userId: string) {
        const rows = await prisma.friendship.findMany({
            where: {
                OR: [
                    { requesterId: userId },
                    { receiverId: userId },
                ],
                status: FriendshipStatus.ACCEPTED,
            },
            include: {
                requester: { ...userSelect },
                receiver: { ...userSelect },
            },
            orderBy: { acceptedAt: 'desc' },
        });

        const seen = new Set<string>();
        const result: Array<{
            id: string;
            requesterId: string;
            receiverId: string;
            status: FriendshipStatus;
            createdAt: Date;
            acceptedAt: Date | null;
            receiver: { id: string; name: string; profilePicUrl: string | null };
        }> = [];

        for (const row of rows) {
            const friend = row.requesterId === userId ? row.receiver : row.requester;
            if (seen.has(friend.id)) continue;
            seen.add(friend.id);
            result.push({
                id: row.id,
                requesterId: row.requesterId,
                receiverId: row.receiverId,
                status: row.status,
                createdAt: row.createdAt,
                acceptedAt: row.acceptedAt,
                receiver: {
                    id: friend.id,
                    name: friend.name,
                    profilePicUrl: friend.profilePicUrl,
                },
            });
        }

        return result;
    }

    async listPendingRequests(userId: string) {
        const rows = await prisma.friendship.findMany({
            where: {
                OR: [
                    { receiverId: userId },
                    { requesterId: userId },
                ],
                status: FriendshipStatus.PENDING,
            },
            include: {
                requester: { ...userSelect },
                receiver: { ...userSelect },
            },
            orderBy: { createdAt: 'desc' },
        });

        return rows.map((row) => ({
            ...row,
            direction: row.requesterId === userId ? ('outgoing' as const) : ('incoming' as const),
        }));
    }

    async checkFriendshipStatus(user1Id: string, user2Id: string): Promise<FriendshipStatus | null> {
        const friendship = await prisma.friendship.findFirst({
            where: {
                OR: [
                    { requesterId: user1Id, receiverId: user2Id },
                    { requesterId: user2Id, receiverId: user1Id },
                ],
            },
            orderBy: { createdAt: 'desc' },
            select: { status: true },
        });
        return friendship ? friendship.status : null;
    }
}
