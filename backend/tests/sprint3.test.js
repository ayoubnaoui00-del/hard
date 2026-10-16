import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import app, { server } from '../src/index.js';
import {
  sequelize,
  User,
  Exercise,
  Workout,
  WorkoutExercise,
  XpLog,
  Achievement,
} from '../src/models/index.js';
import xpService from '../src/services/xpService.js';

describe('Sprint 3: Gamification & XP System (HRD-14)', () => {
  const userA = {
    username: 'athlete_alpha',
    email: 'alpha@example.com',
    password: 'password123',
  };

  let tokenA = '';
  let userIdA = '';
  let sampleExercise = null;

  before(async () => {
    // Clean up test athlete
    const existing = await User.findAll({
      where: { email: userA.email },
    });
    for (const u of existing) {
      await Workout.destroy({ where: { userId: u.id } });
      await XpLog.destroy({ where: { userId: u.id } });
      await Achievement.destroy({ where: { userId: u.id } });
      await u.destroy();
    }

    // Register User A
    const resA = await request(app).post('/auth/register').send(userA);
    assert.equal(resA.status, 201);
    tokenA = resA.body.data.accessToken;
    userIdA = resA.body.data.user.id;

    // Grab a seeded exercise
    sampleExercise = await Exercise.findOne({ where: { muscleGroup: 'Chest' } });
    if (!sampleExercise) {
      sampleExercise = await Exercise.findOne();
    }
    assert.ok(sampleExercise, 'Requires at least one seeded exercise');
  });

  after(async () => {
    try {
      const users = await User.findAll({
        where: { email: userA.email },
      });
      for (const u of users) {
        await Workout.destroy({ where: { userId: u.id } });
        await XpLog.destroy({ where: { userId: u.id } });
        await Achievement.destroy({ where: { userId: u.id } });
        await u.destroy();
      }
    } catch (_) {}

    await sequelize.close();
    server.close();
  });

  // =========================================================================
  // 1. Task 3.1: XP Logger & Leveling System (HRD-14)
  // =========================================================================
  describe('XP Logger & Leveling System (HRD-14)', () => {
    it('GET /users/me/xp should reject unauthenticated requests with 401', async () => {
      const res = await request(app).get('/users/me/xp');
      assert.equal(res.status, 401);
      assert.equal(res.body.success, false);
    });

    it('GET /users/me/xp should return user XP progress summary and audit logs', async () => {
      const res = await request(app)
        .get('/users/me/xp')
        .set('Authorization', `Bearer ${tokenA}`);

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.equal(res.body.data.user.id, userIdA);
      assert.equal(res.body.data.user.level, 1);
      assert.equal(res.body.data.user.nextLevelAt, 500);
      assert.ok(Array.isArray(res.body.data.recentLogs));
    });

    it('POST /workouts should award XP and record immutable XpLog entry', async () => {
      // 3 sets of 10 reps = 30 reps. XP = 100 + (30 * 10) = 400 XP.
      const payload = {
        name: 'XP Test Workout',
        duration: 30,
        exercises: [
          {
            exerciseId: sampleExercise.id,
            sets: 3,
            reps: 10,
            weight: 50,
          },
        ],
      };

      const res = await request(app)
        .post('/workouts')
        .set('Authorization', `Bearer ${tokenA}`)
        .send(payload);

      assert.equal(res.status, 201);
      assert.equal(res.body.success, true);
      assert.ok(res.body.data.xp, 'Expected XP details in workout response');
      assert.equal(res.body.data.xp.xpLog.amount, 400);
      assert.equal(res.body.data.xp.xpLog.type, 'WORKOUT');
      assert.equal(res.body.data.xp.user.totalXp, 400);
      assert.equal(res.body.data.xp.user.currentXp, 400);

      // Verify immutable log entry in DB
      const logs = await XpLog.findAll({ where: { userId: userIdA } });
      assert.ok(logs.length >= 1);
      assert.equal(logs[0].amount, 400);
    });

    it('Level-up logic: Adding XP past threshold should increment level and carry over currentXp', async () => {
      // Current XP = 400, Level 1 needs 500. Adding 200 XP -> total current 600 -> Level 2, currentXp 100.
      const result = await xpService.addXp(
        userIdA,
        'BONUS',
        200,
        'Level up test bonus'
      );

      assert.equal(result.leveledUp, true);
      assert.equal(result.user.level, 2);
      assert.equal(result.user.currentXp, 100);
      assert.equal(result.user.totalXp, 600);
      assert.equal(result.user.nextLevelAt, 1000); // Level 2 requires 1000 XP
    });
  });
});
