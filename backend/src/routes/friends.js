import { Router } from 'express';
import FriendController from '../controllers/FriendController.js';
import { authenticate } from '../middleware/auth.js';

const router = Router();

// All friend routes require authentication
router.use(authenticate);

// Friend Management
router.post('/', FriendController.sendRequest);
router.get('/', FriendController.listFriends);
router.put('/:friendId', FriendController.respondToRequest);
router.delete('/:friendId', FriendController.removeFriend);

export default router;
