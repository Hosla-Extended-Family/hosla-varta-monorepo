import { z } from 'zod';

export const createEmergencyLogSchema = {
    body: z.object({
        button: z.string({
            required_error: 'Button pressed type is required',
        }).min(1, 'Button type cannot be empty'),
    }),
};
