# Task 4.5: Implement RAG (Retrieval-Augmented Generation) — Test & Deliverable Report

**Project:** Hard Backend API  
**Sprint:** Sprint 4 — AI Integration  
**Issue:** [HRD-23](https://ayoubnaoui00.atlassian.net/browse/HRD-23)  
**Date:** 2026-09-28  

---

## 🎯 Task Objective & Acceptance Criteria

Equip the AI Coach agent with Retrieval-Augmented Generation (RAG) capabilities using exercise vector embeddings:
1. **Embedding Generation**: Convert user prompts to 384-dimensional dense vectors via Ollama (`all-minilm` model).
2. **Vector Similarity Search**: Query the 1,324 pre-seeded exercise embeddings in PostgreSQL using cosine distance. Supports pgvector `<=>` operator with an optimized in-memory cosine fallback.
3. **Context Injection**: Top 3–5 matching exercises (with target muscle group, instructions, form tips, and alternatives) are injected into the agent system prompt context.
4. **Reliability & Resilience**: Vector search failures degrade gracefully without interrupting the Server-Sent Events (SSE) chat stream.

---

## 🏗️ Architecture & Implementation

### 1. `src/services/ragService.js`
- `getEmbedding(text)`: Communicates with `OLLAMA_BASE_URL/api/embeddings` using model `all-minilm`.
- `cosineSimilarity(vecA, vecB)` & `cosineDistance(vecA, vecB)`: Precision linear algebra implementation for vector comparison.
- `retrieveRelevantExercises(userMessage, limit = 5)`: 
  - Generates query embedding.
  - Searches `Embeddings` and `Exercises` tables with pgvector / cosine distance.
  - Returns top ranked exercises with `distance` and `similarity` metrics.

### 2. `src/constants/agentPrompts.js`
- Extended `formatSystemPrompt({ user, recentWorkouts, relevantExercises })` to inject:
  ```text
  RELEVANT EXERCISES (EXERCISE DATABASE / RAG CONTEXT):
  - [Exercise Name] (Muscle Group: [Muscle])
    Instructions: ...
    Form Tips: ...
    Alternatives: ...
  ```

### 3. `src/services/agentService.js`
- Integrated RAG retrieval into `streamChat()`:
  - Automatically queries `ragService.retrieveRelevantExercises(messageText, 5)`.
  - Injects retrieved domain knowledge into prompt prior to LLM streaming.
  - Returns `relevantExercises` in the resolution payload.

---

## 🧪 Test Results (`tests/rag.test.js`)

Executed with Node's native test runner against live database and Ollama instance:

```text
▶ Sprint 4: Task 4.5 — Implement RAG (HRD-23)
  ▶ RagService - Vector Math & Similarity Metrics
    ✔ should return 1 for identical normalized vectors
    ✔ should return 0 for orthogonal vectors
    ✔ should return -1 for opposite vectors
    ✔ should handle empty or invalid vectors gracefully
  ✔ RagService - Vector Math & Similarity Metrics
  ▶ RagService - Ollama Embedding Generation
    ✔ should generate an embedding vector with length 384 for fitness text
    ✔ should reject empty or invalid query string with Error
  ✔ RagService - Ollama Embedding Generation
  ▶ RagService - Exercise Retrieval with Similarity Ordering
    ✔ should return top relevant exercises for chest-focused query
    ✔ should return top relevant exercises for leg-focused query
    ✔ should return empty array for empty or whitespace query
    ✔ should respect custom limit parameter
  ✔ RagService - Exercise Retrieval with Similarity Ordering
  ▶ formatSystemPrompt - RAG Context Injection
    ✔ should inject relevant exercises into the coach system prompt
  ✔ formatSystemPrompt - RAG Context Injection
✔ Sprint 4: Task 4.5 — Implement RAG (HRD-23)
ℹ tests 11
ℹ suites 5
ℹ pass 11
ℹ fail 0
```

All 11 tests passed with 0 failures.
