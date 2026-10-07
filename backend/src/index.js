import 'dotenv/config';
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { sequelize, initModels } from './models/index.js';
import authRouter from './routes/auth.js';
import exerciseRouter from './routes/exercises.js';
import workoutRouter from './routes/workouts.js';
import achievementRouter from './routes/achievements.js';
import xpRouter from './routes/xp.js';
import conversationRouter from './routes/conversations.js';
import agentRouter from './routes/agent.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const datasetDir = path.resolve(__dirname, '../exercises-dataset-main');

const app = express();
const PORT = process.env.PORT || 3000;

// CORS Middleware
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Static Media Serving for Exercise Images and Demonstration Videos
const staticOptions = {
  maxAge: '1d',
  setHeaders: (res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
  },
};

app.use('/media/exercises', express.static(datasetDir, staticOptions));
app.use('/media/images', express.static(path.join(datasetDir, 'images'), staticOptions));
app.use('/media/videos', express.static(path.join(datasetDir, 'videos'), staticOptions));
app.use('/images', express.static(path.join(datasetDir, 'images'), staticOptions));
app.use('/videos', express.static(path.join(datasetDir, 'videos'), staticOptions));

app.use('/api/media/exercises', express.static(datasetDir, staticOptions));
app.use('/api/media/images', express.static(path.join(datasetDir, 'images'), staticOptions));
app.use('/api/media/videos', express.static(path.join(datasetDir, 'videos'), staticOptions));

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

const isTestEnv = process.env.NODE_ENV === 'test' || process.argv.some((arg) => arg.includes('test'));

// Start Server & Connect to DB
const startServer = async () => {
  try {
    await sequelize.authenticate();
    console.log('[Hard Backend] Connected to PostgreSQL database successfully.');

    initModels();

    if (isTestEnv) {
      return {
        close: (cb) => {
          if (typeof cb === 'function') cb();
        },
        listening: false,
      };
    }

    const server = app.listen(PORT, () => {
      console.log(`[Hard Backend] Express server running on port ${PORT}`);
    });

    server.on('error', (err) => {
      if (err.code === 'EADDRINUSE') {
        console.warn(`[Hard Backend] Port ${PORT} already in use. Skipping server listen.`);
      } else {
        console.error('[Hard Backend] Server error:', err);
      }
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
