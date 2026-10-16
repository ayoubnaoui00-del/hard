import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class LogWorkoutSubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback? onSubmit;

  const LogWorkoutSubmitButton({
    super.key,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isSubmitting ? null : onSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.velocityLimeBright,
        foregroundColor: AppTheme.velocityDark,
        disabledBackgroundColor: AppTheme.velocityLime.withValues(alpha: 0.5),
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: isSubmitting
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.velocityDark),
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_rounded, size: 22, color: AppTheme.velocityDark),
                SizedBox(width: 8),
                Text(
                  'Log Workout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.velocityDark,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
    );
  }
}
