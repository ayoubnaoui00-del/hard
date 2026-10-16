/**
 * Ollama / OpenAI-compatible Function Calling Tool Definitions (HRD-24)
 */

export const AGENT_TOOLS = [
  {
    type: 'function',
    function: {
      name: 'logWorkout',
      description: 'Log and save a completed workout session with exercises, sets, reps, and weights to the database. Automatically computes volume, updates streak, and awards XP.',
      parameters: {
        type: 'object',
        properties: {
          name: {
            type: 'string',
            description: 'Name of the workout session (e.g. "Chest & Triceps", "Heavy Leg Day", "Push Day").',
          },
          duration: {
            type: 'number',
            description: 'Estimated workout duration in minutes (e.g. 45, 60).',
          },
          exercises: {
            type: 'array',
            description: 'List of performed exercises with sets, reps, and weight.',
            items: {
              type: 'object',
              properties: {
                exerciseName: {
                  type: 'string',
                  description: 'Name of the exercise (e.g. "Barbell Bench Press", "Squat", "Pull-up").',
                },
                sets: {
                  type: 'number',
                  description: 'Number of sets completed.',
                },
                reps: {
                  type: 'number',
                  description: 'Number of repetitions per set.',
                },
                weight: {
                  type: 'number',
                  description: 'Weight lifted in kilograms (kg) (0 for bodyweight).',
                },
              },
              required: ['exerciseName', 'sets', 'reps'],
            },
          },
          notes: {
            type: 'string',
            description: 'Optional workout notes or feedback.',
          },
        },
        required: ['name', 'exercises'],
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'getUserStats',
      description: 'Retrieve current athlete stats including level, total XP, current streak, total workouts logged, and total volume lifted.',
      parameters: {
        type: 'object',
        properties: {},
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'getRecentWorkouts',
      description: 'Fetch the athlete\'s recent workout history including exercises, sets, reps, and weights to analyze progress or check previous performance.',
      parameters: {
        type: 'object',
        properties: {
          limit: {
            type: 'number',
            description: 'Number of recent workouts to retrieve (default 3, max 10).',
          },
          exerciseFilter: {
            type: 'string',
            description: 'Optional exercise name to filter or search for (e.g. "Bench Press", "Squat").',
          },
        },
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'addXp',
      description: 'Award XP (experience points) to the athlete for logging a workout, hitting a PR, or achieving a milestone.',
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

