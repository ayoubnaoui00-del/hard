import { ACHIEVEMENT_DEFINITIONS } from '../src/constants/achievements.js';

export const seedAchievements = async () => {
  console.log(`[Seed Achievements] Total defined achievements: ${ACHIEVEMENT_DEFINITIONS.length}`);
  ACHIEVEMENT_DEFINITIONS.forEach((a, i) => {
    console.log(`  ${i + 1}. [${a.type}] ${a.name} - ${a.description} (Badge: ${a.badgeIcon})`);
  });
  return ACHIEVEMENT_DEFINITIONS;
};

if (process.argv[1] && process.argv[1].endsWith('seed-achievements.js')) {
  seedAchievements()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
