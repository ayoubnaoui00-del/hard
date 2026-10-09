import 'package:flutter/material.dart';
import '../../../config/theme.dart';

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
        border: Border.all(color: AppTheme.velocityBorder),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.velocityTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: value > min ? () => onChanged(value - 1) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: value > min ? AppTheme.velocitySurface : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: value > min ? AppTheme.velocityBorder : Colors.transparent,
                    ),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 16,
                    color: value > min ? AppTheme.velocityDark : AppTheme.velocityTextMuted,
                  ),
                ),
              ),
              Text(
                '$value',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: AppTheme.velocityTextPrimary,
                ),
              ),
              InkWell(
                onTap: value < max ? () => onChanged(value + 1) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: value < max ? AppTheme.velocitySurface : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: value < max ? AppTheme.velocityBorder : Colors.transparent,
                    ),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: value < max ? AppTheme.velocityDark : AppTheme.velocityTextMuted,
                  ),
                ),
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
        border: Border.all(color: AppTheme.velocityBorder),
      ),
      child: Column(
        children: [
          const Text(
            'Weight (kg)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.velocityTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: value >= 2.5
                    ? () => onChanged((value - 2.5).clamp(0.0, 999.0))
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: value >= 2.5 ? AppTheme.velocitySurface : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: value >= 2.5 ? AppTheme.velocityBorder : Colors.transparent,
                    ),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 16,
                    color: value >= 2.5 ? AppTheme.velocityDark : AppTheme.velocityTextMuted,
                  ),
                ),
              ),
              Text(
                value % 1 == 0 ? '${value.toInt()}' : value.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppTheme.velocityTextPrimary,
                ),
              ),
              InkWell(
                onTap: () => onChanged((value + 2.5).clamp(0.0, 999.0)),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.velocitySurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.velocityBorder),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: AppTheme.velocityDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
