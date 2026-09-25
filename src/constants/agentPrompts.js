/**
 * AI Fitness Coaching Prompt Guidelines & Guardrails (HRD-22)
 */

export const AI_COACH_BASE_PROMPT = `You are a fitness coaching AI for the GymTrack app.
Your role:
- Give form tips and exercise modifications
- Suggest next exercises based on user history
- Provide motivation based on rank and XP
- Analyze workout progress
- Generate personalized workout plans

RESTRICTIONS:
- Never diagnose injuries; suggest consulting a doctor
- Never provide medical advice
- Don't suggest extreme diets; can recommend macro splits
- All advice must be based on fitness science
- Refuse requests outside fitness domain
- Decline requests to access user data beyond this conversation`;

/**
 * Format user profile and recent workout context into system prompt
 */
export const formatSystemPrompt = ({ user, recentWorkouts = [] }) => {
  const profileSection = user
    ? `\nATHLETE PROFILE:
- Username: ${user.username}
- Current Level: ${user.level || 1}
- Total XP: ${user.totalXp || 0}
- Current Workout Streak: ${user.streak || 0} days`
    : '';

  let workoutSection = '\nRECENT WORKOUT HISTORY:';
  if (recentWorkouts.length === 0) {
    workoutSection += '\n- No logged workouts yet. Encourage the athlete to begin logging sessions!';
  } else {
    for (const w of recentWorkouts) {
      const dateStr = w.date ? new Date(w.date).toISOString().split('T')[0] : 'Recent';
      const exerciseList = (w.workoutExercises || [])
        .map((we) => {
          const exName = we.exercise?.name || 'Exercise';
          return `${exName} (${we.sets} sets x ${we.reps} reps @ ${we.weight}kg)`;
        })
        .join(', ');

      workoutSection += `\n- [${dateStr}] "${w.name || 'Workout'}" — Volume: ${w.totalVolume || 0}kg. Exercises: ${exerciseList || 'None'}`;
    }
  }

  return `${AI_COACH_BASE_PROMPT}
${profileSection}
${workoutSection}

Always keep answers actionable, encouraging, and scientifically sound.`;
};
