'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('WorkoutExercises', {
      id: {
        allowNull: false,
        primaryKey: true,
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
      },
      workoutId: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'Workouts',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      exerciseId: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'Exercises',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      sets: {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 1,
      },
      reps: {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 1,
      },
      weight: {
        type: Sequelize.FLOAT,
        allowNull: false,
        defaultValue: 0,
      },
      order: {
        type: Sequelize.INTEGER,
        defaultValue: 0,
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE,
        defaultValue: Sequelize.fn('NOW'),
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE,
        defaultValue: Sequelize.fn('NOW'),
      },
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('WorkoutExercises');
  },
};