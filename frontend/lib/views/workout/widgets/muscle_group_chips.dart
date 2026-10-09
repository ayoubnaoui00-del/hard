import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'body_map_models.dart';

class MuscleGroupChips extends StatelessWidget {
  final MuscleGroupType selectedMuscle;
  final ValueChanged<MuscleGroupType> onSelectMuscle;

  const MuscleGroupChips({
    super.key,
    required this.selectedMuscle,
    required this.onSelectMuscle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: MuscleGroupType.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final muscle = MuscleGroupType.values[index];
          final isSelected = selectedMuscle == muscle;
          return InkWell(
            onTap: () => onSelectMuscle(muscle),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.velocityLime : AppTheme.velocitySurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppTheme.velocityLime : AppTheme.velocityBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppTheme.velocityLime.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    muscle.icon,
                    size: 15,
                    color: isSelected ? AppTheme.velocityDark : muscle.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    muscle.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppTheme.velocityDark : AppTheme.velocityTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
