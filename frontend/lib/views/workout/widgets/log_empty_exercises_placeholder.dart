import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class LogEmptyExercisesPlaceholder extends StatelessWidget {
  const LogEmptyExercisesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.velocitySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
      ),
      child: const Column(
        children: [
          Icon(Icons.fitness_center_outlined, size: 26, color: AppTheme.velocityDark),
          SizedBox(height: 12),
          Text(
            'No exercises added yet',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.velocityTextPrimary),
          ),
          SizedBox(height: 4),
          Text(
            'Tap "+ Add Exercise" below to pick your first exercise.',
            style: TextStyle(color: AppTheme.velocityTextSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
