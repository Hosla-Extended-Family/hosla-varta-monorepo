import { z } from 'zod';
import { commonSchemas } from './common';

export const chatSchemas = {
    createDirectParams: z.object({
        friendId: commonSchemas.id,
    }),

    conversationParams: z.object({
        conversationId: commonSchemas.id,
    }),

    listMessagesQuery: z.object({
        page: z.string().optional().transform((v) => (v ? Math.max(1, parseInt(v, 10) || 1) : 1)),
        limit: z
            .string()
            .optional()
            .transform((v) => {
                if (!v) return 50;
                return Math.min(100, Math.max(1, parseInt(v, 10) || 50));
            }),
    }),

    sendMessageBody: z.object({
        content: z.string().trim().min(1).max(4000),
    }),
};
