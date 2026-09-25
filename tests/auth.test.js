import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import app, { server } from '../src/index.js';
import { sequelize, User } from '../src/models/index.js';

describe('Authentication API (HRD-5 & HRD-6)', () => {
  const testUser = {
    username: 'testathlete',
    email: 'athlete@example.com',
    password: 'password123',
  };

  let accessToken = '';
  let refreshToken = '';

  before(async () => {
    // Ensure clean state before running tests
    await User.destroy({
      where: {
        email: [testUser.email, 'duplicate@example.com'],
      },
    });
  });

  after(async () => {
    // Clean up test data and close connections
    try {
      await User.destroy({
        where: {
          email: [testUser.email, 'duplicate@example.com'],
        },
      });
    } catch (_) {}

    await sequelize.close();
    server.close();
  });

  describe('POST /auth/register', () => {
    it('should fail with 400 if required fields are missing', async () => {
      const res = await request(app)
        .post('/auth/register')
        .send({ email: testUser.email });

      assert.equal(res.status, 400);
      assert.equal(res.body.success, false);
      assert.ok(res.body.error);
    });

    it('should fail with 400 if username is shorter than 3 characters', async () => {
      const res = await request(app)
        .post('/auth/register')
        .send({ email: 'short@test.com', username: 'ab', password: 'password123' });

      assert.equal(res.status, 400);
      assert.equal(res.body.success, false);
      assert.match(res.body.error, /Username must be at least 3 characters/);
    });

    it('should fail with 400 if password is shorter than 6 characters', async () => {
      const res = await request(app)
        .post('/auth/register')
        .send({ email: 'shortpw@test.com', username: 'validuser', password: '123' });

      assert.equal(res.status, 400);
      assert.equal(res.body.success, false);
      assert.match(res.body.error, /Password must be at least 6 characters/);
    });

    it('should register a valid user successfully with 201', async () => {
      const res = await request(app)
        .post('/auth/register')
        .send(testUser);

      assert.equal(res.status, 201);
      assert.equal(res.body.success, true);
      assert.ok(res.body.data.user);
      assert.equal(res.body.data.user.email, testUser.email);
      assert.equal(res.body.data.user.username, testUser.username);
      assert.equal(res.body.data.user.password, undefined); // Password never exposed
      assert.equal(res.body.data.user.level, 1);
      assert.equal(res.body.data.user.currentXp, 0);
      assert.ok(res.body.data.accessToken);
      assert.ok(res.body.data.refreshToken);

      accessToken = res.body.data.accessToken;
      refreshToken = res.body.data.refreshToken;
    });

    it('should fail with 409 if registering duplicate email', async () => {
      const res = await request(app)
        .post('/auth/register')
        .send({
          email: testUser.email,
          username: 'differentname',
          password: 'password123',
        });

      assert.equal(res.status, 409);
      assert.equal(res.body.success, false);
      assert.match(res.body.error, /email already exists/i);
    });

    it('should fail with 409 if registering duplicate username', async () => {
      const res = await request(app)
        .post('/auth/register')
        .send({
          email: 'unique@example.com',
          username: testUser.username,
          password: 'password123',
        });

      assert.equal(res.status, 409);
      assert.equal(res.body.success, false);
      assert.match(res.body.error, /Username is already taken/i);
    });
  });

  describe('POST /auth/login', () => {
    it('should fail with 400 when missing email or password', async () => {
      const res = await request(app)
        .post('/auth/login')
        .send({ email: testUser.email });

      assert.equal(res.status, 400);
      assert.equal(res.body.success, false);
    });

    it('should fail with 401 when using wrong password', async () => {
      const res = await request(app)
        .post('/auth/login')
        .send({ email: testUser.email, password: 'wrongpassword' });

      assert.equal(res.status, 401);
      assert.equal(res.body.success, false);
      assert.match(res.body.error, /Invalid email or password/);
    });

    it('should fail with 401 when email does not exist', async () => {
      const res = await request(app)
        .post('/auth/login')
        .send({ email: 'nonexistent@example.com', password: 'password123' });

      assert.equal(res.status, 401);
      assert.equal(res.body.success, false);
      assert.match(res.body.error, /Invalid email or password/);
    });

    it('should successfully log in with valid credentials', async () => {
      const res = await request(app)
        .post('/auth/login')
        .send({ email: testUser.email, password: testUser.password });

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.ok(res.body.data.user);
      assert.equal(res.body.data.user.email, testUser.email);
      assert.equal(res.body.data.user.password, undefined);
      assert.ok(res.body.data.accessToken);
      assert.ok(res.body.data.refreshToken);

      accessToken = res.body.data.accessToken;
      refreshToken = res.body.data.refreshToken;
    });
  });

  describe('Protected Route: GET /auth/me', () => {
    it('should return 401 when Authorization header is missing', async () => {
      const res = await request(app).get('/auth/me');

      assert.equal(res.status, 401);
      assert.equal(res.body.success, false);
      assert.match(res.body.error, /No token provided/);
    });

    it('should return 401 when token is invalid', async () => {
      const res = await request(app)
        .get('/auth/me')
        .set('Authorization', 'Bearer invalid.jwt.token');

      assert.equal(res.status, 401);
      assert.equal(res.body.success, false);
      assert.equal(res.body.code, 'TOKEN_INVALID');
    });

    it('should return 200 and user profile when valid token provided', async () => {
      const res = await request(app)
        .get('/auth/me')
        .set('Authorization', `Bearer ${accessToken}`);

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.ok(res.body.data.user);
      assert.equal(res.body.data.user.email, testUser.email);
      assert.equal(res.body.data.user.username, testUser.username);
      assert.equal(res.body.data.user.password, undefined);
    });
  });

  describe('POST /auth/refresh', () => {
    it('should fail with 400 when refreshToken is missing', async () => {
      const res = await request(app)
        .post('/auth/refresh')
        .send({});

      assert.equal(res.status, 400);
      assert.equal(res.body.success, false);
    });

    it('should fail with 401 when refreshToken is invalid', async () => {
      const res = await request(app)
        .post('/auth/refresh')
        .send({ refreshToken: 'invalid.token' });

      assert.equal(res.status, 401);
      assert.equal(res.body.success, false);
      assert.equal(res.body.code, 'REFRESH_TOKEN_INVALID');
    });

    it('should generate a new accessToken with valid refreshToken', async () => {
      const res = await request(app)
        .post('/auth/refresh')
        .send({ refreshToken });

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.ok(res.body.data.accessToken);
      assert.ok(res.body.data.refreshToken);

      // Verify the new token works on protected route
      const newAccessToken = res.body.data.accessToken;
      const meRes = await request(app)
        .get('/auth/me')
        .set('Authorization', `Bearer ${newAccessToken}`);

      assert.equal(meRes.status, 200);
      assert.equal(meRes.body.data.user.email, testUser.email);
    });
  });

  describe('POST /auth/logout', () => {
    it('should successfully log out with 200', async () => {
      const res = await request(app).post('/auth/logout');

      assert.equal(res.status, 200);
      assert.equal(res.body.success, true);
      assert.match(res.body.message, /Logged out successfully/);
    });
  });
});
