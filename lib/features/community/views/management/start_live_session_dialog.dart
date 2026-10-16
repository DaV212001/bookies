import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:bookies/data/models/live_reading_session.dart';
import 'package:bookies/data/providers/local_data_service.dart';

class StartLiveSessionDialog extends StatefulWidget {
  final String communityId;
  final String bookId;
  final String communityName;

  const StartLiveSessionDialog({
    super.key,
    required this.communityId,
    required this.bookId,
    required this.communityName,
  });

  static Future<LiveReadingSession?> show(
    BuildContext context, {
    required String communityId,
    required String bookId,
    required String communityName,
  }) {
    return showDialog<LiveReadingSession>(
      context: context,
      builder: (_) => StartLiveSessionDialog(
        communityId: communityId,
        bookId: bookId,
        communityName: communityName,
      ),
    );
  }

  @override
  State<StartLiveSessionDialog> createState() => _StartLiveSessionDialogState();
}

class _StartLiveSessionDialogState extends State<StartLiveSessionDialog> {
  final _titleController = TextEditingController(text: 'Live Book Reading & Discussion');
  final _chapterController = TextEditingController(text: 'Chapter 1');
  LiveReadingAccessMode _accessMode = LiveReadingAccessMode.allMembers;
  final Set<String> _selectedAllowedUserIds = {};

  @override
  void dispose() {
    _titleController.dispose();
    _chapterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = context.watch<LocalDataService>();
    final activeMembers = data
        .getCommunityMembers(widget.communityId)
        .where((m) => !m.isBanned && !m.isRestricted && m.user.id != data.currentUser.id)
        .toList();

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.radio, color: Colors.redAccent, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('Start Live Reading')),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Initiate a synchronized live reading session for ${widget.communityName}. Members can follow your reading location in real time.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Session Title',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g. Chapter 1 Deep Dive',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Starting Chapter / Topic',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _chapterController,
                decoration: InputDecoration(
                  hintText: 'e.g. Chapter 1: The Gathering',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Who can join this session?',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RadioGroup<LiveReadingAccessMode>(
                groupValue: _accessMode,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _accessMode = val;
                      if (val == LiveReadingAccessMode.custom &&
                          _selectedAllowedUserIds.isEmpty) {
                        _selectedAllowedUserIds
                            .addAll(activeMembers.map((m) => m.user.id));
                      }
                    });
                  }
                },
                child: Column(
                  children: LiveReadingAccessMode.values.map((mode) {
                    return RadioListTile<LiveReadingAccessMode>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(mode.label,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        mode.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: mode,
                    );
                  }).toList(),
                ),
              ),
              if (_accessMode == LiveReadingAccessMode.custom) ...[
                const SizedBox(height: 8),
                Text(
                  'Select Invited Readers (${_selectedAllowedUserIds.length} allowed)',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: activeMembers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final member = activeMembers[i];
                      final isSelected = _selectedAllowedUserIds.contains(member.user.id);

                      return CheckboxListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        title: Text(member.user.displayName, style: const TextStyle(fontSize: 14)),
                        subtitle: Text('@${member.user.username}', style: const TextStyle(fontSize: 12)),
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedAllowedUserIds.add(member.user.id);
                            } else {
                              _selectedAllowedUserIds.remove(member.user.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(LucideIcons.radio, size: 16),
          label: const Text('Launch Session'),
          onPressed: () async {
            final title = _titleController.text.trim();
            final session = await data.startLiveReadingSession(
              communityId: widget.communityId,
              bookId: widget.bookId,
              title: title.isEmpty ? 'Live Reading Session' : title,
              chapterTitle: _chapterController.text.trim(),
              accessMode: _accessMode,
              allowedUserIds: _selectedAllowedUserIds,
            );
            if (context.mounted) {
              Navigator.of(context).pop(session);
            }
          },
        ),
      ],
    );
  }
}
