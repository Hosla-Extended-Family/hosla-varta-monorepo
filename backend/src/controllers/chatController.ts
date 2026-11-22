import { Request, Response } from 'express';
import { asyncHandler } from '../middlewares/asyncHandler';
import { ChatService } from '../services/chatService';

export class ChatController {
    static listChats = asyncHandler(async (req: Request, res: Response) => {
        const userId = req.user!.id;
        const chats = await ChatService.listChats(userId);

        res.status(200).json({ success: true, data: chats });
    });

    static createDirectChat = asyncHandler(async (req: Request, res: Response) => {
        const userId = req.user!.id;
        const { friendId } = req.params;

        const chat = await ChatService.getOrCreateDirectChat(userId, friendId);

        res.status(200).json({ success: true, data: chat });
    });

    static getMessages = asyncHandler(async (req: Request, res: Response) => {
        const userId = req.user!.id;
        const { conversationId } = req.params;
        const page = Number(req.query.page) || 1;
        const limit = Math.min(100, Number(req.query.limit) || 50);

        const result = await ChatService.getMessages(userId, conversationId, page, limit);

        res.status(200).json({ success: true, data: result });
    });

    static sendMessage = asyncHandler(async (req: Request, res: Response) => {
        const userId = req.user!.id;
        const { conversationId } = req.params;
        const { content } = req.body;

        const { message } = await ChatService.sendMessage(userId, conversationId, content);

        res.status(201).json({ success: true, data: message });
    });

    static markRead = asyncHandler(async (req: Request, res: Response) => {
        const userId = req.user!.id;
        const { conversationId } = req.params;

        const result = await ChatService.markChatRead(userId, conversationId);

        res.status(200).json({ success: true, data: result });
    });
}
