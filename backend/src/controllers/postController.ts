import { Request, Response } from 'express';
import { asyncHandler } from '../middlewares/asyncHandler';
import prisma from '../config/database';
import { AppError } from '../utils/AppError';
import { ErrorCode } from '../utils/errorCodes';
import { Role, PostStatus } from '@prisma/client';
import logger from '../utils/logger';
import { TextFilterService } from '../services/textFilterService';
import { ROLE_PRIORITIES } from '../config/feedConfig';
import { formatDate } from '../utils/dateUtils';
import { PostRepository, FeedCursor } from '../repositories/PostRepository';
import { PostVisibility } from '@prisma/client';
import { UploadService } from '../services/uploadService';

const postRepository = new PostRepository();

interface EncodedCursor {
    isPinned: boolean;
    rolePriority: number;
    publishedAt: string;
    id: string;
}

const encodeCursor = (cursor: EncodedCursor): string => {
    return Buffer.from(JSON.stringify(cursor)).toString('base64');
};

const decodeCursor = (cursorStr: string): EncodedCursor | null => {
    try {
        return JSON.parse(Buffer.from(cursorStr, 'base64').toString('ascii'));
    } catch {
        return null;
    }
};

export class PostController {
    private static formatPostResponse(post: any, viewerId?: string, viewerRole?: Role, likedPostIds?: Set<string>, savedPostIds?: Set<string>) {
        const isAuthor = viewerId === post.authorId;
        const isAdmin = viewerRole === Role.ADMIN;
        const isUser = viewerRole === Role.USER;

        return {
            id: post.id,
            title: post.title,
            body: post.body,
            visibility: post.visibility,
            mediaUrls: post.mediaUrls,
            youtubeVideoId: post.youtubeVideoId,
            tags: post.tags, // Return array of tags
            isPinned: post.isPinned,
            createdAt: formatDate(post.createdAt),


            authorId: post.author.id,
            authorName: post.author.name,
            authorProfilePicUrl: post.author.profilePicUrl,


            isLikedByMe: likedPostIds ? likedPostIds.has(post.id) : false,
            isSavedByMe: savedPostIds ? savedPostIds.has(post.id) : false,
            likeCount: post._count.likes,
            commentCount: post._count.comments,


            canEdit: isAuthor,
            canDelete: isAuthor || isAdmin,
            canReport: !!viewerId && !isAuthor && isUser,
        };
    }

    static createPost = asyncHandler(async (req: Request, res: Response) => {
        logger.info('Create Post Payload', {
            body: req.body,
            files: req.files ? (req.files as any[]).map((f: any) => f.originalname) : []
        });
        const { title, body, youtubeVideoId, isPinned, tagIds, visibility } = req.body;
        let { mediaUrls } = req.body;
        const user = req.user!;

        // Handle uploaded files
        if (req.files && Array.isArray(req.files) && req.files.length > 0) {
            const uploadedUrls = await Promise.all(
                (req.files as Express.Multer.File[]).map(async (file) => {
                    const fileType = file.mimetype.split('/')[0];
                    if (fileType === 'image') {
                        const processedFilename = await UploadService.processImage(file);
                        return `/uploads/${processedFilename}`;
                    } else {
                        return `/uploads/${file.filename}`;
                    }
                })
            );

            // Initialize or append to mediaUrls
            if (!mediaUrls) {
                mediaUrls = uploadedUrls;
            } else if (Array.isArray(mediaUrls)) {
                mediaUrls = [...mediaUrls, ...uploadedUrls];
            } else {
                // If mediaUrls came as a string (from single input in multipart), convert to array
                mediaUrls = [mediaUrls, ...uploadedUrls];
            }
        }

        if (isPinned && user.role !== Role.ADMIN && user.role !== Role.STAFF) {
            throw new AppError(ErrorCode.FORBIDDEN, 'Only Admin/Staff can pin posts');
        }

        const filterResult = await TextFilterService.checkContent((title || '') + ' ' + body);

        if (!filterResult.isAllowed) {
            throw new AppError(ErrorCode.VALIDATION_ERROR, filterResult.description || 'Content violations found');
        }

        const status = filterResult.status;

        // Handle tags
        let finalTagIds: string[] = [];

        // If 'tags' (names) provided, look them up
        if (req.body.tags) {
            const inputTags = Array.isArray(req.body.tags) ? req.body.tags : [req.body.tags];
            const validTags = await prisma.tag.findMany({
                where: { name: { in: inputTags } },
                select: { id: true }
            });
            finalTagIds = [...finalTagIds, ...validTags.map(t => t.id)];
        }

        // If 'tag' (singular name) provided - legacy/alternative support
        if (req.body.tag) {
            const singleTag = await prisma.tag.findUnique({ where: { name: req.body.tag } });
            if (singleTag) finalTagIds.push(singleTag.id);
        }

        // If 'tagIds' (IDs) provided, allow that too
        if (tagIds) {
            let parsedTagIds = tagIds;
            if (typeof tagIds === 'string') {
                try {
                    parsedTagIds = JSON.parse(tagIds);
                } catch {
                    if (tagIds.startsWith('[') && tagIds.endsWith(']')) {
                        parsedTagIds = tagIds.slice(1, -1).split(',').map((id: string) => id.trim());
                    } else {
                        parsedTagIds = [tagIds];
                    }
                }
            }
            if (Array.isArray(parsedTagIds) && parsedTagIds.length > 0) {
                finalTagIds = [...finalTagIds, ...parsedTagIds];
            }
        }

        // Deduplicate
        finalTagIds = [...new Set(finalTagIds)];

        if (finalTagIds.length === 0) {
            // Default tag if none provided
            const defaultTag = await prisma.tag.findUnique({ where: { name: 'DEFAULT' } });
            if (defaultTag) finalTagIds = [defaultTag.id];
        }

        // Calculate rolePriority based on tags
        let rolePriority = ROLE_PRIORITIES[user.role] || 10;

        if (finalTagIds.length > 0) {
            const tags = await prisma.tag.findMany({
                where: { id: { in: finalTagIds } },
                select: { priority: true }
            });

            if (tags.length > 0) {
                const maxTagPriority = Math.max(...tags.map(t => t.priority));
                rolePriority = Math.max(rolePriority, maxTagPriority);
            }
        }

        const post = await prisma.post.create({
            data: {
                authorId: user.id,
                title,
                body,
                mediaUrls: mediaUrls || [],
                youtubeVideoId,
                isPinned: isPinned || false,
                status,
                rolePriority,
                visibility: visibility || PostVisibility.PUBLIC,
                tags: {
                    connect: finalTagIds.map(id => ({ id }))
                }
            },
            include: {
                author: {
                    select: {
                        id: true,
                        name: true,
                        profilePicUrl: true,
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

        logger.info('Post created', {
            postId: post.id,
            authorId: user.id,
            status,
        });

        const flattenedPost = PostController.formatPostResponse(
            post,
            user.id,
            user.role,
            undefined,
            undefined
        );

        res.status(201).json({
            success: true,
            data: { post: flattenedPost },
        });
    });

    static getFeed = asyncHandler(async (req: Request, res: Response) => {
        const limit = parseInt(req.query.limit as string) || 20;
        const cursorStr = req.query.cursor as string;
        const page = req.query.page ? parseInt(req.query.page as string) : null;

        const includeHidden = req.query.includeHidden === 'true';
        const isAdmin = req.user?.role === Role.ADMIN;
        const viewerId = req.user?.id;
        const viewerRole = req.user?.role;

        if (!viewerId) {
            // Should be handled by verifyToken, but strictly:
            throw new AppError(ErrorCode.UNAUTHORIZED, 'User not authenticated');
        }

        let cursor: FeedCursor | undefined;
        if (cursorStr) {
            const decoded = decodeCursor(cursorStr);
            if (decoded) {
                cursor = {
                    isPinned: decoded.isPinned,
                    rolePriority: decoded.rolePriority,
                    publishedAt: new Date(decoded.publishedAt),
                    id: decoded.id
                };
            }
        }

        const rawPosts = await postRepository.getFeed(viewerId, isAdmin, limit, cursor, includeHidden);

        let nextCursor: string | null = null;

        if (rawPosts.length > limit) {
            rawPosts.pop();

            if (rawPosts.length > 0) {
                const lastPost = rawPosts[rawPosts.length - 1];
                nextCursor = encodeCursor({
                    isPinned: lastPost.isPinned,
                    rolePriority: lastPost.rolePriority,
                    publishedAt: lastPost.publishedAt.toISOString(),
                    id: lastPost.id,
                });
            }
        }

        const likedPostIds = new Set<string>();
        const savedPostIds = new Set<string>();

        if (viewerId) {
            const likes = await prisma.like.findMany({
                where: {
                    userId: viewerId,
                    postId: { in: rawPosts.map(p => p.id) }
                },
                select: { postId: true }
            });
            likes.forEach(l => likedPostIds.add(l.postId));

            const savedPosts = await prisma.savedPost.findMany({
                where: {
                    userId: viewerId,
                    postId: { in: rawPosts.map(p => p.id) }
                },
                select: { postId: true }
            });
            savedPosts.forEach((sp: any) => savedPostIds.add(sp.postId));
        }

        const posts = rawPosts.map(post => PostController.formatPostResponse(
            post,
            viewerId,
            viewerRole,
            likedPostIds,
            savedPostIds
        ));

        res.status(200).json({
            success: true,
            data: {
                posts,
                nextCursor,
                pagination: page ? { page, limit } : undefined
            },
        });
    });

    static deletePost = asyncHandler(async (req: Request, res: Response) => {
        const { id } = req.params;
        const user = req.user!;

        const post = await prisma.post.findUnique({ where: { id } });
        if (!post) {
            throw new AppError(ErrorCode.NOT_FOUND, 'Post not found');
        }

        const isAuthor = post.authorId === user.id;
        const isAdmin = user.role === Role.ADMIN;

        if (!isAuthor && !isAdmin) {
            throw new AppError(ErrorCode.FORBIDDEN, 'You can only delete your own posts');
        }

        await prisma.post.update({
            where: { id },
            data: { status: PostStatus.DELETED },
        });

        res.status(200).json({
            success: true,
            message: 'Post deleted successfully',
        });
    });

    static updatePost = asyncHandler(async (req: Request, res: Response) => {
        logger.info('Update Post Payload', {
            body: req.body,
            files: req.files ? (req.files as any[]).map((f: any) => f.originalname) : []
        });
        const { id } = req.params;
        const { title, body, mediaUrls, youtubeVideoId, isPinned, tagIds, visibility } = req.body;
        const user = req.user!;

        const post = await prisma.post.findUnique({ where: { id } },);
        if (!post) {
            throw new AppError(ErrorCode.NOT_FOUND, 'Post not found');
        }

        const isAuthor = post.authorId === user.id;
        const isAdmin = user.role === Role.ADMIN;

        if (!isAuthor && !isAdmin) {
            throw new AppError(ErrorCode.FORBIDDEN, 'You can only edit your own posts');
        }

        if (isPinned !== undefined) {
            if (user.role !== Role.ADMIN && user.role !== Role.STAFF) {
                throw new AppError(ErrorCode.FORBIDDEN, 'Only Admin/Staff can pin posts');
            }
        }

        let newStatus: PostStatus | undefined;


        if (title || body) {
            const checkText = (title || post.title || '') + ' ' + (body || post.body || '');
            const filterResult = await TextFilterService.checkContent(checkText);

            if (!filterResult.isAllowed) {
                throw new AppError(ErrorCode.VALIDATION_ERROR, filterResult.description || 'Content violations found');
            }


            if (filterResult.status === PostStatus.PUBLISHED) {
                newStatus = PostStatus.PUBLISHED;
            } else {
                newStatus = filterResult.status;
            }
        }

        // Handle tags update if provided
        let tagsUpdate = undefined;
        let finalTagIds: string[] | undefined = undefined;

        if (req.body.tags || req.body.tag || tagIds) {
            finalTagIds = [];

            if (req.body.tags) {
                const inputTags = Array.isArray(req.body.tags) ? req.body.tags : [req.body.tags];
                const validTags = await prisma.tag.findMany({
                    where: { name: { in: inputTags } },
                    select: { id: true }
                });
                finalTagIds = [...finalTagIds, ...validTags.map(t => t.id)];
            }

            if (req.body.tag) {
                const singleTag = await prisma.tag.findUnique({ where: { name: req.body.tag } });
                if (singleTag) finalTagIds.push(singleTag.id);
            }

            if (tagIds) {
                let parsedTagIds = tagIds;
                if (typeof tagIds === 'string') {
                    try {
                        parsedTagIds = JSON.parse(tagIds);
                    } catch {
                        if (tagIds.startsWith('[') && tagIds.endsWith(']')) {
                            parsedTagIds = tagIds.slice(1, -1).split(',').map((id: string) => id.trim());
                        } else {
                            parsedTagIds = [tagIds];
                        }
                    }
                }
                if (Array.isArray(parsedTagIds)) {
                    finalTagIds = [...finalTagIds, ...parsedTagIds];
                }
            }

            // Deduplicate
            finalTagIds = [...new Set(finalTagIds)];

            tagsUpdate = {
                set: finalTagIds.map(id => ({ id }))
            };
        }

        let rolePriority = undefined;

        if (finalTagIds && finalTagIds.length > 0) {
            const tags = await prisma.tag.findMany({
                where: { id: { in: finalTagIds } },
                select: { priority: true }
            });

            if (tags.length > 0) {
                const maxTagPriority = Math.max(...tags.map(t => t.priority));
                const userBasePriority = ROLE_PRIORITIES[user.role] || 10;
                rolePriority = Math.max(userBasePriority, maxTagPriority);
            }
        }


        const updatedPost = await prisma.post.update({
            where: { id },
            data: {
                title,
                body,
                mediaUrls,
                youtubeVideoId,
                ...(tagsUpdate && { tags: tagsUpdate }),
                ...(rolePriority !== undefined && { rolePriority }),
                ...(isPinned !== undefined && { isPinned }),
                ...(newStatus && { status: newStatus }),
                ...(visibility && { visibility }),
            },
            include: {
                author: {
                    select: {
                        id: true,
                        name: true,
                        profilePicUrl: true,
                        role: true, // Ensuring role is selected for consistency
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

        const like = await prisma.like.findUnique({
            where: {
                postId_userId: {
                    postId: id,
                    userId: user.id,
                },
            },
        });

        const flattenedPost = PostController.formatPostResponse(
            updatedPost,
            user.id,
            user.role,
            like ? new Set([like.postId]) : undefined,
            undefined
        );

        res.status(200).json({
            success: true,
            data: { post: flattenedPost },
        });
    });

    static adminHidePost = asyncHandler(async (req: Request, res: Response) => {
        const { id } = req.params;
        const adminId = req.user!.id;

        const post = await prisma.post.findUnique({ where: { id } });
        if (!post) {
            throw new AppError(ErrorCode.NOT_FOUND, 'Post not found');
        }

        const updatedPost = await prisma.post.update({
            where: { id },
            data: { status: PostStatus.HIDDEN },
            include: { tags: true } // Include tags in response
        });

        logger.warn('Post hidden by Admin', {
            postId: id,
            adminId,
            timestamp: new Date(),
        });

        res.status(200).json({
            success: true,
            message: 'Post hidden successfully',
            data: { post: updatedPost },
        });
    });

    static adminRestorePost = asyncHandler(async (req: Request, res: Response) => {
        const { id } = req.params;
        const adminId = req.user!.id;

        const post = await prisma.post.findUnique({ where: { id } });
        if (!post) {
            throw new AppError(ErrorCode.NOT_FOUND, 'Post not found');
        }

        const updatedPost = await prisma.post.update({
            where: { id },
            data: { status: PostStatus.PUBLISHED },
            include: { tags: true }
        });

        logger.info('Post restored by Admin', {
            postId: id,
            adminId,
            timestamp: new Date(),
        });

        res.status(200).json({
            success: true,
            message: 'Post restored successfully',
            data: { post: updatedPost },
        });
    });

    static getUserPosts = asyncHandler(async (req: Request, res: Response) => {
        const { userId } = req.params;
        const viewerId = req.user?.id;
        const viewerRole = req.user?.role;
        const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);
        const page = Math.max(parseInt(req.query.page as string) || 1, 1);
        const skip = (page - 1) * limit;
        const skipCount = req.query.skipCount === 'true';

        logger.info('Fetching user posts', { userId, viewerId, page, limit });

        const user = await prisma.user.findUnique({
            where: { id: userId },
        });

        if (!user) {
            logger.warn('User not found for getUserPosts', { userId, viewerId });
            return res.status(200).json({
                success: true,
                data: {
                    posts: [],
                    pagination: { page, limit, total: 0, totalPages: 0 },
                },
            });
        }

        if (user.isDeleted) {
            logger.info('Deleted user profile accessed', { userId, viewerId });
            return res.status(200).json({
                success: true,
                data: {
                    posts: [],
                    pagination: { page, limit, total: 0, totalPages: 0 },
                },
            });
        }

        if (viewerId && viewerId !== userId) {
            const isBlocked = await prisma.blockedUser.findFirst({
                where: {
                    OR: [
                        { blockerId: viewerId, blockedId: userId },
                        { blockerId: userId, blockedId: viewerId },
                    ],
                },
            });

            if (isBlocked) {
                logger.info('Blocked user profile access blocked', { userId, viewerId });
                return res.status(200).json({
                    success: true,
                    data: {
                        posts: [],
                        pagination: { page, limit, total: 0, totalPages: 0 },
                    },
                });
            }
        }

        const where: any = {
            authorId: userId,
            status: PostStatus.PUBLISHED,
        };

        if (viewerId === userId || viewerRole === Role.ADMIN) {
            delete where.status;
        }

        const posts = await prisma.post.findMany({
            where,
            take: limit,
            skip,
            orderBy: { createdAt: 'desc' },
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

        const likedPostIds = new Set<string>();
        const savedPostIds = new Set<string>();

        if (viewerId && posts.length > 0) {
            const likes = await prisma.like.findMany({
                where: {
                    userId: viewerId,
                    postId: { in: posts.map(p => p.id) },
                },
                select: { postId: true },
            });
            likes.forEach(l => likedPostIds.add(l.postId));

            const savedPosts = await prisma.savedPost.findMany({
                where: {
                    userId: viewerId,
                    postId: { in: posts.map(p => p.id) },
                },
                select: { postId: true },
            });
            savedPosts.forEach(sp => savedPostIds.add(sp.postId));
        }

        const formattedPosts = posts.map(post =>
            PostController.formatPostResponse(
                post,
                viewerId,
                viewerRole,
                likedPostIds,
                savedPostIds
            )
        );

        const totalCount = skipCount ? undefined : await prisma.post.count({ where });

        logger.info('Fetched user posts', { userId, viewerId, count: posts.length });

        res.status(200).json({
            success: true,
            data: {
                posts: formattedPosts,
                pagination: skipCount ? { page, limit } : {
                    page,
                    limit,
                    total: totalCount,
                    totalPages: Math.ceil(totalCount! / limit),
                },
            },
        });
    });
}
