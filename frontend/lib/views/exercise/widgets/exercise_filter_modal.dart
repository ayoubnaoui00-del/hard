import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'exercise_types.dart';

class ExerciseFilterModal extends StatefulWidget {
  final String selectedMuscle;
  final String selectedEquipment;
  final String selectedCategory;
  final Function(String muscle, String equipment, String category) onApply;

  const ExerciseFilterModal({
    super.key,
    required this.selectedMuscle,
    required this.selectedEquipment,
    required this.selectedCategory,
    required this.onApply,
  });

  static void show(
    BuildContext context, {
    required String selectedMuscle,
    required String selectedEquipment,
    required String selectedCategory,
    required Function(String muscle, String equipment, String category) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExerciseFilterModal(
        selectedMuscle: selectedMuscle,
        selectedEquipment: selectedEquipment,
        selectedCategory: selectedCategory,
        onApply: onApply,
      ),
    );
  }

  @override
  State<ExerciseFilterModal> createState() => _ExerciseFilterModalState();
}

class _ExerciseFilterModalState extends State<ExerciseFilterModal> {
  late String _currentMuscle;
  late String _currentEquipment;
  late String _currentCategory;

  @override
  void initState() {
    super.initState();
    _currentMuscle = widget.selectedMuscle;
    _currentEquipment = widget.selectedEquipment;
    _currentCategory = widget.selectedCategory;
  }

  void _reset() {
    setState(() {
      _currentMuscle = 'All';
      _currentEquipment = 'All';
      _currentCategory = 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.velocitySurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.velocityBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Exercises',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.velocityTextPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Reset All'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 1. Muscle Filter
            const Text(
              'Target Muscle Group',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.velocityTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kMuscleOptions.map((opt) {
                final isSel = _currentMuscle == opt.name;
                return ChoiceChip(
                  label: Text(opt.name),
                  selected: isSel,
                  onSelected: (val) {
                    setState(() => _currentMuscle = opt.name);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // 2. Equipment Filter
            const Text(
              'Equipment',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.velocityTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kEquipmentOptions.map((eq) {
                final isSel = _currentEquipment == eq;
                return ChoiceChip(
                  label: Text(eq),
                  selected: isSel,
                  onSelected: (val) {
                    setState(() => _currentEquipment = eq);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // 3. Category Filter
            const Text(
              'Training Goal / Category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.velocityTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kCategoryOptions.map((cat) {
                final isSel = _currentCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSel,
                  onSelected: (val) {
                    setState(() => _currentCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Apply Button
            ElevatedButton(
              onPressed: () {
                widget.onApply(_currentMuscle, _currentEquipment, _currentCategory);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.velocityLime,
                foregroundColor: AppTheme.velocityDark,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
