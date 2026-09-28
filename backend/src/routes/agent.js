import { Router } from 'express';
import AgentController from '../controllers/AgentController.js';
import { authenticate } from '../middleware/auth.js';

const router = Router();

// All agent endpoints require authentication
router.use(authenticate);

// POST /agent/chat - Server-Sent Events stream for AI agent chat
router.post('/chat', AgentController.streamChat);

export default router;
