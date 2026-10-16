import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

import 'package:bookies/data/models/book.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/features/discussion/views/discussions_bottom_sheet.dart';
import 'package:bookies/core/widgets/create_community_dialog.dart';

class ChapterListDrawer extends StatefulWidget {
  final Book book;
  final String? currentChapterTitle;
  final List<EpubChapter> chapters;
  final ValueChanged<EpubChapter>? onChapterSelected;

  const ChapterListDrawer({
    super.key,
    required this.book,
    this.chapters = const [],
    this.currentChapterTitle,
    this.onChapterSelected,
  });

  @override
  State<ChapterListDrawer> createState() => _ChapterListDrawerState();
}

class _ChapterListDrawerState extends State<ChapterListDrawer> {
  final ScrollController _scrollController = ScrollController();
  int _scrollAttempts = 0;

  Book get book => widget.book;
  String? get currentChapterTitle => widget.currentChapterTitle;
  List<EpubChapter> get chapters => widget.chapters;
  ValueChanged<EpubChapter>? get onChapterSelected => widget.onChapterSelected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  @override
  void didUpdateWidget(covariant ChapterListDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentChapterTitle != widget.currentChapterTitle ||
        oldWidget.chapters != widget.chapters) {
      _scrollAttempts = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrent() {
    if (!mounted || currentChapterTitle == null || _scrollAttempts > 12) return;
    _scrollAttempts++;
    final key = _keyForTitle(currentChapterTitle!);
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.35,
      );
      _scrollAttempts = 0;
    } else {
      // The drawer/ExpansionTile may still be laying out on its first frame.
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (mounted) _scrollToCurrent();
      });
    }
  }

  GlobalObjectKey _keyForTitle(String title) =>
      GlobalObjectKey('${book.id}:$title');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<LocalDataService>();

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.listTree,
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
                              'Table of Contents',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              book.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB45309).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFB45309).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.messageSquare,
                          size: 14,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap chapter discussion icon to read or add chapter notes',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFFB45309),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // close drawer
                        CreateCommunityDialog.show(context, book: book);
                      },
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('Create Community'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Table of contents
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                children: _buildEntries(context, theme, dataService, chapters),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                leading: const Icon(LucideIcons.arrowLeft, size: 18),
                title: const Text('Exit to Library'),
                onTap: () {
                  Navigator.pop(context); // close drawer
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEntries(
    BuildContext context,
    ThemeData theme,
    LocalDataService dataService,
    List<EpubChapter> entries,
  ) {
    return [
      for (final entry in entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: entry.subitems.isNotEmpty
              ? _buildSection(context, theme, dataService, entry)
              : _buildLeaf(context, theme, dataService, entry),
        ),
    ];
  }

  Widget _buildSection(
    BuildContext context,
    ThemeData theme,
    LocalDataService dataService,
    EpubChapter entry,
  ) {
    final isActivePart = _containsCurrent(entry);
    return Material(
      color: isActivePart
          ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.22)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
        minTileHeight: 54,
        shape: const Border(),
        collapsedShape: const Border(),
        visualDensity: VisualDensity.compact,
        initiallyExpanded: isActivePart,
        onExpansionChanged: (expanded) {
          if (expanded && isActivePart) {
            _scrollAttempts = 0;
            Future<void>.delayed(const Duration(milliseconds: 350), () {
              if (mounted) _scrollToCurrent();
            });
          }
        },
        leading: Icon(
          LucideIcons.folderOpen,
          size: 19,
          color: isActivePart
              ? theme.colorScheme.secondary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          entry.title,
          softWrap: true,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: isActivePart ? theme.colorScheme.secondary : null,
            height: 1.25,
          ),
        ),
        subtitle: Text(
          '${entry.subitems.length} ${entry.subitems.length == 1 ? 'entry' : 'entries'}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          Container(
            margin: const EdgeInsets.only(left: 19, right: 4, bottom: 6),
            padding: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              children: _buildEntries(
                context,
                theme,
                dataService,
                entry.subitems,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaf(
    BuildContext context,
    ThemeData theme,
    LocalDataService dataService,
    EpubChapter entry,
  ) {
    final type = _entryType(entry);
    final isSpecial = type != _TocEntryType.chapter;
    final isCurrent = entry.title == currentChapterTitle;
    final discussions = dataService.getChapterDiscussions(book.id, entry.title);

    final icon = switch (type) {
      _TocEntryType.cover => LucideIcons.image,
      _TocEntryType.map => LucideIcons.map,
      _TocEntryType.frontMatter => LucideIcons.fileText,
      _TocEntryType.chapter => LucideIcons.bookOpenText,
    };

    final radius = BorderRadius.circular(8);
    return Material(
      key: _keyForTitle(entry.title),
      color: isCurrent
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : isSpecial
          ? theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.55)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: isCurrent
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        dense: isSpecial,
        contentPadding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
        minTileHeight: isSpecial ? 48 : 58,
        minLeadingWidth: 24,
        horizontalTitleGap: 10,
        leading: Icon(
          icon,
          size: isSpecial ? 17 : 19,
          color: isCurrent
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          entry.title,
          softWrap: true,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
            height: 1.3,
          ),
        ),
        subtitle: isSpecial
            ? Text(
                _entryLabel(type),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : Text(
                '${discussions.length} ${discussions.length == 1 ? 'discussion' : 'discussions'}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
        trailing: isSpecial
            ? const Icon(LucideIcons.chevronRight, size: 18)
            : IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(LucideIcons.messageSquarePlus, size: 18),
                tooltip: 'Chapter Discussions',
                onPressed: () => _openDiscussions(context, entry.title),
              ),
        onTap: entry.href.isEmpty ? null : () => _select(context, entry),
      ),
    );
  }

  bool _containsCurrent(EpubChapter entry) =>
      entry.title == currentChapterTitle ||
      entry.subitems.any(_containsCurrent);

  void _select(BuildContext context, EpubChapter entry) {
    Navigator.pop(context);
    onChapterSelected?.call(entry);
  }

  void _openDiscussions(BuildContext context, String title) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DiscussionsBottomSheet(bookId: book.id, cfi: title),
    );
  }

  _TocEntryType _entryType(EpubChapter entry) {
    final value = '${entry.title} ${entry.href}'.toLowerCase();
    if (value.contains('cover')) return _TocEntryType.cover;
    if (value.contains('map')) return _TocEntryType.map;
    if (value.contains('title page') ||
        value.contains('copyright') ||
        value.contains('dedication') ||
        value.contains('contents') ||
        value.contains('preface') ||
        value.contains('foreword')) {
      return _TocEntryType.frontMatter;
    }
    return _TocEntryType.chapter;
  }

  String _entryLabel(_TocEntryType type) => switch (type) {
    _TocEntryType.cover => 'Cover',
    _TocEntryType.map => 'Map',
    _TocEntryType.frontMatter => 'Front matter',
    _TocEntryType.chapter => 'Chapter',
  };
}

enum _TocEntryType { chapter, cover, map, frontMatter }
