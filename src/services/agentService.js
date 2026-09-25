import dotenv from 'dotenv';
import {
  User,
  Workout,
  WorkoutExercise,
  Exercise,
  Conversation,
  Message,
} from '../models/index.js';
import { formatSystemPrompt } from '../constants/agentPrompts.js';

dotenv.config();

const OLLAMA_BASE_URL = process.env.OLLAMA_BASE_URL || 'http://localhost:11434';
const OLLAMA_CHAT_MODEL = process.env.OLLAMA_CHAT_MODEL || 'mistral';

class AgentService {
  /**
   * Fetch context for an athlete (user profile stats & recent workouts)
   */
  async getUserContext(userId) {
    const user = await User.findByPk(userId, {
      attributes: ['id', 'username', 'email', 'level', 'currentXp', 'totalXp', 'streak'],
    });

    const recentWorkouts = await Workout.findAll({
      where: { userId },
      order: [['date', 'DESC']],
      limit: 3,
      include: [
        {
          model: WorkoutExercise,
          as: 'workoutExercises',
          include: [
            {
              model: Exercise,
              as: 'exercise',
              attributes: ['id', 'name', 'muscleGroup'],
            },
          ],
        },
      ],
    });

    return { user, recentWorkouts };
  }

  /**
   * Fetch recent conversation messages for prompt history
   */
  async getConversationHistory(conversationId, limit = 10) {
    const messages = await Message.findAll({
      where: { conversationId },
      order: [['createdAt', 'DESC']],
      limit,
    });

    // Reverse to chronological order (oldest first)
    return messages.reverse();
  }

  /**
   * Execute chat stream with Ollama LLM and persist conversation messages
   */
  async streamChat({ conversation, conversationId, userId, messageText, onChunk, signal }) {
    // 1. Verify conversation ownership if not already passed
    const activeConversation =
      conversation ||
      (await Conversation.findOne({
        where: { id: conversationId, userId },
      }));

    if (!activeConversation) {
      const error = new Error('Conversation not found or unauthorized.');
      error.statusCode = 404;
      throw error;
    }

    const convId = activeConversation.id;

    // 2. Persist the user message to database
    const userMessage = await Message.create({
      conversationId: convId,
      role: 'user',
      content: messageText.trim(),
    });

    // 3. Fetch context & conversation history
    const { user, recentWorkouts } = await this.getUserContext(userId);
    const history = await this.getConversationHistory(convId, 10);

    // 4. Build prompt messages
    const systemPrompt = formatSystemPrompt({ user, recentWorkouts });

    const messages = [
      { role: 'system', content: systemPrompt },
      ...history.map((m) => ({
        role: m.role,
        content: m.content,
      })),
    ];

    // 5. Connect to Ollama chat stream
    const ollamaResponse = await fetch(`${OLLAMA_BASE_URL}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: OLLAMA_CHAT_MODEL,
        messages,
        stream: true,
      }),
      signal,
    });

    if (!ollamaResponse.ok) {
      const errorText = await ollamaResponse.text();
      throw new Error(`Ollama service error (${ollamaResponse.status}): ${errorText}`);
    }

    if (!ollamaResponse.body) {
      throw new Error('No readable stream returned from Ollama');
    }

    const reader = ollamaResponse.body.getReader();
    const decoder = new TextDecoder();
    let accumulatedResponse = '';
    let buffer = '';

    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        // Keep the last partial segment in the buffer
        buffer = lines.pop() || '';

        for (const line of lines) {
          const trimmed = line.trim();
          if (!trimmed) continue;

          try {
            const parsed = JSON.parse(trimmed);
            const chunkContent = parsed.message?.content || '';

            if (chunkContent) {
              accumulatedResponse += chunkContent;
              if (onChunk) {
                onChunk(chunkContent);
              }
            }

            if (parsed.done) {
              break;
            }
          } catch (jsonErr) {
            console.warn('[AgentService] Failed to parse Ollama NDJSON chunk:', trimmed, jsonErr.message);
          }
        }
      }

      // Process any remaining bytes in buffer
      if (buffer.trim()) {
        try {
          const parsed = JSON.parse(buffer.trim());
          const chunkContent = parsed.message?.content || '';
          if (chunkContent) {
            accumulatedResponse += chunkContent;
            if (onChunk) {
              onChunk(chunkContent);
            }
          }
        } catch (_) {}
      }
    } catch (streamError) {
      // If client aborted or stream error, propagate
      throw streamError;
    } finally {
      reader.releaseLock();
    }

    // 6. Save assistant response to Messages table
    let assistantMessage = null;
    if (accumulatedResponse.trim()) {
      assistantMessage = await Message.create({
        conversationId: convId,
        role: 'assistant',
        content: accumulatedResponse.trim(),
      });

      // Update conversation updatedAt
      await activeConversation.changed('updatedAt', true);
      await activeConversation.update({ updatedAt: new Date() });
    }

    return {
      userMessage,
      assistantMessage,
      fullResponse: accumulatedResponse,
    };
  }
}

export default new AgentService();
