import { Request, Response } from 'express';
import { asyncHandler } from '../middlewares/asyncHandler';
import prisma from '../config/database';
import { AppError } from '../utils/AppError';
import { ErrorCode } from '../utils/errorCodes';
import { Role } from '@prisma/client';

export class TagController {

    static getAllTags = asyncHandler(async (req: Request, res: Response) => {
        const tags = await prisma.tag.findMany({
            orderBy: [
                { priority: 'desc' },
                { name: 'asc' }
            ]
        });

        res.status(200).json({
            success: true,
            data: { tags }
        });
    });

    static createTag = asyncHandler(async (req: Request, res: Response) => {
        const { name, priority } = req.body;
        const user = req.user!;

        if (user.role !== Role.ADMIN) {
            throw new AppError(ErrorCode.FORBIDDEN, 'Only Admins can create tags');
        }

        const existingTag = await prisma.tag.findUnique({
            where: { name }
        });

        if (existingTag) {
            throw new AppError(ErrorCode.CONFLICT, 'Tag already exists');
        }

        const tag = await prisma.tag.create({
            data: {
                name,
                priority: priority || 10
            }
        });

        res.status(201).json({
            success: true,
            data: { tag }
        });
    });

    static updateTag = asyncHandler(async (req: Request, res: Response) => {
        const { id } = req.params;
        const { name, priority } = req.body;
        const user = req.user!;

        if (user.role !== Role.ADMIN) {
            throw new AppError(ErrorCode.FORBIDDEN, 'Only Admins can update tags');
        }

        const tag = await prisma.tag.findUnique({ where: { id } });
        if (!tag) {
            throw new AppError(ErrorCode.NOT_FOUND, 'Tag not found');
        }

        if (name && name !== tag.name) {
            const existingTag = await prisma.tag.findUnique({ where: { name } });
            if (existingTag) {
                throw new AppError(ErrorCode.CONFLICT, 'Tag name already exists');
            }
        }

        const updatedTag = await prisma.tag.update({
            where: { id },
            data: {
                ...(name && { name }),
                ...(priority !== undefined && { priority })
            }
        });

        res.status(200).json({
            success: true,
            data: { tag: updatedTag }
        });
    });

    static deleteTag = asyncHandler(async (req: Request, res: Response) => {
        const { id } = req.params;
        const user = req.user!;

        if (user.role !== Role.ADMIN) {
            throw new AppError(ErrorCode.FORBIDDEN, 'Only Admins can delete tags');
        }

        const tag = await prisma.tag.findUnique({ where: { id } });
        if (!tag) {
            throw new AppError(ErrorCode.NOT_FOUND, 'Tag not found');
        }

        await prisma.tag.delete({ where: { id } });

        res.status(200).json({
            success: true,
            message: 'Tag deleted successfully'
        });
    });
}
