import 'package:flutter/material.dart';
import 'package:bookies/domain/entities/live_passage_reaction.dart';

class PassageReactionBubble extends StatelessWidget {
  final LivePassageReaction reaction;
  final VoidCallback? onDismiss;

  const PassageReactionBubble({
    super.key,
    required this.reaction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reaction.emoji,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              reaction.displayName,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (reaction.quoteText != null && reaction.quoteText!.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                '• "${reaction.quoteText!.length > 20 ? '${reaction.quoteText!.substring(0, 20)}...' : reaction.quoteText}"',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class QuickPassageReactionPicker extends StatelessWidget {
  final void Function(String emoji) onEmojiSelected;

  static const List<String> availableEmojis = [
    '❤️',
    '🤯',
    '😭',
    '💡',
    '👏',
    '🔥',
  ];

  const QuickPassageReactionPicker({
    super.key,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: availableEmojis.map((emoji) {
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onEmojiSelected(emoji),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
