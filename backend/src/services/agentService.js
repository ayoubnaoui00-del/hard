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
import { AGENT_TOOLS } from '../constants/agentTools.js';
import ragService from './ragService.js';
import agentToolService from './agentToolService.js';

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
   * Directly execute a backend tool on behalf of the user (HRD-24)
   */
  async executeTool(userId, toolName, args = {}) {
    return await agentToolService.executeTool(userId, toolName, args);
  }

  /**
   * Internal helper to consume an Ollama NDJSON stream
   */
  async _readStream(stream, { onChunk, signal } = {}) {
    const reader = stream.getReader();
    const decoder = new TextDecoder();
    let accumulatedText = '';
    const accumulatedToolCalls = [];
    let buffer = '';

    try {
      while (true) {
        if (signal?.aborted) {
          reader.cancel();
          break;
        }

        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() || '';

        for (const line of lines) {
          const trimmed = line.trim();
          if (!trimmed) continue;

          try {
            const parsed = JSON.parse(trimmed);
            const chunkContent = parsed.message?.content || '';

            if (chunkContent) {
              accumulatedText += chunkContent;
              if (onChunk) {
                onChunk(chunkContent);
              }
            }

            // Collect any tool calls streamed by Ollama
            if (Array.isArray(parsed.message?.tool_calls) && parsed.message.tool_calls.length > 0) {
              accumulatedToolCalls.push(...parsed.message.tool_calls);
            }

            if (parsed.done) {
              break;
            }
          } catch (jsonErr) {
            console.warn('[AgentService] Failed to parse Ollama NDJSON chunk:', trimmed, jsonErr.message);
          }
        }
      }

      // Check remaining buffer
      if (buffer.trim()) {
        try {
          const parsed = JSON.parse(buffer.trim());
          const chunkContent = parsed.message?.content || '';
          if (chunkContent) {
            accumulatedText += chunkContent;
            if (onChunk) onChunk(chunkContent);
          }
          if (Array.isArray(parsed.message?.tool_calls)) {
            accumulatedToolCalls.push(...parsed.message.tool_calls);
          }
        } catch (_) {}
      }
    } finally {
      reader.releaseLock();
    }

    return {
      text: accumulatedText,
      toolCalls: accumulatedToolCalls,
    };
  }

  /**
   * Execute chat stream with Ollama LLM, RAG retrieval & Function Calling (HRD-22, HRD-23, HRD-24)
   */
  async streamChat({
    conversation,
    conversationId,
    userId,
    messageText,
    onChunk,
    onToolCall,
    signal,
  }) {
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

    // 3. Fetch context, conversation history & RAG relevant exercises (HRD-23)
    const { user, recentWorkouts } = await this.getUserContext(userId);
    const history = await this.getConversationHistory(convId, 10);
    let relevantExercises = [];
    try {
      relevantExercises = await ragService.retrieveRelevantExercises(messageText, 5);
    } catch (ragErr) {
      console.warn('[AgentService] RAG retrieval error (non-fatal):', ragErr.message);
    }

    // 4. Build prompt messages with RAG context
    const systemPrompt = formatSystemPrompt({ user, recentWorkouts, relevantExercises });

    const messages = [
      { role: 'system', content: systemPrompt },
      ...history.map((m) => ({
        role: m.role,
        content: m.content,
      })),
    ];

    // 5. Connect to Ollama chat with tools enabled (HRD-24)
    let ollamaResponse;
    try {
      ollamaResponse = await fetch(`${OLLAMA_BASE_URL}/api/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: OLLAMA_CHAT_MODEL,
          messages,
          tools: AGENT_TOOLS,
          stream: true,
        }),
        signal,
      });
    } catch (fetchErr) {
      throw new Error(`Failed to connect to Ollama service: ${fetchErr.message}`);
    }

    if (!ollamaResponse.ok) {
      const errorText = await ollamaResponse.text();
      throw new Error(`Ollama service error (${ollamaResponse.status}): ${errorText}`);
    }

    if (!ollamaResponse.body) {
      throw new Error('No readable stream returned from Ollama');
    }

    // Read initial stream
    const firstPass = await this._readStream(ollamaResponse.body, { onChunk, signal });
    let finalResponseText = firstPass.text;
    const executedTools = [];

    // 6. Handle Function Calling if tools were invoked by Ollama (HRD-24)
    if (firstPass.toolCalls && firstPass.toolCalls.length > 0) {
      for (const call of firstPass.toolCalls) {
        const toolName = call.function?.name;
        let args = call.function?.arguments || {};

        if (typeof args === 'string') {
          try {
            args = JSON.parse(args);
          } catch (_) {
            args = {};
          }
        }

        if (toolName) {
          const toolResult = await agentToolService.executeTool(userId, toolName, args);
          executedTools.push({
            tool: toolName,
            arguments: args,
            result: toolResult,
          });

          if (onToolCall) {
            onToolCall({
              tool: toolName,
              arguments: args,
              result: toolResult,
            });
          }
        }
      }

      // Append assistant tool_calls and tool results to messages for follow-up stream
      const followUpMessages = [
        ...messages,
        {
          role: 'assistant',
          content: firstPass.text || '',
          tool_calls: firstPass.toolCalls,
        },
        ...executedTools.map((et) => ({
          role: 'tool',
          name: et.tool,
          content: JSON.stringify(et.result),
        })),
      ];

      // Request second-pass response explaining the tool results to athlete
      try {
        const followUpResponse = await fetch(`${OLLAMA_BASE_URL}/api/chat`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            model: OLLAMA_CHAT_MODEL,
            messages: followUpMessages,
            stream: true,
          }),
          signal,
        });

        if (followUpResponse.ok && followUpResponse.body) {
          const secondPass = await this._readStream(followUpResponse.body, { onChunk, signal });
          finalResponseText = (finalResponseText ? finalResponseText + '\n\n' : '') + secondPass.text;
        }
      } catch (followUpErr) {
        console.warn('[AgentService] Follow-up stream failed after tool execution:', followUpErr.message);
        // Fall back to summarizing tool execution results directly
        if (!finalResponseText) {
          const summary = executedTools.map((et) => et.result?.message || 'Action performed.').join(' ');
          finalResponseText = summary;
          if (onChunk) onChunk(summary);
        }
      }
    }

    // 7. Save assistant response to Messages table
    let assistantMessage = null;
    if (finalResponseText.trim()) {
      assistantMessage = await Message.create({
        conversationId: convId,
        role: 'assistant',
        content: finalResponseText.trim(),
      });

      // Update conversation updatedAt
      await activeConversation.changed('updatedAt', true);
      await activeConversation.update({ updatedAt: new Date() });
    }

    return {
      userMessage,
      assistantMessage,
      relevantExercises,
      executedTools,
      fullResponse: finalResponseText,
    };
  }

  /**
   * Non-streaming conversational interface (useful for tests and sync requests)
   */
  async chat({ conversation, conversationId, userId, messageText }) {
    let accumulated = '';
    return await this.streamChat({
      conversation,
      conversationId,
      userId,
      messageText,
      onChunk: (chunk) => {
        accumulated += chunk;
      },
    });
  }
}

export default new AgentService();
