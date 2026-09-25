import { Model } from 'sequelize';

export default (sequelize, DataTypes) => {
  class User extends Model {
    static associate(models) {
      User.hasMany(models.Workout, { foreignKey: 'userId', as: 'workouts', onDelete: 'CASCADE' });
      User.hasMany(models.XpLog, { foreignKey: 'userId', as: 'xpLogs', onDelete: 'CASCADE' });
      User.hasMany(models.Achievement, { foreignKey: 'userId', as: 'achievements', onDelete: 'CASCADE' });
      User.hasOne(models.Leaderboard, { foreignKey: 'userId', as: 'leaderboard', onDelete: 'CASCADE' });
      User.hasMany(models.Friend, { foreignKey: 'userId', as: 'sentFriendRequests', onDelete: 'CASCADE' });
      User.hasMany(models.Friend, { foreignKey: 'friendId', as: 'receivedFriendRequests', onDelete: 'CASCADE' });
      User.hasMany(models.Conversation, { foreignKey: 'userId', as: 'conversations', onDelete: 'CASCADE' });
      User.hasMany(models.Challenge, { foreignKey: 'challengerId', as: 'createdChallenges', onDelete: 'CASCADE' });
      User.hasMany(models.Challenge, { foreignKey: 'challengedId', as: 'receivedChallenges', onDelete: 'CASCADE' });
    }
  }

  User.init(
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        allowNull: false,
      },
      username: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
        validate: {
          notEmpty: true,
          len: [3, 50],
        },
      },
      email: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
        validate: {
          isEmail: true,
          notEmpty: true,
        },
      },
      password: {
        type: DataTypes.STRING,
        allowNull: false,
        validate: {
          notEmpty: true,
        },
      },
      level: {
        type: DataTypes.INTEGER,
        defaultValue: 1,
        allowNull: false,
        validate: {
          min: 1,
        },
      },
      currentXp: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
        allowNull: false,
        validate: {
          min: 0,
        },
      },
      totalXp: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
        allowNull: false,
        validate: {
          min: 0,
        },
      },
      streak: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
        allowNull: false,
        validate: {
          min: 0,
        },
      },
      lastActiveAt: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW,
      },
    },
    {
      sequelize,
      modelName: 'User',
      tableName: 'Users',
    }
  );

  return User;
};