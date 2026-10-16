import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { sequelize, User, Workout, XpLog, Achievement, Conversation, Message } from '../src/models/index.js';
import agentToolService from '../src/services/agentToolService.js';
import agentService from '../src/services/agentService.js';
import { AGENT_TOOLS } from '../src/constants/agentTools.js';

describe('Sprint 4: Task 4.6 — Implement Function Calling (HRD-24)', () => {
  const testUser = {
    username: 'tool_tester',
    email: 'tool_tester@example.com',
    password: 'password123',
    level: 2,
    currentXp: 50,
    totalXp: 250,
    streak: 3,
  };

  let userId = '';
  let conversationId = '';

  before(async () => {
    await sequelize.authenticate();

    // Clean up existing test user
    const existing = await User.findOne({ where: { email: testUser.email } });
    if (existing) {
      await XpLog.destroy({ where: { userId: existing.id } });
      await Achievement.destroy({ where: { userId: existing.id } });
      await Conversation.destroy({ where: { userId: existing.id } });
      await Workout.destroy({ where: { userId: existing.id } });
      await existing.destroy();
    }

    const created = await User.create(testUser);
    userId = created.id;

    // Create a workout for volume / suggestion testing
    await Workout.create({
      userId,
      name: 'Initial Chest Session',
      date: new Date(),
      duration: 45,
      totalVolume: 2500,
    });

    const conv = await Conversation.create({
      userId,
      title: 'Function Calling Session',
    });
    conversationId = conv.id;
  });

  after(async () => {
    try {
      if (userId) {
        await XpLog.destroy({ where: { userId } });
        await Achievement.destroy({ where: { userId } });
        await Conversation.destroy({ where: { userId } });
        await Workout.destroy({ where: { userId } });
        await User.destroy({ where: { id: userId } });
      }
    } catch (_) {}
  });

  // =========================================================================
  // 1. Tool Specification Definitions
  // =========================================================================
  describe('AGENT_TOOLS Schema Specifications', () => {
    it('should define all 8 required intent tools with parameters conforming to JSON Schema', () => {
      assert.equal(AGENT_TOOLS.length, 8);

      const toolNames = AGENT_TOOLS.map((t) => t.function.name);
      assert.ok(toolNames.includes('logWorkout'));
      assert.ok(toolNames.includes('getUserStats'));
      assert.ok(toolNames.includes('getRecentWorkouts'));
      assert.ok(toolNames.includes('addXp'));
      assert.ok(toolNames.includes('checkAchievements'));
      assert.ok(toolNames.includes('suggestNextExercise'));
      assert.ok(toolNames.includes('generateWorkoutPlan'));
      assert.ok(toolNames.includes('updateStreak'));

      for (const tool of AGENT_TOOLS) {
        assert.equal(tool.type, 'function');
        assert.ok(tool.function.description);
        assert.ok(tool.function.parameters);
        assert.equal(tool.function.parameters.type, 'object');
      }
    });
  });

  // =========================================================================
  // 2. Individual Tool Execution (AgentToolService)
  // =========================================================================
  describe('AgentToolService - Core Functions Execution', () => {
    it('1. addXp should award XP, log to XpLog, and update user totalXp', async () => {
      const result = await agentToolService.handleAddXp(userId, {
        amount: 75,
        reason: 'Crushed heavy bench press sets',
      });

      assert.equal(result.success, true);
      assert.equal(result.awardedXp, 75);
      assert.ok(result.totalXp >= 325);

      const log = await XpLog.findOne({
        where: { userId, amount: 75 },
        order: [['createdAt', 'DESC']],
      });
      assert.ok(log);
      assert.equal(log.type, 'BONUS');
      assert.ok(log.description.includes('bench press'));
    });

    it('2. logWorkout should create a workout, calculate volume, and award XP', async () => {
      const result = await agentToolService.handleLogWorkout(userId, {
        name: 'AI Logged Push Day',
        duration: 50,
        exercises: [
          { exerciseName: 'Barbell Bench Press', sets: 3, reps: 10, weight: 80 },
          { exerciseName: 'Incline Dumbbell Press', sets: 3, reps: 12, weight: 24 },
        ],
        notes: 'Felt strong on all sets',
      });

      assert.equal(result.success, true);
      assert.equal(result.name, 'AI Logged Push Day');
      assert.ok(result.totalVolume > 0);
      assert.ok(result.awardedXp > 0);
      assert.ok(result.workoutId);
    });

    it('3. getUserStats should return athlete summary with workouts and volume', async () => {
      const result = await agentToolService.handleGetUserStats(userId);

      assert.equal(result.success, true);
      assert.equal(result.username, 'tool_tester');
      assert.ok(result.totalWorkouts >= 1);
      assert.ok(result.totalVolumeKg > 0);
      assert.ok(result.nextLevelAt > 0);
    });

    it('4. getRecentWorkouts should return list of past logged workouts', async () => {
      const result = await agentToolService.handleGetRecentWorkouts(userId, { limit: 5 });

      assert.equal(result.success, true);
      assert.ok(Array.isArray(result.workouts));
      assert.ok(result.count >= 1);
      assert.ok(result.workouts[0].name);
    });

    it('5. checkAchievements should evaluate milestones without throwing', async () => {
      const result = await agentToolService.handleCheckAchievements(userId);

      assert.equal(result.success, true);
      assert.ok(typeof result.unlockedCount === 'number');
      assert.ok(Array.isArray(result.unlockedBadges));
    });

    it('6. suggestNextExercise should suggest an exercise for the requested muscle group', async () => {
      const result = await agentToolService.handleSuggestNextExercise(userId, {
        muscleGroup: 'Chest',
      });

      assert.equal(result.success, true);
      assert.equal(result.muscleGroup, 'Chest');
      assert.ok(result.suggestedExercise);
      assert.ok(result.suggestedExercise.name);
      assert.ok(result.suggestedExercise.instructions);
    });

    it('7. generateWorkoutPlan should return a structured plan JSON', async () => {
      const result = await agentToolService.handleGenerateWorkoutPlan(userId, {
        duration: 45,
        focus: 'Legs',
      });

      assert.equal(result.success, true);
      assert.ok(result.plan);
      assert.equal(result.plan.durationMinutes, 45);
      assert.equal(result.plan.focus, 'Legs');
      assert.ok(Array.isArray(result.plan.exercises));
      assert.ok(result.plan.exercises.length >= 3);
      assert.ok(result.plan.warmup);
      assert.ok(result.plan.cooldown);

      const firstEx = result.plan.exercises[0];
      assert.ok(firstEx.name);
      assert.ok(firstEx.sets);
      assert.ok(firstEx.reps);
    });

    it('8. updateStreak should increment consecutive days streak', async () => {
      const userBefore = await User.findByPk(userId);
      const prevStreak = userBefore.streak;

      const result = await agentToolService.handleUpdateStreak(userId);

      assert.equal(result.success, true);
      assert.equal(result.currentStreak, prevStreak + 1);

      const userAfter = await User.findByPk(userId);
      assert.equal(userAfter.streak, prevStreak + 1);
    });

    it('should handle unknown tool names gracefully without throwing', async () => {
      const result = await agentToolService.executeTool(userId, 'nonExistentTool', {});
      assert.equal(result.success, false);
      assert.ok(result.error.includes('Unknown tool function'));
    });
  });

  // =========================================================================
  // 3. AgentService Tool Dispatcher Integration
  // =========================================================================
  describe('AgentService - Tool Execution Dispatcher', () => {
    it('should route tool execution correctly through agentService.executeTool', async () => {
      const result = await agentService.executeTool(userId, 'addXp', {
        amount: 25,
        reason: 'Quick consistency bonus',
      });

      assert.equal(result.success, true);
      assert.equal(result.awardedXp, 25);
    });

    it('should route getUserStats correctly through agentService.executeTool', async () => {
      const result = await agentService.executeTool(userId, 'getUserStats', {});

      assert.equal(result.success, true);
      assert.equal(result.username, 'tool_tester');
    });
  });

  // =========================================================================
  // 4. Pre-prompt Intent & Selective Tool Router (routeUserIntent)
  // =========================================================================
  describe('AgentService - Pre-prompt Intent & Selective Tool Routing', () => {
    it('should classify casual greetings with NO tools and NO RAG context', async () => {
      const decision1 = await agentService.routeUserIntent('Hello coach!');
      assert.equal(decision1.intent, 'greeting');
      assert.deepEqual(decision1.relevantTools, []);
      assert.equal(decision1.needsExerciseRag, false);
      assert.equal(decision1.needsWorkoutHistory, false);

      const decision2 = await agentService.routeUserIntent('Hey, how are you doing today?');
      assert.equal(decision2.intent, 'greeting');
      assert.deepEqual(decision2.relevantTools, []);
      assert.equal(decision2.needsExerciseRag, false);
    });

    it('should classify nutrition queries with NO tools and NO exercise RAG', async () => {
      const decision = await agentService.routeUserIntent('How many grams of protein should I eat per day?');
      assert.deepEqual(decision.relevantTools, []);
      assert.equal(decision.needsExerciseRag, false);
    });

    it('should select logWorkout tool when athlete requests logging', async () => {
      const decision = await agentService.routeUserIntent('Log my workout: 3 sets of bench press 10 reps at 80kg');
      assert.ok(decision.relevantTools.includes('logWorkout'));
    });

    it('should select getUserStats tool when athlete asks for their stats and level', async () => {
      const decision = await agentService.routeUserIntent('Show me my user stats and total volume lifted');
      assert.ok(decision.relevantTools.includes('getUserStats'));
    });

    it('should select suggestNextExercise and flag workout history when athlete asks what to do next', async () => {
      const decision = await agentService.routeUserIntent('Suggest next exercise for my chest session');
      assert.ok(decision.relevantTools.includes('suggestNextExercise'));
      assert.equal(decision.needsWorkoutHistory, true);
    });

    it('should select generateWorkoutPlan when athlete requests a routine', async () => {
      const decision = await agentService.routeUserIntent('Can you generate a workout plan for 45 minutes?');
      assert.ok(decision.relevantTools.includes('generateWorkoutPlan'));
    });

    it('should flag needsExerciseRag for exercise form & technique questions', async () => {
      const decision = await agentService.routeUserIntent('What is the proper technique and form for barbell squats?');
      assert.equal(decision.needsExerciseRag, true);
    });

    it('should handle null, empty or non-string input safely', async () => {
      const decision = await agentService.routeUserIntent('');
      assert.equal(decision.intent, 'greeting');
      assert.deepEqual(decision.relevantTools, []);
      assert.equal(decision.needsExerciseRag, false);
      assert.equal(decision.needsWorkoutHistory, false);
    });
  });
});
