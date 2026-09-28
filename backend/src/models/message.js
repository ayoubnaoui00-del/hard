import { Model } from 'sequelize';

export default (sequelize, DataTypes) => {
  class Message extends Model {
    static associate(models) {
      Message.belongsTo(models.Conversation, { foreignKey: 'conversationId', as: 'conversation', onDelete: 'CASCADE' });
    }
  }

  Message.init(
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        allowNull: false,
      },
      conversationId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: 'Conversations',
          key: 'id',
        },
      },
      role: {
        type: DataTypes.ENUM('user', 'assistant', 'system'),
        allowNull: false,
      },
      content: {
        type: DataTypes.TEXT,
        allowNull: false,
      },
    },
    {
      sequelize,
      modelName: 'Message',
      tableName: 'Messages',
    }
  );

  return Message;
};