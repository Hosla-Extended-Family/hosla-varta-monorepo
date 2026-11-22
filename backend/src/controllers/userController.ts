import { Request, Response } from 'express';
import { asyncHandler } from '../middlewares/asyncHandler';
import prisma from '../config/database';
import { AppError } from '../utils/AppError';
import { ErrorCode } from '../utils/errorCodes';
import { UploadService } from '../services/uploadService';
import { Gender, ProfileVisibility, FriendshipStatus } from '@prisma/client';

export class UserController {

    static updateProfile = asyncHandler(async (req: Request, res: Response) => {
        const userId = (req as any).user?.id;
        if (!userId) {
            throw new AppError(ErrorCode.UNAUTHORIZED, 'User authentication failed');
        }

        const { name, dateOfBirth, email, gender, bio } = req.body;

        const [day, month, year] = dateOfBirth.split('-').map(Number);
        const dobDate = new Date(year, month - 1, day);

        if (isNaN(dobDate.getTime())) {
            throw new AppError(ErrorCode.VALIDATION_ERROR, 'Invalid date of birth');
        }

        if (email) {
            const existingUser = await prisma.user.findFirst({
                where: {
                    email,
                    id: { not: userId },
                },
            });

            if (existingUser) {
                throw new AppError(ErrorCode.USER_ALREADY_EXISTS, 'Email is already in use');
            }
        }

        let profilePicUrl: string | undefined;
        if (req.file) {
            const processedFilename = await UploadService.processImage(req.file, {
                quality: 85,
                width: 400,
            });
            profilePicUrl = `/uploads/${processedFilename}`;
        }

        const updatedUser = await prisma.user.update({
            where: { id: userId },
            data: {
                name,
                dateOfBirth: dobDate,
                email: email || null,
                gender: gender as Gender,
                bio: bio || null,
                ...(profilePicUrl && { profilePicUrl }),
            },
        });

        res.status(200).json({
            success: true,
            message: 'Profile updated successfully',
            data: {
                user: updatedUser,
            },
        });
    });

    static getProfile = asyncHandler(async (req: Request, res: Response) => {
        const userId = (req as any).user?.id;

        const user = await prisma.user.findUnique({
            where: { id: userId },
        });

        if (!user) {
            throw new AppError(ErrorCode.USER_NOT_FOUND, 'User not found');
        }

        res.status(200).json({
            success: true,
            data: {
                user,
            },
        });
    });

    static getUserProfile = asyncHandler(async (req: Request, res: Response) => {
        const { userId } = req.params;
        const viewerId = (req as any).user?.id;

        const user = await prisma.user.findUnique({
            where: { id: userId },
            select: {
                id: true,
                name: true,
                bio: true,
                profilePicUrl: true,
                profileVisibility: true,
                role: true,
            },
        });

        if (!user) {
            throw new AppError(ErrorCode.USER_NOT_FOUND, 'User not found');
        }

        const isSelf = userId === viewerId;
        const isAdmin = (req as any).user?.role === 'ADMIN';

        if (isSelf || isAdmin) {
            return res.status(200).json({ success: true, data: { user } });
        }

        // Check if blocked
        const blocked = await prisma.blockedUser.findFirst({
            where: {
                OR: [
                    { blockerId: viewerId, blockedId: userId },
                    { blockerId: userId, blockedId: viewerId },
                ],
            },
        });

        if (blocked) {
            // "Cannot see profile" -> 404 per instructions ("Otherwise return 404 (not forbidden)")
            throw new AppError(ErrorCode.USER_NOT_FOUND, 'User not found');
        }

        // Check Visibility
        // PUBLIC: Allow
        // FRIENDS: Allow if friends

        let friendshipStatus: 'NOT_FRIENDS' | 'PENDING' | 'ACCEPTED' | 'REJECTED' | 'BLOCKED' = 'NOT_FRIENDS';
        let friendshipId: string | null = null;
        let isIncoming = false;

        if (viewerId) {
            const friendship = await prisma.friendship.findFirst({
                where: {
                    OR: [
                        { requesterId: viewerId, receiverId: userId },
                        { requesterId: userId, receiverId: viewerId }
                    ],
                }
            });

            if (friendship) {
                friendshipStatus = friendship.status as any;
                friendshipId = friendship.id;
                isIncoming = friendship.receiverId === viewerId;
            }
        }

        res.status(200).json({
            success: true,
            data: {
                user,
                friendshipStatus,
                friendshipId,
                isIncoming
            },
        });
    });

    static searchUsers = asyncHandler(async (req: Request, res: Response) => {
        const q = req.query.q as string;
        const viewerId = (req as any).user?.id;
        const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);
        const page = Math.max(parseInt(req.query.page as string) || 1, 1);
        const skip = (page - 1) * limit;

        if (!q || q.trim().length === 0) {
            return res.status(200).json({
                success: true,
                data: { users: [], pagination: { page, limit, total: 0, totalPages: 0 } }
            });
        }

        const query = q.trim();

        const where: any = {
            AND: [
                { id: { not: viewerId } },
                { isDeleted: false },
                { isActive: true },
                {
                    OR: [
                        { name: { contains: query, mode: 'insensitive' } },
                        { email: { contains: query, mode: 'insensitive' } },
                        { phone: { contains: query, mode: 'insensitive' } },
                    ],
                },
            ],
        };

        const [users, totalCount] = await Promise.all([
            prisma.user.findMany({
                where,
                select: {
                    id: true,
                    name: true,
                    profilePicUrl: true,
                    bio: true,
                    role: true,
                    sentFriendRequests: {
                        where: { receiverId: viewerId },
                        select: { id: true, status: true }
                    },
                    receivedFriendRequests: {
                        where: { requesterId: viewerId },
                        select: { id: true, status: true }
                    }
                },
                take: limit,
                skip,
                orderBy: { name: 'asc' }
            }),
            prisma.user.count({ where })
        ]);

        const formattedUsers = users.map(user => {
            let friendshipStatus = 'NOT_FRIENDS';
            let friendshipId = null;

            const incoming = user.sentFriendRequests[0];
            const outgoing = user.receivedFriendRequests[0];

            if (incoming) {
                friendshipStatus = incoming.status;
                friendshipId = incoming.id;
            } else if (outgoing) {
                friendshipStatus = outgoing.status;
                friendshipId = outgoing.id;
            }

            return {
                id: user.id,
                name: user.name,
                profilePicUrl: user.profilePicUrl,
                bio: user.bio,
                role: user.role,
                friendshipStatus,
                friendshipId
            };
        });

        res.status(200).json({
            success: true,
            data: {
                users: formattedUsers,
                pagination: {
                    page,
                    limit,
                    total: totalCount,
                    totalPages: Math.ceil(totalCount / limit),
                },
            },
        });
    });
}
