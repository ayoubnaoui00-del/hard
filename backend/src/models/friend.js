import { Model } from 'sequelize';

export default (sequelize, DataTypes) => {
  class Friend extends Model {
    static associate(models) {
      Friend.belongsTo(models.User, { foreignKey: 'userId', as: 'user', onDelete: 'CASCADE' });
      Friend.belongsTo(models.User, { foreignKey: 'friendId', as: 'friend', onDelete: 'CASCADE' });
    }
  }

  Friend.init(
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
      friendId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: 'Users',
          key: 'id',
        },
      },
      status: {
        type: DataTypes.ENUM('PENDING', 'ACCEPTED', 'BLOCKED'),
        defaultValue: 'PENDING',
        allowNull: false,
      },
    },
    {
      sequelize,
      modelName: 'Friend',
      tableName: 'Friends',
      indexes: [
        {
          unique: true,
          fields: ['userId', 'friendId'],
        },
      ],
    }
  );

  return Friend;
};