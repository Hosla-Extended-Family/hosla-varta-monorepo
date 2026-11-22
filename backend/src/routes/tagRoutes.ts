import express from 'express';
import { TagController } from '../controllers/tagController';
import { verifyToken } from '../middlewares/verifyToken';
import { requireRole } from '../middlewares/requireRole';
import { Role } from '@prisma/client';

const router = express.Router();

router.get('/', verifyToken, TagController.getAllTags);

router.post('/', verifyToken, requireRole([Role.ADMIN]), TagController.createTag);
router.put('/:id', verifyToken, requireRole([Role.ADMIN]), TagController.updateTag);
router.delete('/:id', verifyToken, requireRole([Role.ADMIN]), TagController.deleteTag);

export default router;
