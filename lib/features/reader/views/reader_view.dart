import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter/services.dart';

import 'package:bookies/data/models/book.dart';
import 'package:bookies/data/models/thread_scope.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/features/reader/bloc/reader_bloc.dart';
import 'package:bookies/features/discussion/views/discussions_bottom_sheet.dart';
import 'package:bookies/core/widgets/reading_well.dart';
import 'package:bookies/core/widgets/ambient_progress_bar.dart';
import 'package:bookies/features/reader/views/reading_settings_modal.dart';
import 'package:bookies/features/reader/views/chapter_list_drawer.dart';
import 'package:bookies/features/reader/widgets/epub_js_reader.dart';

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
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          DiscussionsBottomSheet(bookId: bookId, cfi: currentCfi ?? ''),
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
                  chapters: _chaptersBookId == currentBook.id ? _chapters : const [],
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
              final activeDiscussions = context
                  .watch<LocalDataService>()
                  .getDiscussionsByScope(state.book.id, ThreadScope.passage);

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
                          AmbientProgressBar(
                            progress:
                                  state.progression,
                          ),
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
                                      : _firstNavigableChapter(_chapters)?.title;
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
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Subtle Passage Discussion Marker Overlay (Warm Ochre indicator)
                    if (activeDiscussions.isNotEmpty)
                      Positioned(
                        bottom: 24,
                        right: 20,
                        child: GestureDetector(
                          onTap: () {
                            _showDiscussions(
                              context,
                              state.book.id,
                              'cfi-passage-1',
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB45309), // Ochre
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFB45309,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.messageSquare,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${activeDiscussions.length} Passage Discussions',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
