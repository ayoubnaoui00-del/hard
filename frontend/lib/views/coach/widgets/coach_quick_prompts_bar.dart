import 'package:flutter/material.dart';
import '../../../config/theme.dart';

const List<Map<String, String>> defaultCoachQuickPrompts = [
  {
    'label': '💪 Recommend 4-day Routine',
    'prompt':
        'Can you recommend a balanced 4-day upper/lower hypertrophy workout split?',
  },
  {
    'label': '🏋️ Form Check: Barbell Squat',
    'prompt':
        'What are the top 3 cues for maintaining proper depth and bar path during a heavy back squat?',
  },
  {
    'label': '📈 Break Bench Plateau',
    'prompt':
        'My bench press has been stuck at 90 kg for 4 weeks. How should I adjust volume or intensity?',
  },
  {
    'label': '🥗 Post-Workout Recovery',
    'prompt':
        'What should my optimal post-workout protein and carb intake look like for recovery?',
  },
];

class CoachQuickPromptsBar extends StatelessWidget {
  final List<Map<String, String>> prompts;
  final ValueChanged<String> onSelectPrompt;

  const CoachQuickPromptsBar({
    super.key,
    this.prompts = defaultCoachQuickPrompts,
    required this.onSelectPrompt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = prompts[index];
          return ActionChip(
            label: Text(
              prompt['label']!,
              style: const TextStyle(fontSize: 11, color: AppTheme.velocityTextPrimary, fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.velocitySurfaceMuted,
            side: const BorderSide(color: AppTheme.velocityBorder),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            onPressed: () => onSelectPrompt(prompt['prompt']!),
          );
        },
      ),
    );
  }
}
