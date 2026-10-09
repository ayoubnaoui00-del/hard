import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../viewmodels/home/home_viewmodel.dart';

class HomeTodaySummaryCard extends StatelessWidget {
  final HomeState state;
  final String todayFormatted;

  const HomeTodaySummaryCard({
    super.key,
    required this.state,
    required this.todayFormatted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Summary",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                color: AppTheme.velocityTextPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.velocitySurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.velocityBorder),
              ),
              child: Text(
                todayFormatted,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.velocityTextSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Workouts Logged Today Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.velocitySurface,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: AppTheme.velocityBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.velocityLime.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppTheme.velocityLime,
                            size: 20,
                          ),
                        ),
                        Text(
                          '${state.workoutsToday}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.velocityTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Workouts Logged',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.velocityTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.workoutsToday > 0
                          ? 'Sessions completed'
                          : 'No workouts yet',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.velocityTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Total Volume Today Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.velocitySurface,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: AppTheme.velocityBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.velocityAmber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.line_weight_rounded,
                            color: AppTheme.velocityAmber,
                            size: 20,
                          ),
                        ),
                        Text(
                          NumberFormat('#,##0').format(state.todayVolume),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.velocityTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Total Volume',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.velocityTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'kg lifted today',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.velocityTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
