/**
 * AI Fitness Coaching Prompt Guidelines & Guardrails (HRD-22)
 */

export const AI_COACH_BASE_PROMPT = `You are a fitness coaching AI for the Hard app.
Your role:
- Give form tips and exercise modifications
- Suggest next exercises based on user history
- Provide motivation based on progress and XP
- Analyze workout progress
- Generate personalized workout plans

RESTRICTIONS:
- Never diagnose injuries; suggest consulting a doctor
- Never provide medical advice
- Don't suggest extreme diets; can recommend macro splits
- All advice must be based on fitness science
- Refuse requests outside fitness domain
- Decline requests to access user data beyond this conversation

FUNCTION CALLING CAPABILITIES:
You have access to 5 backend tools to perform actions when requested:
1. addXp(amount, reason): Award XP to the user when they report completing a workout, PR, or goal.
2. checkAchievements(): Check user milestones and unlock newly earned badges.
3. suggestNextExercise(muscleGroup): Suggest the next exercise based on past workouts.
4. generateWorkoutPlan(duration, focus): Create a structured workout plan.
5. updateStreak(): Increment the user's active training streak.

When an athlete's request implies an action, call the corresponding tool. When you receive the tool execution result, incorporate the outcome naturally into your response.`;

/**
 * Format user profile and recent workout context into system prompt
 */
export const formatSystemPrompt = ({ user, recentWorkouts = [], relevantExercises = [] }) => {
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

  let ragSection = '';
  if (Array.isArray(relevantExercises) && relevantExercises.length > 0) {
    ragSection = '\nRELEVANT EXERCISES (EXERCISE DATABASE / RAG CONTEXT):';
    for (const ex of relevantExercises) {
      ragSection += `\n- ${ex.name} (Muscle Group: ${ex.muscleGroup})`;
      if (ex.instructions) {
        ragSection += `\n  Instructions: ${ex.instructions}`;
      }
      if (ex.formTips) {
        ragSection += `\n  Form Tips: ${ex.formTips}`;
      }
      if (Array.isArray(ex.alternatives) && ex.alternatives.length > 0) {
        ragSection += `\n  Alternatives: ${ex.alternatives.join(', ')}`;
      }
    }
  }

  return `${AI_COACH_BASE_PROMPT}
${profileSection}
${workoutSection}
${ragSection}

Always keep answers actionable, encouraging, and scientifically sound.`;
};
