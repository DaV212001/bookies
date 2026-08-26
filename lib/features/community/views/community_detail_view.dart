import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bookies/core/widgets/create_thread_dialog.dart';
import 'package:bookies/core/widgets/quote_card_rating_widget.dart';
import 'package:bookies/data/models/discussion.dart';
import 'package:bookies/data/models/highlight.dart';
import 'package:bookies/data/models/thread_scope.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/features/discussion/views/discussion_chat_screen.dart';

class CommunityDetailView extends StatefulWidget {
  final String bookId;
  final String communityId;
  final String communityName;
  final String description;

  const CommunityDetailView({
    super.key,
    required this.bookId,
    required this.communityId,
    required this.communityName,
    this.description =
        'Discussion hub for readers exploring themes, chapters, and favorite passages.',
  });

  @override
  State<CommunityDetailView> createState() => _CommunityDetailViewState();
}

class _CommunityDetailViewState extends State<CommunityDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCreateThreadModal() {
    showDialog(
      context: context,
      builder: (_) => CreateThreadDialog(
        bookId: widget.bookId,
        communityId: widget.communityId,
        communityName: widget.communityName,
        onThreadCreated: () => setState(() {}),
      ),
    );
  }

  void _openDiscussion(Discussion discussion) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => DiscussionChatScreen(
          bookId: widget.bookId,
          bookTitle: widget.communityName,
          discussion: discussion,
          communityId: widget.communityId,
        ),
      ),
    );
  }

  Future<void> _joinCommunity() async {
    await context.read<LocalDataService>().joinCommunity(widget.communityId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joined ${widget.communityName}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<LocalDataService>();
    final book = dataService
        .getBooks()
        .where((item) => item.id == widget.bookId)
        .firstOrNull;
    final discussions = dataService.getDiscussionsByScope(
      widget.bookId,
      null,
      communityId: widget.communityId,
    );
    final isMember = dataService.isMemberOfCommunity(widget.communityId);
    final bookThreads = discussions
        .where((discussion) => discussion.scope == ThreadScope.book)
        .toList();
    final chapterThreads = discussions
        .where((discussion) => discussion.scope == ThreadScope.chapter)
        .toList();
    final highlights = dataService.getHighlightsForBook(widget.bookId);
    final highlightThreads = discussions
        .where((discussion) => discussion.scope == ThreadScope.passage)
        .toList();
    final quotes = dataService.getFavoriteQuotes(widget.bookId);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isMember ? _openCreateThreadModal : _joinCommunity,
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: theme.colorScheme.onSecondary,
        icon: Icon(
          isMember ? LucideIcons.messageSquarePlus : LucideIcons.userPlus,
          size: 18,
        ),
        label: Text(isMember ? 'Start Discussion' : 'Join community'),
      ),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: _buildCommunityHeader(
                theme,
                book?.coverUrl,
                book?.author,
                discussions.length,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarHeaderDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: const [
                    Tab(text: 'Global Discussion'),
                    Tab(text: 'Chapter Discussions'),
                    Tab(text: 'Highlights'),
                    Tab(text: 'Quotes'),
                  ],
                ),
                theme.colorScheme.surface,
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildGlobalTab(theme, discussions, bookThreads),
              _buildChapterTab(theme, chapterThreads),
              _buildHighlightsTab(theme, highlights, highlightThreads),
              _buildQuotesTab(theme, quotes),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityHeader(
    ThemeData theme,
    String? coverUrl,
    String? author,
    int discussionCount,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Back',
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 128,
            height: 192,
            margin: const EdgeInsets.only(bottom: 20),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: const [
                BoxShadow(blurRadius: 14, color: Color(0x22000000)),
              ],
            ),
            child: _buildCover(theme, coverUrl),
          ),
          Text(
            widget.communityName,
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'by ${author ?? 'Unknown author'}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.users,
                size: 16,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 7),
              Text(
                '142 Active Readers',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          if (discussionCount > 0) ...[
            const SizedBox(height: 5),
            Text(
              '$discussionCount discussions',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCover(ThemeData theme, String? coverUrl) {
    final fallback = Center(
      child: Icon(
        LucideIcons.bookOpen,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final path = coverUrl?.trim();
    if (path == null || path.isEmpty) return fallback;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    final file = File(path);
    if (!file.existsSync()) return fallback;
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  Widget _buildGlobalTab(
    ThemeData theme,
    List<Discussion> allDiscussions,
    List<Discussion> bookThreads,
  ) {
    final topics = bookThreads
        .where((thread) => thread.title.isNotEmpty)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        const SizedBox(height: 20),
        _buildDiscussionCard(
          theme,
          Discussion(
            id: 'general-${widget.bookId}',
            highlightId: 'general:${widget.bookId}',
            bookId: widget.bookId,
            userId: '',
            title: 'General Chat',
            content: 'A shared hub for every topic and subtopic in this book.',
            scope: ThreadScope.book,
            upvotes: allDiscussions.length,
            createdAt: DateTime.now(),
          ),
          prominent: true,
        ),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            'DISCUSSION CATEGORIES',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (topics.isEmpty)
          _emptyState(
            theme,
            LucideIcons.listTree,
            'No topics yet',
            'Topics will appear here as readers start focused discussions.',
          )
        else
          ...topics.map((topic) => _buildCategoryCard(theme, topic)),
      ],
    );
  }

  Widget _buildCategoryCard(ThemeData theme, Discussion topic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openDiscussion(topic),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  topic.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${context.read<LocalDataService>().getDiscussionsForCfi(topic.highlightId, communityId: widget.communityId).length} Topics',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                LucideIcons.chevronDown,
                size: 19,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterTab(ThemeData theme, List<Discussion> threads) {
    final grouped = <String, List<Discussion>>{};
    for (final thread in threads) {
      final chapter = thread.chapterTitle?.trim();
      if (chapter != null && chapter.isNotEmpty) {
        grouped.putIfAbsent(chapter, () => []).add(thread);
      }
    }
    if (grouped.isEmpty) {
      return _emptyState(
        theme,
        LucideIcons.bookOpenText,
        'No chapter discussions yet',
        'Start a chapter conversation from the reader or this page.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries
          .map((entry) => _buildChapterCard(theme, entry.key, entry.value))
          .toList(),
    );
  }

  Widget _buildHighlightsTab(
    ThemeData theme,
    List<Highlight> highlights,
    List<Discussion> threads,
  ) {
    if (highlights.isEmpty) {
      return _emptyState(
        theme,
        LucideIcons.highlighter,
        'No highlights yet',
        'Highlights you save in the reader will appear here.',
      );
    }
    final discussionsByHighlight = <String, List<Discussion>>{};
    for (final thread in threads) {
      discussionsByHighlight.putIfAbsent(thread.highlightId, () => []).add(thread);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: highlights
          .map((highlight) => _buildHighlightCard(
                theme,
                highlight,
                discussionsByHighlight[highlight.cfi] ?? const [],
              ))
          .toList(),
    );
  }

  Widget _buildQuotesTab(ThemeData theme, List quotes) {
    if (quotes.isEmpty) {
      return _emptyState(
        theme,
        LucideIcons.quote,
        'No community quotes yet',
        'Notable passages selected by readers will appear here.',
      );
    }
    final dataService = context.read<LocalDataService>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: quotes
          .map(
            (quote) => QuoteCardRatingWidget(
              quote: quote,
              onUpvote: () async {
                await dataService.upvoteQuote(quote.id);
                setState(() {});
              },
            ),
          )
          .toList(),
    );
  }

  Widget _buildDiscussionCard(
    ThemeData theme,
    Discussion discussion, {
    bool prominent = false,
  }) {
    final data = context.read<LocalDataService>();
    final preview = data
        .getDiscussionsByScope(
          widget.bookId,
          null,
          communityId: widget.communityId,
        )
        .take(2)
        .toList();
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDiscussion(discussion),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.messagesSquare,
                    color: theme.colorScheme.secondary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'General Chat',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    LucideIcons.arrowRight,
                    color: theme.colorScheme.outlineVariant,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'The shared hub for every topic and subtopic',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: preview.isEmpty
                      ? [
                          Text(
                            'No messages yet. Start the conversation.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ]
                      : preview
                            .map(
                              (message) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor:
                                          theme.colorScheme.primaryContainer,
                                      child: Text(
                                        (message.user?.displayName ?? 'R')
                                            .substring(0, 1),
                                      ),
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Text(
                                        message.content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${discussion.upvotes} readers active',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'JOIN CONVERSATION',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterCard(
    ThemeData theme,
    String chapter,
    List<Discussion> threads,
  ) {
    return _surfaceCard(
      theme,
      onTap: () => _openDiscussion(threads.first),
      child: Row(
        children: [
          Icon(
            LucideIcons.bookmark,
            color: theme.colorScheme.secondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                _metadata(
                  theme,
                  '${threads.length} discussions · ${threads.fold<int>(0, (sum, item) => sum + (item.replies?.length ?? 1))} messages',
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 18),
        ],
      ),
    );
  }

  Widget _buildHighlightCard(
    ThemeData theme,
    Highlight highlight,
    List<Discussion> discussions,
  ) {
    final discussion = discussions.isNotEmpty
        ? discussions.first
        : Discussion(
            id: 'highlight-${highlight.id}',
            highlightId: highlight.cfi,
            bookId: highlight.bookId,
            userId: highlight.userId,
            content: '',
            scope: ThreadScope.passage,
            quoteText: highlight.text,
            createdAt: highlight.createdAt,
          );
    return _surfaceCard(
      theme,
      onTap: () => _openDiscussion(discussion),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.highlighter,
                size: 17,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  discussion.chapterTitle ?? 'Book highlight',
                  style: theme.textTheme.labelMedium,
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 18),
            ],
          ),
          if (highlight.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.secondary,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                highlight.text,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          _metadata(
            theme,
            discussions.isEmpty
                ? 'No discussion yet'
                : '${discussions.length} ${discussions.length == 1 ? 'message' : 'messages'}',
          ),
        ],
      ),
    );
  }

  Widget _surfaceCard(
    ThemeData theme, {
    required Widget child,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      ),
    );
  }

  Widget _metadata(ThemeData theme, String text) => Text(
    text,
    style: theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );

  Widget _emptyState(
    ThemeData theme,
    IconData icon,
    String title,
    String message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
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

class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _TabBarHeaderDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarHeaderDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar ||
      oldDelegate.backgroundColor != backgroundColor;
}
