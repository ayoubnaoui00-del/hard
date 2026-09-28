import { Model } from 'sequelize';

export default (sequelize, DataTypes) => {
  class Embedding extends Model {
    static associate(models) {
      Embedding.belongsTo(models.Exercise, { foreignKey: 'exerciseId', as: 'exercise', onDelete: 'CASCADE' });
    }
  }

  Embedding.init(
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        allowNull: false,
      },
      exerciseId: {
        type: DataTypes.UUID,
        allowNull: false,
        unique: true,
        references: {
          model: 'Exercises',
          key: 'id',
        },
      },
      vector: {
        type: DataTypes.JSON,
        allowNull: false,
        comment: '1536-dimensional embedding vector or JSON array',
      },
    },
    {
      sequelize,
      modelName: 'Embedding',
      tableName: 'Embeddings',
    }
  );

  return Embedding;
};