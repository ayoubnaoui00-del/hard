import { Sequelize, DataTypes } from 'sequelize';
import { createRequire } from 'module';
import path from 'path';
import { fileURLToPath } from 'url';
import 'dotenv/config';

import initUserModel from './user.js';
import initWorkoutModel from './workout.js';
import initExerciseModel from './exercise.js';
import initWorkoutExerciseModel from './workoutexercise.js';
import initEmbeddingModel from './embedding.js';
import initXpLogModel from './xplog.js';
import initAchievementModel from './achievement.js';
import initLeaderboardModel from './leaderboard.js';
import initFriendModel from './friend.js';
import initConversationModel from './conversation.js';
import initMessageModel from './message.js';
import initChallengeModel from './challenge.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const require = createRequire(import.meta.url);

const env = process.env.NODE_ENV || 'development';
const config = require('../../config/config.json')[env];

let sequelize;
if (config.use_env_variable && process.env[config.use_env_variable]) {
  sequelize = new Sequelize(process.env[config.use_env_variable], config);
} else {
  sequelize = new Sequelize(
    process.env.DB_NAME || config.database,
    process.env.DB_USER || config.username,
    process.env.DB_PASSWORD || config.password,
    {
      host: process.env.DB_HOST || config.host,
      port: process.env.DB_PORT || config.port || 5432,
      dialect: config.dialect || 'postgres',
      logging: process.env.NODE_ENV === 'development' ? console.log : false,
      dialectOptions: config.dialectOptions || {},
    }
  );
}

// Initialize all 12 models
const User = initUserModel(sequelize, DataTypes);
const Workout = initWorkoutModel(sequelize, DataTypes);
const Exercise = initExerciseModel(sequelize, DataTypes);
const WorkoutExercise = initWorkoutExerciseModel(sequelize, DataTypes);
const Embedding = initEmbeddingModel(sequelize, DataTypes);
const XpLog = initXpLogModel(sequelize, DataTypes);
const Achievement = initAchievementModel(sequelize, DataTypes);
const Leaderboard = initLeaderboardModel(sequelize, DataTypes);
const Friend = initFriendModel(sequelize, DataTypes);
const Conversation = initConversationModel(sequelize, DataTypes);
const Message = initMessageModel(sequelize, DataTypes);
const Challenge = initChallengeModel(sequelize, DataTypes);

const db = {
  User,
  Workout,
  Exercise,
  WorkoutExercise,
  Embedding,
  XpLog,
  Achievement,
  Leaderboard,
  Friend,
  Conversation,
  Message,
  Challenge,
  sequelize,
  Sequelize,
};

// Set up all model associations
Object.keys(db).forEach((modelName) => {
  if (db[modelName]?.associate) {
    db[modelName].associate(db);
  }
});

export const initModels = () => db;

export {
  sequelize,
  Sequelize,
  User,
  Workout,
  Exercise,
  WorkoutExercise,
  Embedding,
  XpLog,
  Achievement,
  Leaderboard,
  Friend,
  Conversation,
  Message,
  Challenge,
};

export default db;
