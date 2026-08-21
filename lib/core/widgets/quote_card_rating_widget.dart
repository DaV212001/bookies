import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bookies/data/models/quote_rating.dart';

class QuoteCardRatingWidget extends StatelessWidget {
  final QuoteRating quote;
  final VoidCallback onUpvote;

  const QuoteCardRatingWidget({
    super.key,
    required this.quote,
    required this.onUpvote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quote Icon Header & Chapter Source
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.quote,
                    size: 16,
                    color: Color(0xFFB45309), // Ochre
                  ),
                  const SizedBox(width: 6),
                  Text(
                    quote.chapterTitle,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFB45309),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(LucideIcons.star, size: 14, color: Colors.amber[700]),
                  const SizedBox(width: 4),
                  Text(
                    quote.averageRating.toStringAsFixed(1),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quote Body (Literata serif style)
          Text(
            '"${quote.quoteText}"',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Footer: Author attribution, Saved By user & Upvote Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '— ${quote.authorName} (shared by ${quote.addedByUsername})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              InkWell(
                onTap: onUpvote,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: quote.isUpvotedByMe
                        ? const Color(0xFFB45309).withOpacity(0.15)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: quote.isUpvotedByMe
                          ? const Color(0xFFB45309)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        quote.isUpvotedByMe ? LucideIcons.heartHandshake : LucideIcons.heart,
                        size: 14,
                        color: quote.isUpvotedByMe
                            ? const Color(0xFFB45309)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${quote.upvotes}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: quote.isUpvotedByMe
                              ? const Color(0xFFB45309)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
