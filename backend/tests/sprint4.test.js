import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import app, { server } from '../src/index.js';
import { sequelize, User, Conversation, Message } from '../src/models/index.js';

describe('Sprint 4: AI Integration — Chat Sessions & Messaging (HRD-21)', () => {
  const user1 = {
    username: 'aicoachathlete',
    email: 'aicoach@example.com',
    password: 'password123',
  };

  const user2 = {
    username: 'otherathlete',
    email: 'other@example.com',
    password: 'password123',
  };

  let token1 = '';
  let token2 = '';
  let user1Id = '';
  let createdConvId = '';

  before(async () => {
    // Cleanup prior test users
    const existing = await User.findAll({
      where: { email: [user1.email, user2.email] },
    });
    for (const u of existing) {
      await Conversation.destroy({ where: { userId: u.id } });
      await u.destroy();
    }

    // Register user 1
    const regRes1 = await request(app).post('/auth/register').send(user1);
    assert.equal(regRes1.status, 201);
    token1 = regRes1.body.data.accessToken;
    user1Id = regRes1.body.data.user.id;

    // Register user 2
    const regRes2 = await request(app).post('/auth/register').send(user2);
    assert.equal(regRes2.status, 201);
    token2 = regRes2.body.data.accessToken;
  });

  after(async () => {
    try {
      const users = await User.findAll({
        where: { email: [user1.email, user2.email] },
      });
      for (const u of users) {
        await Conversation.destroy({ where: { userId: u.id } });
        await u.destroy();
      }
    } catch (_) {}

    await sequelize.close();
    server.close();
  });

  // =========================================================================
  // 1. POST /conversations - Start Conversation
  // =========================================================================
  describe('POST /conversations (HRD-21)', () => {
    it('should reject unauthenticated request with 401', async () => {
      const res = await request(app)
        .post('/conversations')
        .send({ topic: 'form feedback' });

      assert.equal(res.status, 401);
    });

    it('should create a new conversation with a topic/title', async () => {
      const res = await request(app)
        .post('/conversations')
        .set('Authorization', `Bearer ${token1}`)
        .send({ topic: 'Bench Press Form Check' });

      assert.equal(res.status, 201);
      assert.equal(res.body.success, true);
      assert.ok(res.body.data.id);
      assert.equal(res.body.data.userId, user1Id);
      assert.equal(res.body.data.title, 'Bench Press Form Check');

      createdConvId = res.body.data.id;
    });

    it('should default title to New Chat if not provided', async () => {
      const res = await request(app)
        .post('/conversations')
        .set('Authorization', `Bearer ${token1}`)
        .send({});

      assert.equal(res.status, 201);
      assert.equal(res.body.data.title, 'New Chat');
    });
  });

  // =========================================================================
  // 2. GET /conversations - List User Conversations
  // =========================================================================
  describe('GET /conversations (HRD-21)', () => {
    it('should return paginated list of user conversations', async () => {
      const res = await request(app)
        .get('/conversations?page=1&limit=10')
        .set('Authorization', `Bearer ${token1}`);

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.ok(res.body.data.total >= 2);
      assert.equal(res.body.data.page, 1);
      assert.equal(res.body.data.limit, 10);
      assert.ok(Array.isArray(res.body.data.conversations));
    });

    it('should isolate conversations between different users', async () => {
      const res = await request(app)
        .get('/conversations')
        .set('Authorization', `Bearer ${token2}`);

      assert.equal(res.status, 200);
      assert.equal(res.body.data.total, 0);
      assert.equal(res.body.data.conversations.length, 0);
    });
  });

  // =========================================================================
  // 3. POST /conversations/:id/messages - Append Messages
  // =========================================================================
  describe('POST /conversations/:id/messages (HRD-21)', () => {
    it('should reject invalid role with 400', async () => {
      const res = await request(app)
        .post(`/conversations/${createdConvId}/messages`)
        .set('Authorization', `Bearer ${token1}`)
        .send({ role: 'hacker', content: 'hello' });

      assert.equal(res.status, 400);
    });

    it('should reject empty message content with 400', async () => {
      const res = await request(app)
        .post(`/conversations/${createdConvId}/messages`)
        .set('Authorization', `Bearer ${token1}`)
        .send({ role: 'user', content: '   ' });

      assert.equal(res.status, 400);
    });

    it('should return 404 when adding message to non-existent conversation', async () => {
      const res = await request(app)
        .post('/conversations/00000000-0000-0000-0000-000000000000/messages')
        .set('Authorization', `Bearer ${token1}`)
        .send({ role: 'user', content: 'Hello coach' });

      assert.equal(res.status, 404);
    });

    it('should return 404 when user tries to post to another user conversation', async () => {
      const res = await request(app)
        .post(`/conversations/${createdConvId}/messages`)
        .set('Authorization', `Bearer ${token2}`)
        .send({ role: 'user', content: 'Intruding' });

      assert.equal(res.status, 404);
    });

    it('should add a user message successfully', async () => {
      const res = await request(app)
        .post(`/conversations/${createdConvId}/messages`)
        .set('Authorization', `Bearer ${token1}`)
        .send({ role: 'user', content: 'How should I arch my back on bench press?' });

      assert.equal(res.status, 201);
      assert.equal(res.body.success, true);
      assert.equal(res.body.data.conversationId, createdConvId);
      assert.equal(res.body.data.role, 'user');
      assert.equal(res.body.data.content, 'How should I arch my back on bench press?');
      assert.ok(res.body.data.id);
    });

    it('should add an assistant message successfully', async () => {
      const res = await request(app)
        .post(`/conversations/${createdConvId}/messages`)
        .set('Authorization', `Bearer ${token1}`)
        .send({
          role: 'assistant',
          content: 'Maintain a natural thoracic arch while keeping your glutes firmly on the bench.',
        });

      assert.equal(res.status, 201);
      assert.equal(res.body.success, true);
      assert.equal(res.body.data.role, 'assistant');
    });
  });

  // =========================================================================
  // 4. GET /conversations/:id - Retrieve Conversation with History
  // =========================================================================
  describe('GET /conversations/:id (HRD-21)', () => {
    it('should retrieve conversation with all messages in chronological order', async () => {
      const res = await request(app)
        .get(`/conversations/${createdConvId}`)
        .set('Authorization', `Bearer ${token1}`);

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.equal(res.body.data.conversation.id, createdConvId);
      assert.equal(res.body.data.messages.length, 2);
      assert.equal(res.body.data.messages[0].role, 'user');
      assert.equal(res.body.data.messages[1].role, 'assistant');
    });

    it('should return 404 if accessed by unauthorized user', async () => {
      const res = await request(app)
        .get(`/conversations/${createdConvId}`)
        .set('Authorization', `Bearer ${token2}`);

      assert.equal(res.status, 404);
    });
  });

  // =========================================================================
  // 5. DELETE /conversations/:id - Remove Conversation
  // =========================================================================
  describe('DELETE /conversations/:id (HRD-21)', () => {
    it('should delete conversation and cascade delete its messages', async () => {
      const delRes = await request(app)
        .delete(`/conversations/${createdConvId}`)
        .set('Authorization', `Bearer ${token1}`);

      assert.equal(delRes.status, 200);
      assert.equal(delRes.body.success, true);

      // Verify conversation no longer exists
      const getRes = await request(app)
        .get(`/conversations/${createdConvId}`)
        .set('Authorization', `Bearer ${token1}`);
      assert.equal(getRes.status, 404);

      // Verify messages are deleted
      const messagesCount = await Message.count({ where: { conversationId: createdConvId } });
      assert.equal(messagesCount, 0);
    });
  });
});
