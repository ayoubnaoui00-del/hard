import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../viewmodels/home/home_viewmodel.dart';

class HomePerformanceSnapshotCard extends StatelessWidget {
  final HomeState state;

  const HomePerformanceSnapshotCard({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Snapshot',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
            color: AppTheme.velocityTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.velocitySurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // 1. Streak
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFFF5722),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${state.streakDays}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.velocityTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Streak',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.velocityTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: AppTheme.velocityBorder),
              // 2. Weekly Vol
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.trending_up_rounded,
                          color: Color(0xFF689F38),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${NumberFormat.compact().format(state.weeklyVolume)} kg',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.velocityTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Weekly Vol',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.velocityTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: AppTheme.velocityBorder),
              // 3. This Month
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: Color(0xFF0288D1),
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${state.workoutsThisMonth}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.velocityTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'This Month',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.velocityTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
