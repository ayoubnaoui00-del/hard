import dotenv from 'dotenv';
import { Pinecone } from '@pinecone-database/pinecone';
import { sequelize, Exercise } from '../src/models/index.js';

dotenv.config();

const PINECONE_API_KEY = process.env.PINECONE_API_KEY;
const PINECONE_INDEX = process.env.PINECONE_INDEX || 'hard';
const PINECONE_EMBED_MODEL = process.env.PINECONE_EMBED_MODEL || 'llama-text-embed-v2';
const BATCH_SIZE = 50;

/**
 * Format exercise into Pinecone integrated inference record
 */
function formatRecord(ex) {
  const summaryText = [
    `Exercise: ${ex.name}`,
    `Target Muscle: ${ex.muscleGroup}`,
    ex.instructions ? `Instructions: ${ex.instructions}` : '',
    ex.formTips ? `Form Tips: ${ex.formTips}` : '',
  ]
    .filter(Boolean)
    .join(' - ');

  return {
    _id: `ex-${ex.id}`,
    text: summaryText,
    exerciseId: String(ex.id),
    name: ex.name,
    muscleGroup: ex.muscleGroup,
    instructions: (ex.instructions || '').substring(0, 1500),
    formTips: (ex.formTips || '').substring(0, 1500),
    alternatives: Array.isArray(ex.alternatives) ? ex.alternatives : [],
  };
}

export const seedEmbeddings = async () => {
  console.log(`[Seed Pinecone] Starting exercise embeddings migration to Pinecone index "${PINECONE_INDEX}" using model "${PINECONE_EMBED_MODEL}"`);

  if (!PINECONE_API_KEY) {
    throw new Error('PINECONE_API_KEY is not configured in .env');
  }

  const pc = new Pinecone({ apiKey: PINECONE_API_KEY });
  const index = pc.index(PINECONE_INDEX);

  try {
    await sequelize.authenticate();
    console.log('[Seed Pinecone] PostgreSQL Database connected.');

    // 1. Fetch all exercises from DB
    const allExercises = await Exercise.findAll({
      attributes: ['id', 'name', 'muscleGroup', 'instructions', 'formTips', 'alternatives'],
      order: [['id', 'ASC']],
    });

    console.log(`[Seed Pinecone] Found ${allExercises.length} total exercises in database.`);

    if (allExercises.length === 0) {
      console.log('[Seed Pinecone] No exercises found in database. Run seed:exercises first.');
      return;
    }

    let completed = 0;
    const total = allExercises.length;
    let upsertedCount = 0;

    // 2. Upsert in batches to Pinecone
    for (let i = 0; i < allExercises.length; i += BATCH_SIZE) {
      const batch = allExercises.slice(i, i + BATCH_SIZE);
      const records = batch.map(formatRecord);

      try {
        await index.upsertRecords({ records });
        upsertedCount += records.length;
      } catch (batchErr) {
        console.error(`\n[Seed Pinecone] Error upserting batch at index ${i}:`, batchErr.message);
        // Retry individually for resilient seeding
        for (const rec of records) {
          try {
            await index.upsertRecords({ records: [rec] });
            upsertedCount++;
          } catch (singleErr) {
            console.error(`[Seed Pinecone] Failed record ${rec._id}:`, singleErr.message);
          }
        }
      }

      completed += batch.length;
      const percent = ((completed / total) * 100).toFixed(1);
      process.stdout.write(`\r[Seed Pinecone] Progress: ${completed}/${total} (${percent}%) exercises uploaded to Pinecone...`);
    }

    console.log(`\n[Seed Pinecone] Successfully upserted ${upsertedCount}/${total} exercises into Pinecone index "${PINECONE_INDEX}"!`);

    // Verify index stats
    try {
      const stats = await index.describeIndexStats();
      console.log('[Seed Pinecone] Pinecone Index Stats:', JSON.stringify(stats, null, 2));
    } catch (_) {
      // describeIndexStats optional on some serverless plans
    }
  } catch (error) {
    console.error('\n[Seed Pinecone] Fatal error during Pinecone seeding:', error);
    throw error;
  }
};

// Execute if run directly
if (process.argv[1] && process.argv[1].endsWith('seed-embeddings.js')) {
  seedEmbeddings()
    .then(() => {
      console.log('[Seed Pinecone] Finished successfully.');
      process.exit(0);
    })
    .catch((err) => {
      console.error('[Seed Pinecone] Failed:', err);
      process.exit(1);
    });
}
