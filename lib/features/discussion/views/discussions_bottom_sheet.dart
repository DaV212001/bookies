import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_readium/flutter_readium.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bookies/data/models/community.dart';
import 'package:bookies/data/models/thread_scope.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/features/discussion/bloc/discussion_bloc.dart';
import 'package:bookies/features/reader/bloc/reader_bloc.dart';
import 'package:bookies/core/widgets/discussion_modal.dart';
import 'package:bookies/core/widgets/quote_card.dart';
import 'package:bookies/core/widgets/primary_button.dart';
import 'package:bookies/core/widgets/community_membership_gate.dart';
import 'package:bookies/features/community/views/community_detail_view.dart';
import 'package:bookies/core/widgets/create_community_dialog.dart';

class DiscussionsBottomSheet extends StatefulWidget {
  final String bookId;
  final String cfi; // The CFI anchor for the thread
  final String? communityId;
  final String? communityName;
  final String? quoteText;

  const DiscussionsBottomSheet({
    super.key,
    required this.bookId,
    required this.cfi,
    this.communityId,
    this.communityName,
    this.quoteText,
  });

  @override
  State<DiscussionsBottomSheet> createState() => _DiscussionsBottomSheetState();
}

class _DiscussionsBottomSheetState extends State<DiscussionsBottomSheet> {
  final TextEditingController _replyController = TextEditingController();
  bool _isMember = true;
  String _bookTitle = 'Book';
  Community? _community;

  String get _communityId => _community?.id ?? '';

  @override
  void initState() {
    super.initState();
    final readerState = context.read<ReaderBloc>().state;
    String currentReaderCfi = '';

    if (readerState is ReaderLoaded) {
      _bookTitle = readerState.book.title;
      currentReaderCfi = readerState.currentCfi ?? '';
    }

    final localData = context.read<LocalDataService>();
    _community = widget.communityId == null
        ? localData.getSelectedCommunityForBook(widget.bookId)
        : localData
              .getCommunitiesForBook(widget.bookId)
              .where((community) => community.id == widget.communityId)
              .firstOrNull;
    _isMember =
        _community != null && localData.isMemberOfCommunity(_communityId);

    context.read<DiscussionBloc>().add(
      LoadThread(
        cfi: widget.cfi,
        currentReaderCfi: currentReaderCfi,
        communityId: _communityId,
      ),
    );
  }

  void _handleJoinCircle() async {
    final localData = context.read<LocalDataService>();
    if (_community == null) return;
    await localData.joinCommunity(_communityId);
    await localData.selectCommunityForBook(
      bookId: widget.bookId,
      communityId: _communityId,
    );

    setState(() {
      _isMember = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Joined Reading Circle for $_bookTitle! Discussions unlocked.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleCreateCircle() async {
    final localData = context.read<LocalDataService>();
    final book = localData.getBooks().where((b) => b.id == widget.bookId).firstOrNull;
    if (book == null) return;

    final community = await showDialog<Community>(
      context: context,
      builder: (context) => CreateCommunityDialog(
        preselectedBook: book,
      ),
    );

    if (community != null && mounted) {
      setState(() {
        _community = community;
        _isMember = true;
      });
      context.read<DiscussionBloc>().add(
        LoadThread(
          cfi: widget.cfi,
          currentReaderCfi: '',
          communityId: community.id,
        ),
      );
    }
  }

  void _navigateToCommunityDetail() {
    Navigator.pop(context); // Close bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityDetailView(
          bookId: widget.bookId,
          communityId: _communityId,
          communityName:
              _community?.name ?? widget.communityName ?? '$_bookTitle Circle',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DiscussionModal(
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with navigation actions.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _bookTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Discussion Threads',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.users),
                      tooltip: 'Go to Community Circle',
                      onPressed: _navigateToCommunityDetail,
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: !_isMember
                  ? Center(
                      child: SingleChildScrollView(
                        child: CommunityMembershipGate(
                          bookTitle: _bookTitle,
                          circleName: '$_bookTitle Circle',
                          onJoined: _handleJoinCircle,
                          onCreateCircle: _handleCreateCircle,
                        ),
                      ),
                    )
                  : BlocBuilder<DiscussionBloc, DiscussionState>(
                      builder: (context, state) {
                        if (state is DiscussionLoading ||
                            state is DiscussionInitial) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state is DiscussionSpoilerWarning) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.shieldAlert,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Spoiler Alert!',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'This discussion is ahead of your current reading progress.',
                                ),
                                const SizedBox(height: 24),
                                PrimaryButton(
                                  label: 'Reveal Anyway',
                                  onPressed: () {
                                    context.read<DiscussionBloc>().add(
                                      LoadThread(
                                        cfi: widget.cfi,
                                        currentReaderCfi: '',
                                        communityId: _communityId,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        }

                        if (state is DiscussionError) {
                          return Center(child: Text('Error: ${state.message}'));
                        }

                        if (state is DiscussionLoaded) {
                          return Column(
                            children: [
                              Builder(
                                builder: (context) {
                                  String quoteText =
                                      widget.quoteText?.trim().isNotEmpty ==
                                          true
                                      ? widget.quoteText!.trim()
                                      : 'Highlighted passage from reader';
                                  if (widget.quoteText?.trim().isNotEmpty !=
                                      true) {
                                    final highlight = context
                                        .read<LocalDataService>()
                                        .getHighlightsForBook(widget.bookId)
                                        .where((item) => item.cfi == widget.cfi)
                                        .firstOrNull;
                                    if (highlight != null)
                                      quoteText = highlight.text;
                                  }
                                  try {
                                    final locator = Locator.fromJsonString(
                                      widget.cfi,
                                    );
                                    if (locator?.text?.highlight?.isNotEmpty ==
                                        true) {
                                      quoteText = locator!.text!.highlight!;
                                    }
                                  } catch (_) {}
                                  return QuoteCard(text: quoteText);
                                },
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: state.comments.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 24),
                                  itemBuilder: (context, index) {
                                    final comment = state.comments[index];
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                          backgroundImage:
                                              comment.user?.avatarUrl != null
                                              ? NetworkImage(
                                                  comment.user!.avatarUrl!,
                                                )
                                              : null,
                                          child: comment.user?.avatarUrl == null
                                              ? const Icon(
                                                  LucideIcons.user,
                                                  size: 16,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    comment.user?.displayName ??
                                                        'Anonymous Scholar',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                  if (comment.rating != null)
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          LucideIcons.star,
                                                          size: 12,
                                                          color:
                                                              Colors.amber[700],
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          comment.rating!
                                                              .toStringAsFixed(
                                                                1,
                                                              ),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                              if (comment.title.isNotEmpty &&
                                                  comment.title != 'Passage' &&
                                                  comment.title != 'Chapter' &&
                                                  comment.title != 'Book')
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 2,
                                                        bottom: 4,
                                                      ),
                                                  child: Text(
                                                    comment.title,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                        0xFFB45309,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(height: 4),
                                              Text(
                                                comment.content,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),

                              // Reply Input
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: TextField(
                                  controller: _replyController,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Share a note or comment with your circle...',
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(LucideIcons.send),
                                      onPressed: () {
                                        if (_replyController.text
                                            .trim()
                                            .isNotEmpty) {
                                          context.read<DiscussionBloc>().add(
                                            PostComment(
                                              cfi: widget.cfi,
                                              text: _replyController.text
                                                  .trim(),
                                              bookId: widget.bookId,
                                              communityId: _communityId,
                                            ),
                                          );
                                          _replyController.clear();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
