import express from 'express';
import { UploadController } from '../controllers/uploadController';
import { upload } from '../middlewares/upload';
import { verifyToken } from '../middlewares/verifyToken';

const router = express.Router();

router.use(verifyToken);

router.post('/image', upload.single('file'), UploadController.uploadFile);
router.post('/video', upload.single('file'), UploadController.uploadFile);
router.post('/file', upload.single('file'), UploadController.uploadFile);

export default router;
