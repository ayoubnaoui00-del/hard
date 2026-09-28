import { Model } from 'sequelize';

export default (sequelize, DataTypes) => {
  class Leaderboard extends Model {
    static associate(models) {
      Leaderboard.belongsTo(models.User, { foreignKey: 'userId', as: 'user', onDelete: 'CASCADE' });
    }
  }

  Leaderboard.init(
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
        unique: true,
        references: {
          model: 'Users',
          key: 'id',
        },
      },
      totalVolume: {
        type: DataTypes.FLOAT,
        defaultValue: 0,
        comment: 'Lifetime accumulated volume',
      },
      weeklyVolume: {
        type: DataTypes.FLOAT,
        defaultValue: 0,
        comment: 'Current week accumulated volume',
      },
      rank: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
      lastCalculatedAt: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW,
      },
    },
    {
      sequelize,
      modelName: 'Leaderboard',
      tableName: 'Leaderboards',
    }
  );

  return Leaderboard;
};







