import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';

class LogDateDurationPickers extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPickDate;
  final TextEditingController durationController;
  final int selectedDuration;
  final List<int> suggestedDurations;
  final ValueChanged<int> onSelectDuration;

  const LogDateDurationPickers({
    super.key,
    required this.selectedDate,
    required this.onPickDate,
    required this.durationController,
    required this.selectedDuration,
    required this.suggestedDurations,
    required this.onSelectDuration,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(selectedDate);

    return Column(
      children: [
        // Date Picker Card
        InkWell(
          onTap: onPickDate,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.velocitySurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.velocityLime.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: AppTheme.velocityDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Workout Date',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.velocityTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.velocityTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.velocityTextSecondary, size: 24),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Duration Picker Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.velocitySurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.velocityLime.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.timer_outlined,
                      color: AppTheme.velocityDark,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Duration (Minutes)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.velocityTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 72,
                    child: TextFormField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppTheme.velocityTextPrimary,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                        filled: true,
                        fillColor: AppTheme.velocitySurfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.velocityBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.velocityBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.velocityDark, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        final intVal = int.tryParse(val);
                        if (intVal != null) {
                          onSelectDuration(intVal);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: suggestedDurations.map((mins) {
                  final isSelected = selectedDuration == mins;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () => onSelectDuration(mins),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.velocityLime : AppTheme.velocitySurfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.velocityLimeDim : AppTheme.velocityBorder,
                              width: 1.2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.velocityLime.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${mins}m',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? AppTheme.velocityDark : AppTheme.velocityTextSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
