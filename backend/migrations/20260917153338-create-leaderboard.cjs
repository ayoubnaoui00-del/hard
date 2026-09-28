'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('Leaderboards', {
      id: {
        allowNull: false,
        primaryKey: true,
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
      },
      userId: {
        type: Sequelize.UUID,
        allowNull: false,
        unique: true,
        references: {
          model: 'Users',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      totalVolume: {
        type: Sequelize.FLOAT,
        defaultValue: 0,
      },
      weeklyVolume: {
        type: Sequelize.FLOAT,
        defaultValue: 0,
      },
      rank: {
        type: Sequelize.INTEGER,
        defaultValue: 0,
      },
      lastCalculatedAt: {
        type: Sequelize.DATE,
        defaultValue: Sequelize.fn('NOW'),
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

    await queryInterface.addIndex('Leaderboards', ['rank'], {
      name: 'leaderboards_rank_idx',
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('Leaderboards');
  },
};