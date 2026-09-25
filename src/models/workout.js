import { Model } from 'sequelize';

export default (sequelize, DataTypes) => {
  class Workout extends Model {
    static associate(models) {
      Workout.belongsTo(models.User, { foreignKey: 'userId', as: 'user', onDelete: 'CASCADE' });
      Workout.hasMany(models.WorkoutExercise, { foreignKey: 'workoutId', as: 'workoutExercises', onDelete: 'CASCADE' });
      Workout.belongsToMany(models.Exercise, {
        through: models.WorkoutExercise,
        foreignKey: 'workoutId',
        otherKey: 'exerciseId',
        as: 'exercises',
      });
    }
  }

  Workout.init(
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
      name: {
        type: DataTypes.STRING,
        defaultValue: 'Workout',
      },
      date: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW,
        allowNull: false,
      },
      duration: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
        comment: 'Duration in minutes',
      },
      totalVolume: {
        type: DataTypes.FLOAT,
        defaultValue: 0,
        comment: 'Total calculated volume in kg',
      },
      notes: {
        type: DataTypes.TEXT,
      },
    },
    {
      sequelize,
      modelName: 'Workout',
      tableName: 'Workouts',
    }
  );

  return Workout;
};