import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../models/achievement_model.dart';
import '../../../viewmodels/profile/profile_viewmodel.dart';

class ProfileAchievementsCard extends StatelessWidget {
  final ProfileState state;
  final void Function(AchievementModel achievement) onShowDetails;

  const ProfileAchievementsCard({
    super.key,
    required this.state,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.velocitySurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACHIEVEMENTS & BADGES',
                style: TextStyle(
                  color: AppTheme.velocityTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                '${state.achievements.where((a) => a.isUnlocked).length} Unlocked',
                style: const TextStyle(
                  color: AppTheme.velocityLime,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.achievements.map((ach) {
              final isUnlocked = ach.isUnlocked;
              return GestureDetector(
                onTap: () => onShowDetails(ach),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 80) / 3,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? AppTheme.velocityLime.withValues(alpha: 0.1)
                        : AppTheme.velocitySurfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isUnlocked
                          ? AppTheme.velocityLime.withValues(alpha: 0.4)
                          : AppTheme.velocityBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isUnlocked
                            ? Icons.workspace_premium_rounded
                            : Icons.lock_outline_rounded,
                        color: isUnlocked
                            ? AppTheme.velocityLime
                            : AppTheme.velocityTextMuted,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ach.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isUnlocked ? AppTheme.velocityTextPrimary : AppTheme.velocityTextMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class AchievementDetailsSheet extends StatelessWidget {
  final AchievementModel achievement;

  const AchievementDetailsSheet({
    super.key,
    required this.achievement,
  });

  static Future<void> show(BuildContext context, AchievementModel achievement) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AchievementDetailsSheet(achievement: achievement),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.velocitySurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.velocityBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? const Color(0xFFFFB300).withValues(alpha: 0.15)
                    : const Color(0xFF222230),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnlocked
                      ? const Color(0xFFFFB300)
                      : const Color(0xFF333348),
                ),
              ),
              child: Icon(
                isUnlocked
                    ? Icons.workspace_premium_rounded
                    : Icons.lock_outline_rounded,
                color: isUnlocked ? const Color(0xFFFFB300) : Colors.white38,
                size: 44,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              achievement.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                    : const Color(0xFF6B7280).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isUnlocked ? 'UNLOCKED' : 'LOCKED',
                style: TextStyle(
                  color: isUnlocked ? const Color(0xFF34D399) : Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.velocitySurfaceMuted,
                  foregroundColor: AppTheme.velocityTextPrimary,
                  side: const BorderSide(color: AppTheme.velocityBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
