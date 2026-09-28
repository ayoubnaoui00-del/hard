import dotenv from 'dotenv';
import { sequelize, Exercise, Embedding } from '../src/models/index.js';

dotenv.config();

const OLLAMA_BASE_URL = process.env.OLLAMA_BASE_URL || 'http://localhost:11434';
const EMBED_MODEL = process.env.OLLAMA_EMBED_MODEL || 'all-minilm';
const CONCURRENCY = 5;
const BATCH_SIZE = 50;

/**
 * Fetch vector embedding from Ollama API
 */
async function getEmbedding(text) {
  const url = `${OLLAMA_BASE_URL}/api/embeddings`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: EMBED_MODEL,
      prompt: text,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Ollama embedding error (${response.status}): ${errorText}`);
  }

  const data = await response.json();
  if (!data.embedding || !Array.isArray(data.embedding)) {
    throw new Error('Invalid embedding vector returned from Ollama');
  }

  return data.embedding;
}

export const seedEmbeddings = async () => {
  console.log(`[Seed Embeddings] Starting exercise embeddings generation using model: "${EMBED_MODEL}" at ${OLLAMA_BASE_URL}`);

  try {
    await sequelize.authenticate();
    console.log('[Seed Embeddings] Database connected.');

    // 1. Fetch already embedded exercise IDs to avoid duplicate processing
    const existingEmbeddings = await Embedding.findAll({ attributes: ['exerciseId'] });
    const existingSet = new Set(existingEmbeddings.map((e) => e.exerciseId));
    console.log(`[Seed Embeddings] Found ${existingSet.size} existing embeddings in database.`);

    // 2. Fetch all exercises
    const allExercises = await Exercise.findAll({
      attributes: ['id', 'name', 'muscleGroup', 'instructions', 'formTips'],
      order: [['name', 'ASC']],
    });

    const pendingExercises = allExercises.filter((ex) => !existingSet.has(ex.id));
    console.log(`[Seed Embeddings] Total exercises: ${allExercises.length} | Pending to embed: ${pendingExercises.length}`);

    if (pendingExercises.length === 0) {
      console.log('[Seed Embeddings] All exercises are already embedded! No work needed.');
      return;
    }

    let completed = 0;
    const total = pendingExercises.length;
    let createdCount = 0;

    // Process in batches with concurrency
    for (let i = 0; i < pendingExercises.length; i += BATCH_SIZE) {
      const batch = pendingExercises.slice(i, i + BATCH_SIZE);
      const recordsToInsert = [];

      // Concurrency control within batch
      for (let j = 0; j < batch.length; j += CONCURRENCY) {
        const chunk = batch.slice(j, j + CONCURRENCY);

        const chunkPromises = chunk.map(async (ex) => {
          const summaryText = [
            `Exercise: ${ex.name}`,
            `Target Muscle: ${ex.muscleGroup}`,
            ex.instructions ? `Instructions: ${ex.instructions}` : '',
            ex.formTips ? `Form Tips: ${ex.formTips}` : '',
          ]
            .filter(Boolean)
            .join(' - ');

          try {
            const vector = await getEmbedding(summaryText);
            return {
              exerciseId: ex.id,
              vector,
            };
          } catch (err) {
            console.error(`[Seed Embeddings] Error embedding exercise "${ex.name}" (${ex.id}):`, err.message);
            return null;
          }
        });

        const chunkResults = await Promise.all(chunkPromises);
        for (const res of chunkResults) {
          if (res) recordsToInsert.push(res);
        }

        completed += chunk.length;
        const percent = ((completed / total) * 100).toFixed(1);
        process.stdout.write(`\r[Seed Embeddings] Progress: ${completed}/${total} (${percent}%) completed...`);
      }

      if (recordsToInsert.length > 0) {
        await Embedding.bulkCreate(recordsToInsert, { ignoreDuplicates: true });
        createdCount += recordsToInsert.length;
      }
    }

    console.log(`\n[Seed Embeddings] Successfully stored ${createdCount} new embeddings in database.`);
    const totalInDb = await Embedding.count();
    console.log(`[Seed Embeddings] Total embeddings now in database: ${totalInDb}/${allExercises.length}`);
  } catch (error) {
    console.error('\n[Seed Embeddings] Fatal error generating embeddings:', error);
    throw error;
  }
};

// Execute if run directly
if (process.argv[1] && process.argv[1].endsWith('seed-embeddings.js')) {
  seedEmbeddings()
    .then(() => {
      console.log('[Seed Embeddings] Finished successfully.');
      process.exit(0);
    })
    .catch((err) => {
      console.error('[Seed Embeddings] Failed:', err);
      process.exit(1);
    });
}
