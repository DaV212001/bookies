import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_readium/flutter_readium.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bookies/data/models/chat_message.dart';
import 'package:bookies/data/models/discussion.dart';
import 'package:bookies/data/models/highlight.dart';
import 'package:bookies/data/models/thread_scope.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/data/repositories/discussion_repository.dart';
import 'package:bookies/features/discussion/bloc/discussion_chat_bloc.dart';
import 'package:bookies/features/discussion/bloc/discussion_chat_event.dart';
import 'package:bookies/features/discussion/bloc/discussion_chat_state.dart';
import 'package:bookies/features/reader/bloc/reader_bloc.dart';
import 'package:bookies/features/reader/views/reader_view.dart';

class DiscussionChatScreen extends StatelessWidget {
  final String bookId;
  final String bookTitle;
  final Discussion discussion;
  final String? communityId;

  const DiscussionChatScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.discussion,
    this.communityId,
  });

  @override
  Widget build(BuildContext context) {
    final localData = context.read<LocalDataService>();
    final repository = context.read<DiscussionRepository>();

    // Determine current reader progress for spoiler evaluations
    String? readerCfi;
    int? readerChapter;
    try {
      final readerState = context.read<ReaderBloc?>()?.state;
      if (readerState is ReaderLoaded) {
        readerCfi = readerState.currentCfi;
      }
    } catch (_) {}

    if (readerCfi == null) {
      final progressJson = localData.getProgress(bookId);
      if (progressJson != null) {
        readerCfi = progressJson;
        try {
          final loc = Locator.fromJsonString(progressJson);
          readerChapter = loc?.locations?.position;
        } catch (_) {}
      }
    }

    return BlocProvider<DiscussionChatBloc>(
      create: (context) => DiscussionChatBloc(
        repository: repository,
        currentUser: localData.currentUser,
      )..add(
          InitializeChat(
            discussion: discussion,
            bookId: bookId,
            communityId: communityId,
            currentReaderCfi: readerCfi,
            currentReaderChapter: readerChapter,
          ),
        ),
      child: _DiscussionChatView(
        bookId: bookId,
        bookTitle: bookTitle,
        initialDiscussion: discussion,
        communityId: communityId,
      ),
    );
  }
}

class _DiscussionChatView extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final Discussion initialDiscussion;
  final String? communityId;

  const _DiscussionChatView({
    required this.bookId,
    required this.bookTitle,
    required this.initialDiscussion,
    this.communityId,
  });

  @override
  State<_DiscussionChatView> createState() => _DiscussionChatViewState();
}

class _DiscussionChatViewState extends State<_DiscussionChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _revealedSpoilers = {};
  bool _markAsSpoiler = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(BuildContext context) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<DiscussionChatBloc>().add(
          SendMessage(
            content: text,
            isSpoiler: _markAsSpoiler,
          ),
        );

    _messageController.clear();
    setState(() {
      _markAsSpoiler = false;
    });
  }

  void _jumpToReader(String? targetCfi) {
    final localData = context.read<LocalDataService>();
    final book = localData.getBooks().where((b) => b.id == widget.bookId).firstOrNull;
    if (book != null) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => ReaderView(book: book, initialCfi: targetCfi),
        ),
      );
    }
  }

  void _showMessageActions(BuildContext context, ChatMessage message) {
    final theme = Theme.of(context);
    final bloc = context.read<DiscussionChatBloc>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick emoji bar
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['👍', '❤️', '💡', '🔥', '👏', '🔖'].map((emoji) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          bloc.add(ToggleReaction(messageId: message.id, emoji: emoji));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(LucideIcons.reply, size: 20),
                  title: const Text('Reply'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    bloc.add(SelectReplyMessage(message));
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.copy, size: 20),
                  title: const Text('Copy message'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.content));
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChannelDrawer(ThemeData theme, LocalDataService dataService, Discussion currentDiscussion) {
    final bookThreads = dataService.getDiscussionsByScope(widget.bookId, null, communityId: widget.communityId);
    final chapters = bookThreads
        .where((d) => d.scope == ThreadScope.chapter && d.chapterTitle != null)
        .fold<Map<String, List<Discussion>>>({}, (acc, item) {
      final key = item.chapterTitle!;
      acc.putIfAbsent(key, () => []).add(item);
      return acc;
    });

    final topics = dataService.getTopicsForBook(widget.bookId, communityId: widget.communityId);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Icon(LucideIcons.bookOpen, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.bookTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Community Server',
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                children: [
                  _channelTile(
                    theme,
                    icon: LucideIcons.messageSquare,
                    title: 'General Chat',
                    active: currentDiscussion.highlightId.startsWith('general:'),
                    onTap: () {
                      Navigator.pop(context);
                      context.read<DiscussionChatBloc>().add(
                            InitializeChat(
                              discussion: Discussion(
                                id: 'general-${widget.bookId}',
                                highlightId: 'general:${widget.bookId}',
                                bookId: widget.bookId,
                                userId: '',
                                title: 'General Chat',
                                content: 'A shared hub for every reader in this community.',
                                scope: ThreadScope.book,
                                createdAt: DateTime.now(),
                              ),
                              bookId: widget.bookId,
                              communityId: widget.communityId,
                            ),
                          );
                    },
                  ),
                  if (chapters.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _sectionHeader(theme, 'CHAPTER DISCUSSIONS'),
                    ...chapters.entries.map((entry) {
                      final first = entry.value.first;
                      final isActive = currentDiscussion.highlightId == first.highlightId ||
                          currentDiscussion.chapterTitle == entry.key;
                      return _channelTile(
                        theme,
                        icon: LucideIcons.bookmark,
                        title: entry.key,
                        badge: '${entry.value.length}',
                        active: isActive,
                        onTap: () {
                          Navigator.pop(context);
                          context.read<DiscussionChatBloc>().add(
                                InitializeChat(
                                  discussion: first,
                                  bookId: widget.bookId,
                                  communityId: widget.communityId,
                                ),
                              );
                        },
                      );
                    }),
                  ],
                  if (topics.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _sectionHeader(theme, 'TOPICS & SUBTOPICS'),
                    ...topics.map((topic) {
                      final subtopics = dataService.getSubtopics(topic.id);
                      final isActive = currentDiscussion.id == topic.id;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _channelTile(
                            theme,
                            icon: LucideIcons.hash,
                            title: topic.title,
                            active: isActive,
                            onTap: () {
                              Navigator.pop(context);
                              context.read<DiscussionChatBloc>().add(
                                    InitializeChat(
                                      discussion: topic,
                                      bookId: widget.bookId,
                                      communityId: widget.communityId,
                                    ),
                                  );
                            },
                          ),
                          if (subtopics.isNotEmpty)
                            ...subtopics.map((sub) {
                              final isSubActive = currentDiscussion.id == sub.id;
                              return Padding(
                                padding: const EdgeInsets.only(left: 18.0),
                                child: _channelTile(
                                  theme,
                                  icon: LucideIcons.cornerDownRight,
                                  title: sub.title,
                                  active: isSubActive,
                                  onTap: () {
                                    Navigator.pop(context);
                                    context.read<DiscussionChatBloc>().add(
                                          InitializeChat(
                                            discussion: sub,
                                            bookId: widget.bookId,
                                            communityId: widget.communityId,
                                          ),
                                        );
                                  },
                                ),
                              );
                            }),
                        ],
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _channelTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    String? badge,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: active ? theme.colorScheme.surfaceContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 17,
          color: active ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: active ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<LocalDataService>();

    return BlocConsumer<DiscussionChatBloc, DiscussionChatState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!), behavior: SnackBarBehavior.floating),
          );
        }
      },
      builder: (context, state) {
        final currentDiscussion = state.discussion ?? widget.initialDiscussion;
        final isGeneralChat = currentDiscussion.highlightId.startsWith('general:');
        final pinnedHighlight = _pinnedHighlight(dataService, currentDiscussion);

        return Scaffold(
          drawer: _buildChannelDrawer(theme, dataService, currentDiscussion),
          appBar: AppBar(
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(currentDiscussion.scope.icon, size: 17),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isGeneralChat
                            ? 'General Chat'
                            : currentDiscussion.title.isEmpty
                                ? '${currentDiscussion.scope.label} Discussion'
                                : currentDiscussion.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${widget.bookTitle} · ${state.messages.length} messages',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                if (pinnedHighlight != null)
                  _buildPassageContext(theme, pinnedHighlight, currentDiscussion),
                if (state.isSpoilerThread && !state.spoilerRevealed)
                  _buildSpoilerThreadShield(theme, context)
                else
                  Expanded(
                    child: state.status == DiscussionChatStatus.loading && state.messages.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : state.messages.isEmpty
                            ? _buildEmptyState(theme)
                            : _buildMessageList(theme, dataService, state.messages),
                  ),
                if (!state.isSpoilerThread || state.spoilerRevealed)
                  _buildComposer(theme, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpoilerThreadShield(ThemeData theme, BuildContext context) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertTriangle, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Spoiler Protection',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'This discussion is ahead of your current reading progress. Open with caution to avoid spoilers.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                icon: const Icon(LucideIcons.eye, size: 16),
                label: const Text('Reveal Discussion'),
                onPressed: () {
                  context.read<DiscussionChatBloc>().add(const RevealSpoilerWarning());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _pinnedHighlight(LocalDataService dataService, Discussion discussion) {
    final threadQuote = discussion.quoteText?.trim();
    if (threadQuote?.isNotEmpty == true) return threadQuote;
    for (final Highlight highlight in dataService.getHighlightsForBook(widget.bookId)) {
      if (highlight.cfi == discussion.highlightId) return highlight.text;
    }
    return null;
  }

  Widget _buildPassageContext(ThemeData theme, String quoteText, Discussion discussion) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      color: theme.colorScheme.surfaceContainerLow,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _jumpToReader(discussion.highlightId),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
                border: Border(
                  left: BorderSide(color: theme.colorScheme.secondary, width: 3),
                ),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.pin, size: 13, color: theme.colorScheme.secondary),
                            const SizedBox(width: 5),
                            Text(
                              discussion.chapterTitle ?? 'Pinned passage excerpt',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          quoteText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(LucideIcons.arrowUpRight, size: 16, color: theme.colorScheme.secondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(ThemeData theme, LocalDataService dataService, List<ChatMessage> messages) {
    // Inverted list: index 0 is at the bottom (newest).
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMine = message.userId == dataService.currentUser.id;

        // Grouping: Older message is at index + 1
        final olderMessage = index + 1 < messages.length ? messages[index + 1] : null;
        final newerMessage = index - 1 >= 0 ? messages[index - 1] : null;

        final isFirstInGroup = olderMessage == null ||
            olderMessage.userId != message.userId ||
            message.createdAt.difference(olderMessage.createdAt).inMinutes > 3 ||
            !_isSameDay(message.createdAt, olderMessage.createdAt);

        final isLastInGroup = newerMessage == null ||
            newerMessage.userId != message.userId ||
            newerMessage.createdAt.difference(message.createdAt).inMinutes > 3 ||
            !_isSameDay(message.createdAt, newerMessage.createdAt);

        final showDateSeparator = olderMessage == null || !_isSameDay(message.createdAt, olderMessage.createdAt);

        return Column(
          children: [
            if (showDateSeparator) _buildDateChip(theme, message.createdAt),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: _buildMessageBubble(
                  theme: theme,
                  message: message,
                  isMine: isMine,
                  isFirstInGroup: isFirstInGroup,
                  isLastInGroup: isLastInGroup,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateChip(ThemeData theme, DateTime date) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(date, now)) {
      label = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label = '${date.month}/${date.day}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required ThemeData theme,
    required ChatMessage message,
    required bool isMine,
    required bool isFirstInGroup,
    required bool isLastInGroup,
  }) {
    final author = isMine ? 'You' : message.user?.displayName ?? 'Reader';
    final time = TimeOfDay.fromDateTime(message.createdAt).format(context);
    final isSpoilerRevealed = _revealedSpoilers.contains(message.id);

    return Padding(
      padding: EdgeInsets.only(top: isFirstInGroup ? 8 : 2, bottom: isLastInGroup ? 6 : 1),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine) ...[
            if (isFirstInGroup)
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                backgroundImage:
                    message.user?.avatarUrl != null ? NetworkImage(message.user!.avatarUrl!) : null,
                child: message.user?.avatarUrl == null
                    ? const Icon(LucideIcons.user, size: 14)
                    : null,
              )
            else
              const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (isFirstInGroup)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                    child: Text(
                      '$author · $time',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                GestureDetector(
                  onLongPress: () => _showMessageActions(context, message),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 540),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMine
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isMine ? 14 : (isFirstInGroup ? 4 : 14)),
                        topRight: Radius.circular(isMine ? (isFirstInGroup ? 4 : 14) : 14),
                        bottomLeft: const Radius.circular(14),
                        bottomRight: const Radius.circular(14),
                      ),
                      border: isMine ? null : Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quoted Reply Context
                        if (message.replyToContent != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                            decoration: BoxDecoration(
                              color: isMine
                                  ? Colors.black.withValues(alpha: 0.15)
                                  : theme.colorScheme.surfaceContainerHigh,
                              border: Border(
                                left: BorderSide(
                                  color: isMine ? Colors.white70 : theme.colorScheme.primary,
                                  width: 2.5,
                                ),
                              ),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.replyToAuthor ?? 'Replied to message',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isMine ? Colors.white70 : theme.colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  message.replyToContent!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isMine ? Colors.white60 : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Message content or spoiler barrier
                        if (message.isSpoiler && !isSpoilerRevealed)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _revealedSpoilers.add(message.id);
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.eyeOff,
                                  size: 15,
                                  color: isMine ? Colors.white70 : theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Spoiler content · Tap to reveal',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 13,
                                    color: isMine ? Colors.white70 : theme.colorScheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            message.content,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isMine ? theme.colorScheme.onPrimary : null,
                              height: 1.35,
                            ),
                          ),

                        // Message Sending Status Indicator
                        if (isMine && message.status == MessageStatus.sending) ...[
                          const SizedBox(height: 3),
                          const Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white70),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Reaction Pills
                if (message.reactions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: message.reactions.entries.map((entry) {
                      final hasMyReaction = entry.value.contains(context.read<LocalDataService>().currentUser.id);
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          context.read<DiscussionChatBloc>().add(
                                ToggleReaction(messageId: message.id, emoji: entry.key),
                              );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: hasMyReaction
                                ? theme.colorScheme.secondaryContainer
                                : theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: hasMyReaction
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.outlineVariant,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${entry.key} ${entry.value.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: hasMyReaction ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(ThemeData theme, DiscussionChatState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Replying To Banner
              if (state.replyingTo != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.reply, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Replying to ${state.replyingTo?.user?.displayName ?? 'Reader'}: "${state.replyingTo?.content}"',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(LucideIcons.x, size: 14),
                        onPressed: () {
                          context.read<DiscussionChatBloc>().add(const SelectReplyMessage(null));
                        },
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: _markAsSpoiler ? 'Marked as spoiler' : 'Mark as spoiler',
                    icon: Icon(
                      _markAsSpoiler ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 20,
                      color: _markAsSpoiler ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() {
                        _markAsSpoiler = !_markAsSpoiler;
                      });
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(context),
                      decoration: InputDecoration(
                        hintText: _markAsSpoiler
                            ? 'Write message (flagged as spoiler)...'
                            : 'Write a thought or question...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _sendMessage(context),
                    icon: const Icon(LucideIcons.send, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.messagesSquare, size: 42, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Start the conversation',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Be the first to share an insight or question with fellow readers.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
