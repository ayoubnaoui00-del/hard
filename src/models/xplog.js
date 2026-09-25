import { Model } from 'sequelize';

export default (sequelize, DataTypes) => {
  class XpLog extends Model {
    static associate(models) {
      XpLog.belongsTo(models.User, { foreignKey: 'userId', as: 'user', onDelete: 'CASCADE' });
    }
  }

  XpLog.init(
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
      amount: {
        type: DataTypes.INTEGER,
        allowNull: false,
      },
      type: {
        type: DataTypes.ENUM('WORKOUT', 'PR', 'STREAK', 'CHALLENGE', 'ACHIEVEMENT', 'BONUS'),
        allowNull: false,
      },
      description: {
        type: DataTypes.STRING,
      },
    },
    {
      sequelize,
      modelName: 'XpLog',
      tableName: 'XpLogs',
    }
  );

  return XpLog;
};