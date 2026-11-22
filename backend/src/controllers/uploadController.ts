import { Request, Response } from 'express';
import { asyncHandler } from '../middlewares/asyncHandler';
import { AppError } from '../utils/AppError';
import { ErrorCode } from '../utils/errorCodes';
import { UploadService } from '../services/uploadService';

export class UploadController {
    static uploadFile = asyncHandler(async (req: Request, res: Response) => {
        if (!req.file) {
            throw new AppError(ErrorCode.VALIDATION_ERROR, 'No file uploaded', 400);
        }

        const fileType = req.file.mimetype.split('/')[0]; // 'image' or 'video'

        // Use existing UploadService logic (assuming it handles raw files or paths)
        // Since userController used `processImage`, we might need to check if we just return the path
        // or process it. For now, let's assume direct return or simple processing.

        let fileUrl: string;

        if (fileType === 'image') {
            const processedFilename = await UploadService.processImage(req.file, {
                quality: 80,
                // maintain original width if not specified, or sensible default
            });
            fileUrl = `/uploads/${processedFilename}`;
        } else {
            // For non-images (videos, pdfs), usually just return the path (UploadService might need expansion if it only does images)
            // But multer already saved it to disk in `req.file.path` (or `req.file.filename`).
            // The middleware `upload` saves to `uploads/`.

            // If UploadService.processImage moves/renames, we should follow suit or just use the multer filename
            // User controller usage: `processImage` returns a filename.

            // For now, let's just return the filename multer generated, 
            // but strictly speaking we might want to move it to a subfolder or similar.
            // Given the middleware saves to root `uploads/`, let's just use that.

            fileUrl = `/uploads/${req.file.filename}`;
        }

        res.status(200).json({
            success: true,
            data: {
                url: fileUrl,
                originalName: req.file.originalname,
                mimetype: req.file.mimetype,
                size: req.file.size
            },
        });
    });
}
