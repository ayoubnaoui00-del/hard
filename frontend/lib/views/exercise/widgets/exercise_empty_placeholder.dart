import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class ExerciseEmptyPlaceholder extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onResetFilters;

  const ExerciseEmptyPlaceholder({
    super.key,
    required this.hasActiveFilters,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppTheme.velocityTextMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'No exercises found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.velocityTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try adjusting your search query or filters',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.velocityTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (hasActiveFilters)
              ElevatedButton.icon(
                onPressed: onResetFilters,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset All Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.velocityDark,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(160, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
