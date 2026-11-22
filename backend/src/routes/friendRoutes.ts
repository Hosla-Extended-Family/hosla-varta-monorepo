import express from 'express';
import { FriendController } from '../controllers/FriendController';
import { verifyToken } from '../middlewares/verifyToken';
import { validate } from '../middlewares/validate';
import { friendSchemas } from '../validations/friendValidation';

const router = express.Router();

// All routes require authentication
router.use(verifyToken);

router.post(
    '/request/:userId',
    validate({ params: friendSchemas.userParams }),
    FriendController.sendRequest
);
router.post(
    '/accept/:friendshipId',
    validate({ params: friendSchemas.friendshipParams }),
    FriendController.acceptRequest
);
router.post(
    '/reject/:friendshipId',
    validate({ params: friendSchemas.friendshipParams }),
    FriendController.rejectRequest
);
router.delete(
    '/requests/:friendshipId',
    validate({ params: friendSchemas.friendshipParams }),
    FriendController.cancelRequest
);
router.delete(
    '/:friendshipId',
    validate({ params: friendSchemas.friendshipParams }),
    FriendController.removeFriend
);
router.get('/', FriendController.listFriends);
router.get('/requests', FriendController.listRequests);

export default router;
