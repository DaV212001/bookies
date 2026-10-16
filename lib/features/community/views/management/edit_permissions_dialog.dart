import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:bookies/data/models/community_member.dart';
import 'package:bookies/data/providers/local_data_service.dart';

class EditPermissionsDialog extends StatefulWidget {
  final CommunityMember member;

  const EditPermissionsDialog({
    super.key,
    required this.member,
  });

  static Future<bool?> show(
    BuildContext context, {
    required CommunityMember member,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => EditPermissionsDialog(member: member),
    );
  }

  @override
  State<EditPermissionsDialog> createState() => _EditPermissionsDialogState();
}

class _EditPermissionsDialogState extends State<EditPermissionsDialog> {
  late Set<CommunityPermission> _permissions;
  bool _isCustom = false;

  @override
  void initState() {
    super.initState();
    _isCustom = widget.member.customPermissions != null;
    _permissions = widget.member.customPermissions != null
        ? Set.from(widget.member.customPermissions!)
        : CommunityPermission.values
            .where((p) => widget.member.hasPermission(p))
            .toSet();
  }

  void _resetToDefaults() {
    setState(() {
      _isCustom = false;
      _permissions = CommunityPermission.values.where((p) {
        switch (widget.member.role) {
          case CommunityRole.creator:
          case CommunityRole.admin:
            return true;
          case CommunityRole.member:
            return p == CommunityPermission.joinLiveReading ||
                p == CommunityPermission.commentInLiveReading ||
                p == CommunityPermission.createThreads ||
                p == CommunityPermission.postReplies;
        }
      }).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final member = widget.member;

    final categories = <String, List<CommunityPermission>>{};
    for (final p in CommunityPermission.values) {
      categories.putIfAbsent(p.category, () => []).add(p);
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.shieldCheck, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Permissions: ${member.user.displayName}', style: theme.textTheme.titleMedium),
                Text(
                  'Role: ${member.role.label} (${_isCustom ? 'Custom overrides' : 'Role defaults'})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (member.isRestricted) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.shieldAlert, color: theme.colorScheme.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Note: This member is restricted (${member.restrictionReason ?? 'No reason provided'}). '
                          'Discussion posting and live comment permissions remain suppressed while restricted.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              ...categories.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                      child: Text(
                        entry.key.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    ...entry.value.map((permission) {
                      final isGranted = _permissions.contains(permission);
                      return SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(
                          permission.label,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          permission.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        value: isGranted,
                        onChanged: member.isCreator
                            ? null
                            : (val) {
                                setState(() {
                                  _isCustom = true;
                                  if (val) {
                                    _permissions.add(permission);
                                  } else {
                                    _permissions.remove(permission);
                                  }
                                });
                              },
                      );
                    }),
                    const Divider(height: 18),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        if (!member.isCreator)
          TextButton(
            onPressed: _resetToDefaults,
            child: const Text('Reset to Defaults'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: member.isCreator
              ? () => Navigator.of(context).pop(false)
              : () async {
                  final data = context.read<LocalDataService>();
                  await data.updateMemberPermissions(
                    widget.member.communityId,
                    widget.member.user.id,
                    _isCustom ? _permissions : null,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
          child: const Text('Save Permissions'),
        ),
      ],
    );
  }
}
