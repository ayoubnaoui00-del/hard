# Task 4.6: Implement Function Calling — Test & Deliverable Report

**Project:** Hard Backend API  
**Sprint:** Sprint 4 — AI Integration  
**Issue:** [HRD-24](https://ayoubnaoui00.atlassian.net/browse/HRD-24)  
**Date:** 2026-09-28  

---

## 🎯 Task Objective & Acceptance Criteria

Equip the AI Coach agent with backend action execution capabilities using Function Calling:
1. **Tool Definitions (`AGENT_TOOLS`)**: Define 6 OpenAI/Ollama compatible function schemas with parameter validation.
2. **6 Core Backend Actions**:
   - `addXp(userId, amount, reason)`: Awards XP, logs immutable audit entry to `XpLogs`, increments user XP, and handles leveling up.
   - `updateLeaderboard(userId)`: Recalculates user lifetime volume, weekly volume, and current rank on `Leaderboards`.
   - `checkAchievements(userId)`: Evaluates user stats against achievement milestone definitions and unlocks newly earned badges.
   - `suggestNextExercise(userId, muscleGroup)`: Queries recent workout history to recommend fresh complementary exercises for a given muscle group.
   - `generateWorkoutPlan(userId, duration, focus)`: Creates a structured workout routine JSON (warmup, exercises with sets/reps/rest, cooldown).
   - `updateStreak(userId)`: Increments and persists the athlete's consecutive workout day streak.
3. **Execution Loop & Resilience**:
   - Executes tools automatically during chat sessions.
   - Feeds tool output back into the conversation for natural AI responses.
   - Non-fatal degradation: tool execution errors do not crash the chat stream.

---

## 🏗️ Architecture & Implementation

### 1. `src/constants/agentTools.js`
- JSON Schema declarations for all 6 tools conforming to standard function-calling protocols.

### 2. `src/services/agentToolService.js`
- `handleAddXp`: Integrates with `xpService.addXp(userId, 'BONUS', amount, reason)`.
- `handleUpdateLeaderboard`: Integrates with `leaderboardService.updateUserLeaderboard(userId)`.
- `handleCheckAchievements`: Integrates with `achievementService.checkAndUnlock(userId, 'AGENT_CHECK', {})`.
- `handleSuggestNextExercise`: Scans recent `WorkoutExercise` records and fetches candidate `Exercises` by muscle group.
- `handleGenerateWorkoutPlan`: Scales exercise counts and sets based on requested duration and muscle focus.
- `handleUpdateStreak`: Increments `User.streak` and updates `lastActiveAt`.
- `executeTool(userId, toolName, args)`: Central dispatcher with safe error catching.

### 3. `src/services/agentService.js`
- Integrated `AGENT_TOOLS` into Ollama `/api/chat` payload.
- Consumes streamed `tool_calls`, triggers `agentToolService.executeTool`, appends results to message history, and executes second-pass streaming to deliver conversational confirmation.
- Emits real-time `tool_call` events over SSE stream via `AgentController.js`.

---

## 🧪 Test Results (`tests/function-calling.test.js`)

Executed with Node's native test runner against live database:

```text
▶ Sprint 4: Task 4.6 — Implement Function Calling (HRD-24)
  ▶ AGENT_TOOLS Schema Specifications
    ✔ should define all 6 required tools with parameters conforming to JSON Schema
  ✔ AGENT_TOOLS Schema Specifications
  ▶ AgentToolService - 6 Core Functions Execution
    ✔ 1. addXp should award XP, log to XpLog, and update user totalXp
    ✔ 2. updateLeaderboard should recalculate volume and rank
    ✔ 3. checkAchievements should evaluate milestones without throwing
    ✔ 4. suggestNextExercise should suggest an exercise for the requested muscle group
    ✔ 5. generateWorkoutPlan should return a structured plan JSON
    ✔ 6. updateStreak should increment consecutive days streak
    ✔ should handle unknown tool names gracefully without throwing
  ✔ AgentToolService - 6 Core Functions Execution
  ▶ AgentService - Tool Execution Dispatcher
    ✔ should route tool execution correctly through agentService.executeTool
  ✔ AgentService - Tool Execution Dispatcher
✔ Sprint 4: Task 4.6 — Implement Function Calling (HRD-24)
ℹ tests 9
ℹ suites 4
ℹ pass 9
ℹ fail 0
```

All 9 tests passed with 0 failures.
