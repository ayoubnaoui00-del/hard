import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';

class MainShellView extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellView({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: AppTheme.velocityBackground,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 18, right: 18, bottom: 16),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.velocityLime,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.velocityLime.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
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
                  label: 'Explore',
                  icon: Icons.interests_outlined,
                  activeIcon: Icons.interests_rounded,
                  onTap: () => _onTap(1),
                ),
                _buildNavItem(
                  index: 2,
                  currentIndex: currentIndex,
                  label: 'Activity',
                  icon: Icons.sync_rounded,
                  activeIcon: Icons.sync_rounded,
                  onTap: () => _onTap(2),
                ),
                _buildNavItem(
                  index: 3,
                  currentIndex: currentIndex,
                  label: 'Velo-AI',
                  icon: Icons.auto_awesome_outlined,
                  activeIcon: Icons.auto_awesome,
                  onTap: () => _onTap(3),
                ),
                _buildNavItem(
                  index: 4,
                  currentIndex: currentIndex,
                  label: 'More',
                  icon: Icons.grid_view_rounded,
                  activeIcon: Icons.grid_view_rounded,
                  onTap: () => _onTap(4),
                ),
              ],
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
            // Icon container with active dark badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 12 : 6,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.velocityDark
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 22,
                color: isSelected
                    ? AppTheme.velocityLimeBright
                    : const Color(0xFF2C3925),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppTheme.velocityDark
                    : const Color(0xFF2C3925),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
