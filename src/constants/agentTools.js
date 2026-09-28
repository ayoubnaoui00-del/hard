/**
 * Ollama / OpenAI-compatible Function Calling Tool Definitions (HRD-24)
 */

export const AGENT_TOOLS = [
  {
    type: 'function',
    function: {
      name: 'addXp',
      description: 'Award XP (experience points) to the athlete for logging a workout, hitting a PR, or completing a challenge.',
      parameters: {
        type: 'object',
        properties: {
          amount: {
            type: 'number',
            description: 'The number of XP points to award (e.g. 50, 100, 150).',
          },
          reason: {
            type: 'string',
            description: 'The description or achievement justifying the XP award (e.g. "Completed leg day workout", "Hit new bench PR").',
          },
        },
        required: ['amount', 'reason'],
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'updateLeaderboard',
      description: 'Recalculate the athlete\'s total lifetime volume, weekly volume, and current global rank on the leaderboard.',
      parameters: {
        type: 'object',
        properties: {},
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'checkAchievements',
      description: 'Evaluate the athlete\'s workout count, volume, streak, and level to unlock any newly earned achievement badges.',
      parameters: {
        type: 'object',
        properties: {},
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'suggestNextExercise',
      description: 'Query workout history and suggest the optimal next exercise for a specific muscle group based on what hasn\'t been trained recently.',
      parameters: {
        type: 'object',
        properties: {
          muscleGroup: {
            type: 'string',
            description: 'Target muscle group (e.g. "Chest", "Back", "Legs", "Biceps", "Triceps", "Shoulders", "Core").',
          },
        },
        required: ['muscleGroup'],
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'generateWorkoutPlan',
      description: 'Generate a structured workout routine tailored to the requested duration and muscle focus.',
      parameters: {
        type: 'object',
        properties: {
          duration: {
            type: 'number',
            description: 'Estimated workout duration in minutes (e.g. 30, 45, 60).',
          },
          focus: {
            type: 'string',
            description: 'Primary muscle or workout split focus (e.g. "Chest", "Legs", "Upper Body", "Full Body", "Back").',
          },
        },
        required: ['duration', 'focus'],
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'updateStreak',
      description: 'Update the athlete\'s active workout streak (consecutive training days).',
      parameters: {
        type: 'object',
        properties: {},
      },
    },
  },
];
