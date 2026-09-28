import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { sequelize, Exercise, Embedding } from '../src/models/index.js';
import ragService from '../src/services/ragService.js';
import { formatSystemPrompt } from '../src/constants/agentPrompts.js';

describe('Sprint 4: Task 4.5 — Implement RAG (HRD-23)', () => {
  before(async () => {
    await sequelize.authenticate();
  });

  after(async () => {
    // Keep connection open or clean up if needed
  });

  // =========================================================================
  // 1. Vector Math Unit Tests
  // =========================================================================
  describe('RagService - Vector Math & Similarity Metrics', () => {
    it('should return 1 for identical normalized vectors', () => {
      const vecA = [1, 0, 0];
      const vecB = [1, 0, 0];
      const similarity = ragService.cosineSimilarity(vecA, vecB);
      assert.equal(Math.round(similarity), 1);
      assert.equal(Math.round(ragService.cosineDistance(vecA, vecB)), 0);
    });

    it('should return 0 for orthogonal vectors', () => {
      const vecA = [1, 0, 0];
      const vecB = [0, 1, 0];
      const similarity = ragService.cosineSimilarity(vecA, vecB);
      assert.equal(similarity, 0);
      assert.equal(ragService.cosineDistance(vecA, vecB), 1);
    });

    it('should return -1 for opposite vectors', () => {
      const vecA = [1, 0, 0];
      const vecB = [-1, 0, 0];
      const similarity = ragService.cosineSimilarity(vecA, vecB);
      assert.equal(Math.round(similarity), -1);
      assert.equal(Math.round(ragService.cosineDistance(vecA, vecB)), 2);
    });

    it('should handle empty or invalid vectors gracefully', () => {
      assert.equal(ragService.cosineSimilarity([], []), 0);
      assert.equal(ragService.cosineSimilarity(null, [1, 2]), 0);
      assert.equal(ragService.cosineSimilarity([1, 2], null), 0);
    });
  });

  // =========================================================================
  // 2. Ollama Embeddings Generation
  // =========================================================================
  describe('RagService - Ollama Embedding Generation', () => {
    it('should generate an embedding vector with length 384 for fitness text', async () => {
      const vector = await ragService.getEmbedding('bench press chest exercise');
      assert.ok(Array.isArray(vector), 'Expected an array vector');
      assert.equal(vector.length, 384, 'all-minilm should produce 384-dimensional embeddings');
      assert.ok(vector.every((val) => typeof val === 'number'), 'All vector items should be numbers');
    });

    it('should reject empty or invalid query string with Error', async () => {
      await assert.rejects(
        () => ragService.getEmbedding(''),
        /Text input is required/
      );
      await assert.rejects(
        () => ragService.getEmbedding('   '),
        /Text input is required/
      );
    });
  });

  // =========================================================================
  // 3. Exercise Vector Retrieval (RAG)
  // =========================================================================
  describe('RagService - Exercise Retrieval with Similarity Ordering', () => {
    it('should return top relevant exercises for chest-focused query', async () => {
      const results = await ragService.retrieveRelevantExercises('What exercises target my lower chest?', 3);
      assert.ok(Array.isArray(results));
      assert.equal(results.length, 3);

      for (const ex of results) {
        assert.ok(ex.id, 'Exercise should have an id');
        assert.ok(ex.name, 'Exercise should have a name');
        assert.ok(ex.muscleGroup, 'Exercise should have a muscleGroup');
        assert.ok(typeof ex.similarity === 'number', 'Exercise should have a numeric similarity score');
        assert.ok(typeof ex.distance === 'number', 'Exercise should have a numeric distance score');
        assert.ok(ex.similarity > 0.5, 'Relevant chest exercises should have high similarity');
      }

      // Check results are sorted by distance ascending (similarity descending)
      for (let i = 0; i < results.length - 1; i++) {
        assert.ok(
          results[i].distance <= results[i + 1].distance,
          'Results should be ordered by distance ascending'
        );
      }
    });

    it('should return top relevant exercises for leg-focused query', async () => {
      const results = await ragService.retrieveRelevantExercises('best quad workout for strength', 3);
      assert.ok(Array.isArray(results));
      assert.equal(results.length, 3);
      assert.ok(results[0].similarity > 0.5);
    });

    it('should return empty array for empty or whitespace query', async () => {
      const results = await ragService.retrieveRelevantExercises('   ', 5);
      assert.deepEqual(results, []);
    });

    it('should respect custom limit parameter', async () => {
      const results = await ragService.retrieveRelevantExercises('biceps curls', 2);
      assert.equal(results.length, 2);
    });
  });

  // =========================================================================
  // 4. System Prompt Context Integration
  // =========================================================================
  describe('formatSystemPrompt - RAG Context Injection', () => {
    it('should inject relevant exercises into the coach system prompt', () => {
      const relevantExercises = [
        {
          name: 'Incline Dumbbell Press',
          muscleGroup: 'Chest',
          instructions: 'Press dumbbells up at a 30-degree incline.',
          formTips: 'Keep wrists stacked over elbows.',
          alternatives: ['Incline Barbell Bench Press'],
        },
      ];

      const prompt = formatSystemPrompt({
        user: { username: 'athlete1', level: 3, totalXp: 1500, streak: 5 },
        recentWorkouts: [],
        relevantExercises,
      });

      assert.ok(prompt.includes('RELEVANT EXERCISES (EXERCISE DATABASE / RAG CONTEXT):'));
      assert.ok(prompt.includes('Incline Dumbbell Press (Muscle Group: Chest)'));
      assert.ok(prompt.includes('Instructions: Press dumbbells up at a 30-degree incline.'));
      assert.ok(prompt.includes('Form Tips: Keep wrists stacked over elbows.'));
      assert.ok(prompt.includes('Alternatives: Incline Barbell Bench Press'));
    });
  });
});
