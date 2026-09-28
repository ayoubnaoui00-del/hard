'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    // Achievements are unlocked dynamically per user.
    // This seeder logs the availability of the 17 predefined system achievements.
    console.log('[Seed Achievements] 17 dynamic achievements initialized in system constants.');
  },

  async down(queryInterface, Sequelize) {
    // No-op
  },
};
