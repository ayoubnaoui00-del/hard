import { Model } from 'sequelize';

export default (sequelize, DataTypes) => {
  class WorkoutExercise extends Model {
    static associate(models) {
      WorkoutExercise.belongsTo(models.Workout, { foreignKey: 'workoutId', as: 'workout', onDelete: 'CASCADE' });
      WorkoutExercise.belongsTo(models.Exercise, { foreignKey: 'exerciseId', as: 'exercise', onDelete: 'CASCADE' });
    }
  }

  WorkoutExercise.init(
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        allowNull: false,
      },
      workoutId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: 'Workouts',
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
      sets: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 1,
        validate: {
          min: 1,
        },
      },
      reps: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 1,
        validate: {
          min: 1,
        },
      },
      weight: {
        type: DataTypes.FLOAT,
        allowNull: false,
        defaultValue: 0,
        validate: {
          min: 0,
        },
      },
      order: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
    },
    {
      sequelize,
      modelName: 'WorkoutExercise',
      tableName: 'WorkoutExercises',
    }
  );

  return WorkoutExercise;
};