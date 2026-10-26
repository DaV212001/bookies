import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bookies/core/widgets/create_thread_dialog.dart';
import 'package:bookies/core/widgets/quote_card_rating_widget.dart';
import 'package:bookies/core/widgets/responsive_text.dart';
import 'package:bookies/data/models/book.dart';
import 'package:bookies/data/models/discussion.dart';
import 'package:bookies/data/models/highlight.dart';
import 'package:bookies/data/models/thread_scope.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/features/community/views/management/community_management_view.dart';
import 'package:bookies/features/community/bloc/community_bloc.dart';
import 'package:bookies/features/discussion/views/discussion_chat_screen.dart';
import 'package:bookies/features/reader/views/reader_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bookies/domain/repositories/book_repository.dart';
import 'package:bookies/domain/repositories/catalog_repository.dart';
import 'package:bookies/domain/entities/catalog_book_entity.dart';
import 'package:bookies/core/widgets/edition_fingerprint_scanner_modal.dart';

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

  bool _isDownloadingCommunityBook = false;

  Future<void> _downloadAndSyncCommunityEdition(BuildContext context) async {
    if (_isDownloadingCommunityBook) return;
    final messenger = ScaffoldMessenger.of(context);
    final catalogRepo = context.read<CatalogRepository>();
    final dataService = context.read<LocalDataService>();

    final community = dataService.communities
        .where((c) => c.id == widget.communityId)
        .firstOrNull;

    setState(() => _isDownloadingCommunityBook = true);

    try {
      final scanResult = await EditionFingerprintScannerModal.show(
        context: context,
        title: 'Syncing Community Edition',
        subtitle: widget.communityName,
        onScan: (updateProgress) async {
          updateProgress('Connecting to edition stream...', 0.15);

          // 1. Resolve target download endpoint
          CatalogBookEntity targetCatalogBook;
          if (community?.downloadUrl != null && community!.downloadUrl!.isNotEmpty) {
            targetCatalogBook = CatalogBookEntity(
              id: widget.bookId,
              title: widget.communityName,
              author: community.editionTitle ?? 'Official Edition',
              downloadUrl: community.downloadUrl,
            );
          } else {
            final catalogBooks = await catalogRepo.getDiscoverCatalog();
            var matching = catalogBooks.where((b) => b.id == widget.bookId).firstOrNull;
            if (matching == null) {
              final searchResults = await catalogRepo.searchCatalog(widget.communityName);
              matching = searchResults.firstOrNull;
            }
            targetCatalogBook = matching ??
                CatalogBookEntity(
                  id: widget.bookId,
                  title: widget.communityName,
                  author: 'Official Edition',
                  downloadUrl: '/catalog/${widget.bookId}/download',
                );
          }

          updateProgress('Downloading & unpacking EPUB archive...', 0.45);
          final importedBook = await catalogRepo.downloadAndImportBook(
            catalogBook: targetCatalogBook,
          );

          updateProgress('Calibrating chapter spine & DOM text nodes...', 0.75);
          await Future.delayed(const Duration(milliseconds: 250));

          updateProgress('Verifying Readium CFI compatibility digest...', 0.95);
          final canonicalFingerprint = community?.canonicalFingerprint;
          final isMatch = canonicalFingerprint != null &&
              canonicalFingerprint.isNotEmpty &&
              importedBook.fingerprint == canonicalFingerprint;

          await dataService.selectCommunityForBook(
            bookId: importedBook.id,
            communityId: widget.communityId,
          );

          return FingerprintScanResult(
            isSuccess: true,
            isMatch: isMatch,
            computedFingerprint: importedBook.fingerprint,
            expectedFingerprint: canonicalFingerprint,
            payload: importedBook,
          );
        },
      );

      if (mounted) {
        setState(() => _isDownloadingCommunityBook = false);
        if (scanResult != null && scanResult.isMatch) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Official Community Edition verified & synced! (100% Match)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloadingCommunityBook = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndImportLocalBook(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final bookRepo = context.read<BookRepository>();
    final dataService = context.read<LocalDataService>();
    try {
      final pickResult = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );
      if (pickResult != null && pickResult.files.single.path != null) {
        final filePath = pickResult.files.single.path!;
        final community = dataService.communities
            .where((c) => c.id == widget.communityId)
            .firstOrNull;

        if (!context.mounted) return;

        final scanResult = await EditionFingerprintScannerModal.show(
          context: context,
          title: 'Scanning Imported EPUB',
          subtitle: pickResult.files.single.name,
          onScan: (updateProgress) async {
            updateProgress('Reading local EPUB file...', 0.25);
            updateProgress('Extracting reading spine & DOM elements...', 0.60);
            final imported = await bookRepo.importBook(filePath);

            updateProgress('Calibrating CFI anchors with community...', 0.90);
            final canonicalFingerprint = community?.canonicalFingerprint;
            final isMatch = canonicalFingerprint != null &&
                canonicalFingerprint.isNotEmpty &&
                imported.fingerprint == canonicalFingerprint;

            await dataService.selectCommunityForBook(
              bookId: imported.id,
              communityId: widget.communityId,
            );

            return FingerprintScanResult(
              isSuccess: true,
              isMatch: isMatch,
              computedFingerprint: imported.fingerprint,
              expectedFingerprint: canonicalFingerprint,
              payload: imported,
            );
          },
        );

        if (mounted) {
          setState(() {});
          if (scanResult != null && scanResult.isMatch) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Imported EPUB verified! 100% in sync.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to import EPUB: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  bool _isEditionSynced(LocalDataService dataService, Book? exactBook) {
    if (exactBook == null) return false;
    final community = dataService.communities
        .where((c) => c.id == widget.communityId)
        .firstOrNull;
    if (community == null) return false;
    final canonicalFingerprint = community.canonicalFingerprint;
    // Strict edition verification: Fail closed!
    if (canonicalFingerprint == null || canonicalFingerprint.isEmpty) {
      // If current user created this community and has the book, calibrate it now!
      if (community.creatorId == dataService.currentUser.id && exactBook.fingerprint.isNotEmpty) {
        dataService.calibrateCommunityCanonicalFingerprint(community.id, exactBook.fingerprint);
        return true;
      }
      return false; // Regular members cannot progress until canonical standard is established
    }
    return exactBook.fingerprint == canonicalFingerprint;
  }

  Widget _buildEditionSyncBadge(
    ThemeData theme,
    LocalDataService dataService,
    Book? exactBook,
  ) {
    // If the book edition matches canonical fingerprint, remove the exact match badge completely
    if (_isEditionSynced(dataService, exactBook)) {
      return const SizedBox.shrink();
    }

    final allBooks = dataService.getBooks();
    final normalizedCommName = widget.communityName.toLowerCase();
    final alternateBook = allBooks.where((b) {
      final normalizedTitle = b.title.toLowerCase();
      return normalizedTitle.contains(normalizedCommName) ||
          normalizedCommName.contains(normalizedTitle);
    }).firstOrNull;

    if (alternateBook != null) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.triangleAlert, size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Text(
                  'Different EPUB Edition Detected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'You have an alternate edition (${alternateBook.title}). You must sync to the official community edition before you can participate in discussions or reading.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            _isDownloadingCommunityBook
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(LucideIcons.downloadCloud, size: 14),
                    label: const Text('Download Official Community Edition', style: TextStyle(fontSize: 12)),
                    onPressed: () => _downloadAndSyncCommunityEdition(context),
                  ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.bookDown, color: Colors.amber.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Official Community Edition Required',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.amber.shade800,
                  ),
                ),
                Text(
                  'Download the verified EPUB to unlock community discussions and reading.',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          _isDownloadingCommunityBook
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : FilledButton.tonal(
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => _downloadAndSyncCommunityEdition(context),
                  child: const Text('Download', style: TextStyle(fontSize: 12)),
                ),
        ],
      ),
    );
  }

  Widget _buildEditionSyncGate(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.gitFork,
                  size: 32,
                  color: Colors.amber.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Edition Sync Required',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This community is synchronized to a specific EPUB release. To participate in passage discussions, view shared chapter highlights, and join co-reading sessions, you must sync to the official edition.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _isDownloadingCommunityBook
                  ? const SizedBox(
                      height: 32,
                      width: 32,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(LucideIcons.downloadCloud, size: 16),
                      label: const Text(
                        'Download & Sync Official Edition',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _downloadAndSyncCommunityEdition(context),
                    ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(LucideIcons.folderOpen, size: 16),
                label: const Text('Import Own EPUB (BYOB / Telegram)'),
                onPressed: () => _pickAndImportLocalBook(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditionSyncRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.triangleAlert, color: Colors.amber),
            SizedBox(width: 8),
            Text('Edition Sync Required'),
          ],
        ),
        content: const Text(
          'Your EPUB edition differs from the community edition (or is not yet in your library). Page numbers, chapter DOM markers, and CFI anchors must match so everyone\'s highlights and live reading stay aligned.\n\nPlease sync to the official community edition to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _pickAndImportLocalBook(context);
            },
            icon: const Icon(LucideIcons.folderOpen, size: 16),
            label: const Text('Import File'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.amber.shade800),
            onPressed: () {
              Navigator.pop(ctx);
              _downloadAndSyncCommunityEdition(context);
            },
            icon: const Icon(LucideIcons.downloadCloud, size: 16),
            label: const Text('Download Sync'),
          ),
        ],
      ),
    );
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
    try {
      context.read<CommunityBloc>().add(JoinCommunityRequested(widget.communityId));
    } catch (_) {
      await context.read<LocalDataService>().joinCommunity(widget.communityId);
    }
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
    final bookThreads = <Discussion>[];
    final chapterThreads = <Discussion>[];
    final highlightThreads = <Discussion>[];
    for (final discussion in discussions) {
      switch (discussion.scope) {
        case ThreadScope.book:
          bookThreads.add(discussion);
          break;
        case ThreadScope.chapter:
          chapterThreads.add(discussion);
          break;
        case ThreadScope.passage:
          highlightThreads.add(discussion);
          break;
        case ThreadScope.topic:
        case ThreadScope.subtopic:
          break;
      }
    }
    final highlights = dataService.getHighlightsForBook(widget.bookId);
    final quotes = dataService.getFavoriteQuotes(widget.bookId);

    final isSynced = _isEditionSynced(dataService, book);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!isSynced) {
            _showEditionSyncRequiredDialog(context);
            return;
          }
          if (isMember) {
            _openCreateThreadModal();
          } else {
            _joinCommunity();
          }
        },
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: theme.colorScheme.onSecondary,
        icon: Icon(
          !isSynced
              ? LucideIcons.downloadCloud
              : (isMember ? LucideIcons.messageSquarePlus : LucideIcons.userPlus),
          size: 18,
        ),
        label: Text(
          !isSynced
              ? 'Sync Edition to Discuss'
              : (isMember ? 'Start Discussion' : 'Join community'),
        ),
      ),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: _buildCommunityHeader(
                theme,
                book,
                discussions.length,
                dataService,
                isSynced,
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
          body: !isSynced
              ? _buildEditionSyncGate(theme)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGlobalTab(theme, discussions, bookThreads),
                    _buildChapterTab(theme, book, chapterThreads),
                    _buildHighlightsTab(theme, book, highlights, highlightThreads),
                    _buildQuotesTab(theme, quotes),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCommunityHeader(
    ThemeData theme,
    Book? book,
    int discussionCount,
    LocalDataService dataService,
    bool isSynced,
  ) {
    final canManage = dataService.canManageCommunity(widget.communityId);
    final members = dataService.getCommunityMembers(widget.communityId);
    final activeMemberCount = members.where((m) => !m.isBanned).length;
    final activeLiveSession =
        dataService.getActiveLiveReadingSession(widget.communityId);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Back',
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Share Deep Link',
                    icon: const Icon(LucideIcons.share2),
                    onPressed: () {
                      final deepLink = 'https://bookies.app/community/${widget.communityId}';
                      Clipboard.setData(ClipboardData(text: deepLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Deep link copied: $deepLink'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  if (canManage) ...[
                    const SizedBox(width: 4),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(LucideIcons.shieldCheck, size: 16),
                      label: const Text('Reader Management'),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (_) => CommunityManagementView(
                              communityId: widget.communityId,
                              communityName: widget.communityName,
                              bookId: widget.bookId,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ],
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
            child: _buildCover(theme, book?.coverUrl),
          ),
          ResponsiveText.display(
            widget.communityName,
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            minFontSize: 18,
          ),
          const SizedBox(height: 4),
          ResponsiveText.body(
            'by ${book?.author ?? 'Unknown author'}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            minFontSize: 12,
            textAlign: TextAlign.center,
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
                '$activeMemberCount Active Readers',
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
          _buildEditionSyncBadge(theme, dataService, book),
          if (activeLiveSession != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'LIVE READING',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ ${activeLiveSession.participantUserIds.length} listening',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        ResponsiveText.title(
                          activeLiveSession.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 2,
                          minFontSize: 11,
                        ),
                        ResponsiveText.label(
                          'Host: ${activeLiveSession.host.displayName} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ ${activeLiveSession.chapterTitle ?? 'Reading in sync'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          minFontSize: 9.5,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(LucideIcons.radio, size: 14),
                    label: const Text('Join Live'),
                    onPressed: () async {
                      if (!isSynced) {
                        _showEditionSyncRequiredDialog(context);
                        return;
                      }
                      final canJoin = dataService.canUserJoinLiveReading(
                        widget.communityId,
                        dataService.currentUser.id,
                      );
                      if (canJoin) {
                        await dataService.joinLiveReadingSession(
                          widget.communityId,
                          dataService.currentUser.id,
                        );
                        if (mounted && book != null) {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => ReaderView(
                                book: book,
                                initialCfi: activeLiveSession.currentCfi,
                              ),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Access to this live session is restricted by the community creator.'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
          if (book != null && isSynced) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => ReaderView(book: book),
                  ),
                );
              },
              icon: const Icon(LucideIcons.bookOpen, size: 18),
              label: const Text('Read Book'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _downloadAndSyncCommunityEdition(context),
              icon: _isDownloadingCommunityBook
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.downloadCloud, size: 18),
              label: Text(_isDownloadingCommunityBook
                  ? 'Syncing Edition...'
                  : 'Sync Community Edition to Read'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
    final topics = context.watch<LocalDataService>().getTopicsForBook(
          widget.bookId,
          communityId: widget.communityId,
        );
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
    final dataService = context.watch<LocalDataService>();
    final subtopics = dataService.getSubtopics(topic.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _openDiscussion(topic),
              child: Row(
                children: [
                  Icon(LucideIcons.hash, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ResponsiveText.title(
                      topic.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      minFontSize: 13,
                    ),
                  ),
                  Text(
                    '${subtopics.length} subtopics',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(LucideIcons.chevronRight, size: 18, color: theme.colorScheme.outline),
                ],
              ),
            ),
            if (topic.content.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  topic.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            if (subtopics.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 6),
              ...subtopics.map((sub) => InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _openDiscussion(sub),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: Row(
                        children: [
                          Icon(LucideIcons.cornerDownRight, size: 16, color: theme.colorScheme.outline),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sub.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(LucideIcons.messageSquare, size: 14, color: theme.colorScheme.outline),
                        ],
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChapterTab(ThemeData theme, Book? book, List<Discussion> threads) {
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
    final entries = grouped.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) => _buildChapterCard(
        theme,
        book,
        entries[index].key,
        entries[index].value,
      ),
    );
  }

  Widget _buildHighlightsTab(
    ThemeData theme,
    Book? book,
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: highlights.length,
      itemBuilder: (context, index) {
        final highlight = highlights[index];
        return _buildHighlightCard(
          theme,
          book,
          highlight,
          discussionsByHighlight[highlight.cfi] ?? const [],
        );
      },
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        final quote = quotes[index];
        return QuoteCardRatingWidget(
          quote: quote,
          onUpvote: () async {
            await dataService.upvoteQuote(quote.id);
            setState(() {});
          },
        );
      },
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
    Book? book,
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
                  '${threads.length} discussions Ãƒâ€šÃ‚Â· ${threads.fold<int>(0, (sum, item) => sum + (item.replies?.length ?? 1))} messages',
                ),
              ],
            ),
          ),
          if (book != null)
            IconButton(
              icon: const Icon(LucideIcons.bookOpen, size: 18),
              tooltip: 'Read chapter in book',
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => ReaderView(book: book, initialCfi: chapter),
                  ),
                );
              },
            ),
          const Icon(LucideIcons.chevronRight, size: 18),
        ],
      ),
    );
  }

  Widget _buildHighlightCard(
    ThemeData theme,
    Book? book,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metadata(
                theme,
                discussions.isEmpty
                    ? 'No discussion yet'
                    : '${discussions.length} ${discussions.length == 1 ? 'message' : 'messages'}',
              ),
              if (book != null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(LucideIcons.bookOpen, size: 14),
                  label: const Text('Read in book', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => ReaderView(
                          book: book,
                          initialCfi: highlight.cfi,
                        ),
                      ),
                    );
                  },
                ),
            ],
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
