'use strict';
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('sequelize').DataTypes.UUIDV4 ? { v4: () => require('crypto').randomUUID() } : {};

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    const datasetPath = path.resolve(__dirname, '../exercises-dataset-main/data/exercises.json');
    if (!fs.existsSync(datasetPath)) {
      console.warn('Dataset file not found at:', datasetPath);
      return;
    }

    const rawData = fs.readFileSync(datasetPath, 'utf8');
    const exercises = JSON.parse(rawData);

    const normalizeMuscleGroup = (bodyPart, target) => {
      if (!bodyPart) return 'Full Body';
      const bp = bodyPart.toLowerCase();
      switch (bp) {
        case 'chest': return 'Chest';
        case 'back': return 'Back';
        case 'shoulders': return 'Shoulders';
        case 'upper arms': return target && target.toLowerCase().includes('triceps') ? 'Triceps' : 'Biceps';
        case 'lower arms': return 'Forearms';
        case 'upper legs': return target && target.toLowerCase().includes('hamstrings') ? 'Hamstrings' : 'Quadriceps';
        case 'lower legs': return 'Calves';
        case 'waist': return 'Core';
        case 'cardio': return 'Cardio';
        case 'neck': return 'Neck';
        default: return bodyPart.charAt(0).toUpperCase() + bodyPart.slice(1);
      }
    };

    const seenNames = new Set();
    const records = [];
    const now = new Date();

    for (const item of exercises) {
      let exerciseName = (item.name || '').trim();
      if (!exerciseName) continue;

      const lower = exerciseName.toLowerCase();
      if (seenNames.has(lower)) {
        exerciseName = item.equipment ? `${exerciseName} (${item.equipment})` : `${exerciseName} - ${item.id}`;
      }
      seenNames.add(exerciseName.toLowerCase());

      const instructionsText =
        (item.instructions && item.instructions.en) ||
        (Array.isArray(item.instruction_steps && item.instruction_steps.en)
          ? item.instruction_steps.en.join(' ')
          : '') ||
        'No instructions provided.';

      const secondary = Array.isArray(item.secondary_muscles) ? item.secondary_muscles.join(', ') : '';
      const formTipsText = `Target: ${item.target || 'General'}. Equipment: ${item.equipment || 'None'}.${
        secondary ? ` Secondary muscles: ${secondary}.` : ''
      }`;

      records.push({
        id: require('crypto').randomUUID(),
        name: exerciseName,
        muscleGroup: normalizeMuscleGroup(item.body_part, item.target),
        instructions: instructionsText,
        formTips: formTipsText,
        alternatives: JSON.stringify({
          originalId: item.id,
          category: item.category,
          bodyPart: item.body_part,
          target: item.target,
          equipment: item.equipment,
          secondaryMuscles: item.secondary_muscles || [],
          imageUrl: item.image || null,
          gifUrl: item.gif_url || null,
        }),
        createdAt: now,
        updatedAt: now,
      });
    }

    // Insert in chunks of 200 with ignoreDuplicates
    const CHUNK_SIZE = 200;
    for (let i = 0; i < records.length; i += CHUNK_SIZE) {
      const chunk = records.slice(i, i + CHUNK_SIZE);
      await queryInterface.bulkInsert('Exercises', chunk, {
        ignoreDuplicates: true,
      });
    }
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.bulkDelete('Exercises', null, {});
  },
};
