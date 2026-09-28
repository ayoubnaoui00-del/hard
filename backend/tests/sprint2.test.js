import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import app, { server } from '../src/index.js';
import { sequelize, User, Exercise, Workout, WorkoutExercise, Achievement } from '../src/models/index.js';

describe('Sprint 2: Core Features — Exercises, Workouts & Achievements (HRD-8, HRD-9, HRD-10, HRD-11)', () => {
  const testUser = {
    username: 'sprint2athlete',
    email: 'sprint2@example.com',
    password: 'password123',
  };

  let token = '';
  let sampleExercise = null;
  let createdWorkoutId = null;

  before(async () => {
    // Clean up test athlete if exists
    const existing = await User.findOne({ where: { email: testUser.email } });
    if (existing) {
      await Workout.destroy({ where: { userId: existing.id } });
      await Achievement.destroy({ where: { userId: existing.id } });
      await existing.destroy();
    }

    // Register user to get JWT token
    const regRes = await request(app).post('/auth/register').send(testUser);
    assert.equal(regRes.status, 201);
    token = regRes.body.data.accessToken;

    // Pick a seeded exercise
    sampleExercise = await Exercise.findOne({ where: { muscleGroup: 'Chest' } });
    if (!sampleExercise) {
      sampleExercise = await Exercise.findOne();
    }
    assert.ok(sampleExercise, 'Expected at least one seeded exercise in the database');
  });

  after(async () => {
    try {
      const user = await User.findOne({ where: { email: testUser.email } });
      if (user) {
        await Workout.destroy({ where: { userId: user.id } });
        await Achievement.destroy({ where: { userId: user.id } });
        await user.destroy();
      }
    } catch (_) {}

    await sequelize.close();
    server.close();
  });

  // =========================================================================
  // 1. Task 2.1 & 2.2: Exercise Catalog API (HRD-8 & HRD-9)
  // =========================================================================
  describe('Exercise Catalog API (HRD-9)', () => {
    it('GET /exercises should return paginated list of exercises', async () => {
      const res = await request(app).get('/exercises?limit=10&page=1');

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.ok(res.body.data.total >= 60, 'Should have at least 60 exercises');
      assert.equal(res.body.data.page, 1);
      assert.equal(res.body.data.limit, 10);
      assert.equal(res.body.data.exercises.length, 10);
    });

    it('GET /exercises?muscle=Chest should filter by muscle group', async () => {
      const res = await request(app).get('/exercises?muscle=Chest&limit=5');

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.ok(res.body.data.exercises.length > 0);
      for (const ex of res.body.data.exercises) {
        assert.match(ex.muscleGroup.toLowerCase(), /chest/);
      }
    });

    it('GET /exercises?search=press should search exercises by keyword', async () => {
      const res = await request(app).get('/exercises?search=press&limit=5');

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      for (const ex of res.body.data.exercises) {
        assert.match(ex.name.toLowerCase(), /press/);
      }
    });

    it('GET /exercises/:id should return details for a valid UUID', async () => {
      const res = await request(app).get(`/exercises/${sampleExercise.id}`);

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.equal(res.body.data.id, sampleExercise.id);
      assert.equal(res.body.data.name, sampleExercise.name);
      assert.ok(res.body.data.instructions !== undefined);
      assert.ok(res.body.data.formTips !== undefined);
    });

    it('GET /exercises/:id should return 400 for malformed UUID', async () => {
      const res = await request(app).get('/exercises/not-a-valid-uuid');

      assert.equal(res.status, 400);
      assert.equal(res.body.success, false);
      assert.match(res.body.error, /UUID/);
    });

    it('GET /exercises/:id should return 404 for nonexistent UUID', async () => {
      const nonExistentUuid = '00000000-0000-0000-0000-000000000000';
      const res = await request(app).get(`/exercises/${nonExistentUuid}`);

      assert.equal(res.status, 404);
      assert.equal(res.body.success, false);
      assert.match(res.body.error, /not found/i);
    });
  });

  // =========================================================================
  // 2. Task 2.3: Workout Logging & CRUD API (HRD-10)
  // =========================================================================
  describe('Workout Controller & CRUD (HRD-10)', () => {
    it('POST /workouts should reject unauthenticated requests with 401', async () => {
      const res = await request(app)
        .post('/workouts')
        .send({ name: 'Unauthorized workout' });

      assert.equal(res.status, 401);
      assert.equal(res.body.success, false);
    });

    it('POST /workouts should log a workout and compute totalVolume accurately', async () => {
      const payload = {
        name: 'Upper Body Power',
        duration: 45,
        notes: 'Great pump today!',
        exercises: [
          {
            exerciseId: sampleExercise.id,
            sets: 4,
            reps: 10,
            weight: 80, // volume = 4 * 10 * 80 = 3200 kg
            order: 1,
          },
        ],
      };

      const res = await request(app)
        .post('/workouts')
        .set('Authorization', `Bearer ${token}`)
        .send(payload);

      assert.equal(res.status, 201);
      assert.equal(res.body.success, true);
      assert.equal(res.body.data.workout.name, 'Upper Body Power');
      assert.equal(res.body.data.workout.duration, 45);
      assert.equal(res.body.data.workout.totalVolume, 3200);
      assert.equal(res.body.data.workout.workoutExercises.length, 1);
      assert.equal(
        res.body.data.workout.workoutExercises[0].exerciseId,
        sampleExercise.id
      );

      // Verify that achievement unlocked on 1st workout
      assert.ok(Array.isArray(res.body.data.unlockedAchievements));
      const firstStepUnlocked = res.body.data.unlockedAchievements.some(
        (a) => a.name === 'First Step'
      );
      assert.ok(firstStepUnlocked, 'Expected "First Step" achievement to unlock');

      createdWorkoutId = res.body.data.workout.id;
    });

    it('GET /workouts should return user workout history (paginated)', async () => {
      const res = await request(app)
        .get('/workouts?page=1&limit=10')
        .set('Authorization', `Bearer ${token}`);

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.ok(res.body.data.total >= 1);
      assert.equal(res.body.data.workouts[0].id, createdWorkoutId);
      assert.ok(res.body.data.workouts[0].workoutExercises.length > 0);
    });

    it('GET /workouts/:id should return single workout details', async () => {
      const res = await request(app)
        .get(`/workouts/${createdWorkoutId}`)
        .set('Authorization', `Bearer ${token}`);

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.equal(res.body.data.id, createdWorkoutId);
      assert.equal(res.body.data.workoutExercises.length, 1);
      assert.equal(
        res.body.data.workoutExercises[0].exercise.name,
        sampleExercise.name
      );
    });

    it('PUT /workouts/:id should update workout and recalculate totalVolume', async () => {
      const updatePayload = {
        name: 'Upper Body Heavy',
        duration: 60,
        notes: 'Updated notes with PR',
        exercises: [
          {
            exerciseId: sampleExercise.id,
            sets: 5,
            reps: 10,
            weight: 100, // volume = 5 * 10 * 100 = 5000 kg
            order: 1,
          },
        ],
      };

      const res = await request(app)
        .put(`/workouts/${createdWorkoutId}`)
        .set('Authorization', `Bearer ${token}`)
        .send(updatePayload);

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.equal(res.body.data.name, 'Upper Body Heavy');
      assert.equal(res.body.data.duration, 60);
      assert.equal(res.body.data.totalVolume, 5000);
      assert.equal(res.body.data.workoutExercises[0].sets, 5);
      assert.equal(res.body.data.workoutExercises[0].weight, 100);
    });

    it('DELETE /workouts/:id should remove workout and cascade delete exercises', async () => {
      const res = await request(app)
        .delete(`/workouts/${createdWorkoutId}`)
        .set('Authorization', `Bearer ${token}`);

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);

      // Verify deletion from database
      const found = await Workout.findByPk(createdWorkoutId);
      assert.equal(found, null);

      const orphanedExercises = await WorkoutExercise.findAll({
        where: { workoutId: createdWorkoutId },
      });
      assert.equal(orphanedExercises.length, 0);
    });
  });

  // =========================================================================
  // 3. Task 2.4: Achievement System (HRD-11)
  // =========================================================================
  describe('Achievement System (HRD-11)', () => {
    it('GET /achievements should reject unauthorized requests with 401', async () => {
      const res = await request(app).get('/achievements');

      assert.equal(res.status, 401);
      assert.equal(res.body.success, false);
    });

    it('GET /achievements should return user achievements and full catalog', async () => {
      const res = await request(app)
        .get('/achievements')
        .set('Authorization', `Bearer ${token}`);

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.ok(res.body.data.totalAvailable >= 15, 'Expected 15+ available achievements');
      assert.ok(Array.isArray(res.body.data.unlocked));
      assert.ok(Array.isArray(res.body.data.catalog));

      // At least 'First Step' or 'Warmup Warrior' should be unlocked from earlier workout test
      const firstStepInCatalog = res.body.data.catalog.find(
        (a) => a.name === 'First Step'
      );
      assert.ok(firstStepInCatalog, 'Expected First Step in catalog');
      assert.equal(firstStepInCatalog.isUnlocked, true);
    });
  });
});
