import { Router } from 'express';
import authRoutes from './authRoutes';
import userRoutes from './userRoutes';
import postRoutes from './postRoutes';
import commentRoutes from './commentRoutes';
import reportRoutes from './reportRoutes';
import analyticsRoutes from './analyticsRoutes';
import deviceRoutes from './deviceRoutes';
import tagRoutes from './tagRoutes';
import friendRoutes from './friendRoutes';
import emergencyRoutes from './emergencyRoutes';
import chatRoutes from './chatRoutes';
// import uploadRoutes from './uploadRoutes';

const router = Router();

router.get('/health', (_req, res) => {
    res.json({
        success: true,
        data: {
            status: 'ok',
            timestamp: new Date().toISOString(),
        },
    });
});

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/posts', postRoutes);
router.use('/comments', commentRoutes);
router.use('/reports', reportRoutes);
router.use('/analytics', analyticsRoutes);
router.use('/devices', deviceRoutes);
router.use('/tags', tagRoutes);
router.use('/friends', friendRoutes);
router.use('/emergency', emergencyRoutes);
router.use('/chats', chatRoutes);
// router.use('/upload', uploadRoutes);

export default router;
