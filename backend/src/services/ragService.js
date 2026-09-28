import dotenv from 'dotenv';
import { sequelize, Exercise, Embedding } from '../models/index.js';

dotenv.config();

const OLLAMA_BASE_URL = process.env.OLLAMA_BASE_URL || 'http://localhost:11434';
const EMBED_MODEL = process.env.OLLAMA_EMBED_MODEL || 'all-minilm';

class RagService {
  /**
   * Calculate cosine similarity between two numeric vectors
   * dot(A, B) / (norm(A) * norm(B))
   */
  cosineSimilarity(vecA, vecB) {
    if (!Array.isArray(vecA) || !Array.isArray(vecB) || vecA.length === 0 || vecB.length === 0) {
      return 0;
    }

    const length = Math.min(vecA.length, vecB.length);
    let dotProduct = 0;
    let normA = 0;
    let normB = 0;

    for (let i = 0; i < length; i++) {
      const a = vecA[i];
      const b = vecB[i];
      dotProduct += a * b;
      normA += a * a;
      normB += b * b;
    }

    if (normA === 0 || normB === 0) {
      return 0;
    }

    return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
  }

  /**
   * Calculate cosine distance (1 - cosine similarity)
   */
  cosineDistance(vecA, vecB) {
    return 1 - this.cosineSimilarity(vecA, vecB);
  }

  /**
   * Fetch embedding vector from Ollama API
   */
  async getEmbedding(text) {
    if (!text || typeof text !== 'string' || !text.trim()) {
      throw new Error('Text input is required to generate an embedding');
    }

    const response = await fetch(`${OLLAMA_BASE_URL}/api/embeddings`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: EMBED_MODEL,
        prompt: text.trim(),
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Ollama embedding error (${response.status}): ${errorText}`);
    }

    const data = await response.json();
    if (!data.embedding || !Array.isArray(data.embedding)) {
      throw new Error('Invalid embedding vector returned from Ollama');
    }

    return data.embedding;
  }

  /**
   * Retrieve the most relevant exercises based on user query using vector similarity (HRD-23)
   * @param {string} userMessage - Athlete prompt or question
   * @param {number} limit - Maximum number of exercises to retrieve (default 5)
   * @returns {Promise<Array<Object>>} List of exercises with similarity metrics
   */
  async retrieveRelevantExercises(userMessage, limit = 5) {
    if (!userMessage || typeof userMessage !== 'string' || !userMessage.trim()) {
      return [];
    }

    const queryLimit = Math.max(1, Math.min(20, parseInt(limit, 10) || 5));
    let queryVector = null;

    // 1. Generate embedding for user query
    try {
      queryVector = await this.getEmbedding(userMessage);
    } catch (embedError) {
      console.warn('[RagService] Failed to generate query embedding via Ollama:', embedError.message);
      // Graceful fallback: return empty list or keyword fallback so chat never crashes
      return [];
    }

    // 2. Try native pgvector query if extension and vector casting are supported
    try {
      const vectorLiteral = `[${queryVector.join(',')}]`;
      const [pgvectorResults] = await sequelize.query(
        `
        SELECT e.id, e.name, e."muscleGroup", e.instructions, e."formTips", e.alternatives,
               (e1.vector::text::vector <=> :vectorParam::vector) AS distance
        FROM "Exercises" e
        JOIN "Embeddings" e1 ON e.id = e1."exerciseId"
        ORDER BY distance ASC
        LIMIT :limit
        `,
        {
          replacements: {
            vectorParam: vectorLiteral,
            limit: queryLimit,
          },
        }
      );

      if (Array.isArray(pgvectorResults) && pgvectorResults.length > 0) {
        return pgvectorResults.map((row) => ({
          id: row.id,
          name: row.name,
          muscleGroup: row.muscleGroup,
          instructions: row.instructions,
          formTips: row.formTips,
          alternatives: Array.isArray(row.alternatives) ? row.alternatives : [],
          distance: parseFloat(row.distance) || 0,
          similarity: 1 - (parseFloat(row.distance) || 0),
        }));
      }
    } catch (pgvectorError) {
      // pgvector operator not supported on JSON column or extension not installed;
      // fall through to high-performance application-level cosine similarity
    }

    // 3. Fallback: Application-level cosine similarity over stored embeddings
    try {
      const records = await Embedding.findAll({
        attributes: ['id', 'exerciseId', 'vector'],
        include: [
          {
            model: Exercise,
            as: 'exercise',
            attributes: ['id', 'name', 'muscleGroup', 'instructions', 'formTips', 'alternatives'],
          },
        ],
      });

      if (!records || records.length === 0) {
        return [];
      }

      const scored = [];
      for (const record of records) {
        if (!record.exercise) continue;

        let itemVector = record.vector;
        if (typeof itemVector === 'string') {
          try {
            itemVector = JSON.parse(itemVector);
          } catch (_) {
            continue;
          }
        }

        if (!Array.isArray(itemVector) || itemVector.length === 0) {
          continue;
        }

        const similarity = this.cosineSimilarity(queryVector, itemVector);
        const distance = 1 - similarity;

        scored.push({
          id: record.exercise.id,
          name: record.exercise.name,
          muscleGroup: record.exercise.muscleGroup,
          instructions: record.exercise.instructions,
          formTips: record.exercise.formTips,
          alternatives: record.exercise.alternatives || [],
          distance,
          similarity,
        });
      }

      // Sort by distance ascending (highest similarity first)
      scored.sort((a, b) => a.distance - b.distance);

      return scored.slice(0, queryLimit);
    } catch (dbError) {
      console.error('[RagService] Error during fallback exercise retrieval:', dbError.message);
      return [];
    }
  }
}

export default new RagService();
