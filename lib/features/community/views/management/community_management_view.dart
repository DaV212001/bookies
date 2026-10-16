import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:bookies/core/widgets/create_community_dialog.dart';
import 'package:bookies/core/widgets/responsive_text.dart';
import 'package:bookies/data/models/community_member.dart';
import 'package:bookies/data/models/live_reading_session.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/features/community/views/community_detail_view.dart';
import 'add_member_dialog.dart';
import 'edit_permissions_dialog.dart';
import 'restrict_member_dialog.dart';
import 'start_live_session_dialog.dart';

class CommunityManagementView extends StatefulWidget {
  final String communityId;
  final String communityName;
  final String bookId;

  const CommunityManagementView({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.bookId,
  });

  @override
  State<CommunityManagementView> createState() => _CommunityManagementViewState();
}

class _CommunityManagementViewState extends State<CommunityManagementView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  CommunityRole? _roleFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAddMemberDialog() async {
    final added = await AddMemberDialog.show(
      context,
      communityId: widget.communityId,
      communityName: widget.communityName,
    );
    if (added != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${added.user.displayName} to community.')),
      );
      setState(() {});
    }
  }

  void _openStartLiveSessionDialog() async {
    final session = await StartLiveSessionDialog.show(
      context,
      communityId: widget.communityId,
      bookId: widget.bookId,
      communityName: widget.communityName,
    );
    if (session != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Live reading session "${session.title}" started!')),
      );
      _tabController.animateTo(1);
      setState(() {});
    }
  }

  Future<void> _openExportToNewBookDialog() async {
    final created = await CreateCommunityDialog.show(
      context,
      initialSourceCommunityId: widget.communityId,
    );
    if (created != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created "${created.name}" with roster from ${widget.communityName}!'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CommunityDetailView(
                    bookId: created.bookId,
                    communityId: created.id,
                    communityName: created.name,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> _openImportReadersDialog() async {
    final data = context.read<LocalDataService>();
    final otherCommunities = data.communities
        .where((c) => c.id != widget.communityId && data.canManageCommunity(c.id))
        .toList();

    if (otherCommunities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other communities available to import readers from.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String? selectedCommId = otherCommunities.first.id;
    bool copyRoles = true;
    bool skipRestricted = true;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          return AlertDialog(
            title: const Row(
              children: [
                Icon(LucideIcons.users, size: 20),
                SizedBox(width: 8),
                Text('Import Readers'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a community to import active members into "${widget.communityName}":',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCommId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: otherCommunities.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.name} (${c.memberCount} readers)'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedCommId = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: const Text('Preserve Admin roles'),
                  value: copyRoles,
                  onChanged: (val) => setDialogState(() => copyRoles = val ?? true),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: const Text('Exclude banned & restricted'),
                  value: skipRestricted,
                  onChanged: (val) => setDialogState(() => skipRestricted = val ?? true),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  if (selectedCommId != null) {
                    final imported = await data.importMembers(
                      targetCommunityId: widget.communityId,
                      sourceCommunityId: selectedCommId!,
                      copyRoles: copyRoles,
                      skipRestrictedOrBanned: skipRestricted,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Imported $imported reader${imported == 1 ? '' : 's'} successfully!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Import'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMemberActionSheet(CommunityMember member) {
    final data = context.read<LocalDataService>();
    final isMe = member.user.id == data.currentUser.id;
    final isCreator = member.isCreator;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: member.user.avatarUrl != null
                        ? NetworkImage(member.user.avatarUrl!)
                        : null,
                    onBackgroundImageError: (_, __) {},
                    child: member.user.avatarUrl == null
                        ? Text(member.user.displayName[0].toUpperCase())
                        : null,
                  ),
                  title: Text(member.user.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '@${member.user.username} • ${member.role.label} (${member.status.label})'),
                ),
                const Divider(),
                if (!isMe && !isCreator) ...[
                  // Role promotion / demotion
                  if (member.role == CommunityRole.admin)
                    ListTile(
                      leading: const Icon(LucideIcons.userMinus),
                      title: const Text('Demote to Reader'),
                      subtitle: const Text('Remove administrative privileges'),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await data.updateMemberRole(
                          widget.communityId,
                          member.user.id,
                          CommunityRole.member,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Demoted ${member.user.displayName} to Reader.')),
                          );
                        }
                      },
                    )
                  else
                    ListTile(
                      leading: const Icon(LucideIcons.shieldCheck),
                      title: const Text('Promote to Community Admin'),
                      subtitle: const Text('Grant moderation and session management rights'),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await data.updateMemberRole(
                          widget.communityId,
                          member.user.id,
                          CommunityRole.admin,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Promoted ${member.user.displayName} to Admin.')),
                          );
                        }
                      },
                    ),
                  // Edit Permissions
                  ListTile(
                    leading: const Icon(LucideIcons.sliders),
                    title: const Text('Edit Permissions'),
                    subtitle: const Text('Fine-tune live reading, discussions, and commenting rights'),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final updated = await EditPermissionsDialog.show(
                        context,
                        member: member,
                      );
                      if (updated == true && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Permissions updated for ${member.user.displayName}.')),
                        );
                      }
                    },
                  ),
                  // Restriction
                  if (member.isRestricted)
                    ListTile(
                      leading: const Icon(LucideIcons.shieldAlert),
                      title: const Text('Lift Restriction'),
                      subtitle: const Text('Restore full participation privileges'),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await data.unrestrictMember(widget.communityId, member.user.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Restriction lifted for ${member.user.displayName}.')),
                          );
                        }
                      },
                    )
                  else
                    ListTile(
                      leading: const Icon(LucideIcons.shieldAlert),
                      title: const Text('Restrict Reader'),
                      subtitle: const Text('Prevent discussion posts and commenting in live sessions'),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        final reason = await RestrictMemberDialog.show(
                          context,
                          member: member,
                          isBan: false,
                        );
                        if (reason != null) {
                          await data.restrictMember(
                            widget.communityId,
                            member.user.id,
                            reason: reason,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Restricted ${member.user.displayName}.')),
                            );
                          }
                        }
                      },
                    ),
                  // Ban / Unban
                  if (member.isBanned)
                    ListTile(
                      leading: const Icon(LucideIcons.userCheck),
                      title: const Text('Unban Reader'),
                      subtitle: const Text('Allow member back into the community'),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await data.unbanMember(widget.communityId, member.user.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Unbanned ${member.user.displayName}.')),
                          );
                        }
                      },
                    )
                  else
                    ListTile(
                      leading: Icon(LucideIcons.ban, color: theme.colorScheme.error),
                      title: Text('Ban Reader', style: TextStyle(color: theme.colorScheme.error)),
                      subtitle: const Text('Block from accessing discussions and live sessions'),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        final reason = await RestrictMemberDialog.show(
                          context,
                          member: member,
                          isBan: true,
                        );
                        if (reason != null) {
                          await data.banMember(
                            widget.communityId,
                            member.user.id,
                            reason: reason,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Banned ${member.user.displayName}.')),
                            );
                          }
                        }
                      },
                    ),
                  // Remove / Kick
                  ListTile(
                    leading: Icon(LucideIcons.userX, color: theme.colorScheme.error),
                    title: Text('Remove from Community',
                        style: TextStyle(color: theme.colorScheme.error)),
                    subtitle: const Text('Remove reader from community membership'),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remove Member?'),
                          content: Text(
                              'Are you sure you want to remove ${member.user.displayName} from ${widget.communityName}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await data.removeMember(widget.communityId, member.user.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Removed ${member.user.displayName}.')),
                          );
                        }
                      }
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(LucideIcons.info),
                    title: const Text('Community Creator / Self'),
                    subtitle: const Text('Creator rights and personal settings cannot be altered here.'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = context.watch<LocalDataService>();
    final canManage = data.canManageCommunity(widget.communityId);
    final allMembers = data.getCommunityMembers(widget.communityId);
    final activeLiveSession = data.getActiveLiveReadingSession(widget.communityId);

    if (!canManage) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reader Management'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.shieldOff, size: 56, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Access Restricted',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Only the community creator and designated administrators have access to reader management and live reading controls.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Return to Community'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final adminCount = allMembers.where((m) => m.isAdmin && !m.isBanned).length;
    final restrictedCount = allMembers.where((m) => m.isRestricted).length;
    final bannedCount = allMembers.where((m) => m.isBanned).length;
    final activeCount = allMembers.where((m) => !m.isBanned).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reader Management'),
            ResponsiveText.label(
              widget.communityName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              minFontSize: 10,
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.crown, size: 14, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 5),
                Text(
                  'Creator Mode',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.ellipsisVertical),
            tooltip: 'Club Options',
            onSelected: (val) {
              if (val == 'export_to_new_book') {
                _openExportToNewBookDialog();
              } else if (val == 'import_readers') {
                _openImportReadersDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_to_new_book',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.bookPlus, size: 18),
                    SizedBox(width: 10),
                    Expanded(child: Text('Start Next Book Forum')),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import_readers',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.users, size: 18),
                    SizedBox(width: 10),
                    Expanded(child: Text('Import Readers from Club...')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabAlignment: TabAlignment.center,
          isScrollable: true,
          tabs: [
            Tab(
              icon: const Icon(LucideIcons.users, size: 18),
              text: 'Readers ($activeCount)',
            ),
            Tab(
              icon: Icon(
                LucideIcons.radio,
                size: 18,
                color: activeLiveSession != null ? Colors.redAccent : null,
              ),
              text: activeLiveSession != null ? 'Live (Active)' : 'Live Reading',
            ),
            Tab(
              icon: const Icon(LucideIcons.shieldAlert, size: 18),
              text: 'Moderation (${restrictedCount + bannedCount})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReadersTab(theme, data, allMembers, adminCount, activeCount),
          _buildLiveReadingTab(theme, data, activeLiveSession, allMembers),
          _buildModerationTab(theme, data, allMembers),
        ],
      ),
    );
  }

  Widget _buildReadersTab(
    ThemeData theme,
    LocalDataService data,
    List<CommunityMember> allMembers,
    int adminCount,
    int activeCount,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = allMembers.where((m) {
      if (m.isBanned) return false;
      if (_roleFilter != null && m.role != _roleFilter) return false;
      if (query.isNotEmpty) {
        return m.user.displayName.toLowerCase().contains(query) ||
            m.user.username.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Dedicated full-width search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              hintText: 'Search readers...',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        // Dedicated action toolbar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(LucideIcons.userPlus, size: 16),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Add Member'),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _openAddMemberDialog,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.bookPlus, size: 16),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Next Book'),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _openExportToNewBookDialog,
                ),
              ),
            ],
          ),
        ),
        // Role filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              ChoiceChip(
                label: Text('All Readers ($activeCount)'),
                selected: _roleFilter == null,
                onSelected: (_) => setState(() => _roleFilter = null),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                avatar: const Icon(LucideIcons.shieldCheck, size: 14),
                label: Text('Admins & Creator ($adminCount)'),
                selected: _roleFilter == CommunityRole.admin,
                onSelected: (_) => setState(() => _roleFilter = CommunityRole.admin),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                avatar: const Icon(LucideIcons.bookOpen, size: 14),
                label: Text('Standard Readers (${activeCount - adminCount})'),
                selected: _roleFilter == CommunityRole.member,
                onSelected: (_) => setState(() => _roleFilter = CommunityRole.member),
              ),
            ],
          ),
        ),
        const Divider(height: 16),
        // Readers list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.userSearch, size: 40, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(
                        'No readers found',
                        style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final member = filtered[index];
                    final isMe = member.user.id == data.currentUser.id;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: member.user.avatarUrl != null
                            ? NetworkImage(member.user.avatarUrl!)
                            : null,
                        onBackgroundImageError: (_, __) {},
                        child: member.user.avatarUrl == null
                            ? Text(member.user.displayName[0].toUpperCase())
                            : null,
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: ResponsiveText.title(
                              member.user.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              minFontSize: 13,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'You',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('@${member.user.username}'),
                          _buildRoleBadge(theme, member.role),
                          if (member.isRestricted) _buildStatusBadge(theme, member.status),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.moreVertical, size: 18),
                        tooltip: 'Member Options',
                        onPressed: () => _showMemberActionSheet(member),
                      ),
                      onTap: () => _showMemberActionSheet(member),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(ThemeData theme, CommunityRole role) {
    Color bg;
    Color fg;
    IconData icon;

    switch (role) {
      case CommunityRole.creator:
        bg = Colors.amber.withValues(alpha: 0.18);
        fg = Colors.amber.shade900;
        icon = LucideIcons.crown;
        break;
      case CommunityRole.admin:
        bg = theme.colorScheme.primaryContainer;
        fg = theme.colorScheme.primary;
        icon = LucideIcons.shield;
        break;
      case CommunityRole.member:
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
        icon = LucideIcons.bookOpen;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            role.label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, CommunityMemberStatus status) {
    if (status == CommunityMemberStatus.active) return const SizedBox.shrink();

    final isBan = status == CommunityMemberStatus.banned;
    final bg = isBan
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.5)
        : Colors.amber.withValues(alpha: 0.2);
    final fg = isBan ? theme.colorScheme.error : Colors.amber.shade900;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildLiveReadingTab(
    ThemeData theme,
    LocalDataService data,
    LiveReadingSession? activeSession,
    List<CommunityMember> allMembers,
  ) {
    final activeMembers = allMembers.where((m) => !m.isBanned).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Session Banner Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: activeSession != null
                    ? [
                        theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                        theme.colorScheme.surfaceContainerLow,
                      ]
                    : [
                        theme.colorScheme.surfaceContainerLow,
                        theme.colorScheme.surfaceContainerLowest,
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: activeSession != null
                    ? Colors.redAccent.withValues(alpha: 0.5)
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: activeSession != null ? Colors.redAccent : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      activeSession != null ? 'LIVE READING ACTIVE' : 'NO ACTIVE SESSION',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: activeSession != null ? Colors.redAccent : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (activeSession != null) ...[
                  Text(
                    activeSession.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hosted by ${activeSession.host.displayName} • ${activeSession.chapterTitle ?? 'Reading in sync'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(LucideIcons.users, size: 14),
                        label: Text('${activeSession.participantUserIds.length} attending'),
                      ),
                      Chip(
                        avatar: const Icon(LucideIcons.lock, size: 14),
                        label: Text(activeSession.accessMode.label),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        ),
                        icon: const Icon(LucideIcons.phoneOff, size: 16),
                        label: const Text('End Session'),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('End Live Reading?'),
                              content: const Text('This will close the synchronized session for all participants.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('End Session'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await data.endLiveReadingSession(widget.communityId);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Live reading session ended.')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'Host a Live Reading Room',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Synchronize pages, host group discussions, and invite readers to read through chapters together.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    icon: const Icon(LucideIcons.radio, size: 16),
                    label: const Text('Start Live Reading Session'),
                    onPressed: _openStartLiveSessionDialog,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Live Reading Access & Discussion Controls',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Control who among community members can attend live reading sessions and post live comments.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),

          // Member commenting toggles
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeMembers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = activeMembers[index];
                final canComment = member.hasPermission(CommunityPermission.commentInLiveReading);
                final canJoin = member.hasPermission(CommunityPermission.joinLiveReading);

                return ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundImage: member.user.avatarUrl != null
                        ? NetworkImage(member.user.avatarUrl!)
                        : null,
                    onBackgroundImageError: (_, __) {},
                    child: member.user.avatarUrl == null
                        ? Text(member.user.displayName[0].toUpperCase())
                        : null,
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.user.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildRoleBadge(theme, member.role),
                    ],
                  ),
                  subtitle: Text(
                    canComment ? 'Live comments enabled' : 'Silent reader (read along)',
                    style: TextStyle(
                      fontSize: 12,
                      color: canComment ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: member.isCreator
                      ? const Icon(LucideIcons.messageSquare, size: 18, color: Colors.green)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: canComment ? 'Disable live comments' : 'Enable live comments',
                              icon: Icon(
                                canComment ? LucideIcons.messageSquare : LucideIcons.messageSquareOff,
                                size: 18,
                                color: canComment ? theme.colorScheme.primary : theme.colorScheme.outline,
                              ),
                              onPressed: member.isRestricted
                                  ? null
                                  : () async {
                                      final currentPermissions = member.customPermissions ??
                                          CommunityPermission.values
                                              .where((p) => member.hasPermission(p))
                                              .toSet();
                                      final updated = Set<CommunityPermission>.from(currentPermissions);
                                      if (canComment) {
                                        updated.remove(CommunityPermission.commentInLiveReading);
                                      } else {
                                        updated.add(CommunityPermission.commentInLiveReading);
                                      }
                                      await data.updateMemberPermissions(
                                        widget.communityId,
                                        member.user.id,
                                        updated,
                                      );
                                    },
                            ),
                            IconButton(
                              tooltip: canJoin ? 'Revoke live access' : 'Grant live access',
                              icon: Icon(
                                canJoin ? LucideIcons.userCheck : LucideIcons.userX,
                                size: 18,
                                color: canJoin ? Colors.green : Colors.red,
                              ),
                              onPressed: member.isRestricted
                                  ? null
                                  : () async {
                                      final currentPermissions = member.customPermissions ??
                                          CommunityPermission.values
                                              .where((p) => member.hasPermission(p))
                                              .toSet();
                                      final updated = Set<CommunityPermission>.from(currentPermissions);
                                      if (canJoin) {
                                        updated.remove(CommunityPermission.joinLiveReading);
                                      } else {
                                        updated.add(CommunityPermission.joinLiveReading);
                                      }
                                      await data.updateMemberPermissions(
                                        widget.communityId,
                                        member.user.id,
                                        updated,
                                      );
                                    },
                            ),
                          ],
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModerationTab(
    ThemeData theme,
    LocalDataService data,
    List<CommunityMember> allMembers,
  ) {
    final sanctioned = allMembers.where((m) => m.isRestricted || m.isBanned).toList();

    if (sanctioned.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.shieldCheck, size: 52, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Community In Good Standing',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'No readers are currently restricted or banned in ${widget.communityName}.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sanctioned.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final member = sanctioned[index];
        final isBan = member.isBanned;

        return Card(
          elevation: 0,
          color: isBan
              ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
              : Colors.amber.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isBan
                  ? theme.colorScheme.error.withValues(alpha: 0.4)
                  : Colors.amber.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: member.user.avatarUrl != null
                          ? NetworkImage(member.user.avatarUrl!)
                          : null,
                      onBackgroundImageError: (_, __) {},
                      child: member.user.avatarUrl == null
                          ? Text(member.user.displayName[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.user.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('@${member.user.username}'),
                        ],
                      ),
                    ),
                    _buildStatusBadge(theme, member.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Reason:',
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  member.restrictionReason ?? 'No reason recorded.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isBan)
                      FilledButton.icon(
                        icon: const Icon(LucideIcons.userCheck, size: 16),
                        label: const Text('Unban Reader'),
                        onPressed: () async {
                          await data.unbanMember(widget.communityId, member.user.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Unbanned ${member.user.displayName}.')),
                            );
                          }
                        },
                      )
                    else
                      FilledButton.icon(
                        icon: const Icon(LucideIcons.shieldAlert, size: 16),
                        label: const Text('Lift Restriction'),
                        onPressed: () async {
                          await data.unrestrictMember(widget.communityId, member.user.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Restriction lifted for ${member.user.displayName}.')),
                            );
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
