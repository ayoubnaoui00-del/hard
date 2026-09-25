import { sequelize, Embedding } from '../src/models/index.js';

async function check() {
  try {
    await sequelize.authenticate();
    const [exts] = await sequelize.query('SELECT extname FROM pg_extension;');
    console.log('Installed extensions:', exts.map(e => e.extname));

    const count = await Embedding.count();
    console.log('Embedding count:', count);

    const sample = await Embedding.findOne();
    if (sample) {
      console.log('Sample embedding id:', sample.id, 'vector length:', Array.isArray(sample.vector) ? sample.vector.length : typeof sample.vector);
    }
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await sequelize.close();
  }
}

check();
