import { z } from 'zod';
import { VALID_TAGS } from '../config/feedConfig';

export const createPostSchema = {
    body: z.object({
        title: z.string().optional(),
        body: z.string().min(1, 'Post body cannot be empty').max(5000, 'Post body too long'),
        mediaUrls: z.array(z.string()).optional(),
        youtubeVideoId: z.string().optional(),
        tags: z.union([z.array(z.string()), z.string()]).optional(),
        tag: z.enum(VALID_TAGS).optional(),
        tagIds: z.union([z.array(z.string()), z.string()]).optional(),
        visibility: z.enum(['PUBLIC', 'FRIENDS', 'ONLY_ME']).optional(),
        isPinned: z.union([z.boolean(), z.string()]).transform(val => val === 'true' || val === true).optional(),
    }),
};

export const updatePostSchema = {
    body: z.object({
        title: z.string().optional(),
        body: z.string().min(1).max(5000).optional(),
        mediaUrls: z.array(z.string()).optional(),
        youtubeVideoId: z.string().optional(),
        tags: z.union([z.array(z.string()), z.string()]).optional(),
        tag: z.enum(VALID_TAGS).optional(),
        tagIds: z.union([z.array(z.string()), z.string()]).optional(),
        visibility: z.enum(['PUBLIC', 'FRIENDS', 'ONLY_ME']).optional(),
        isPinned: z.union([z.boolean(), z.string()]).transform(val => val === 'true' || val === true).optional(),
    }),
};

export const userIdParamSchema = z.object({
    userId: z.string().uuid({ message: 'Invalid user ID format' }),
});
