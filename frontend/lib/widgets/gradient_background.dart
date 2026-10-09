import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Wraps any screen in the Forest Noir gradient background.
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.forestNoirGradient,
      ),
      child: child,
    );
  }
}
