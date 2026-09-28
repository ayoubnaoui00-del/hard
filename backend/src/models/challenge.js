import { Model } from 'sequelize';

export default (sequelize, DataTypes) => {
  class Challenge extends Model {
    static associate(models) {
      Challenge.belongsTo(models.User, { foreignKey: 'challengerId', as: 'challenger', onDelete: 'CASCADE' });
      Challenge.belongsTo(models.User, { foreignKey: 'challengedId', as: 'challenged', onDelete: 'CASCADE' });
      Challenge.belongsTo(models.User, { foreignKey: 'winnerId', as: 'winner', onDelete: 'SET NULL' });
      Challenge.belongsTo(models.Exercise, { foreignKey: 'exerciseId', as: 'exercise', onDelete: 'CASCADE' });
    }
  }

  Challenge.init(
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        allowNull: false,
      },
      challengerId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: 'Users',
          key: 'id',
        },
      },
      challengedId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: 'Users',
          key: 'id',
        },
      },
      exerciseId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: 'Exercises',
          key: 'id',
        },
      },
      challengerScore: {
        type: DataTypes.FLOAT,
        defaultValue: 0,
        comment: 'Score calculated from volume (weight * sets * reps)',
      },
      challengedScore: {
        type: DataTypes.FLOAT,
        defaultValue: 0,
        comment: 'Score calculated from volume (weight * sets * reps)',
      },
      winnerId: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
          model: 'Users',
          key: 'id',
        },
      },
      status: {
        type: DataTypes.ENUM('PENDING', 'IN_PROGRESS', 'COMPLETED', 'DECLINED'),
        defaultValue: 'PENDING',
        allowNull: false,
      },
      rewardXp: {
        type: DataTypes.INTEGER,
        defaultValue: 150,
      },
    },
    {
      sequelize,
      modelName: 'Challenge',
      tableName: 'Challenges',
    }
  );

  return Challenge;
};