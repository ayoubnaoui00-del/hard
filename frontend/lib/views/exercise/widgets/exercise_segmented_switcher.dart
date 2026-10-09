import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class ExerciseSegmentedSwitcher extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const ExerciseSegmentedSwitcher({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.velocitySurfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.velocityBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => onTabChanged(0),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selectedTab == 0 ? AppTheme.velocityDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    if (selectedTab == 0)
                      BoxShadow(
                        color: AppTheme.velocityDark.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fitness_center_rounded,
                      size: 17,
                      color: selectedTab == 0
                          ? AppTheme.velocityLime
                          : AppTheme.velocityTextSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All Exercises',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: selectedTab == 0
                            ? Colors.white
                            : AppTheme.velocityTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => onTabChanged(1),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selectedTab == 1 ? AppTheme.velocityDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    if (selectedTab == 1)
                      BoxShadow(
                        color: AppTheme.velocityDark.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.accessibility_new_rounded,
                      size: 17,
                      color: selectedTab == 1
                          ? AppTheme.velocityLime
                          : AppTheme.velocityTextSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '3D Body Model',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: selectedTab == 1
                            ? Colors.white
                            : AppTheme.velocityTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: selectedTab == 1
                            ? AppTheme.velocityLime
                            : AppTheme.velocityLime.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '3D',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.velocityDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
