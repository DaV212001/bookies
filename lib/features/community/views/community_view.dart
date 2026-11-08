import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bookies/data/models/book.dart';
import 'package:bookies/data/models/community.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/data/repositories/local_community_repository.dart';
import 'package:bookies/data/repositories/local_book_repository.dart';
import 'package:bookies/features/community/bloc/community_bloc.dart';
import 'package:bookies/features/community/views/community_detail_view.dart';
import 'package:bookies/core/widgets/create_community_dialog.dart';
import 'package:bookies/core/widgets/responsive_text.dart';

typedef _CommunityListItem = ({Community community, Book? book, bool isJoined});

class CommunitiesView extends StatelessWidget {
  const CommunitiesView({super.key});

  @override
  Widget build(BuildContext context) {
    // Graceful fallback if CommunityBloc was not provided in a standalone test
    try {
      context.read<CommunityBloc>();
      return const _CommunitiesContent();
    } catch (_) {
      final localData = context.read<LocalDataService>();
      return BlocProvider(
        create: (_) => CommunityBloc(
          communityRepository: LocalCommunityRepository(localData),
          bookRepository: LocalBookRepository(localData),
        )..add(const LoadCommunities()),
        child: const _CommunitiesContent(),
      );
    }
  }
}

class _CommunitiesContent extends StatefulWidget {
  const _CommunitiesContent();

  @override
  State<_CommunitiesContent> createState() => _CommunitiesContentState();
}

class _CommunitiesContentState extends State<_CommunitiesContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<CommunityBloc, CommunityState>(
      builder: (context, state) {
        if (state is CommunityLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final communities = (state is CommunityLoaded)
            ? state.allCommunities
                .map((c) => (
                      community: Community.fromDomain(c),
                      book: null as Book?,
                      isJoined: state.joinedCommunityIds.contains(c.id),
                    ))
                .toList()
            : <_CommunityListItem>[];

        final filteredCommunities = (state is CommunityLoaded)
            ? state.filteredItems
                .map((item) => (
                      community: Community.fromDomain(item.community),
                      book: item.book != null ? Book.fromDomain(item.book!) : null,
                      isJoined: item.isJoined,
                    ))
                .toList()
            : <_CommunityListItem>[];

        final popularFirst = (state is CommunityLoaded) ? state.popularFirst : false;
        final filterTab = (state is CommunityLoaded)
            ? state.filterTab
            : CommunityFilterTab.myClubs;
        final myClubsCount = (state is CommunityLoaded) ? state.myClubsCount : 0;
        final exploreCount = (state is CommunityLoaded) ? state.exploreCount : 0;
        final totalCount = (state is CommunityLoaded) ? state.totalCount : 0;
        final query = _searchController.text.trim();

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
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CommunityIntro(
                              theme: theme,
                              communities: communities,
                              joinedCount: myClubsCount,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                context.read<CommunityBloc>().add(
                                      SearchCommunities(
                                        query: val,
                                        popularFirst: popularFirst,
                                      ),
                                    );
                              },
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.normal,
                                color: theme.colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Search communities or books',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.normal,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.65),
                                ),
                                prefixIcon: const Icon(
                                  LucideIcons.search,
                                  size: 17,
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                suffixIcon: query.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear search',
                                        icon: const Icon(LucideIcons.x, size: 16),
                                        constraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          _searchController.clear();
                                          context.read<CommunityBloc>().add(
                                                SearchCommunities(
                                                  query: '',
                                                  popularFirst: popularFirst,
                                                ),
                                              );
                                        },
                                      ),
                                suffixIconConstraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Filter Segmented Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ChoiceChip(
                                    avatar: Icon(
                                      LucideIcons.bookmarkCheck,
                                      size: 14,
                                      color: filterTab == CommunityFilterTab.myClubs
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.primary,
                                    ),
                                    label: Text('My Clubs ($myClubsCount)'),
                                    selected: filterTab == CommunityFilterTab.myClubs,
                                    selectedColor: theme.colorScheme.primary,
                                    labelStyle: TextStyle(
                                      color: filterTab == CommunityFilterTab.myClubs
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                      fontWeight: filterTab == CommunityFilterTab.myClubs
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 12.5,
                                    ),
                                    onSelected: (_) {
                                      context.read<CommunityBloc>().add(
                                            const SetCommunityFilterTab(
                                              CommunityFilterTab.myClubs,
                                            ),
                                          );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    avatar: Icon(
                                      LucideIcons.compass,
                                      size: 14,
                                      color: filterTab == CommunityFilterTab.explore
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    label: Text('Explore Public ($exploreCount)'),
                                    selected: filterTab == CommunityFilterTab.explore,
                                    selectedColor: theme.colorScheme.primary,
                                    labelStyle: TextStyle(
                                      color: filterTab == CommunityFilterTab.explore
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                      fontWeight: filterTab == CommunityFilterTab.explore
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 12.5,
                                    ),
                                    onSelected: (_) {
                                      context.read<CommunityBloc>().add(
                                            const SetCommunityFilterTab(
                                              CommunityFilterTab.explore,
                                            ),
                                          );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    avatar: Icon(
                                      LucideIcons.globe,
                                      size: 14,
                                      color: filterTab == CommunityFilterTab.all
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    label: Text('All ($totalCount)'),
                                    selected: filterTab == CommunityFilterTab.all,
                                    selectedColor: theme.colorScheme.primary,
                                    labelStyle: TextStyle(
                                      color: filterTab == CommunityFilterTab.all
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                      fontWeight: filterTab == CommunityFilterTab.all
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 12.5,
                                    ),
                                    onSelected: (_) {
                                      context.read<CommunityBloc>().add(
                                            const SetCommunityFilterTab(
                                              CommunityFilterTab.all,
                                            ),
                                          );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Sort row
                            Row(
                              children: [
                                Text(
                                  'Sort:',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    context.read<CommunityBloc>().add(
                                          const ToggleSortOrder(),
                                        );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: theme.colorScheme.outlineVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          popularFirst
                                              ? LucideIcons.trendingUp
                                              : LucideIcons.clock,
                                          size: 13,
                                          color: theme.colorScheme.secondary,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          popularFirst ? 'Most readers' : 'Default order',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.secondary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          LucideIcons.arrowUpDown,
                                          size: 11,
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                    if (filteredCommunities.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildEmptyFilterState(
                          context,
                          theme,
                          filterTab: filterTab,
                          query: query,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final item = filteredCommunities[index];
                            return _CommunityBookCard(
                              community: item.community,
                              book: item.book,
                              isJoined: item.isJoined,
                              onQuickJoin: item.isJoined
                                  ? null
                                  : () {
                                      context.read<CommunityBloc>().add(
                                            JoinCommunityRequested(
                                              item.community.id,
                                            ),
                                          );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Joined "${item.community.name}".',
                                          ),
                                        ),
                                      );
                                    },
                              onTap: () =>
                                  Navigator.of(context, rootNavigator: true).push(
                                    MaterialPageRoute(
                                      builder: (_) => CommunityDetailView(
                                        bookId: item.community.bookId,
                                        communityId: item.community.id,
                                        communityName: item.community.name,
                                        description: item.community.description,
                                      ),
                                    ),
                                  ),
                            );
                          }, childCount: filteredCommunities.length),
                        ),
                      ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              final books = (state is CommunityLoaded)
                  ? state.books.map((b) => Book.fromDomain(b)).toList()
                  : <Book>[];
              CreateCommunityDialog.show(context, availableBooks: books);
            },
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            tooltip: 'Create Community',
            child: const Icon(LucideIcons.plus),
          ),
        );
      },
    );
  }

  Widget _buildEmptyFilterState(
    BuildContext context,
    ThemeData theme, {
    required CommunityFilterTab filterTab,
    required String query,
  }) {
    if (query.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 36, 16, 36),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.searchX,
                size: 38,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(
                'No communities match "$query"',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try searching with a different term or clear the search filter.',
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

    if (filterTab == CommunityFilterTab.myClubs) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.bookmarkCheck,
                  size: 34,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You haven\'t joined any clubs yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Explore reading rooms to share discussions, highlights, and annotations with fellow readers.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  context.read<CommunityBloc>().add(
                        const SetCommunityFilterTab(
                          CommunityFilterTab.explore,
                        ),
                      );
                },
                icon: const Icon(LucideIcons.compass, size: 16),
                label: const Text('Explore Public Clubs'),
              ),
            ],
          ),
        ),
      );
    }

    if (filterTab == CommunityFilterTab.explore) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.checkCheck,
                  size: 34,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You\'re part of every club!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'You have already joined all active reading rooms. Start a new club around any book in your library!',
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

    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 36),
      child: Center(
        child: Text('No communities available.'),
      ),
    );
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
  final List<({Community community, Book? book, bool isJoined})> communities;
  final int joinedCount;

  const _CommunityIntro({
    required this.theme,
    required this.communities,
    required this.joinedCount,
  });

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
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.messagesSquare,
                color: theme.colorScheme.primary,
              ),
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
              const SizedBox(width: 20),
              _Stat(label: 'MY CLUBS', value: '$joinedCount', theme: theme),
              const SizedBox(width: 20),
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
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _CommunityBookCard extends StatelessWidget {
  final Community community;
  final Book? book;
  final bool isJoined;
  final VoidCallback onTap;
  final VoidCallback? onQuickJoin;

  const _CommunityBookCard({
    required this.community,
    required this.book,
    required this.isJoined,
    required this.onTap,
    this.onQuickJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isJoined
            ? BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
                width: 1.2,
              )
            : BorderSide.none,
      ),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ResponsiveText.title(
                            community.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            minFontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isJoined)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.check,
                                  size: 11,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Member',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Public',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
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
                        Icon(
                          LucideIcons.users,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${community.memberCount} readers',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        if (!isJoined && onQuickJoin != null)
                          SizedBox(
                            height: 28,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                foregroundColor: theme.colorScheme.primary,
                              ),
                              onPressed: onQuickJoin,
                              icon: const Icon(LucideIcons.userPlus, size: 13),
                              label: const Text(
                                'Join',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        else
                          Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                      ],
                    ),
                  ],
                ),
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
