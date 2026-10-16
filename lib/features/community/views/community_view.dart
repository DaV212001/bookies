import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bookies/data/models/book.dart';
import 'package:bookies/data/models/community.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/features/community/views/community_detail_view.dart';
import 'package:bookies/core/widgets/create_community_dialog.dart';
import 'package:bookies/core/widgets/responsive_text.dart';

class CommunitiesView extends StatefulWidget {
  const CommunitiesView({super.key});

  @override
  State<CommunitiesView> createState() => _CommunitiesViewState();
}

class _CommunitiesViewState extends State<CommunitiesView> {
  final _searchController = TextEditingController();
  bool _popularFirst = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = context.watch<LocalDataService>();
    final books = data.getBooks();
    final communities = <({Community community, Book? book})>[
      for (final community in data.communities)
        (community: community, book: _bookFor(books, community.bookId)),
    ];
    final query = _searchController.text.trim().toLowerCase();
    final filtered = communities.where((item) {
      if (query.isEmpty) return true;
      return item.community.name.toLowerCase().contains(query) ||
          item.community.description.toLowerCase().contains(query) ||
          (item.book?.title.toLowerCase().contains(query) ?? false);
    }).toList()
      ..sort((a, b) => _popularFirst
          ? b.community.memberCount.compareTo(a.community.memberCount)
          : 0);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Find your people around a book',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: communities.isEmpty
          ? _emptyState(theme)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
        _CommunityIntro(theme: theme, communities: communities),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search communities or books',
            prefixIcon: const Icon(LucideIcons.search, size: 19),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('Browse', style: theme.textTheme.labelLarge),
            const SizedBox(width: 10),
            ChoiceChip(
              label: const Text('All rooms'),
              selected: !_popularFirst,
              onSelected: (_) => setState(() => _popularFirst = false),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Most readers'),
              selected: _popularFirst,
              onSelected: (_) => setState(() => _popularFirst = true),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(child: Text('No communities match your search.')),
          ),
        ...filtered.map(
                  (item) => _CommunityBookCard(
                    community: item.community,
                    book: item.book,
                    onTap: () => Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => CommunityDetailView(
                          bookId: item.community.bookId,
                          communityId: item.community.id,
                          communityName: item.community.name,
                          description: item.community.description,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          CreateCommunityDialog.show(
            context,
            availableBooks: books,
          );
        },
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: theme.colorScheme.onSecondary,
        child: const Icon(LucideIcons.plus),
        tooltip: 'Create Community',
      ),
    );
  }

  static Book? _bookFor(List<Book> books, String bookId) {
    for (final book in books) {
      if (book.id == bookId) return book;
    }
    return null;
  }

  Widget _emptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.library,
              size: 46,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text(
              'No book communities yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Communities focus on one book, and anyone can create a new community around the same book.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityIntro extends StatelessWidget {
  final ThemeData theme;
  final List<({Community community, Book? book})> communities;

  const _CommunityIntro({required this.theme, required this.communities});

  @override
  Widget build(BuildContext context) {
    final readers = communities.fold<int>(
      0,
      (sum, item) => sum + item.community.memberCount,
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.messagesSquare, color: theme.colorScheme.primary),
              const SizedBox(width: 9),
              Text(
                'Reading rooms',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Join a conversation with its own pace, personality, and point of view.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(
                label: communities.length == 1 ? 'COMMUNITY' : 'COMMUNITIES',
                value: '${communities.length}',
                theme: theme,
              ),
              const SizedBox(width: 24),
              _Stat(label: 'READERS', value: '$readers', theme: theme),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _Stat({required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.8)),
      ],
    );
  }
}

class _CommunityBookCard extends StatelessWidget {
  final Community community;
  final Book? book;
  final VoidCallback onTap;

  const _CommunityBookCard({
    required this.community,
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 76,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: _buildCover(theme, book),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText.title(
                      community.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      minFontSize: 13,
                    ),
                    const SizedBox(height: 3),
                    ResponsiveText.label(
                      book?.title ?? 'Book community',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      minFontSize: 10,
                    ),
                    if (book?.author.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      ResponsiveText.label(
                        book!.author,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                        maxLines: 1,
                        minFontSize: 9.5,
                      ),
                    ],
                    const SizedBox(height: 7),
                    ResponsiveText.body(
                      community.description,
                      maxLines: 2,
                      minFontSize: 11,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(LucideIcons.users, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          '${community.memberCount} readers',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 27),
                child: Icon(LucideIcons.chevronRight, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(ThemeData theme, Book? book) {
    final path = book?.coverUrl?.trim();
    if (path == null || path.isEmpty) {
      return Icon(
        LucideIcons.bookOpen,
        color: theme.colorScheme.onSurfaceVariant,
      );
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          LucideIcons.bookOpen,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    final file = File(path);
    if (!file.existsSync()) {
      return Icon(
        LucideIcons.bookOpen,
        color: theme.colorScheme.onSurfaceVariant,
      );
    }
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Icon(LucideIcons.bookOpen, color: theme.colorScheme.onSurfaceVariant),
    );
  }
}
