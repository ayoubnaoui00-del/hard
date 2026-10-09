import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/gradient_background.dart';

class SocialView extends StatelessWidget {
  const SocialView({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'Community',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.velocityTextPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.velocitySurfaceMuted,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: AppTheme.velocityLime,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Social Feed & Leaderboards',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.velocityTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Connect, share progress, and compete.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.velocityTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
