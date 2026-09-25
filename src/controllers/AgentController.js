import agentService from '../services/agentService.js';
import { Conversation } from '../models/index.js';

class AgentController {
  /**
   * POST /agent/chat
   * Server-Sent Events (SSE) streaming chat endpoint (HRD-22)
   */
  async streamChat(req, res) {
    const userId = req.user.id;
    const { conversationId, message } = req.body;

    // Validate inputs
    if (!conversationId || typeof conversationId !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'A valid conversationId is required.',
      });
    }

    if (!message || typeof message !== 'string' || !message.trim()) {
      return res.status(400).json({
        success: false,
        error: 'Message content cannot be empty.',
      });
    }

    // Verify conversation existence and ownership before sending SSE headers
    const conversation = await Conversation.findOne({
      where: { id: conversationId, userId },
    });

    if (!conversation) {
      return res.status(404).json({
        success: false,
        error: 'Conversation not found or unauthorized.',
      });
    }

    const abortController = new AbortController();
    let headersSent = false;

    // Abort upstream Ollama request if client disconnects early
    req.on('close', () => {
      if (!res.writableEnded) {
        abortController.abort();
      }
    });

    try {
      // Setup SSE Headers
      res.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache, no-transform',
        'Connection': 'keep-alive',
        'X-Accel-Buffering': 'no',
      });
      headersSent = true;

      // Stream chunks to the client via SSE
      await agentService.streamChat({
        conversation,
        userId,
        messageText: message,
        signal: abortController.signal,
        onChunk: (chunk) => {
          if (!res.writableEnded) {
            res.write(`data: ${JSON.stringify({ chunk })}\n\n`);
          }
        },
      });

      // Signal completion and end stream
      if (!res.writableEnded) {
        res.write('data: [DONE]\n\n');
        res.end();
      }
    } catch (error) {
      console.error('[AgentController.streamChat] Error:', error);

      if (!headersSent) {
        const status = error.statusCode || 500;
        return res.status(status).json({
          success: false,
          error: error.message || 'AI streaming failed.',
        });
      } else if (!res.writableEnded) {
        res.write(`data: ${JSON.stringify({ error: error.message })}\n\n`);
        res.end();
      }
    }
  }
}

export default new AgentController();
