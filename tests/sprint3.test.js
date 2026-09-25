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
  Leaderboard,
  Friend,
  Challenge,
  Achievement,
} from '../src/models/index.js';
import xpService from '../src/services/xpService.js';

describe('Sprint 3: Gamification & Social (HRD-14, HRD-15, HRD-16, HRD-17)', () => {
  const userA = {
    username: 'athlete_alpha',
    email: 'alpha@example.com',
    password: 'password123',
  };

  const userB = {
    username: 'athlete_bravo',
    email: 'bravo@example.com',
    password: 'password123',
  };

  let tokenA = '';
  let tokenB = '';
  let userIdA = '';
  let userIdB = '';
  let sampleExercise = null;
  let testChallengeId = null;

  before(async () => {
    // Clean up test athletes
    const existing = await User.findAll({
      where: { email: [userA.email, userB.email] },
    });
    for (const u of existing) {
      await Workout.destroy({ where: { userId: u.id } });
      await XpLog.destroy({ where: { userId: u.id } });
      await Leaderboard.destroy({ where: { userId: u.id } });
      await Friend.destroy({ where: { userId: u.id } });
      await Friend.destroy({ where: { friendId: u.id } });
      await Challenge.destroy({ where: { challengerId: u.id } });
      await Challenge.destroy({ where: { challengedId: u.id } });
      await Achievement.destroy({ where: { userId: u.id } });
      await u.destroy();
    }

    // Register User A
    const resA = await request(app).post('/auth/register').send(userA);
    assert.equal(resA.status, 201);
    tokenA = resA.body.data.accessToken;
    userIdA = resA.body.data.user.id;

    // Register User B
    const resB = await request(app).post('/auth/register').send(userB);
    assert.equal(resB.status, 201);
    tokenB = resB.body.data.accessToken;
    userIdB = resB.body.data.user.id;

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
        where: { email: [userA.email, userB.email] },
      });
      for (const u of users) {
        await Workout.destroy({ where: { userId: u.id } });
        await XpLog.destroy({ where: { userId: u.id } });
        await Leaderboard.destroy({ where: { userId: u.id } });
        await Friend.destroy({ where: { userId: u.id } });
        await Friend.destroy({ where: { friendId: u.id } });
        await Challenge.destroy({ where: { challengerId: u.id } });
        await Challenge.destroy({ where: { challengedId: u.id } });
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

  // =========================================================================
  // 2. Task 3.2: Leaderboard System (HRD-15)
  // =========================================================================
  describe('Leaderboard System (HRD-15)', () => {
    it('GET /leaderboard/global should return athletes ranked by volume', async () => {
      const res = await request(app).get('/leaderboard/global');

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.ok(Array.isArray(res.body.data.leaderboard));
      assert.ok(res.body.data.leaderboard.length >= 1);

      // User A logged 3 * 10 * 50 = 1500 kg volume
      const alphaEntry = res.body.data.leaderboard.find(
        (e) => e.user && e.user.id === userIdA
      );
      assert.ok(alphaEntry, 'Expected User A in global leaderboard');
      assert.equal(alphaEntry.totalVolume, 1500);
    });

    it('GET /leaderboard/weekly should return weekly volume rankings', async () => {
      const res = await request(app).get('/leaderboard/weekly');

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.ok(Array.isArray(res.body.data.leaderboard));

      const alphaEntry = res.body.data.leaderboard.find(
        (e) => e.user && e.user.id === userIdA
      );
      assert.ok(alphaEntry);
      assert.equal(alphaEntry.weeklyVolume, 1500);
    });

    it('POST /leaderboard/update/:userId should manually refresh ranking', async () => {
      const res = await request(app)
        .post(`/leaderboard/update/${userIdA}`)
        .set('Authorization', `Bearer ${tokenA}`);

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.equal(res.body.data.userId, userIdA);
      assert.equal(res.body.data.totalVolume, 1500);
    });
  });

  // =========================================================================
  // 3. Task 3.3: Friend & Social Graph (HRD-16)
  // =========================================================================
  describe('Friend & Social Graph (HRD-16)', () => {
    it('POST /friends should fail if sending friend request to oneself', async () => {
      const res = await request(app)
        .post('/friends')
        .set('Authorization', `Bearer ${tokenA}`)
        .send({ friendId: userIdA });

      assert.equal(res.status, 400);
      assert.equal(res.body.success, false);
      assert.match(res.body.error, /yourself/i);
    });

    it('POST /friends should send friend request with status PENDING', async () => {
      const res = await request(app)
        .post('/friends')
        .set('Authorization', `Bearer ${tokenA}`)
        .send({ friendId: userIdB });

      assert.equal(res.status, 201);
      assert.equal(res.body.success, true);
      assert.equal(res.body.data.status, 'PENDING');
      assert.equal(res.body.data.userId, userIdA);
      assert.equal(res.body.data.friendId, userIdB);
    });

    it('GET /friends?status=PENDING should show incoming request for User B', async () => {
      const res = await request(app)
        .get('/friends?status=PENDING')
        .set('Authorization', `Bearer ${tokenB}`);

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.ok(res.body.data.pendingCount >= 1);
      const reqFromA = res.body.data.friends.find(
        (f) => f.friend && f.friend.id === userIdA
      );
      assert.ok(reqFromA, 'User B should see incoming request from User A');
      assert.equal(reqFromA.isIncomingRequest, true);
    });

    it('PUT /friends/:friendId with accept action should update status to ACCEPTED', async () => {
      const res = await request(app)
        .put(`/friends/${userIdA}`)
        .set('Authorization', `Bearer ${tokenB}`)
        .send({ action: 'accept' });

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.equal(res.body.data.status, 'ACCEPTED');
    });

    it('GET /leaderboard/friends should show rankings including friends', async () => {
      const res = await request(app)
        .get('/leaderboard/friends')
        .set('Authorization', `Bearer ${tokenA}`);

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.ok(res.body.data.leaderboard.length >= 1);
    });

    it('DELETE /friends/:friendId should remove friend connection', async () => {
      const res = await request(app)
        .delete(`/friends/${userIdB}`)
        .set('Authorization', `Bearer ${tokenA}`);

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);

      // Verify removal
      const check = await Friend.findOne({
        where: { userId: userIdA, friendId: userIdB },
      });
      assert.equal(check, null);
    });
  });

  // =========================================================================
  // 4. Task 3.4: 1v1 Challenge System (HRD-17)
  // =========================================================================
  describe('1v1 Challenge System (HRD-17)', () => {
    it('POST /challenges should create a PENDING challenge', async () => {
      const res = await request(app)
        .post('/challenges')
        .set('Authorization', `Bearer ${tokenA}`)
        .send({
          challengedId: userIdB,
          exerciseId: sampleExercise.id,
          rewardXp: 150,
        });

      assert.equal(res.status, 201);
      assert.equal(res.body.success, true);
      assert.equal(res.body.data.challengerId, userIdA);
      assert.equal(res.body.data.challengedId, userIdB);
      assert.equal(res.body.data.status, 'PENDING');
      assert.equal(res.body.data.rewardXp, 150);

      testChallengeId = res.body.data.id;
    });

    it('GET /challenges should list user challenges', async () => {
      const res = await request(app)
        .get('/challenges')
        .set('Authorization', `Bearer ${tokenA}`);

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.ok(res.body.data.total >= 1);
      assert.equal(res.body.data.challenges[0].id, testChallengeId);
    });

    it('PUT /challenges/:id with accept should update status to IN_PROGRESS', async () => {
      const res = await request(app)
        .put(`/challenges/${testChallengeId}`)
        .set('Authorization', `Bearer ${tokenB}`)
        .send({ action: 'accept' });

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.equal(res.body.data.status, 'IN_PROGRESS');
    });

    it('Logging workout with challenged exercise should update participant scores', async () => {
      // User A logs workout with the challenged exercise: 4 sets * 10 reps @ 100kg = 4000kg
      await request(app)
        .post('/workouts')
        .set('Authorization', `Bearer ${tokenA}`)
        .send({
          name: 'Challenge Push Session',
          duration: 40,
          exercises: [
            {
              exerciseId: sampleExercise.id,
              sets: 4,
              reps: 10,
              weight: 100,
            },
          ],
        });

      // Verify challenge score updated
      const challenge = await Challenge.findByPk(testChallengeId);
      assert.ok(challenge.challengerScore >= 4000);
    });

    it('PUT /challenges/:id with complete should declare winner and award XP', async () => {
      // Challenger has 4000kg, Challenged has 0kg -> Challenger (User A) wins!
      const initialTotalXpA = (await User.findByPk(userIdA)).totalXp;

      const res = await request(app)
        .put(`/challenges/${testChallengeId}`)
        .set('Authorization', `Bearer ${tokenA}`)
        .send({ action: 'complete' });

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.equal(res.body.data.status, 'COMPLETED');
      assert.equal(res.body.data.winnerId, userIdA);

      // Verify User A received 150 XP bonus for winning
      const updatedUserA = await User.findByPk(userIdA);
      assert.equal(updatedUserA.totalXp, initialTotalXpA + 150);

      // Verify User B received 50 XP consolation
      const logsB = await XpLog.findAll({
        where: { userId: userIdB, type: 'CHALLENGE' },
      });
      assert.ok(logsB.length >= 1);
      assert.equal(logsB[0].amount, 50);
    });
  });
});
