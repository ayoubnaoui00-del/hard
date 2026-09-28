import { Conversation, Message } from '../models/index.js';

class ConversationController {
  /**
   * POST /conversations
   * Start a new chat session / conversation.
   */
  async createConversation(req, res) {
    try {
      const userId = req.user.id;
      const { topic, title } = req.body;

      const conversationTitle = (title || topic || 'New Chat').trim();

      const conversation = await Conversation.create({
        userId,
        title: conversationTitle,
      });

      return res.status(201).json({
        success: true,
        data: {
          id: conversation.id,
          userId: conversation.userId,
          title: conversation.title,
          topic: conversation.title,
          createdAt: conversation.createdAt,
          updatedAt: conversation.updatedAt,
        },
      });
    } catch (error) {
      console.error('[ConversationController.createConversation] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to create conversation.',
        details: error.message,
      });
    }
  }

  /**
   * GET /conversations
   * List authenticated user's conversations with pagination.
   */
  async listConversations(req, res) {
    try {
      const userId = req.user.id;
      const page = Math.max(1, parseInt(req.query.page, 10) || 1);
      const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));
      const offset = (page - 1) * limit;

      const { count, rows } = await Conversation.findAndCountAll({
        where: { userId },
        limit,
        offset,
        order: [['updatedAt', 'DESC']],
      });

      return res.status(200).json({
        success: true,
        data: {
          total: count,
          page,
          limit,
          totalPages: Math.ceil(count / limit),
          conversations: rows,
        },
      });
    } catch (error) {
      console.error('[ConversationController.listConversations] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to retrieve conversations.',
        details: error.message,
      });
    }
  }

  /**
   * GET /conversations/:id
   * Get single conversation with all its messages ordered chronologically.
   */
  async getConversation(req, res) {
    try {
      const userId = req.user.id;
      const { id } = req.params;

      const conversation = await Conversation.findOne({
        where: { id, userId },
        include: [
          {
            model: Message,
            as: 'messages',
          },
        ],
        order: [[{ model: Message, as: 'messages' }, 'createdAt', 'ASC']],
      });

      if (!conversation) {
        return res.status(404).json({
          success: false,
          error: 'Conversation not found.',
        });
      }

      return res.status(200).json({
        success: true,
        data: {
          conversation: {
            id: conversation.id,
            userId: conversation.userId,
            title: conversation.title,
            createdAt: conversation.createdAt,
            updatedAt: conversation.updatedAt,
          },
          messages: conversation.messages || [],
        },
      });
    } catch (error) {
      console.error('[ConversationController.getConversation] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to retrieve conversation.',
        details: error.message,
      });
    }
  }

  /**
   * POST /conversations/:id/messages
   * Append an immutable message (user or assistant) to a conversation.
   */
  async addMessage(req, res) {
    try {
      const userId = req.user.id;
      const { id } = req.params;
      const { role, content } = req.body;

      if (!role || !['user', 'assistant', 'system'].includes(role)) {
        return res.status(400).json({
          success: false,
          error: "Invalid or missing role. Must be 'user', 'assistant', or 'system'.",
        });
      }

      if (!content || typeof content !== 'string' || !content.trim()) {
        return res.status(400).json({
          success: false,
          error: 'Message content cannot be empty.',
        });
      }

      // Verify conversation ownership
      const conversation = await Conversation.findOne({
        where: { id, userId },
      });

      if (!conversation) {
        return res.status(404).json({
          success: false,
          error: 'Conversation not found.',
        });
      }

      const message = await Message.create({
        conversationId: conversation.id,
        role,
        content: content.trim(),
      });

      // Update conversation updatedAt timestamp
      await conversation.changed('updatedAt', true);
      await conversation.update({ updatedAt: new Date() });

      return res.status(201).json({
        success: true,
        data: {
          id: message.id,
          conversationId: message.conversationId,
          role: message.role,
          content: message.content,
          createdAt: message.createdAt,
        },
      });
    } catch (error) {
      console.error('[ConversationController.addMessage] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to add message.',
        details: error.message,
      });
    }
  }

  /**
   * DELETE /conversations/:id
   * Delete a conversation and its messages.
   */
  async deleteConversation(req, res) {
    try {
      const userId = req.user.id;
      const { id } = req.params;

      const conversation = await Conversation.findOne({
        where: { id, userId },
      });

      if (!conversation) {
        return res.status(404).json({
          success: false,
          error: 'Conversation not found.',
        });
      }

      await conversation.destroy();

      return res.status(200).json({
        success: true,
        message: 'Conversation deleted successfully.',
      });
    } catch (error) {
      console.error('[ConversationController.deleteConversation] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to delete conversation.',
        details: error.message,
      });
    }
  }
}

export default new ConversationController();
