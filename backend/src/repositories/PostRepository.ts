import prisma from '../config/database';
import { PostStatus, PostVisibility, FriendshipStatus, Role } from '@prisma/client';

export interface FeedCursor {
    isPinned: boolean;
    rolePriority: number;
    publishedAt: Date;
    id: string;
}

export class PostRepository {
    async getFeed(
        userId: string,
        isAdmin: boolean,
        limit: number,
        cursor?: FeedCursor,
        includeHidden: boolean = false
    ) {
        const statusFilter = includeHidden && isAdmin ? {} : { status: PostStatus.PUBLISHED };

        const visibilityFilter = isAdmin ? {} : {
            OR: [
                
                { visibility: PostVisibility.PUBLIC },

              
                {
                    visibility: PostVisibility.ONLY_ME,
                    authorId: userId
                },


                {
                    visibility: PostVisibility.FRIENDS,
                    OR: [
                        { authorId: userId }, // Own post
                        {
                            author: {
                                receivedFriendRequests: {
                                    some: {
                                        requesterId: userId,
                                        status: FriendshipStatus.ACCEPTED
                                    }
                                }
                            }
                        }
                    ]
                }
            ]
        };



        let cursorWhere = {};
        if (cursor) {
            cursorWhere = {
                OR: [
                    ...(cursor.isPinned ? [{ isPinned: false }] : []),
                    { isPinned: cursor.isPinned, rolePriority: { lt: cursor.rolePriority } },
                    {
                        isPinned: cursor.isPinned,
                        rolePriority: cursor.rolePriority,
                        publishedAt: { lt: cursor.publishedAt }
                    },
                    {
                        isPinned: cursor.isPinned,
                        rolePriority: cursor.rolePriority,
                        publishedAt: cursor.publishedAt,
                        id: { lt: cursor.id }
                    },
                ]
            };
        }

        const where = {
            ...statusFilter,
            ...visibilityFilter,
            ...cursorWhere,
  
            author: {
                blockedUsers: {
                    none: { blockedId: userId }
                },
                blockedBy: {
                    none: { blockerId: userId }
                }
            }
        };

        return prisma.post.findMany({
            where,
            take: limit + 1,
            orderBy: [
                { isPinned: 'desc' },
                { rolePriority: 'desc' },
                { publishedAt: 'desc' },
                { id: 'desc' },
            ],
            include: {
                author: {
                    select: {
                        id: true,
                        name: true,
                        profilePicUrl: true,
                        role: true,
                    },
                },
                tags: true,
                _count: {
                    select: {
                        likes: true,
                        comments: true,
                    },
                },
            },
        });
    }

    async getById(id: string) {
        return prisma.post.findUnique({
            where: { id },
            include: {
                author: {
                    select: {
                        id: true,
                        name: true,
                        profilePicUrl: true,
                        role: true,
                    },
                },
                tags: true,
                _count: {
                    select: {
                        likes: true,
                        comments: true,
                    },
                },
            },
        });
    }
}
