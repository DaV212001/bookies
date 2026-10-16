import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bookies/data/models/community_member.dart';

class RestrictMemberDialog extends StatefulWidget {
  final CommunityMember member;
  final bool isBan;

  const RestrictMemberDialog({
    super.key,
    required this.member,
    this.isBan = false,
  });

  static Future<String?> show(
    BuildContext context, {
    required CommunityMember member,
    bool isBan = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => RestrictMemberDialog(
        member: member,
        isBan: isBan,
      ),
    );
  }

  @override
  State<RestrictMemberDialog> createState() => _RestrictMemberDialogState();
}

class _RestrictMemberDialogState extends State<RestrictMemberDialog> {
  final _reasonController = TextEditingController();

  final List<String> _quickReasons = [
    'Posting spoilers without warning',
    'Disruptive in live reading sessions',
    'Spamming off-topic messages',
    'Disrespectful community conduct',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBan = widget.isBan;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isBan ? LucideIcons.ban : LucideIcons.shieldAlert,
            color: isBan ? theme.colorScheme.error : theme.colorScheme.secondary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(isBan ? 'Ban Member' : 'Restrict Member'),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBan
                  ? 'Banning @${widget.member.user.username} will remove their access to community discussions and prevent them from attending any live reading sessions.'
                  : 'Restricting @${widget.member.user.username} prevents them from posting new threads, sending chat messages, and posting live comments in live reading sessions.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Reason for ${isBan ? 'ban' : 'restriction'}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Enter reason or select a preset below...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _quickReasons.map((reason) {
                return ActionChip(
                  label: Text(reason, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    setState(() {
                      _reasonController.text = reason;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isBan ? theme.colorScheme.error : theme.colorScheme.secondary,
            foregroundColor: isBan ? theme.colorScheme.onError : theme.colorScheme.onSecondary,
          ),
          onPressed: () {
            final reason = _reasonController.text.trim();
            Navigator.of(context).pop(
              reason.isEmpty
                  ? (isBan ? 'Violated community guidelines.' : 'Restricted by community moderator.')
                  : reason,
            );
          },
          child: Text(isBan ? 'Ban Member' : 'Apply Restriction'),
        ),
      ],
    );
  }
}
