import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../viewmodels/home/home_viewmodel.dart';

class HomeRecentAchievementsSection extends StatelessWidget {
  final HomeState state;

  const HomeRecentAchievementsSection({
    super.key,
    required this.state,
  });

  static IconData _getAchievementIcon(String iconKey) {
    switch (iconKey.toLowerCase()) {
      case 'footsteps':
        return Icons.directions_walk_rounded;
      case 'calendar-check':
        return Icons.event_available_rounded;
      case 'dumbbell':
        return Icons.fitness_center_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'crown':
        return Icons.workspace_premium_rounded;
      case 'weight':
      case 'anvil':
        return Icons.line_weight_rounded;
      case 'fire':
      case 'flame':
        return Icons.local_fire_department_rounded;
      case 'meteor':
      case 'lightning':
        return Icons.bolt_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'medal':
        return Icons.military_tech_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Achievements',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                color: AppTheme.velocityTextPrimary,
              ),
            ),
            Text(
              '${state.recentAchievements.length} Unlocked',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.velocityLime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.recentAchievements.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.velocitySurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.velocityBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  color: AppTheme.velocityTextMuted,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'Complete workouts to unlock achievement badges!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.velocityTextSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.recentAchievements.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final badge = state.recentAchievements[index];
                return Container(
                  width: 220,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.velocitySurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.velocityBorder,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.velocityLime.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getAchievementIcon(badge.badgeIcon),
                          color: AppTheme.velocityLime,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              badge.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.velocityTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              badge.description,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.velocityTextSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
