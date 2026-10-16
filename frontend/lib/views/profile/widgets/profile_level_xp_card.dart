import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';

class ProfileLevelXpCard extends StatelessWidget {
  final int level;
  final int currentXp;
  final int nextLevelXp;
  final double xpProgress;

  const ProfileLevelXpCard({
    super.key,
    required this.level,
    required this.currentXp,
    required this.nextLevelXp,
    required this.xpProgress,
  });

  static final NumberFormat _numberFormat = NumberFormat('#,###');

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
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.velocityLime,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.velocityLime.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      'LVL $level',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppTheme.velocityDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Level Progression',
                    style: TextStyle(
                      color: AppTheme.velocityTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${_numberFormat.format(currentXp)} / ${_numberFormat.format(nextLevelXp)} XP',
                style: const TextStyle(
                  color: AppTheme.velocityLime,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: xpProgress,
              minHeight: 10,
              backgroundColor: AppTheme.velocityDarkBorder,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.velocityLime),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(xpProgress * 100).toInt()}% completed to Level ${level + 1}',
            style: const TextStyle(color: AppTheme.velocityTextSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
