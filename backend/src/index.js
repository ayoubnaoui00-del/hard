import 'dotenv/config';
import express from 'express';
import { sequelize, initModels } from './models/index.js';
import authRouter from './routes/auth.js';
import exerciseRouter from './routes/exercises.js';
import workoutRouter from './routes/workouts.js';
import achievementRouter from './routes/achievements.js';
import xpRouter from './routes/xp.js';
import conversationRouter from './routes/conversations.js';
import agentRouter from './routes/agent.js';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Register API Routes (supporting both / and /api prefixes)
const mountRoutes = (prefix = '') => {
  app.use(`${prefix}/auth`, authRouter);
  app.use(`${prefix}/exercises`, exerciseRouter);
  app.use(`${prefix}/workouts`, workoutRouter);
  app.use(`${prefix}/achievements`, achievementRouter);
  app.use(`${prefix}/users`, xpRouter);
  app.use(`${prefix}/conversations`, conversationRouter);
  app.use(`${prefix}/agent`, agentRouter);
};

mountRoutes();
mountRoutes('/api');

// Root & Health Check Endpoints
app.get(['/', '/api'], (_req, res) => {
  res.json({
    app: 'Hard API',
    status: 'ok', 
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
  });
});

app.get(['/health', '/api/health'], async (_req, res) => {
  try {
    await sequelize.authenticate();
    res.json({
      status: 'healthy',
      database: 'connected',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      database: 'disconnected',
      error: error.message,
      timestamp: new Date().toISOString(),
    });
  }
});

// Start Server & Connect to DB
const startServer = async () => {
  try {
    await sequelize.authenticate();
    console.log('[Hard Backend] Connected to PostgreSQL database successfully.');

   initModels();

    const server = app.listen(PORT, () => {
      console.log(`[Hard Backend] Express server running on port ${PORT}`);
    });

    return server;
  } catch (error) {
    console.error('[Hard Backend] Unable to connect to the database:', error);
    process.exit(1);
  }
};

const server = await startServer();

export default app;
export { server };
