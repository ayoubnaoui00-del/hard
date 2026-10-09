import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../providers/chat_provider.dart';

class CoachCreateConversationDialog extends ConsumerStatefulWidget {
  const CoachCreateConversationDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const CoachCreateConversationDialog(),
    );
  }

  @override
  ConsumerState<CoachCreateConversationDialog> createState() =>
      _CoachCreateConversationDialogState();
}

class _CoachCreateConversationDialogState
    extends ConsumerState<CoachCreateConversationDialog> {
  final TextEditingController _titleController = TextEditingController();
  String _selectedTopic = 'Workout Plan';

  final List<String> _topics = const [
    'Workout Plan',
    'Form Tips',
    'Nutrition & Recovery',
    'Progression & 1RM',
    'General Fitness',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.velocitySurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.velocityBorder, width: 1.2),
      ),
      title: const Text(
        'Start New Conversation',
        style: TextStyle(
          color: AppTheme.velocityTextPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Topic',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _topics.map((topic) {
                final isSelected = _selectedTopic == topic;
                return ChoiceChip(
                  label: Text(
                    topic,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppTheme.velocityDark : AppTheme.velocityTextPrimary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.velocityLime,
                  backgroundColor: AppTheme.velocitySurfaceMuted,
                  side: BorderSide(
                    color: isSelected ? AppTheme.velocityLime : AppTheme.velocityBorder,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedTopic = topic);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const Text('Custom Title (Optional)',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Chest Hypertrophy Focus',
                hintStyle:
                    const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF282838),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.velocityTextSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.velocityLime,
            foregroundColor: AppTheme.velocityDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            final title = _titleController.text.trim().isNotEmpty
                ? _titleController.text.trim()
                : _selectedTopic;
            ref.read(chatViewModelProvider.notifier).createConversation(
                  title: title,
                  topic: _selectedTopic,
                );
            Navigator.of(context).pop();
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
