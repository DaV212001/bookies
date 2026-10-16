import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:bookies/data/models/community_member.dart';
import 'package:bookies/data/models/user.dart';
import 'package:bookies/data/providers/local_data_service.dart';

class AddMemberDialog extends StatefulWidget {
  final String communityId;
  final String communityName;

  const AddMemberDialog({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  static Future<CommunityMember?> show(
    BuildContext context, {
    required String communityId,
    required String communityName,
  }) {
    return showDialog<CommunityMember>(
      context: context,
      builder: (_) => AddMemberDialog(
        communityId: communityId,
        communityName: communityName,
      ),
    );
  }

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final _searchController = TextEditingController();
  CommunityRole _selectedRole = CommunityRole.member;
  User? _selectedUser;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = context.watch<LocalDataService>();
    final available = data.getAvailableUsersToInvite(widget.communityId);
    final query = _searchController.text.trim().toLowerCase();

    final filteredUsers = available.where((u) {
      if (query.isEmpty) return true;
      return u.displayName.toLowerCase().contains(query) ||
          u.username.toLowerCase().contains(query);
    }).toList();

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.userPlus, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 10),
          const Expanded(child: Text('Add Community Reader')),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a reader to invite or add to ${widget.communityName}.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                hintText: 'Search available readers...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Text(
              'Available Readers',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: filteredUsers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          available.isEmpty
                              ? 'All registered readers are already members!'
                              : 'No readers match your search.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filteredUsers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final isSelected = _selectedUser?.id == user.id;

                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            backgroundImage: user.avatarUrl != null
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            onBackgroundImageError: (_, __) {},
                            child: user.avatarUrl == null
                                ? Text(user.displayName.isNotEmpty
                                    ? user.displayName[0].toUpperCase()
                                    : '?')
                                : null,
                          ),
                          title: Text(
                            user.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('@${user.username}'),
                          trailing: isSelected
                              ? Icon(LucideIcons.check, color: theme.colorScheme.primary, size: 18)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedUser = user;
                            });
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              'Initial Role',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(LucideIcons.bookOpen, size: 16),
                    label: const Text('Reader (Member)'),
                    selected: _selectedRole == CommunityRole.member,
                    onSelected: (val) {
                      if (val) setState(() => _selectedRole = CommunityRole.member);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(LucideIcons.shield, size: 16),
                    label: const Text('Community Admin'),
                    selected: _selectedRole == CommunityRole.admin,
                    onSelected: (val) {
                      if (val) setState(() => _selectedRole = CommunityRole.admin);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Add Member'),
          onPressed: _selectedUser == null
              ? null
              : () async {
                  final added = await data.addMember(
                    widget.communityId,
                    _selectedUser!,
                    role: _selectedRole,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop(added);
                  }
                },
        ),
      ],
    );
  }
}
