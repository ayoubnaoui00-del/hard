import { Model } from 'sequelize';

export default (sequelize, DataTypes) => {
  class Achievement extends Model {
    static associate(models) {
      Achievement.belongsTo(models.User, { foreignKey: 'userId', as: 'user', onDelete: 'CASCADE' });
    }
  }

  Achievement.init(
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        allowNull: false,
      },
      userId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: 'Users',
          key: 'id',
        },
      },
      type: {
        type: DataTypes.ENUM('WORKOUT_MILESTONE', 'STREAK_MILESTONE', 'VOLUME_MILESTONE', 'CHALLENGE_WIN', 'LEVEL_UP'),
        allowNull: false,
      },
      name: {
        type: DataTypes.STRING,
        allowNull: false,
      },
      description: {
        type: DataTypes.TEXT,
      },
      badgeIcon: {
        type: DataTypes.STRING,
      },
      unlockedAt: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW,
      },
    },
    {
      sequelize,
      modelName: 'Achievement',
      tableName: 'Achievements',
    }
  );

  return Achievement;
};