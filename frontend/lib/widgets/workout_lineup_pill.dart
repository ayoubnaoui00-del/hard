import 'package:flutter/material.dart';
import '../config/theme.dart';

class WorkoutLineUpPill extends StatelessWidget {
  final String title;
  final Color playButtonColor;
  final Color playIconColor;
  final VoidCallback onPlay;
  final VoidCallback onRemove;

  const WorkoutLineUpPill({
    super.key,
    required this.title,
    required this.playButtonColor,
    required this.playIconColor,
    required this.onPlay,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Play Button
          GestureDetector(
            onTap: onPlay,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: playButtonColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: playButtonColor.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: playIconColor,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.velocityTextPrimary,
            ),
          ),
          const SizedBox(width: 8),
          // Close / Remove icon
          GestureDetector(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppTheme.velocityTextSecondary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
