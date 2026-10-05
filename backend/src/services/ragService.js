import dotenv from 'dotenv';
import { Pinecone } from '@pinecone-database/pinecone';
import { sequelize, Exercise, Embedding } from '../models/index.js';

dotenv.config();

const PINECONE_API_KEY = process.env.PINECONE_API_KEY;
const PINECONE_INDEX = process.env.PINECONE_INDEX || 'hard';
const PINECONE_EMBED_MODEL = process.env.PINECONE_EMBED_MODEL || 'llama-text-embed-v2';

class RagService {
  constructor() {
    this.indexName = PINECONE_INDEX;
    this.embedModel = PINECONE_EMBED_MODEL;
    this.pinecone = null;
    this.index = null;

    this.initPinecone();
  }

  /**
   * Initialize Pinecone Client and Index
   */
  initPinecone() {
    const apiKey = process.env.PINECONE_API_KEY || PINECONE_API_KEY;
    if (apiKey) {
      try {
        this.pinecone = new Pinecone({ apiKey });
        this.index = this.pinecone.index(this.indexName);
      } catch (err) {
        console.warn('[RagService] Could not initialize Pinecone client:', err.message);
      }
    } else {
      console.warn('[RagService] PINECONE_API_KEY is not set in environment.');
    }
  }

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
   * Fetch embedding vector from Pinecone Inference API (llama-text-embed-v2)
   * Dimension: 1024
   */
  async getEmbedding(text, inputType = 'passage') {
    if (!text || typeof text !== 'string' || !text.trim()) {
      throw new Error('Text input is required to generate an embedding');
    }

    if (!this.pinecone) {
      this.initPinecone();
    }

    if (!this.pinecone) {
      throw new Error('Pinecone client is not initialized. Please configure PINECONE_API_KEY.');
    }

    const response = await this.pinecone.inference.embed({
      model: this.embedModel,
      inputs: [text.trim()],
      parameters: {
        inputType: inputType === 'query' ? 'query' : 'passage',
        truncate: 'END',
      },
    });

    const values = response.data?.[0]?.values;
    if (!values || !Array.isArray(values)) {
      throw new Error('Invalid embedding vector returned from Pinecone inference');
    }

    return values;
  }

  /**
   * Format exercise data into structured Pinecone record for Integrated Inference
   */
  formatExerciseRecord(ex) {
    const summaryText = [
      `Exercise: ${ex.name}`,
      `Target Muscle: ${ex.muscleGroup}`,
      ex.instructions ? `Instructions: ${ex.instructions}` : '',
      ex.formTips ? `Form Tips: ${ex.formTips}` : '',
    ]
      .filter(Boolean)
      .join(' - ');

    return {
      _id: `ex-${ex.id}`,
      text: summaryText,
      exerciseId: String(ex.id),
      name: ex.name,
      muscleGroup: ex.muscleGroup,
      instructions: (ex.instructions || '').substring(0, 1500),
      formTips: (ex.formTips || '').substring(0, 1500),
      alternatives: Array.isArray(ex.alternatives) ? ex.alternatives : [],
    };
  }

  /**
   * Upsert a batch of exercises into Pinecone index
   */
  async upsertExercises(exercises) {
    if (!this.index) {
      this.initPinecone();
    }
    if (!this.index) {
      throw new Error('Pinecone index is not initialized');
    }

    const records = exercises.map((ex) => this.formatExerciseRecord(ex));
    await this.index.upsertRecords({ records });
    return records.length;
  }

  /**
   * Retrieve the most relevant exercises based on user query using vector similarity (HRD-23)
   * Queries Pinecone index with native integrated inference (llama-text-embed-v2)
   *
   * @param {string} userMessage - Athlete prompt or question
   * @param {number} limit - Maximum number of exercises to retrieve (default 5)
   * @returns {Promise<Array<Object>>} List of exercises with similarity metrics
   */
  async retrieveRelevantExercises(userMessage, limit = 5) {
    if (!userMessage || typeof userMessage !== 'string' || !userMessage.trim()) {
      return [];
    }

    const queryLimit = Math.max(1, Math.min(20, parseInt(limit, 10) || 5));

    // 1. Primary: Query Pinecone index using searchRecords (Integrated Inference)
    if (this.index || process.env.PINECONE_API_KEY) {
      if (!this.index) this.initPinecone();

      if (this.index) {
        try {
          const searchRes = await this.index.searchRecords({
            query: {
              inputs: { text: userMessage.trim() },
              topK: queryLimit,
            },
          });

          const hits = searchRes.result?.hits;
          if (Array.isArray(hits) && hits.length > 0) {
            return hits.map((hit) => {
              const fields = hit.fields || {};
              const similarity = typeof hit._score === 'number' ? hit._score : 0;
              const distance = 1 - similarity;

              return {
                id: fields.exerciseId || hit._id.replace(/^ex-/, ''),
                name: fields.name || '',
                muscleGroup: fields.muscleGroup || '',
                instructions: fields.instructions || '',
                formTips: fields.formTips || '',
                alternatives: Array.isArray(fields.alternatives) ? fields.alternatives : [],
                similarity,
                distance,
              };
            });
          }
        } catch (pineconeErr) {
          console.warn('[RagService] Pinecone searchRecords failed, falling back to local database:', pineconeErr.message);
        }
      }
    }

    // 2. Fallback: PostgreSQL database (application-level cosine similarity or pgvector)
    try {
      let queryVector = null;
      try {
        queryVector = await this.getEmbedding(userMessage, 'query');
      } catch (_) {
        // If inference is unavailable, query text fallback
      }

      if (queryVector) {
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

        if (records && records.length > 0) {
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

          scored.sort((a, b) => a.distance - b.distance);
          return scored.slice(0, queryLimit);
        }
      }

      // Keyword fallback from Exercise table if vectors unavailable
      const fallbackExercises = await Exercise.findAll({
        limit: queryLimit,
        order: [['name', 'ASC']],
      });

      return fallbackExercises.map((ex) => ({
        id: ex.id,
        name: ex.name,
        muscleGroup: ex.muscleGroup,
        instructions: ex.instructions,
        formTips: ex.formTips,
        alternatives: ex.alternatives || [],
        similarity: 0.5,
        distance: 0.5,
      }));
    } catch (dbError) {
      console.error('[RagService] Error during fallback exercise retrieval:', dbError.message);
      return [];
    }
  }
}

export default new RagService();
