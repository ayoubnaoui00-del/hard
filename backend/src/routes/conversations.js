import { Router } from 'express';
import ConversationController from '../controllers/ConversationController.js';
import { authenticate } from '../middleware/auth.js';

const router = Router();

// All conversation routes require authentication
router.use(authenticate);

// POST /conversations - Start a new conversation
router.post('/', ConversationController.createConversation);

// GET /conversations - List user's conversations (paginated)
router.get('/', ConversationController.listConversations);

// GET /conversations/:id - Get single conversation with all its messages
router.get('/:id', ConversationController.getConversation);

// POST /conversations/:id/messages - Append a message to conversation
router.post('/:id/messages', ConversationController.addMessage);

// DELETE /conversations/:id - Delete a conversation
router.delete('/:id', ConversationController.deleteConversation);

export default router;
