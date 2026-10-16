import { Model } from 'sequelize';

export default (sequelize, DataTypes) => {
  class Exercise extends Model {
    static associate(models) {
      Exercise.hasMany(models.WorkoutExercise, { foreignKey: 'exerciseId', as: 'workoutExercises', onDelete: 'CASCADE' });
      Exercise.belongsToMany(models.Workout, {
        through: models.WorkoutExercise,
        foreignKey: 'exerciseId',
        otherKey: 'workoutId',
        as: 'workouts',
      });
      Exercise.hasOne(models.Embedding, { foreignKey: 'exerciseId', as: 'embedding', onDelete: 'CASCADE' });
    }
  }

  Exercise.init(
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        allowNull: false,
      },
      name: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
        validate: {
          notEmpty: true,
        },
      },
      muscleGroup: {
        type: DataTypes.STRING,
        allowNull: false,
        validate: {
          notEmpty: true,
        },
      },
      instructions: {
        type: DataTypes.TEXT,
      },
      formTips: {
        type: DataTypes.TEXT,
      },
      alternatives: {
        type: DataTypes.JSON,
        defaultValue: [],
      },
      imageUrl: {
        type: DataTypes.VIRTUAL,
        get() {
          const alt = this.getDataValue('alternatives');
          if (alt && typeof alt === 'object' && alt.imageUrl) {
            const clean = alt.imageUrl.replace(/^\/+/, '');
            return clean.startsWith('images/') ? `/media/exercises/${clean}` : `/media/exercises/images/${clean}`;
          }
          return null;
        },
      },
      videoUrl: {
        type: DataTypes.VIRTUAL,
        get() {
          const alt = this.getDataValue('alternatives');
          if (alt && typeof alt === 'object' && (alt.gifUrl || alt.videoUrl)) {
            const vid = alt.gifUrl || alt.videoUrl;
            const clean = vid.replace(/^\/+/, '');
            return clean.startsWith('videos/') ? `/media/exercises/${clean}` : `/media/exercises/videos/${clean}`;
          }
          return null;
        },
      },
      gifUrl: {
        type: DataTypes.VIRTUAL,
        get() {
          return this.videoUrl;
        },
      },
    },
    {
      sequelize,
      modelName: 'Exercise',
      tableName: 'Exercises',
    }
  );

  return Exercise;
};