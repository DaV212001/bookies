import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter/services.dart';

import 'package:bookies/data/models/book.dart';
import 'package:bookies/data/models/thread_scope.dart';
import 'package:bookies/data/models/community.dart';
import 'package:bookies/data/models/highlight.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/features/reader/bloc/reader_bloc.dart';
import 'package:bookies/features/discussion/views/discussions_bottom_sheet.dart';
import 'package:bookies/core/widgets/reading_well.dart';
import 'package:bookies/core/widgets/ambient_progress_bar.dart';
import 'package:bookies/features/reader/views/reading_settings_modal.dart';
import 'package:bookies/features/reader/views/chapter_list_drawer.dart';
import 'package:bookies/features/reader/widgets/epub_js_reader.dart';
import 'package:bookies/core/widgets/create_thread_dialog.dart';
import 'package:bookies/core/widgets/create_community_dialog.dart';

class ReaderView extends StatefulWidget {
  final Book? book;

  const ReaderView({super.key, this.book});

  @override
  State<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<ReaderView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<bool> _showControlsNotifier = ValueNotifier(true);
  bool _isFullScreen = false;
  bool _isZooming = false;
  double? _displayFontSizeRatio;
  Timer? _zoomOverlayTimer;

  // Gesture tracking state
  final Map<int, Offset> _activePointers = {};
  double _initialPinchDistance = 0.0;
  double _baseFontSizeOnPinch = 1.0;
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;
  List<EpubChapter> _chapters = const [];
  String? _chaptersBookId;
  String? _currentChapterTitle;
  String? _chapterTarget;
  int _drawerOpenCount = 0;
  Community? _activeCommunity(LocalDataService data, String bookId) {
    return data.getSelectedCommunityForBook(bookId);
  }

  Future<Community?> _chooseCommunity(String bookId) async {
    final data = context.read<LocalDataService>();
    final communities = data.getJoinedCommunitiesForBook(bookId);
    
    return showModalBottomSheet<Community>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              communities.isEmpty ? 'Book Communities' : 'Switch community',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...communities.map(
              (community) => ListTile(
                title: Text(community.name),
                leading: const Icon(LucideIcons.users),
                trailing: community.id == _activeCommunity(data, bookId)?.id
                    ? const Icon(LucideIcons.check)
                    : null,
                onTap: () => Navigator.pop(context, community),
              ),
            ),
            if (communities.isNotEmpty) const Divider(),
            ListTile(
              title: const Text('Create new community'),
              leading: const Icon(LucideIcons.plus),
              onTap: () async {
                Navigator.pop(context); // Close bottom sheet
                if (widget.book != null) {
                  CreateCommunityDialog.show(context, book: widget.book!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _switchCommunity(String bookId) async {
    final community = await _chooseCommunity(bookId);
    if (community == null || !mounted) return;
    await context.read<LocalDataService>().selectCommunityForBook(
      bookId: bookId,
      communityId: community.id,
    );
  }

  Future<void> _discussSelection(
    ReaderLoaded state,
    EpubTextSelection selection,
  ) async {
    final data = context.read<LocalDataService>();
    final community = _activeCommunity(data, state.book.id);
    if (!mounted) return;
    if (community == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Join or create a community for this book first.'),
        ),
      );
      return;
    }
    final text = selection.selectedText.trim();
    if (text.isEmpty) return;
    final existing = data
        .getHighlightsForBook(state.book.id)
        .any((highlight) => highlight.cfi == selection.selectionCfi);
    if (!existing) {
      await data.addHighlight(
        Highlight(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          bookId: state.book.id,
          userId: data.currentUser.id,
          text: text,
          cfi: selection.selectionCfi,
          createdAt: DateTime.now(),
        ),
      );
    }
    showDialog(
      context: context,
      builder: (_) => CreateThreadDialog(
        bookId: state.book.id,
        communityId: community.id,
        communityName: community.name,
        initialScope: ThreadScope.passage,
        initialQuoteText: selection.selectedText,
        initialHighlightId: selection.selectionCfi,
        initialChapterTitle: _currentChapterTitle,
        onThreadCreated: () => setState(() {}),
      ),
    );
  }

  Future<void> _highlightSelection(
    ReaderLoaded state,
    EpubTextSelection selection,
  ) async {
    final text = selection.selectedText.trim();
    if (text.isEmpty || selection.selectionCfi.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select some passage text before highlighting.'),
          ),
        );
      }
      return;
    }
    final data = context.read<LocalDataService>();
    await data.addHighlight(
      Highlight(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        bookId: state.book.id,
        userId: data.currentUser.id,
        text: text,
        cfi: selection.selectionCfi,
        createdAt: DateTime.now(),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Highlight saved.')));
    }
  }

  Future<void> _saveQuoteSelection(
    ReaderLoaded state,
    EpubTextSelection selection,
  ) async {
    await context.read<LocalDataService>().addFavoriteQuote(
      bookId: state.book.id,
      bookTitle: state.book.title,
      chapterTitle: _currentChapterTitle ?? 'Current passage',
      quoteText: selection.selectedText,
      authorName: state.book.author,
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      context.read<ReaderBloc>().add(LoadBook(widget.book!));
    }
  }

  @override
  void dispose() {
    _zoomOverlayTimer?.cancel();
    _showControlsNotifier.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleFullScreen() {
    final newFullScreenState = !_isFullScreen;
    setState(() {
      _isFullScreen = newFullScreenState;
      _showControlsNotifier.value = !newFullScreenState;
    });
    if (newFullScreenState) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.position;

    if (_activePointers.length == 1) {
      final now = DateTime.now();
      if (_lastTapTime != null && _lastTapPosition != null) {
        final timeDiff = now.difference(_lastTapTime!);
        final distDiff = (event.position - _lastTapPosition!).distance;

        if (timeDiff < const Duration(milliseconds: 350) && distDiff < 40.0) {
          _lastTapTime = null;
          _lastTapPosition = null;
          _toggleFullScreen();
          return;
        }
      }
      _lastTapTime = now;
      _lastTapPosition = event.position;
    } else if (_activePointers.length == 2) {
      final positions = _activePointers.values.toList();
      _initialPinchDistance = (positions[0] - positions[1]).distance;

      final state = context.read<ReaderBloc>().state;
      if (state is ReaderLoaded) {
        _baseFontSizeOnPinch = state.preferences.fontSize ?? 1.0;
      }

      _zoomOverlayTimer?.cancel();
      setState(() {
        _isZooming = true;
        _displayFontSizeRatio = _baseFontSizeOnPinch;
      });
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_activePointers.containsKey(event.pointer)) return;
    _activePointers[event.pointer] = event.position;

    if (_activePointers.length == 2 &&
        _initialPinchDistance > 10.0 &&
        _isZooming) {
      final positions = _activePointers.values.toList();
      final currentDist = (positions[0] - positions[1]).distance;
      final scale = currentDist / _initialPinchDistance;

      final calculated = (_baseFontSizeOnPinch * scale).clamp(0.4, 2.5);
      final rounded = (calculated * 20).round() / 20.0;

      final state = context.read<ReaderBloc>().state;
      if (state is ReaderLoaded) {
        final currentFontSize = state.preferences.fontSize ?? 1.0;
        if ((rounded - currentFontSize).abs() >= 0.04) {
          context.read<ReaderBloc>().add(ChangeFontSize(rounded));
          setState(() {
            _displayFontSizeRatio = rounded;
          });
        }
      }
    }
  }

  void _handlePointerUpOrCancel(PointerEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.length < 2 && _isZooming) {
      _zoomOverlayTimer?.cancel();
      _zoomOverlayTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _isZooming = false;
          });
        }
      });
    }
  }

  void _showDiscussions(
    BuildContext context,
    String bookId,
    String? currentCfi,
    Community? community,
  ) {
    final quoteText = context
        .read<LocalDataService>()
        .getDiscussionsForCfi(currentCfi ?? '')
        .map((discussion) => discussion.quoteText)
        .firstWhere(
          (text) => text?.trim().isNotEmpty == true,
          orElse: () => null,
        );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DiscussionsBottomSheet(
        bookId: bookId,
        cfi: currentCfi ?? '',
        communityId: community?.id,
        communityName: community?.name,
        quoteText: quoteText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
      builder: (context, state) {
        Color? backgroundColor;
        Color? foregroundColor;

        if (state is ReaderLoaded) {
          backgroundColor = state.preferences.backgroundColor;
          foregroundColor = state.preferences.textColor;
        }

        final theme = Theme.of(context);
        backgroundColor ??= theme.scaffoldBackgroundColor;
        foregroundColor ??= theme.colorScheme.onSurface;

        final isDarkBg =
            ThemeData.estimateBrightnessForColor(backgroundColor) ==
            Brightness.dark;

        final overlayStyle = isDarkBg
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark;

        final currentBook = state is ReaderLoaded ? state.book : widget.book;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: backgroundColor,
          onDrawerChanged: (isOpened) {
            if (isOpened) {
              setState(() => _drawerOpenCount++);
            }
          },
          drawer: currentBook != null
              ? ChapterListDrawer(
                  key: ValueKey(
                    '${currentBook.id}:$_currentChapterTitle:$_drawerOpenCount',
                  ),
                  book: currentBook,
                  chapters: _chaptersBookId == currentBook.id
                      ? _chapters
                      : const [],
                  currentChapterTitle: _currentChapterTitle,
                  onChapterSelected: (chapter) {
                    setState(() {
                      _currentChapterTitle = chapter.title;
                      _chapterTarget = chapter.href;
                    });
                  },
                )
              : null,
          appBar: _isFullScreen
              ? null
              : AppBar(
                  backgroundColor: backgroundColor.withValues(alpha: 0.95),
                  foregroundColor: foregroundColor,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  systemOverlayStyle: overlayStyle,
                  iconTheme: IconThemeData(color: foregroundColor),
                  actionsIconTheme: IconThemeData(color: foregroundColor),
                  leading: IconButton(
                    icon: const Icon(LucideIcons.listTree),
                    tooltip: 'Table of Contents',
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  title: BlocBuilder<ReaderBloc, ReaderState>(
                    builder: (context, state) {
                      if (state is ReaderLoaded) {
                        return Text(
                          state.book.title,
                          style: TextStyle(
                            color: foregroundColor,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }
                      return Text(
                        'Reader',
                        style: TextStyle(
                          color: foregroundColor,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                  actions: [
                    if (state is ReaderLoaded)
                      Builder(
                        builder: (context) {
                          final community = _activeCommunity(
                            context.watch<LocalDataService>(),
                            state.book.id,
                          );
                          if (community == null) return const SizedBox.shrink();
                          return ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 156),
                            child: TextButton.icon(
                              onPressed: () => _switchCommunity(state.book.id),
                              icon: const Icon(LucideIcons.users, size: 17),
                              label: Text(
                                community.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                      ),
                    IconButton(
                      icon: const Icon(LucideIcons.slidersHorizontal),
                      tooltip: 'Reading Settings',
                      onPressed: () {
                        if (state is ReaderLoaded) {
                          ReadingSettingsModal.show(context);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.messageCircle),
                      tooltip: 'Discussions',
                      onPressed: () {
                        if (state is ReaderLoaded) {
                          _showDiscussions(
                            context,
                            state.book.id,
                            state.currentCfi,
                            _activeCommunity(
                              context.read<LocalDataService>(),
                              state.book.id,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
          body: () {
            if (state is ReaderLoading || state is ReaderInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ReaderError) {
              return Center(child: Text('Error: ${state.message}'));
            }

            if (state is ReaderLoaded) {
              final dataService = context.watch<LocalDataService>();
              final activeCommunity = _activeCommunity(
                dataService,
                state.book.id,
              );
              final activeDiscussions = dataService.getDiscussionsByScope(
                state.book.id,
                ThreadScope.passage,
                communityId: activeCommunity?.id,
              );

              return Listener(
                onPointerDown: _handlePointerDown,
                onPointerMove: _handlePointerMove,
                onPointerUp: _handlePointerUpOrCancel,
                onPointerCancel: _handlePointerUpOrCancel,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        if (!_isFullScreen)
                          AmbientProgressBar(progress: state.progression),
                        Expanded(
                          child: ReadingWell(
                            child: EpubJsReader(
                              key: ValueKey(
                                '${state.book.id}:${state.book.localPath}:${state.preferences.scroll == true ? 'scroll' : 'pages'}',
                              ),
                              state: state,
                              showControls: _showControlsNotifier,
                              chapterTarget: _chapterTarget,
                              onChaptersLoaded: (chapters) {
                                if (!mounted) return;
                                setState(() {
                                  _chaptersBookId = state.book.id;
                                  _chapters = chapters;
                                  _currentChapterTitle = _chapters.isEmpty
                                      ? null
                                      : _firstNavigableChapter(
                                          _chapters,
                                        )?.title;
                                  _chapterTarget = null;
                                });
                              },
                              onLocationChanged: (location) {
                                final chapter = _chapterForHref(
                                  _chapters,
                                  location.href,
                                );
                                if (chapter != null &&
                                    chapter.title != _currentChapterTitle) {
                                  setState(() {
                                    _currentChapterTitle = chapter.title;
                                  });
                                }
                              },
                              passageDiscussions: activeDiscussions,
                              onDiscussSelection: (selection) =>
                                  _discussSelection(state, selection),
                              onSaveQuoteSelection: (selection) =>
                                  _saveQuoteSelection(state, selection),
                              onDiscussionIndicatorTapped: (cfi) =>
                                  _showDiscussions(
                                    context,
                                    state.book.id,
                                    cfi,
                                    activeCommunity,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Zoom indicator toast overlay
                    if (_isZooming && _displayFontSizeRatio != null)
                      Positioned(
                        top: _isFullScreen ? 40 : 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: backgroundColor?.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(20),
                              border: foregroundColor == null
                                  ? null
                                  : Border.all(
                                      color: foregroundColor.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.type,
                                  size: 16,
                                  color: foregroundColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Text Size: ${(_displayFontSizeRatio! * 100).round()}%',
                                  style: TextStyle(
                                    color: foregroundColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Full-screen exit button floating hint
                    if (_isFullScreen)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: SafeArea(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _toggleFullScreen,
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: backgroundColor?.withValues(
                                    alpha: 0.8,
                                  ),
                                  shape: BoxShape.circle,
                                  border: foregroundColor == null
                                      ? null
                                      : Border.all(
                                          color: foregroundColor.withValues(
                                            alpha: 0.25,
                                          ),
                                        ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  LucideIcons.minimize2,
                                  size: 18,
                                  color: foregroundColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          }(),
        );
      },
    );
  }

  EpubChapter? _firstNavigableChapter(List<EpubChapter> chapters) {
    for (final chapter in chapters) {
      if (chapter.href.isNotEmpty) return chapter;
      final child = _firstNavigableChapter(chapter.subitems);
      if (child != null) return child;
    }
    return null;
  }

  EpubChapter? _chapterForHref(
    List<EpubChapter> chapters,
    String? currentHref,
  ) {
    if (currentHref == null || currentHref.isEmpty) return null;
    final normalizedCurrent = currentHref.split('#').first;
    for (final chapter in chapters) {
      final chapterHref = chapter.href.split('#').first;
      if (chapterHref == normalizedCurrent ||
          normalizedCurrent.endsWith(chapterHref) ||
          chapterHref.endsWith(normalizedCurrent)) {
        return chapter;
      }
      final child = _chapterForHref(chapter.subitems, currentHref);
      if (child != null) return child;
    }
    return null;
  }
}
