import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../viewmodels/profile/profile_viewmodel.dart';

class ProfileStatisticsCard extends StatelessWidget {
  final ProfileState state;
  final VoidCallback onToggleUnit;

  const ProfileStatisticsCard({
    super.key,
    required this.state,
    required this.onToggleUnit,
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
              const Text(
                'ATHLETE STATISTICS',
                style: TextStyle(
                  color: AppTheme.velocityTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              GestureDetector(
                onTap: onToggleUnit,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.velocitySurfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.velocityBorder),
                  ),
                  child: Row(
                    children: [
                      Text(
                        state.isVolumeInLbs ? 'Unit: lbs' : 'Unit: kg',
                        style: const TextStyle(
                          color: AppTheme.velocityLime,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.swap_horiz_rounded,
                          size: 14, color: AppTheme.velocityLime),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatTile(
                title: 'Workouts',
                value: '${state.totalWorkouts}',
                icon: Icons.fitness_center_rounded,
                color: const Color(0xFF60A5FA),
              ),
              const SizedBox(width: 10),
              _buildStatTile(
                title: 'Total Volume',
                value:
                    '${_numberFormat.format(state.displayVolume.toInt())} ${state.volumeUnit}',
                icon: Icons.scale_rounded,
                color: const Color(0xFFFFB300),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatTile(
                title: 'Current Streak',
                value: '${state.currentStreak} Days',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFFF5252),
              ),
              const SizedBox(width: 10),
              _buildStatTile(
                title: 'Longest Streak',
                value: '${state.longestStreak} Days',
                icon: Icons.bolt_rounded,
                color: const Color(0xFF34D399),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.velocitySurfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.velocityBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.velocityTextPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.velocityTextSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
