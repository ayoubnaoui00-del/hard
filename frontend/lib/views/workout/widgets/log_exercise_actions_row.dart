import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class LogExerciseActionsRow extends StatelessWidget {
  final VoidCallback onAddExercise;
  final VoidCallback onOpenBodyMap;

  const LogExerciseActionsRow({
    super.key,
    required this.onAddExercise,
    required this.onOpenBodyMap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: onAddExercise,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.velocitySurface,
              foregroundColor: AppTheme.velocityDark,
              side: const BorderSide(color: AppTheme.velocityBorder, width: 1.2),
              minimumSize: const Size.fromHeight(48),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: AppTheme.velocityLime, borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.add_rounded, color: AppTheme.velocityDark, size: 16),
            ),
            label: const Text('Add Exercise', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.velocityTextPrimary)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: onOpenBodyMap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.velocityDark,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.accessibility_new_rounded, size: 18, color: AppTheme.velocityLime),
            label: const Text('Body Map', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
