import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bookies/data/models/book.dart';
import 'package:bookies/data/models/community.dart';
import 'package:bookies/data/providers/local_data_service.dart';

class CreateCommunityDialog extends StatefulWidget {
  final Book? preselectedBook;
  final List<Book> availableBooks;
  final String? initialSourceCommunityId;

  const CreateCommunityDialog({
    super.key,
    this.preselectedBook,
    this.availableBooks = const [],
    this.initialSourceCommunityId,
  });

  static Future<Community?> show(
    BuildContext context, {
    Book? book,
    List<Book> availableBooks = const [],
    String? initialSourceCommunityId,
  }) {
    return showDialog<Community>(
      context: context,
      builder: (context) => CreateCommunityDialog(
        preselectedBook: book,
        availableBooks: availableBooks,
        initialSourceCommunityId: initialSourceCommunityId,
      ),
    );
  }

  @override
  State<CreateCommunityDialog> createState() => _CreateCommunityDialogState();
}

class _CreateCommunityDialogState extends State<CreateCommunityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  Book? _selectedBook;
  String? _selectedSourceCommunityId;
  bool _copyRoles = true;
  bool _skipRestricted = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _selectedBook = widget.preselectedBook;
    _selectedSourceCommunityId = widget.initialSourceCommunityId;
    if (_selectedBook == null && widget.availableBooks.isNotEmpty) {
      _selectedBook = widget.availableBooks.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBook == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a book for this community.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final dataService = context.read<LocalDataService>();
      final community = await dataService.createCommunity(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        bookId: _selectedBook!.id,
        importMembersFromCommunityId: _selectedSourceCommunityId,
        copyRoles: _copyRoles,
        copyPermissions: true,
        skipRestrictedOrBanned: _skipRestricted,
      );

      // Auto-select it as active community for this book
      await dataService.selectCommunityForBook(
        bookId: _selectedBook!.id,
        communityId: community.id,
      );

      if (mounted) {
        Navigator.pop(context, community);
        final importMsg = _selectedSourceCommunityId != null && community.memberCount > 1
            ? ' with ${community.memberCount} members'
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Community "${community.name}" created$importMsg!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create community: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<LocalDataService>();
    final books = widget.availableBooks.isNotEmpty
        ? widget.availableBooks
        : dataService.getBooks();

    if (_selectedBook == null && books.isNotEmpty) {
      _selectedBook = books.first;
    }

    final manageableCommunities = dataService.communities
        .where((c) => dataService.canManageCommunity(c.id))
        .toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clean header matching modern dialog style
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.users,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Community',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Start a reading circle',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(LucideIcons.x, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // If book is preselected, display a neat concise chip
                  if (widget.preselectedBook != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.bookOpen,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.preselectedBook!.title,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else if (books.isNotEmpty) ...[
                    // Book selector
                    DropdownButtonFormField<Book>(
                      value: _selectedBook,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Associated Book',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: books.map((book) {
                        return DropdownMenuItem(
                          value: book,
                          child: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedBook = val);
                      },
                      validator: (val) => val == null ? 'Please select a book' : null,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Community Name
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Community Name',
                      hintText: 'e.g. The Dune Scholars',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Description
                  TextFormField(
                    controller: _descController,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'What is this reading circle about?',
                      alignLabelWithHint: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                  if (manageableCommunities.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Material(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.users, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Import Member Roster',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Optional',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String?>(
                            value: _selectedSourceCommunityId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: 'None (Start fresh)',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('None (Start fresh)'),
                              ),
                              ...manageableCommunities.map((c) {
                                return DropdownMenuItem<String?>(
                                  value: c.id,
                                  child: Text(
                                    '${c.name} (${c.memberCount} readers)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedSourceCommunityId = val);
                            },
                          ),
                          if (_selectedSourceCommunityId != null) ...[
                            const SizedBox(height: 6),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              title: const Text('Preserve Admin roles'),
                              subtitle: const Text('Carries over moderator privileges'),
                              value: _copyRoles,
                              onChanged: (val) => setState(() => _copyRoles = val ?? true),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              title: const Text('Exclude banned & restricted'),
                              subtitle: const Text('Do not import moderated members'),
                              value: _skipRestricted,
                              onChanged: (val) => setState(() => _skipRestricted = val ?? true),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isCreating ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isCreating ? null : _submit,
                        child: _isCreating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Create'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
