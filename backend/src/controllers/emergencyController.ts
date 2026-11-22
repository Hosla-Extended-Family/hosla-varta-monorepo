import { Request, Response } from 'express';
import { asyncHandler } from '../middlewares/asyncHandler';
import prisma from '../config/database';
import { AppError } from '../utils/AppError';
import { ErrorCode } from '../utils/errorCodes';

export const logEmergency = asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.id;
    const userName = req.user?.name;
    const { button } = req.body;

    if (!userId || !userName) {
        throw new AppError(ErrorCode.UNAUTHORIZED, 'User information missing for emergency log', 401);
    }

    const options_date = { timeZone: 'Asia/Kolkata', year: 'numeric', month: '2-digit', day: '2-digit' } as const;
    const options_time = { timeZone: 'Asia/Kolkata', hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true } as const;

    const formattedDate = new Intl.DateTimeFormat('en-IN', options_date).format(new Date());
    const formattedTime = new Intl.DateTimeFormat('en-IN', options_time).format(new Date());

    const log = await prisma.emergencyLog.create({
        data: {
            userId,
            userName,
            button,
        },
    });

    // Create Emergency Post
    try {
        const helpMessage = `Please help in my emergency. I am from Hosla Extended Family 7811009309`;

        // Find or create EMERGENCY tag
        let emergencyTag = await prisma.tag.findUnique({ where: { name: 'EMERGENCY' } });
        if (!emergencyTag) {
            emergencyTag = await prisma.tag.create({
                data: { name: 'EMERGENCY', priority: 100 } // High priority for emergencies
            });
        }

        await prisma.post.create({
            data: {
                authorId: userId,
                body: helpMessage,
                status: 'PUBLISHED',
                visibility: 'PUBLIC',
                rolePriority: emergencyTag.priority,
                tags: {
                    connect: { id: emergencyTag.id }
                }
            }
        });
    } catch (error) {
        // Log error but don't fail the emergency log if post creation fails
        console.error('Failed to create emergency post:', error);
    }

    res.status(201).json({
        success: true,
        data: {
            ...log,
            loggedAtDateIST: formattedDate,
            loggedAtTimeIST: formattedTime
        },
        message: 'Emergency log saved successfully',
    });
});
