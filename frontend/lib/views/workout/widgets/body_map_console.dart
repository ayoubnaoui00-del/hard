import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'body_map_models.dart';
import 'interactive_body_model.dart';

class BodyMapConsole extends StatelessWidget {
  final MuscleGroupType selectedMuscle;
  final bool isFrontView;
  final bool isEmbedded;
  final VoidCallback onToggleView;
  final ValueChanged<MuscleGroupType> onSelectMuscle;
  final VoidCallback onFullScreen;

  const BodyMapConsole({
    super.key,
    required this.selectedMuscle,
    required this.isFrontView,
    required this.isEmbedded,
    required this.onToggleView,
    required this.onSelectMuscle,
    required this.onFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.velocityDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.velocityDarkBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.velocityDark.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEmbedded) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppTheme.velocityLime.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.accessibility_new_rounded,
                        color: AppTheme.velocityLime,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Interactive Body Map',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 20),
                  tooltip: 'Full Screen',
                  visualDensity: VisualDensity.compact,
                  onPressed: onFullScreen,
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          SizedBox(
            height: 200,
            child: InteractiveBodyModel(
              selectedMuscle: selectedMuscle,
              isFrontView: isFrontView,
              onToggleView: onToggleView,
              onMuscleSelected: onSelectMuscle,
            ),
          ),
        ],
      ),
    );
  }
}
