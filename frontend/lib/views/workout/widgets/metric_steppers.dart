import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// Tactile, high-contrast stepper action button for workout metrics
class _StepperActionButton extends StatelessWidget {
  final IconData icon;
  final bool isPlus;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _StepperActionButton({
    required this.icon,
    required this.isPlus,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // High-contrast clean color palette for dark UI
    final bgColor = !isEnabled
        ? AppTheme.velocityDark.withValues(alpha: 0.35)
        : isPlus
            ? AppTheme.velocityLime.withValues(alpha: 0.16)
            : const Color(0xFF222B3A);

    final borderColor = !isEnabled
        ? const Color(0xFF1E2634)
        : isPlus
            ? AppTheme.velocityLime.withValues(alpha: 0.42)
            : const Color(0xFF38475F);

    final iconColor = !isEnabled
        ? AppTheme.velocityTextMuted.withValues(alpha: 0.35)
        : isPlus
            ? AppTheme.velocityLime
            : AppTheme.velocityTextPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(9),
        splashColor: isPlus
            ? AppTheme.velocityLime.withValues(alpha: 0.25)
            : Colors.white12,
        highlightColor: isPlus
            ? AppTheme.velocityLime.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.06),
        child: Ink(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: borderColor, width: 1.1),
            boxShadow: isEnabled && isPlus
                ? [
                    BoxShadow(
                      color: AppTheme.velocityLime.withValues(alpha: 0.14),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ]
                : isEnabled
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 17,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class MetricStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const MetricStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.velocitySurfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.velocityBorder, width: 1.1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.velocityTextSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepperActionButton(
                icon: Icons.remove_rounded,
                isPlus: false,
                isEnabled: value > min,
                onTap: () => onChanged(value - 1),
              ),
              Text(
                '$value',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  letterSpacing: -0.3,
                  color: AppTheme.velocityTextPrimary,
                ),
              ),
              _StepperActionButton(
                icon: Icons.add_rounded,
                isPlus: true,
                isEnabled: value < max,
                onTap: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WeightInputStepper extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const WeightInputStepper({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.velocitySurfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.velocityBorder, width: 1.1),
      ),
      child: Column(
        children: [
          const Text(
            'Weight (kg)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.velocityTextSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepperActionButton(
                icon: Icons.remove_rounded,
                isPlus: false,
                isEnabled: value > 0,
                onTap: () => onChanged((value - 2.5).clamp(0.0, 999.0)),
              ),
              Text(
                value % 1 == 0 ? '${value.toInt()}' : value.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  letterSpacing: -0.3,
                  color: AppTheme.velocityTextPrimary,
                ),
              ),
              _StepperActionButton(
                icon: Icons.add_rounded,
                isPlus: true,
                isEnabled: value < 999.0,
                onTap: () => onChanged((value + 2.5).clamp(0.0, 999.0)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
