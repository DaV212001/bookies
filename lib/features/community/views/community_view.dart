import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/core/widgets/community_membership_gate.dart';
import 'package:bookies/features/community/views/community_detail_view.dart';

class CommunitiesView extends StatefulWidget {
  const CommunitiesView({super.key});

  @override
  State<CommunitiesView> createState() => _CommunitiesViewState();
}

class _CommunitiesViewState extends State<CommunitiesView> {
  String _selectedFilter = 'All Circles';

  void _navigateToDetail(String bookId, String communityName, String description) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityDetailView(
          bookId: bookId,
          communityName: communityName,
          description: description,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;
    final localData = context.watch<LocalDataService>();

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
              'Reading Clubs & Discussion Circles',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            tooltip: 'Create Circle',
            onPressed: () => _showCreateCircleDialog(context, theme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCircleDialog(context, theme),
        backgroundColor: secondary,
        foregroundColor: theme.colorScheme.onSecondary,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Create Circle'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Filter Chips Row
          _buildFilterRow(theme),

          const SizedBox(height: 20),

          // Active Reading Clubs Section
          if (_selectedFilter == 'All Circles' ||
              _selectedFilter == 'My Clubs') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Reading Circles',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Active Clubs',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildClubCard(
              theme,
              localData,
              title: 'Modern Classics Society',
              description:
                  'Currently exploring 20th century literary masterpieces.',
              membersCount: 342,
              targetChapter: 'Chapter 12: The Descent',
              activeBook: 'The Secret History',
              bookId: 'mock-book-1',
              progress: 0.65,
              tag: 'Private Circle',
            ),
            const SizedBox(height: 14),

            _buildClubCard(
              theme,
              localData,
              title: 'Deep Sci-Fi Collective',
              description:
                  'Deep analytical reads of speculative fiction and space epics.',
              membersCount: 189,
              targetChapter: 'Chapter 4: First Contact',
              activeBook: 'Dune Messiah',
              bookId: 'mock-book-2',
              progress: 0.35,
              tag: 'Public Circle',
            ),
            const SizedBox(height: 14),

            _buildClubCard(
              theme,
              localData,
              title: 'Philosophy & Mind',
              description:
                  'Explorations into classical philosophy and consciousness.',
              membersCount: 512,
              targetChapter: 'Book II: The Cave Metaphor',
              activeBook: "Plato's Republic",
              bookId: 'mock-book-3',
              progress: 0.80,
              tag: 'Public Circle',
            ),

            const SizedBox(height: 28),
          ],

          // Spoiler Guarded Discussions Section Header
          if (_selectedFilter == 'All Circles' ||
              _selectedFilter == 'Spoiler Threads') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Chapter & Passage Threads',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildThreadTile(
              theme,
              localData,
              chapterTitle: 'Chapter 12: The Descent',
              bookTitle: 'The Secret History',
              bookId: 'mock-book-1',
              authorName: 'Julian Morrow',
              excerpt:
                  "The psychological toll of Henry's decision becomes evident in the opening pages of this section...",
              timeAgo: '12m ago',
              isUnlocked: true,
              repliesCount: 24,
            ),
            _buildThreadTile(
              theme,
              localData,
              chapterTitle: 'Chapter 15: The Epilogue',
              bookTitle: 'The Secret History',
              bookId: 'mock-book-1',
              authorName: 'Richard Papen',
              excerpt:
                  '[SPOILER PROTECTED] Reach Chapter 15 in your reader to automatically unlock this discussion thread.',
              timeAgo: '1h ago',
              isUnlocked: false,
              repliesCount: 58,
            ),
            _buildThreadTile(
              theme,
              localData,
              chapterTitle: 'Chapter 4: First Contact',
              bookTitle: 'Dune Messiah',
              bookId: 'mock-book-2',
              authorName: 'Paul Atreides',
              excerpt:
                  'Analyzing the political maneuvering between the Bene Gesserit and Spacing Guild...',
              timeAgo: '3h ago',
              isUnlocked: true,
              repliesCount: 15,
            ),
          ],

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildFilterRow(ThemeData theme) {
    final filters = ['All Circles', 'My Clubs', 'Spoiler Threads'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onSecondary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                }
              },
              selectedColor: theme.colorScheme.secondary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClubCard(
    ThemeData theme,
    LocalDataService localData, {
    required String title,
    required String description,
    required int membersCount,
    required String targetChapter,
    required String activeBook,
    required String bookId,
    required double progress,
    required String tag,
  }) {
    final secondary = theme.colorScheme.secondary;
    final isMember = localData.isMemberOfCommunity(title) ||
        localData.isMemberOfCommunity(activeBook);

    return InkWell(
      onTap: () => _navigateToDetail(bookId, title, description),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.users,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$membersCount',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.35,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.bookOpen, size: 16, color: secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeBook,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              targetChapter,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isMember)
                        ElevatedButton.icon(
                          onPressed: () {
                            _navigateToDetail(bookId, title, description);
                          },
                          icon: const Icon(LucideIcons.messagesSquare, size: 14),
                          label: const Text('Open Circle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondary,
                            foregroundColor: theme.colorScheme.onSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: const Size(0, 32),
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () async {
                            await localData.joinCommunity(title);
                            await localData.joinCommunity(activeBook);
                            setState(() {});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Joined $title! Discussions unlocked.'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(LucideIcons.userPlus, size: 14),
                          label: const Text('Join Circle'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: const Size(0, 32),
                            side: BorderSide(color: secondary.withOpacity(0.8)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Reading Progress',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: theme.colorScheme.surfaceContainerHigh,
                      color: secondary,
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

  Widget _buildThreadTile(
    ThemeData theme,
    LocalDataService localData, {
    required String chapterTitle,
    required String bookTitle,
    required String bookId,
    required String authorName,
    required String excerpt,
    required String timeAgo,
    required bool isUnlocked,
    required int repliesCount,
  }) {
    final secondary = theme.colorScheme.secondary;
    final isMember = localData.isMemberOfCommunity(bookTitle);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (!isMember) {
            _showGateBottomSheet(context, bookTitle);
          } else {
            _navigateToDetail(bookId, '$bookTitle Society', 'Discussion hub for $bookTitle');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    !isMember
                        ? LucideIcons.lock
                        : (isUnlocked ? LucideIcons.lockOpen : LucideIcons.shieldAlert),
                    size: 16,
                    color: isMember && isUnlocked
                        ? secondary
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chapterTitle,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isMember && isUnlocked
                          ? secondary.withOpacity(0.12)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      !isMember
                          ? 'Join Circle to View'
                          : (isUnlocked ? 'Unlocked' : 'Spoiler Guarded'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isMember && isUnlocked
                            ? secondary
                            : theme.colorScheme.outline,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeAgo,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$bookTitle • by $authorName',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                !isMember
                    ? '[LOCKED] Join or create a circle for "$bookTitle" to view and post chapter threads.'
                    : excerpt,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isMember && isUnlocked
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.outline,
                  fontStyle: isMember && isUnlocked
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    LucideIcons.messageSquare,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$repliesCount discussions',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
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

  void _showGateBottomSheet(BuildContext context, String bookTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: CommunityMembershipGate(
          bookTitle: bookTitle,
          circleName: '$bookTitle Society',
          onJoined: () async {
            Navigator.pop(context);
            final localData = context.read<LocalDataService>();
            await localData.joinCommunity(bookTitle);
            setState(() {});
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Joined $bookTitle circle!')),
              );
            }
          },
          onCreateCircle: () {
            Navigator.pop(context);
            _showCreateCircleDialog(context, Theme.of(context));
          },
        ),
      ),
    );
  }

  void _showCreateCircleDialog(BuildContext context, ThemeData theme) {
    final titleController = TextEditingController();
    final bookController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Reading Circle',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Start a synchronous book club with friends or public readers.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Circle Name',
                  hintText: 'e.g., Modern Philosophy Salon',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bookController,
                decoration: InputDecoration(
                  labelText: 'Active Book',
                  hintText: 'e.g., Dune Messiah',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final circleName = titleController.text.trim();
                    final bookName = bookController.text.trim();
                    if (circleName.isNotEmpty) {
                      final localData = context.read<LocalDataService>();
                      await localData.createCommunity(
                        name: circleName,
                        description: 'Reading circle for $bookName',
                        bookId: bookName,
                      );
                      setState(() {});
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reading Circle created!'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Create Circle'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
