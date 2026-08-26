import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bookies/data/models/discussion.dart';
import 'package:bookies/data/models/highlight.dart';
import 'package:bookies/data/models/thread_scope.dart';
import 'package:bookies/data/providers/local_data_service.dart';

class DiscussionChatScreen extends StatefulWidget {
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
  State<DiscussionChatScreen> createState() => _DiscussionChatScreenState();
}

class _DiscussionChatScreenState extends State<DiscussionChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildChannelDrawer(ThemeData theme, LocalDataService dataService) {
    final topics = dataService
        .getDiscussionsByScope(widget.bookId, ThreadScope.book)
        .where((discussion) => discussion.title.isNotEmpty)
        .toList();
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
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.bookOpen,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Community Server',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'CHANNELS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _channelTile(theme, LucideIcons.hash, 'General Chat', true),
                  ...topics.map(
                    (topic) => _channelTile(
                      theme,
                      LucideIcons.hash,
                      topic.title,
                      false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _channelTile(
    ThemeData theme,
    IconData icon,
    String title,
    bool active,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: active ? theme.colorScheme.surfaceContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 17,
          color: active
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: active ? FontWeight.w600 : null,
          ),
        ),
        onTap: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    _messageController.clear();
    await context.read<LocalDataService>().createThread(
      highlightId: widget.discussion.highlightId,
      bookId: widget.bookId,
      title: widget.discussion.title,
      content: text,
      scope: widget.discussion.scope,
      chapterTitle: widget.discussion.chapterTitle,
      chapterIndex: widget.discussion.chapterIndex,
      quoteText: widget.discussion.quoteText,
      communityId: widget.communityId ?? '',
    );
    if (!mounted) return;
    setState(() => _isSending = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<LocalDataService>();
    final isGeneralChat = widget.discussion.highlightId.startsWith('general:');
    final pinnedHighlight = _pinnedHighlight(dataService);
    final messages =
        (isGeneralChat
                ? dataService.getDiscussionsByScope(widget.bookId, null)
                : dataService.getDiscussionsForCfi(
                    widget.discussion.highlightId,
                    communityId: widget.communityId,
                  ))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Scaffold(
      drawer: _buildChannelDrawer(theme, dataService),
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.discussion.scope.icon, size: 17),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isGeneralChat
                        ? 'General Chat'
                        : widget.discussion.title.isEmpty
                        ? '${widget.discussion.scope.label} Discussion'
                        : widget.discussion.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              '${widget.bookTitle} · ${messages.length} discussions',
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
              _buildPassageContext(theme, pinnedHighlight),
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      itemCount: messages.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 18),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Today',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          );
                        }
                        final message = messages[index - 1];
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: _buildMessage(theme, dataService, message),
                          ),
                        );
                      },
                    ),
            ),
            _buildComposer(theme),
          ],
        ),
      ),
    );
  }

  String? _pinnedHighlight(LocalDataService dataService) {
    final threadQuote = widget.discussion.quoteText?.trim();
    if (threadQuote?.isNotEmpty == true) return threadQuote;
    for (final Highlight highlight
        in dataService.getHighlightsForBook(widget.bookId)) {
      if (highlight.cfi == widget.discussion.highlightId) return highlight.text;
    }
    return null;
  }

  Widget _buildPassageContext(ThemeData theme, String quoteText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      color: theme.colorScheme.surfaceContainerLow,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
              border: Border(
                left: BorderSide(color: theme.colorScheme.secondary, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.pin,
                      size: 14,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.discussion.chapterTitle ?? 'Pinned highlight',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  quoteText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(
    ThemeData theme,
    LocalDataService dataService,
    Discussion message,
  ) {
    final isMine = message.userId == dataService.currentUser.id;
    final author = isMine ? 'You' : message.user?.displayName ?? 'Reader';
    final time = TimeOfDay.fromDateTime(message.createdAt).format(context);
    return Row(
      mainAxisAlignment: isMine
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMine) ...[
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            backgroundImage: message.user?.avatarUrl != null
                ? NetworkImage(message.user!.avatarUrl!)
                : null,
            child: message.user?.avatarUrl == null
                ? const Icon(LucideIcons.user, size: 16)
                : null,
          ),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  '$author · $time',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Container(
                constraints: const BoxConstraints(maxWidth: 560),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isMine
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isMine ? 16 : 4),
                    topRight: Radius.circular(isMine ? 4 : 16),
                    bottomLeft: const Radius.circular(16),
                    bottomRight: const Radius.circular(16),
                  ),
                  border: isMine
                      ? null
                      : Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Text(
                  message.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isMine ? theme.colorScheme.onPrimary : null,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.messagesSquare,
              size: 42,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Start the conversation',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Share the first thought with this reading circle.',
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

  Widget _buildComposer(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    prefixIcon: IconButton(
                      tooltip: 'Attach a passage',
                      icon: const Icon(LucideIcons.paperclip, size: 19),
                      onPressed: () {},
                    ),
                    hintText: 'Message this discussion',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    suffixIcon: IconButton(
                      tooltip: 'Add reaction',
                      icon: const Icon(LucideIcons.smile, size: 19),
                      onPressed: () {},
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _isSending ? null : _sendMessage,
                tooltip: 'Send message',
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.arrowUp, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
