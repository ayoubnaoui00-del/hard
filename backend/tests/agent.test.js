import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import app, { server } from '../src/index.js';
import { sequelize, User, Conversation, Message, Workout } from '../src/models/index.js';

describe('Sprint 4: Task 4.4 — AI Agent Endpoint with SSE Streaming (HRD-22)', () => {
  const coachUser = {
    username: 'coach_tester',
    email: 'coach_tester@example.com',
    password: 'Password123!',
  };

  const otherUser = {
    username: 'coach_other',
    email: 'coach_other@example.com',
    password: 'Password123!',
  };

  let token1 = '';
  let token2 = '';
  let user1Id = '';
  let conversationId = '';

  before(async () => {
    // Cleanup prior test users
    const existing = await User.findAll({
      where: { email: [coachUser.email, otherUser.email] },
    });
    for (const u of existing) {
      await Conversation.destroy({ where: { userId: u.id } });
      await Workout.destroy({ where: { userId: u.id } });
      await u.destroy();
    }

    // Register primary user
    const regRes1 = await request(app).post('/auth/register').send(coachUser);
    assert.equal(regRes1.status, 201);
    token1 = regRes1.body.data.accessToken;
    user1Id = regRes1.body.data.user.id;

    // Register second user
    const regRes2 = await request(app).post('/auth/register').send(otherUser);
    assert.equal(regRes2.status, 201);
    token2 = regRes2.body.data.accessToken;

    // Create a workout for context testing
    await Workout.create({
      userId: user1Id,
      name: 'Legs & Core Blast',
      date: new Date(),
      totalVolume: 3500,
    });

    // Create a conversation session
    const convRes = await request(app)
      .post('/conversations')
      .set('Authorization', `Bearer ${token1}`)
      .send({ topic: 'Leg Day Coaching' });

    assert.equal(convRes.status, 201);
    conversationId = convRes.body.data.id;
  });

  after(async () => {
    try {
      const users = await User.findAll({
        where: { email: [coachUser.email, otherUser.email] },
      });
      for (const u of users) {
        await Conversation.destroy({ where: { userId: u.id } });
        await Workout.destroy({ where: { userId: u.id } });
        await u.destroy();
      }
    } catch (_) {}

    try {
      await sequelize.close();
    } catch (_) {}

    if (server && server.listening) {
      await new Promise((resolve) => server.close(resolve));
    }
  });

  // =========================================================================
  // 1. Validation & Authorization
  // =========================================================================
  describe('POST /agent/chat - Validation & Access Control', () => {
    it('should reject unauthenticated request with 401', async () => {
      const res = await request(app)
        .post('/agent/chat')
        .send({ conversationId, message: 'Hello' });

      assert.equal(res.status, 401);
    });

    it('should reject missing or empty conversationId with 400', async () => {
      const res = await request(app)
        .post('/agent/chat')
        .set('Authorization', `Bearer ${token1}`)
        .send({ message: 'Hello coach' });

      assert.equal(res.status, 400);
      assert.equal(res.body.success, false);
    });

    it('should reject empty message text with 400', async () => {
      const res = await request(app)
        .post('/agent/chat')
        .set('Authorization', `Bearer ${token1}`)
        .send({ conversationId, message: '   ' });

      assert.equal(res.status, 400);
      assert.equal(res.body.success, false);
    });

    it('should reject non-existent conversation with 404', async () => {
      const res = await request(app)
        .post('/agent/chat')
        .set('Authorization', `Bearer ${token1}`)
        .send({
          conversationId: '00000000-0000-0000-0000-000000000000',
          message: 'Hello coach',
        });

      assert.equal(res.status, 404);
      assert.equal(res.body.success, false);
    });

    it('should reject access to another user\'s conversation with 404', async () => {
      const res = await request(app)
        .post('/agent/chat')
        .set('Authorization', `Bearer ${token2}`)
        .send({
          conversationId,
          message: 'Trying to intrude',
        });

      assert.equal(res.status, 404);
      assert.equal(res.body.success, false);
    });
  });

  // =========================================================================
  // 2. Real-Time Streaming & Persistence
  // =========================================================================
  describe('POST /agent/chat - Streaming Execution & DB Persistence', () => {
    it('should stream Server-Sent Events response and persist messages', async () => {
      const userPrompt = 'Give me 1 quick tip for squats.';

      const res = await request(app)
        .post('/agent/chat')
        .set('Authorization', `Bearer ${token1}`)
        .send({ conversationId, message: userPrompt })
        .buffer(true)
        .parse((streamRes, callback) => {
          let text = '';
          streamRes.on('data', (chunk) => {
            text += chunk.toString();
          });
          streamRes.on('end', () => {
            callback(null, text);
          });
          streamRes.on('error', (err) => {
            callback(err);
          });
        });

      // 1. Verify SSE Content-Type
      assert.ok(
        res.headers['content-type']?.includes('text/event-stream'),
        `Expected text/event-stream, got: ${res.headers['content-type']}`
      );

      // 2. Verify SSE Chunks and [DONE] termination
      const rawStream = res.body;
      assert.ok(rawStream.includes('data:'), 'Expected SSE stream data chunks');
      assert.ok(rawStream.includes('[DONE]'), 'Expected stream completion signal [DONE]');

      // 3. Verify user message persisted to database
      const userMsgInDb = await Message.findOne({
        where: { conversationId, role: 'user', content: userPrompt },
      });
      assert.ok(userMsgInDb, 'User prompt should be saved to database');

      // 4. Verify assistant response persisted to database
      const assistantMsgInDb = await Message.findOne({
        where: { conversationId, role: 'assistant' },
        order: [['createdAt', 'DESC']],
      });
      assert.ok(assistantMsgInDb, 'Assistant response should be saved to database');
      assert.ok(assistantMsgInDb.content.length > 0, 'Assistant message content should not be empty');
    });
  });
});
