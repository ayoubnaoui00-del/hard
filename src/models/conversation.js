import { Model } from 'sequelize';

export default (sequelize, DataTypes) => {
  class Conversation extends Model {
    static associate(models) {
      Conversation.belongsTo(models.User, { foreignKey: 'userId', as: 'user', onDelete: 'CASCADE' });
      Conversation.hasMany(models.Message, { foreignKey: 'conversationId', as: 'messages', onDelete: 'CASCADE' });
    }
  }

  Conversation.init(
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
      title: {
        type: DataTypes.STRING,
        defaultValue: 'New Chat',
      },
    },
    {
      sequelize,
      modelName: 'Conversation',
      tableName: 'Conversations',
    }
  );

  return Conversation;
};