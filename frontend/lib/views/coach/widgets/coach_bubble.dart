import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';

class CoachChatBubble extends StatelessWidget {
  final bool isUser;
  final String content;
  final DateTime timestamp;

  const CoachChatBubble({
    super.key,
    required this.isUser,
    required this.content,
    required this.timestamp,
  });

  static final DateFormat _timeFormat = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8, bottom: 4),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2979FF), Color(0xFF00E5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    size: 16, color: Colors.white),
              ),
            ],
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser ? AppTheme.velocityLime : AppTheme.velocitySurface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  border: isUser
                      ? null
                      : Border.all(color: AppTheme.velocityBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? AppTheme.velocityLime.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUser ? AppTheme.velocityDark : AppTheme.velocityTextPrimary,
                        fontWeight: isUser ? FontWeight.w600 : FontWeight.normal,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeFormat.format(timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: isUser ? AppTheme.velocityDark.withValues(alpha: 0.6) : AppTheme.velocityTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CoachStreamingBubble extends StatelessWidget {
  final String responseText;

  const CoachStreamingBubble({
    super.key,
    required this.responseText,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2979FF), Color(0xFF00E5FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  size: 16, color: Colors.white),
            ),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.velocitySurface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(
                    color: AppTheme.velocityAccentBlue.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.velocityAccentBlue.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (responseText.isEmpty)
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Thinking...',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white60,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      )
                    else
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: responseText,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                            const TextSpan(
                              text: ' ▋',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
