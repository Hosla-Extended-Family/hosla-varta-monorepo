import { Request, Response } from 'express';
import { asyncHandler } from '../middlewares/asyncHandler';
import { FriendService } from '../services/FriendService';

export class FriendController {
    static sendRequest = asyncHandler(async (req: Request, res: Response) => {
        const { userId } = req.params;
        const requesterId = req.user!.id;

        const result = await FriendService.sendRequest(requesterId, userId);

        res.status(200).json({
            success: true,
            data: result,
        });
    });

    static acceptRequest = asyncHandler(async (req: Request, res: Response) => {
        const { friendshipId } = req.params;
        const userId = req.user!.id;

        const result = await FriendService.acceptRequest(userId, friendshipId);

        res.status(200).json({
            success: true,
            data: result,
        });
    });

    static rejectRequest = asyncHandler(async (req: Request, res: Response) => {
        const { friendshipId } = req.params;
        const userId = req.user!.id;

        const result = await FriendService.rejectRequest(userId, friendshipId);

        res.status(200).json({
            success: true,
            data: result,
        });
    });

    static cancelRequest = asyncHandler(async (req: Request, res: Response) => {
        const { friendshipId } = req.params;
        const userId = req.user!.id;

        await FriendService.cancelRequest(userId, friendshipId);

        res.status(200).json({
            success: true,
            message: 'Friend request cancelled successfully',
        });
    });

    static removeFriend = asyncHandler(async (req: Request, res: Response) => {
        const { friendshipId } = req.params;
        const userId = req.user!.id;

        await FriendService.removeFriend(userId, friendshipId);

        res.status(200).json({
            success: true,
            message: 'Friend removed successfully',
        });
    });

    static listFriends = asyncHandler(async (req: Request, res: Response) => {
        const userId = req.user!.id;
        const friends = await FriendService.listFriends(userId);

        res.status(200).json({
            success: true,
            data: friends,
        });
    });

    static listRequests = asyncHandler(async (req: Request, res: Response) => {
        const userId = req.user!.id;
        const requests = await FriendService.listRequests(userId);

        res.status(200).json({
            success: true,
            data: requests,
        });
    });
}
