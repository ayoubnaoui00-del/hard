import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class LogValidationErrorBanner extends StatelessWidget {
  final String? error;

  const LogValidationErrorBanner({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFD32F2F), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(error!, style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class WorkoutTitleField extends StatelessWidget {
  final TextEditingController controller;

  const WorkoutTitleField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.velocityTextPrimary),
      decoration: InputDecoration(
        labelText: 'Workout Title',
        labelStyle: const TextStyle(color: AppTheme.velocityTextSecondary, fontWeight: FontWeight.w600),
        prefixIcon: const Icon(Icons.edit_note_rounded, color: AppTheme.velocityDark),
        hintText: 'e.g. Push Day, Morning Cardio',
        filled: true,
        fillColor: AppTheme.velocitySurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.velocityBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.velocityBorder, width: 1.2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.velocityDark, width: 1.5)),
      ),
    );
  }
}

class WorkoutNotesField extends StatelessWidget {
  final TextEditingController controller;

  const WorkoutNotesField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Session Notes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.2, color: AppTheme.velocityTextPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.velocityTextPrimary),
          decoration: InputDecoration(
            hintText: 'Add workout notes (e.g., energy levels, PR attempts)...',
            hintStyle: const TextStyle(color: AppTheme.velocityTextMuted, fontSize: 13),
            filled: true,
            fillColor: AppTheme.velocitySurface,
            prefixIcon: const Padding(padding: EdgeInsets.only(bottom: 40), child: Icon(Icons.notes_rounded, color: AppTheme.velocityTextSecondary)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.velocityBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.velocityBorder, width: 1.2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.velocityDark, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
