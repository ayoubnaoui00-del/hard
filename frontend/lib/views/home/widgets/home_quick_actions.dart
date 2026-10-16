import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
            color: AppTheme.velocityTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Log Workout (Primary Accent)
            Expanded(
              child: _QuickActionCard(
                title: 'Log Workout',
                subtitle: 'Start session',
                icon: Icons.fitness_center_rounded,
                iconColor: AppTheme.velocityDark,
                bgColor: AppTheme.velocityLime,
                titleColor: AppTheme.velocityDark,
                subtitleColor: const Color(0xFF384435),
                onTap: () => context.go('/workouts/log'),
              ),
            ),
            const SizedBox(width: 10),
            // Exercises (Browse library)
            Expanded(
              child: _QuickActionCard(
                title: 'Exercises',
                subtitle: 'Browse library',
                icon: Icons.search_rounded,
                iconColor: AppTheme.velocityLime,
                bgColor: AppTheme.velocitySurface,
                titleColor: AppTheme.velocityTextPrimary,
                subtitleColor: AppTheme.velocityTextSecondary,
                onTap: () => context.go('/explore'),
              ),
            ),
            const SizedBox(width: 10),
            // AI Coach
            Expanded(
              child: _QuickActionCard(
                title: 'AI Coach',
                subtitle: 'Ask coach',
                icon: Icons.auto_awesome,
                iconColor: AppTheme.velocityLime,
                bgColor: AppTheme.velocitySurface,
                titleColor: AppTheme.velocityTextPrimary,
                subtitleColor: AppTheme.velocityTextSecondary,
                onTap: () => context.go('/coach'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = bgColor == AppTheme.velocityLime;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPrimary ? Colors.transparent : AppTheme.velocityBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? AppTheme.velocityLime.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isPrimary
                    ? AppTheme.velocityDark
                    : AppTheme.velocityLime.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isPrimary ? AppTheme.velocityLime : iconColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: titleColor,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: subtitleColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
