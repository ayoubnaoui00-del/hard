import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../providers/chat_provider.dart';

class CoachConversationDrawerSheet extends ConsumerWidget {
  const CoachConversationDrawerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const CoachConversationDrawerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatViewModelProvider);
    final viewModel = ref.read(chatViewModelProvider.notifier);

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.velocitySurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.velocityBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Coaching Conversations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.velocityTextPrimary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    viewModel.resetToNewChat();
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('New Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.velocityLime,
                    foregroundColor: AppTheme.velocityDark,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: chatState.conversations.isEmpty
                  ? const Center(
                      child: Text(
                        'No previous conversations yet.',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      itemCount: chatState.conversations.length,
                      itemBuilder: (context, index) {
                        final conv = chatState.conversations[index];
                        final isSelected =
                            chatState.currentConversation?.id == conv.id;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Material(
                            color: isSelected
                                ? AppTheme.velocityLime.withValues(alpha: 0.12)
                                : AppTheme.velocitySurfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.velocityLime
                                      : AppTheme.velocityBorder,
                                  width: isSelected ? 1.4 : 1.0,
                                ),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: isSelected
                                      ? const Color(0xFF2979FF)
                                      : Colors.white54,
                                  size: 20,
                                ),
                                title: Text(
                                  conv.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  conv.topic ?? 'General Advice',
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 12),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: Colors.white38, size: 18),
                                  onPressed: () =>
                                      viewModel.deleteConversation(conv.id),
                                ),
                                onTap: () {
                                  viewModel.selectConversation(conv);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
