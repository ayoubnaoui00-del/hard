import 'package:flutter/material.dart';
import '../../../config/theme.dart';

import 'coach_quick_prompts_bar.dart';

class CoachWelcomeView extends StatelessWidget {
  final List<Map<String, String>> prompts;
  final ValueChanged<String> onSelectPrompt;

  const CoachWelcomeView({
    super.key,
    this.prompts = defaultCoachQuickPrompts,
    required this.onSelectPrompt,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2979FF).withValues(alpha: 0.2),
                    const Color(0xFF00E5FF).withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2979FF).withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 48,
                color: Color(0xFF2979FF),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Personal AI Coach',
              style: TextStyle(
                color: AppTheme.velocityTextPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask about workout routines, exercise form tips, 1RM calculations, progressive overload, or nutrition advice.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.velocityTextSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: prompts.map((p) {
                return ActionChip(
                  label: Text(
                    p['label']!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.velocityTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: AppTheme.velocitySurface,
                  side: const BorderSide(color: AppTheme.velocityBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: () => onSelectPrompt(p['prompt']!),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
