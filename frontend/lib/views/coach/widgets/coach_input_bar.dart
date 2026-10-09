import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class CoachInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isStreaming;
  final VoidCallback onSend;

  const CoachInputBar({
    super.key,
    required this.controller,
    required this.isStreaming,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppTheme.velocitySurface,
        border: Border(
          top: BorderSide(color: AppTheme.velocityBorder, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.velocitySurfaceMuted,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.velocityBorder),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 4,
                  minLines: 1,
                  enabled: !isStreaming,
                  style: const TextStyle(color: AppTheme.velocityTextPrimary, fontSize: 14),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Ask coach about workouts, sets, form...',
                    hintStyle: TextStyle(color: AppTheme.velocityTextMuted, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: isStreaming ? null : (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: isStreaming
                    ? AppTheme.velocitySurfaceMuted
                    : AppTheme.velocityLime,
                shape: BoxShape.circle,
                boxShadow: [
                  if (!isStreaming)
                    BoxShadow(
                      color: AppTheme.velocityLime.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: IconButton(
                onPressed: isStreaming ? null : onSend,
                icon: isStreaming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.velocityTextMuted,
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        color: AppTheme.velocityDark, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
