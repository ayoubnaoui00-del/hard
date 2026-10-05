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
    it('should define all 5 required tools with parameters conforming to JSON Schema', () => {
      assert.equal(AGENT_TOOLS.length, 5);

      const toolNames = AGENT_TOOLS.map((t) => t.function.name);
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
  describe('AgentToolService - 6 Core Functions Execution', () => {
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



    it('3. checkAchievements should evaluate milestones without throwing', async () => {
      const result = await agentToolService.handleCheckAchievements(userId);

      assert.equal(result.success, true);
      assert.ok(typeof result.unlockedCount === 'number');
      assert.ok(Array.isArray(result.unlockedBadges));
    });

    it('4. suggestNextExercise should suggest an exercise for the requested muscle group', async () => {
      const result = await agentToolService.handleSuggestNextExercise(userId, {
        muscleGroup: 'Chest',
      });

      assert.equal(result.success, true);
      assert.equal(result.muscleGroup, 'Chest');
      assert.ok(result.suggestedExercise);
      assert.ok(result.suggestedExercise.name);
      assert.ok(result.suggestedExercise.instructions);
    });

    it('5. generateWorkoutPlan should return a structured plan JSON', async () => {
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

    it('6. updateStreak should increment consecutive days streak', async () => {
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
  });
});
