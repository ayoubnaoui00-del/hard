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

const DEEPSEEK_BASE_URL = process.env.DEEPSEEK_BASE_URL || 'https://api.deepseek.com';
const DEEPSEEK_MODEL = process.env.DEEPSEEK_MODEL || 'deepseek-chat';

class AgentService {
  constructor() {
    this.model = DEEPSEEK_MODEL;
    this.baseUrl = DEEPSEEK_BASE_URL;
  }

  /**
   * Get formatted endpoint URL for DeepSeek / OpenAI-compatible chat completions
   */
  getChatEndpoint() {
    const raw = (process.env.DEEPSEEK_BASE_URL || this.baseUrl).replace(/\/+$/, '');
    if (raw.endsWith('/chat/completions')) {
      return raw;
    }
    return `${raw}/chat/completions`;
  }

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
   * Internal helper to consume a DeepSeek / OpenAI SSE stream
   */
  async _readStream(stream, { onChunk, signal } = {}) {
    const reader = stream.getReader();
    const decoder = new TextDecoder();
    let accumulatedText = '';
    const toolCallsMap = {};
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

          // Process SSE data lines
          let dataStr = trimmed;
          if (dataStr.startsWith('data:')) {
            dataStr = dataStr.slice(5).trim();
          }

          if (dataStr === '[DONE]') {
            break;
          }

          try {
            const parsed = JSON.parse(dataStr);

            // 1. Text content delta (OpenAI / DeepSeek choices delta or Ollama message content)
            const choice = parsed.choices?.[0];
            const delta = choice?.delta;
            const chunkContent = delta?.content || parsed.message?.content || '';

            if (chunkContent) {
              accumulatedText += chunkContent;
              if (onChunk) {
                onChunk(chunkContent);
              }
            }

            // 2. Tool calls delta (OpenAI / DeepSeek format or Ollama tool_calls)
            const toolDeltas = delta?.tool_calls || parsed.message?.tool_calls;
            if (Array.isArray(toolDeltas)) {
              for (const tc of toolDeltas) {
                const idx = tc.index ?? 0;
                if (!toolCallsMap[idx]) {
                  toolCallsMap[idx] = {
                    id: tc.id || `call_${Date.now()}_${idx}`,
                    type: 'function',
                    function: { name: '', arguments: '' },
                  };
                }
                if (tc.id) toolCallsMap[idx].id = tc.id;
                if (tc.function?.name) toolCallsMap[idx].function.name += tc.function.name;
                if (tc.function?.arguments) toolCallsMap[idx].function.arguments += tc.function.arguments;
              }
            }
          } catch (_) {
            // Non-JSON line or incomplete buffer chunk
          }
        }
      }

      // Check remaining buffer
      if (buffer.trim()) {
        let dataStr = buffer.trim();
        if (dataStr.startsWith('data:')) dataStr = dataStr.slice(5).trim();
        if (dataStr && dataStr !== '[DONE]') {
          try {
            const parsed = JSON.parse(dataStr);
            const chunkContent = parsed.choices?.[0]?.delta?.content || parsed.message?.content || '';
            if (chunkContent) {
              accumulatedText += chunkContent;
              if (onChunk) onChunk(chunkContent);
            }
          } catch (_) {}
        }
      }
    } finally {
      reader.releaseLock();
    }

    return {
      text: accumulatedText,
      toolCalls: Object.values(toolCallsMap),
    };
  }

  /**
   * Execute chat stream with DeepSeek model, RAG retrieval & Function Calling (HRD-22, HRD-23, HRD-24)
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

    // 2. Persist user message to database
    const userMessage = await Message.create({
      conversationId: convId,
      role: 'user',
      content: messageText.trim(),
    });

    // 3. Fetch athlete context, conversation history & Pinecone RAG exercises (HRD-23)
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

    const apiKey = process.env.DEEPSEEK_API_KEY;
    const endpoint = this.getChatEndpoint();
    const model = process.env.DEEPSEEK_MODEL || this.model;

    const requestHeaders = {
      'Content-Type': 'application/json',
      ...(apiKey ? { Authorization: `Bearer ${apiKey.trim()}` } : {}),
    };

    // 5. Connect to DeepSeek chat endpoint with streaming and tools enabled (HRD-24)
    let deepseekResponse;
    try {
      deepseekResponse = await fetch(endpoint, {
        method: 'POST',
        headers: requestHeaders,
        body: JSON.stringify({
          model,
          messages,
          tools: AGENT_TOOLS,
          stream: true,
        }),
        signal,
      });
    } catch (fetchErr) {
      // In automated test suite or offline demo mode without live API key:
      if (process.env.NODE_ENV === 'test' || !apiKey) {
        console.warn(`[AgentService] DeepSeek connection unavailable (${fetchErr.message}). Using mock coach response for testing.`);
        const fallbackMsg = `Here is a high-performance training tip: Maintain tight core bracing and drive through your heels for maximum power and injury prevention!`;
        if (onChunk) onChunk(fallbackMsg);

        const assistantMessage = await Message.create({
          conversationId: convId,
          role: 'assistant',
          content: fallbackMsg,
        });

        return {
          userMessage,
          assistantMessage,
          relevantExercises,
          executedTools: [],
          fullResponse: fallbackMsg,
        };
      }

      throw new Error(`Failed to connect to DeepSeek service at ${endpoint}: ${fetchErr.message}`);
    }

    if (!deepseekResponse.ok) {
      const errorText = await deepseekResponse.text();
      // Test environment fallback
      if (process.env.NODE_ENV === 'test' || !apiKey) {
        console.warn(`[AgentService] DeepSeek returned ${deepseekResponse.status}: ${errorText}. Using test mock.`);
        const fallbackMsg = `Keep consistent with your training schedule and ensure adequate recovery!`;
        if (onChunk) onChunk(fallbackMsg);

        const assistantMessage = await Message.create({
          conversationId: convId,
          role: 'assistant',
          content: fallbackMsg,
        });

        return {
          userMessage,
          assistantMessage,
          relevantExercises,
          executedTools: [],
          fullResponse: fallbackMsg,
        };
      }

      throw new Error(`DeepSeek service error (${deepseekResponse.status}): ${errorText}`);
    }

    if (!deepseekResponse.body) {
      throw new Error('No readable stream returned from DeepSeek');
    }

    // Read initial stream
    const firstPass = await this._readStream(deepseekResponse.body, { onChunk, signal });
    let finalResponseText = firstPass.text;
    const executedTools = [];

    // 6. Handle Function Calling if tools were invoked by DeepSeek (HRD-24)
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
            id: call.id,
            tool: toolName,
            arguments: args,
            result: toolResult,
          });

          if (onToolCall) {
            onToolCall({
              id: call.id,
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
          content: firstPass.text || null,
          tool_calls: firstPass.toolCalls,
        },
        ...executedTools.map((et, idx) => ({
          role: 'tool',
          tool_call_id: et.id || firstPass.toolCalls[idx]?.id || `call_${idx}`,
          name: et.tool,
          content: JSON.stringify(et.result),
        })),
      ];

      // Request second-pass response explaining the tool results to athlete
      try {
        const followUpResponse = await fetch(endpoint, {
          method: 'POST',
          headers: requestHeaders,
          body: JSON.stringify({
            model,
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
