import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { sequelize, Exercise } from '../src/models/index.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const DATASET_PATH = path.resolve(__dirname, '../exercises-dataset-main/data/exercises.json');

const normalizeMuscleGroup = (bodyPart, target) => {
  if (!bodyPart) return 'Full Body';
  const bp = bodyPart.toLowerCase();
  switch (bp) {
    case 'chest':
      return 'Chest';
    case 'back':
      return 'Back';
    case 'shoulders':
      return 'Shoulders';
    case 'upper arms':
      return target && target.toLowerCase().includes('triceps') ? 'Triceps' : 'Biceps';
    case 'lower arms':
      return 'Forearms';
    case 'upper legs':
      return target && target.toLowerCase().includes('hamstrings') ? 'Hamstrings' : 'Quadriceps';
    case 'lower legs':
      return 'Calves';
    case 'waist':
      return 'Core';
    case 'cardio':
      return 'Cardio';
    case 'neck':
      return 'Neck';
    default:
      return bodyPart.charAt(0).toUpperCase() + bodyPart.slice(1);
  }
};

export const seedExercises = async () => {
  console.log('[Seed Exercises] Starting exercise database seeding...');

  if (!fs.existsSync(DATASET_PATH)) {
    throw new Error(`Exercise dataset file not found at: ${DATASET_PATH}`);
  }

  const rawData = fs.readFileSync(DATASET_PATH, 'utf8');
  const exercises = JSON.parse(rawData);
  console.log(`[Seed Exercises] Loaded ${exercises.length} raw exercises from dataset.`);

  const seenNames = new Set();
  const records = [];

  for (const item of exercises) {
    let exerciseName = (item.name || '').trim();
    if (!exerciseName) continue;

    const lowerName = exerciseName.toLowerCase();
    if (seenNames.has(lowerName)) {
      if (item.equipment) {
        exerciseName = `${exerciseName} (${item.equipment})`;
      } else {
        exerciseName = `${exerciseName} - ${item.id}`;
      }
    }
    seenNames.add(exerciseName.toLowerCase());

    const instructionsText =
      (item.instructions && item.instructions.en) ||
      (Array.isArray(item.instruction_steps?.en) ? item.instruction_steps.en.join(' ') : '') ||
      'No instructions provided.';

    const secondary = Array.isArray(item.secondary_muscles) ? item.secondary_muscles.join(', ') : '';
    const formTipsText = `Target: ${item.target || 'General'}. Equipment: ${item.equipment || 'None'}.${
      secondary ? ` Secondary muscles: ${secondary}.` : ''
    }`;

    records.push({
      name: exerciseName,
      muscleGroup: normalizeMuscleGroup(item.body_part, item.target),
      instructions: instructionsText,
      formTips: formTipsText,
      alternatives: {
        originalId: item.id,
        category: item.category,
        bodyPart: item.body_part,
        target: item.target,
        equipment: item.equipment,
        secondaryMuscles: item.secondary_muscles || [],
        imageUrl: item.image || null,
        gifUrl: item.gif_url || null,
      },
    });
  }

  console.log(`[Seed Exercises] Prepared ${records.length} unique exercise records.`);

  // Insert in chunks of 200
  const CHUNK_SIZE = 200;
  let insertedCount = 0;

  for (let i = 0; i < records.length; i += CHUNK_SIZE) {
    const chunk = records.slice(i, i + CHUNK_SIZE);
    await Exercise.bulkCreate(chunk, {
      ignoreDuplicates: true,
      validate: true,
    });
    insertedCount += chunk.length;
    console.log(`[Seed Exercises] Processed ${insertedCount}/${records.length} exercises...`);
  }

  const totalInDb = await Exercise.count();
  console.log(`[Seed Exercises] Successfully finished seeding! Total exercises in database: ${totalInDb}`);
  return totalInDb;
};

// If run directly from CLI
if (process.argv[1] && process.argv[1].endsWith('seed-exercises.js')) {
  (async () => {
    try {
      await sequelize.authenticate();
      console.log('[Seed Exercises] Database connection established.');
      await seedExercises();
      process.exit(0);
    } catch (err) {
      console.error('[Seed Exercises] Failed:', err);
      process.exit(1);
    }
  })();
}
