import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';

/// Helper to parse basic markdown (* and **) into rich bold-italic styled spans
/// so raw asterisks are replaced with distinct, eye-pleasing typography.
class _CoachMarkdownParser {
  static final RegExp _pattern = RegExp(
    r'(\*\*\*(.+?)\*\*\*|\*\*(.+?)\*\*|__(.+?)__|\*(.+?)\*|_(.+?)_)',
    dotAll: true,
  );

  static List<InlineSpan> buildSpans({
    required String rawText,
    required TextStyle baseStyle,
    required TextStyle highlightStyle,
    required TextStyle italicStyle,
    bool isStreaming = false,
  }) {
    String textToParse = rawText;

    // In streaming mode, if in the middle of a bold sequence (odd count of **),
    // virtually close it so raw asterisks don't appear on screen while streaming.
    if (isStreaming) {
      final doubleStarCount = RegExp(r'\*\*').allMatches(textToParse).length;
      if (doubleStarCount % 2 != 0) {
        textToParse = '$textToParse**';
      }
    }

    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in _pattern.allMatches(textToParse)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: textToParse.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      final fullMatch = match.group(0)!;
      if (fullMatch.startsWith('***') && fullMatch.endsWith('***') && fullMatch.length >= 6) {
        final inner = fullMatch.substring(3, fullMatch.length - 3);
        spans.add(TextSpan(
          text: inner,
          style: highlightStyle,
        ));
      } else if ((fullMatch.startsWith('**') && fullMatch.endsWith('**') && fullMatch.length >= 4) ||
                 (fullMatch.startsWith('__') && fullMatch.endsWith('__') && fullMatch.length >= 4)) {
        final inner = fullMatch.substring(2, fullMatch.length - 2);
        spans.add(TextSpan(
          text: inner,
          style: highlightStyle,
        ));
      } else if ((fullMatch.startsWith('*') && fullMatch.endsWith('*') && fullMatch.length >= 2) ||
                 (fullMatch.startsWith('_') && fullMatch.endsWith('_') && fullMatch.length >= 2)) {
        final inner = fullMatch.substring(1, fullMatch.length - 1);
        spans.add(TextSpan(
          text: inner,
          style: italicStyle,
        ));
      } else {
        spans.add(TextSpan(text: fullMatch, style: baseStyle));
      }

      lastIndex = match.end;
    }

    if (lastIndex < textToParse.length) {
      spans.add(TextSpan(
        text: textToParse.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return spans;
  }
}

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
    // Clear, comfortable typography designed for eye comfort
    final baseStyle = TextStyle(
      fontSize: 14.5,
      color: isUser ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
      height: 1.55,
      letterSpacing: 0.2,
    );

    // Highlighted words: distinct bold italic styling with vibrant accent color
    final highlightStyle = TextStyle(
      fontSize: 14.5,
      color: isUser ? const Color(0xFF000000) : AppTheme.velocityLimeBright,
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic,
      height: 1.55,
      letterSpacing: 0.35,
    );

    final italicStyle = TextStyle(
      fontSize: 14.5,
      color: isUser ? const Color(0xFF334155) : const Color(0xFF94A3B8),
      fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
      fontStyle: FontStyle.italic,
      height: 1.55,
      letterSpacing: 0.2,
    );

    final hasMarkdown = content.contains('*') || content.contains('_');

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 10, top: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2979FF), Color(0xFF00E5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? AppTheme.velocityLime : const Color(0xFF141923),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 6),
                    bottomRight: Radius.circular(isUser ? 6 : 18),
                  ),
                  border: isUser
                      ? null
                      : Border.all(color: const Color(0xFF263244), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? AppTheme.velocityLime.withValues(alpha: 0.22)
                          : Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!hasMarkdown)
                      Text(
                        content,
                        style: baseStyle,
                      )
                    else
                      Text.rich(
                        TextSpan(
                          children: _CoachMarkdownParser.buildSpans(
                            rawText: content,
                            baseStyle: baseStyle,
                            highlightStyle: highlightStyle,
                            italicStyle: italicStyle,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      _timeFormat.format(timestamp),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isUser
                            ? const Color(0xFF334155)
                            : const Color(0xFF64748B),
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
    const baseStyle = TextStyle(
      fontSize: 14.5,
      color: Color(0xFFF1F5F9),
      fontWeight: FontWeight.w400,
      height: 1.55,
      letterSpacing: 0.2,
    );

    final highlightStyle = TextStyle(
      fontSize: 14.5,
      color: AppTheme.velocityLimeBright,
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic,
      height: 1.55,
      letterSpacing: 0.35,
    );

    const italicStyle = TextStyle(
      fontSize: 14.5,
      color: Color(0xFF94A3B8),
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
      height: 1.55,
      letterSpacing: 0.2,
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 10, top: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2979FF), Color(0xFF00E5FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141923),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      blurRadius: 10,
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
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Formulating advice...',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF94A3B8),
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      )
                    else
                      Text.rich(
                        TextSpan(
                          children: [
                            ..._CoachMarkdownParser.buildSpans(
                              rawText: responseText,
                              baseStyle: baseStyle,
                              highlightStyle: highlightStyle,
                              italicStyle: italicStyle,
                              isStreaming: true,
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

