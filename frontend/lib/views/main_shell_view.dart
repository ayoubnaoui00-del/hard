import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';

import '../widgets/gradient_background.dart';

class MainShellView extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellView({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 18, right: 18, bottom: 16),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.velocitySurface,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppTheme.velocityLime.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  index: 0,
                  currentIndex: currentIndex,
                  label: 'Home',
                  icon: Icons.home_rounded,
                  activeIcon: Icons.home_rounded,
                  onTap: () => _onTap(0),
                ),
                _buildNavItem(
                  index: 1,
                  currentIndex: currentIndex,
                  label: 'Exercises',
                  icon: Icons.fitness_center_outlined,
                  activeIcon: Icons.fitness_center_rounded,
                  onTap: () => _onTap(1),
                ),
                _buildNavItem(
                  index: 2,
                  currentIndex: currentIndex,
                  label: 'Workouts',
                  icon: Icons.history_rounded,
                  activeIcon: Icons.history_rounded,
                  onTap: () => _onTap(2),
                ),
                _buildNavItem(
                  index: 3,
                  currentIndex: currentIndex,
                  label: 'AI Coach',
                  icon: Icons.auto_awesome_outlined,
                  activeIcon: Icons.auto_awesome,
                  onTap: () => _onTap(3),
                ),
                _buildNavItem(
                  index: 4,
                  currentIndex: currentIndex,
                  label: 'Profile',
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  onTap: () => _onTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Widget _buildNavItem({
    required int index,
    required int currentIndex,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required VoidCallback onTap,
  }) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container with active glowing badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 12 : 6,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.velocityLime.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(
                        color: AppTheme.velocityLime.withValues(alpha: 0.4),
                        width: 1,
                      )
                    : null,
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 22,
                color: isSelected
                    ? AppTheme.velocityLime
                    : AppTheme.velocityTextMuted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppTheme.velocityLime
                    : AppTheme.velocityTextMuted,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
