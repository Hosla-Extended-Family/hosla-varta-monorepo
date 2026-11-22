import { z } from 'zod';
import { commonSchemas } from './common';

export const friendSchemas = {
    userParams: z.object({
        userId: commonSchemas.id,
    }),

    friendshipParams: z.object({
        friendshipId: commonSchemas.id,
    }),
};
