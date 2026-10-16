import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/discussion.dart';

class DiscussionDetailsSheet extends StatelessWidget {
  final List<Discussion> discussions;
  final String? communityName;
  final VoidCallback onOpenFullDiscussion;

  const DiscussionDetailsSheet({
    super.key,
    required this.discussions,
    this.communityName,
    required this.onOpenFullDiscussion,
  });

  int _computeTotalCount() {
    if (discussions.isEmpty) return 1;
    var count = 0;
    for (final d in discussions) {
      count += 1;
      if (d.replies != null) {
        count += d.replies!.length;
      }
    }
    return count > 0 ? count : 1;
  }

  // 6 Heat tiers suited for a large-scale reading platform
  int _heatTier(int count) {
    if (count <= 2) return 1;
    if (count <= 9) return 2;
    if (count <= 29) return 3;
    if (count <= 99) return 4;
    if (count <= 499) return 5;
    return 6;
  }

  Color _heatColor(int tier) {
    switch (tier) {
      case 1:
        return const Color(0xFFFD8A42).withValues(alpha: 0.50);
      case 2:
        return const Color(0xFFF57828).withValues(alpha: 0.70);
      case 3:
        return const Color(0xFFEB6419).withValues(alpha: 0.85);
      case 4:
        return const Color(0xFFDC550C);
      case 5:
        return const Color(0xFFC2410C);
      case 6:
      default:
        return const Color(0xFFEA580C);
    }
  }

  String _heatLabel(int tier) {
    switch (tier) {
      case 1:
        return 'Quiet Thread';
      case 2:
        return 'Active Discussion';
      case 3:
        return 'Popular Conversation';
      case 4:
        return 'Trending Thread';
      case 5:
        return 'Viral Discussion';
      case 6:
      default:
        return 'Mega Thread';
    }
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }

  Discussion? _findLatestDiscussion() {
    if (discussions.isEmpty) return null;
    Discussion? latest;
    for (final d in discussions) {
      if (latest == null || d.createdAt.isAfter(latest.createdAt)) {
        latest = d;
      }
      if (d.replies != null) {
        for (final r in d.replies!) {
          if (latest == null || r.createdAt.isAfter(latest.createdAt)) {
            latest = r;
          }
        }
      }
    }
    return latest;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalCount = _computeTotalCount();
    final tier = _heatTier(totalCount);
    final heatColor = _heatColor(tier);
    final heatLabel = _heatLabel(tier);
    final latestDiscussion = _findLatestDiscussion();

    return Container(
      constraints: const BoxConstraints(maxWidth: AppSpacing.containerMax),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            AppSpacing.s,
            AppSpacing.m,
            AppSpacing.m,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.s),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),

              // Header: Heat Badge chip & Close button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: heatColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: heatColor.withValues(alpha: 0.40),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tier >= 4
                              ? LucideIcons.flame
                              : LucideIcons.messageSquare,
                          size: 14,
                          color: heatColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$totalCount ${totalCount == 1 ? 'chat' : 'chats'}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: heatColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '• $heatLabel',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              if (communityName != null && communityName!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      LucideIcons.users,
                      size: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        communityName!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.m),

              // Latest comment snippet card
              if (latestDiscussion != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.s + 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: heatColor.withValues(alpha: 0.2),
                            child: Text(
                              (latestDiscussion.user?.displayName.isNotEmpty ==
                                      true)
                                  ? latestDiscussion.user!.displayName[0]
                                      .toUpperCase()
                                  : (latestDiscussion.user?.username.isNotEmpty ==
                                          true)
                                      ? latestDiscussion.user!.username[0]
                                          .toUpperCase()
                                      : 'U',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: heatColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              latestDiscussion.user?.displayName ??
                                  latestDiscussion.user?.username ??
                                  'Community Member',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatRelativeTime(latestDiscussion.createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        latestDiscussion.content,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (totalCount > 1) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '+${totalCount - 1} more ${totalCount - 1 == 1 ? 'message' : 'messages'} in this discussion',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      'Tap below to open or join this discussion.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.m),

              // Action button to open full thread
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: totalCount > 1
                      ? 'Open Discussion ($totalCount chats)'
                      : 'Open Discussion',
                  onPressed: () {
                    Navigator.of(context).pop();
                    onOpenFullDiscussion();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
