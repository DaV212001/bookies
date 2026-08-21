import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CommunityMembershipGate extends StatelessWidget {
  final String bookTitle;
  final String circleName;
  final VoidCallback onJoined;
  final VoidCallback onCreateCircle;

  const CommunityMembershipGate({
    super.key,
    required this.bookTitle,
    required this.circleName,
    required this.onJoined,
    required this.onCreateCircle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: secondary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.users,
              size: 36,
              color: secondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Join a Circle to Unlock Discussions',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chapter threads, highlighted quote discussions, and reading notes for "$bookTitle" are shared synchronously inside book circles.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onJoined,
              icon: const Icon(LucideIcons.userPlus, size: 18),
              label: Text('Join ${circleName.isNotEmpty ? circleName : "Reading Circle"}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCreateCircle,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Create New Circle for this Book'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
