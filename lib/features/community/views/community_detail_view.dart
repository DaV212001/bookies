import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bookies/data/models/discussion.dart';
import 'package:bookies/data/models/thread_scope.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/core/widgets/create_thread_dialog.dart';
import 'package:bookies/core/widgets/quote_card_rating_widget.dart';
import 'package:bookies/features/discussion/views/discussions_bottom_sheet.dart';

class CommunityDetailView extends StatefulWidget {
  final String bookId;
  final String communityName;
  final String description;

  const CommunityDetailView({
    super.key,
    required this.bookId,
    required this.communityName,
    this.description = 'Discussion hub for readers exploring themes, chapters, and favorite passages.',
  });

  @override
  State<CommunityDetailView> createState() => _CommunityDetailViewState();
}

class _CommunityDetailViewState extends State<CommunityDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        communityName: widget.communityName,
        onThreadCreated: () {
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<LocalDataService>();

    final allDiscussions = dataService.getDiscussionsByScope(widget.bookId, null);
    final passageDiscussions = dataService.getDiscussionsByScope(
        widget.bookId, ThreadScope.passage);
    final chapterDiscussions = dataService.getDiscussionsByScope(
        widget.bookId, ThreadScope.chapter);
    final bookDiscussions =
        dataService.getDiscussionsByScope(widget.bookId, ThreadScope.book);
    final favoriteQuotes = dataService.getFavoriteQuotes(widget.bookId);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.communityName),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plusCircle),
            tooltip: 'Start Thread',
            onPressed: _openCreateThreadModal,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFB45309), // Ochre
        foregroundColor: Colors.white,
        onPressed: _openCreateThreadModal,
        icon: const Icon(LucideIcons.messageSquarePlus, size: 18),
        label: const Text(
          'Start Thread',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Banner Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB45309).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        LucideIcons.users,
                        color: Color(0xFFB45309),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.communityName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.userCheck,
                                size: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '142 Scholars • Active Community',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // Categorized Filter TabBar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFFB45309),
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: const Color(0xFFB45309),
            tabs: [
              Tab(text: 'All (${allDiscussions.length})'),
              Tab(text: 'Passages (${passageDiscussions.length})'),
              Tab(text: 'Chapters (${chapterDiscussions.length})'),
              Tab(text: 'Book Threads (${bookDiscussions.length})'),
              Tab(text: 'Favorite Quotes (${favoriteQuotes.length})'),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildThreadList(allDiscussions),
                _buildThreadList(passageDiscussions),
                _buildThreadList(chapterDiscussions),
                _buildThreadList(bookDiscussions),
                _buildQuotesList(favoriteQuotes),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadList(List<Discussion> threads) {
    if (threads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.messagesSquare, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'No threads yet in this category.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Be the first scholar to start a conversation!',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _openCreateThreadModal,
                child: const Text('Start Thread'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: threads.length,
      itemBuilder: (context, index) {
        final thread = threads[index];
        return _buildThreadCard(thread);
      },
    );
  }

  Widget _buildThreadCard(Discussion thread) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => DiscussionsBottomSheet(
                bookId: widget.bookId,
                cfi: thread.highlightId,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Scope pill & Author
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB45309).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            thread.scope.icon,
                            size: 12,
                            color: const Color(0xFFB45309),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            thread.scope.label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (thread.rating != null)
                      Row(
                        children: [
                          Icon(LucideIcons.star, size: 14, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(
                            thread.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Thread Custom Title
                if (thread.title.isNotEmpty)
                  Text(
                    thread.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                // Optional Passage Quote Excerpt
                if (thread.quoteText != null && thread.quoteText!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: const Color(0xFFB45309),
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      '"${thread.quoteText}"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                const SizedBox(height: 6),
                Text(
                  thread.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),

                // Footer: User avatar, name, upvotes & comments count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: thread.user?.avatarUrl != null
                              ? NetworkImage(thread.user!.avatarUrl!)
                              : null,
                          child: thread.user?.avatarUrl == null
                              ? const Icon(LucideIcons.user, size: 12)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          thread.user?.displayName ?? 'Scholar',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            context.read<LocalDataService>().upvoteThread(thread.id);
                            setState(() {});
                          },
                          child: Row(
                            children: [
                              const Icon(LucideIcons.thumbsUp, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '${thread.upvotes}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            const Icon(LucideIcons.messageCircle, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${thread.replies?.length ?? 1}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuotesList(quotes) {
    if (quotes.isEmpty) {
      return const Center(child: Text('No community favorite quotes saved yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        final quote = quotes[index];
        return QuoteCardRatingWidget(
          quote: quote,
          onUpvote: () {
            context.read<LocalDataService>().upvoteQuote(quote.id);
            setState(() {});
          },
        );
      },
    );
  }
}
