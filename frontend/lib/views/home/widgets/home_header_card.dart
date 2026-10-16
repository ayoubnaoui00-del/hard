import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../viewmodels/home/home_viewmodel.dart';

class HomeHeaderCard extends StatelessWidget {
  final HomeState state;

  const HomeHeaderCard({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final initials =
        state.displayName.isNotEmpty ? state.displayName[0].toUpperCase() : 'A';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/profile'),
        borderRadius: BorderRadius.circular(16),
        splashColor: AppTheme.velocityLime.withValues(alpha: 0.1),
        highlightColor: AppTheme.velocityLime.withValues(alpha: 0.05),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF141822),
                Color(0xFF181E2B),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.velocityBorder,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Mini Avatar with neon Electric Lime rim
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.velocityLime, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.velocityLime.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/user_avatar.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppTheme.velocityLime,
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.velocityDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name & athlete micro-tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.velocityLime,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'ATHLETE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: AppTheme.velocityTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      state.displayName.isNotEmpty
                          ? state.displayName
                          : 'Athlete',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.velocityTextPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Aesthetic Level Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.velocityDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.velocityLime.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.velocityLime.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 13,
                      color: AppTheme.velocityLime,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'LVL ${state.level}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.velocityLime,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
