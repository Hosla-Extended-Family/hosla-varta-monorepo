import express from 'express';
import { ChatController } from '../controllers/chatController';
import { verifyToken } from '../middlewares/verifyToken';
import { validate } from '../middlewares/validate';
import { chatSchemas } from '../validations/chatValidation';

const router = express.Router();

router.use(verifyToken);

router.get('/', ChatController.listChats);
router.post(
    '/direct/:friendId',
    validate({ params: chatSchemas.createDirectParams }),
    ChatController.createDirectChat
);
router.get(
    '/:conversationId/messages',
    validate({ params: chatSchemas.conversationParams, query: chatSchemas.listMessagesQuery }),
    ChatController.getMessages
);
router.post(
    '/:conversationId/messages',
    validate({
        params: chatSchemas.conversationParams,
        body: chatSchemas.sendMessageBody,
    }),
    ChatController.sendMessage
);
router.post(
    '/:conversationId/read',
    validate({ params: chatSchemas.conversationParams }),
    ChatController.markRead
);

export default router;
