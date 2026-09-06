import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/models/discussion.dart';
import '../bloc/reader_bloc.dart';

class EpubJsReader extends StatefulWidget {
  final ReaderLoaded state;
  final ValueNotifier<bool> showControls;
  final ValueChanged<List<EpubChapter>>? onChaptersLoaded;
  final ValueChanged<EpubLocation>? onLocationChanged;
  final String? chapterTarget;
  final List<Discussion> passageDiscussions;
  final ValueChanged<EpubTextSelection>? onDiscussSelection;
  final ValueChanged<EpubTextSelection>? onSaveQuoteSelection;
  final ValueChanged<String>? onDiscussionIndicatorTapped;
  final void Function(String cfi, Map<String, dynamic>? rect)?
      onDiscussionIndicatorLongPressed;

  const EpubJsReader({
    super.key,
    required this.state,
    required this.showControls,
    this.onChaptersLoaded,
    this.onLocationChanged,
    this.chapterTarget,
    this.passageDiscussions = const [],
    this.onDiscussSelection,
    this.onSaveQuoteSelection,
    this.onDiscussionIndicatorTapped,
    this.onDiscussionIndicatorLongPressed,
  });

  @override
  State<EpubJsReader> createState() => _EpubJsReaderState();
}

class _EpubJsReaderState extends State<EpubJsReader> {
  late final EpubController _controller;
  late final Future<EpubSource> _source;
  late final EpubDisplaySettings _initialDisplaySettings;
  ThemeData? _appliedTheme;
  bool _hasInitialDisplaySettings = false;
  bool _isLoaded = false;
  EpubTextSelection? _lastSelection;
  final Set<String> _renderedDiscussionCfis = {};
  late bool _initialPositionReady;

  @override
  void dispose() {
    _isLoaded = false;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = EpubController();
    _initialPositionReady = widget.state.currentCfi == null;
    _source = _loadSource();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    if (!_hasInitialDisplaySettings) {
      _appliedTheme = theme;
      _initialDisplaySettings = _settings(widget.state);
      _hasInitialDisplaySettings = true;
    } else if (_isLoaded && _appliedTheme != theme) {
      _appliedTheme = theme;
      _applyThemeSafely(widget.state);
    }
  }

  @override
  void didUpdateWidget(covariant EpubJsReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isLoaded &&
        oldWidget.state.preferences.fontSize !=
            widget.state.preferences.fontSize) {
      _runControllerCall(
        () => _controller.setFontSize(
          fontSize: ((widget.state.preferences.fontSize ?? 1.0) * 15).clamp(
            8,
            48,
          ),
        ),
      );
    }
    if (_isLoaded &&
        widget.chapterTarget != null &&
        widget.chapterTarget != oldWidget.chapterTarget) {
      AppLogger.i('EpubJsReader', 'Opening chapter: ${widget.chapterTarget}');
      _runControllerCall(() => _controller.display(cfi: widget.chapterTarget!));
    }
    if (_isLoaded &&
        (oldWidget.state.preferences.backgroundColor !=
                widget.state.preferences.backgroundColor ||
            oldWidget.state.preferences.textColor !=
                widget.state.preferences.textColor ||
            oldWidget.state.preferences.fontFamily !=
                widget.state.preferences.fontFamily ||
            oldWidget.state.preferences.lineHeight !=
                widget.state.preferences.lineHeight ||
            oldWidget.state.preferences.textAlign !=
                widget.state.preferences.textAlign)) {
      _applyThemeSafely(widget.state);
    }
    if (_isLoaded &&
        oldWidget.passageDiscussions != widget.passageDiscussions) {
      _syncDiscussionIndicators();
    }
  }

  Future<void> _applyTheme(ReaderLoaded state) async {
    final prefs = state.preferences;
    final background = prefs.backgroundColor ?? Colors.white;
    final foreground = prefs.textColor ?? Colors.black;
    final selectionCss = _selectionCss();
    AppLogger.i('EpubJsReader', 'Applying theme to ${state.book.title}');
    await _controller.updateTheme(
      theme: EpubTheme.custom(
        backgroundDecoration: BoxDecoration(color: background),
        foregroundColor: foreground,
        customCss: {
          'body': {
            'font-family': prefs.fontFamily ?? 'inherit',
            'line-height': '${prefs.lineHeight ?? 1.5}',
            'text-align': prefs.textAlign == TextAlign.justify
                ? 'justify'
                : 'left',
          },
          '::selection': selectionCss,
        },
      ),
    );
  }

  Future<void> _applyThemeSafely(ReaderLoaded state) async {
    if (!mounted || !_isLoaded) return;
    try {
      await _applyTheme(state);
    } on MissingPluginException {
      // The WebView platform channel may disappear while the reader is closing.
    } catch (error) {
      AppLogger.w('EpubJsReader', 'Unable to apply reader theme: $error');
    }
  }

  Future<void> _runControllerCall(FutureOr<void> Function() call) async {
    if (!mounted || !_isLoaded) return;
    try {
      await call();
    } on MissingPluginException {
      // Ignore calls that finish after the WebView has been detached.
    } catch (error) {
      AppLogger.w('EpubJsReader', 'Reader controller call failed: $error');
    }
  }

  void _syncDiscussionIndicators() {
    // Group discussions by CFI to compute per-passage message counts and quote texts.
    final cfiCounts = <String, int>{};
    final cfiQuotes = <String, String>{};
    for (final discussion in widget.passageDiscussions) {
      final cfi = discussion.highlightId;
      if (cfi.startsWith('epubcfi(')) {
        cfiCounts[cfi] = (cfiCounts[cfi] ?? 0) + 1;
        if (discussion.quoteText != null &&
            discussion.quoteText!.trim().isNotEmpty &&
            !cfiQuotes.containsKey(cfi)) {
          cfiQuotes[cfi] = discussion.quoteText!.trim();
        }
      }
    }
    final cfis = cfiCounts.keys.toSet();
    for (final oldCfi in _renderedDiscussionCfis.difference(cfis)) {
      _runControllerCall(() => _controller.removeUnderline(cfi: oldCfi));
    }
    for (final cfi in cfis.difference(_renderedDiscussionCfis)) {
      _runControllerCall(
        () => _controller.addUnderline(
          cfi: cfi,
          count: cfiCounts[cfi] ?? 1,
          quoteText: cfiQuotes[cfi],
        ),
      );
    }
    _renderedDiscussionCfis
      ..clear()
      ..addAll(cfis);
  }

  Future<EpubSource> _loadSource() async {
    final path = widget.state.book.localPath;
    if (path == null || path.isEmpty) throw StateError('EPUB file not found');
    AppLogger.i('EpubJsReader', 'Loading EPUB source: $path');
    final bytes = await File(path).readAsBytes();
    AppLogger.d(
      'EpubJsReader',
      'Loaded ${bytes.length} bytes for ${widget.state.book.title}',
    );
    return EpubSource.fromData(bytes);
  }

  Map<String, String> _selectionCss() {
    return {'background-color': 'rgba(253, 138, 66, 0.7)', 'color': '#121826'};
  }

  EpubDisplaySettings _settings(ReaderLoaded state) {
    final prefs = state.preferences;
    final bg = prefs.backgroundColor ?? Colors.white;
    final fg = prefs.textColor ?? Colors.black;
    return EpubDisplaySettings(
      flow: prefs.scroll == false ? EpubFlow.paginated : EpubFlow.scrolled,
      manager: prefs.scroll == false
          ? EpubManager.continuous
          : EpubManager.defaultManager,
      snap: prefs.scroll == false,
      fontSize: ((prefs.fontSize ?? 1.0) * 15).round().clamp(8, 48),
      theme: EpubTheme.custom(
        backgroundDecoration: BoxDecoration(color: bg),
        foregroundColor: fg,
        customCss: {
          'body': {
            'font-family': prefs.fontFamily ?? 'inherit',
            'line-height': '${prefs.lineHeight ?? 1.5}',
            'text-align': prefs.textAlign == TextAlign.justify
                ? 'justify'
                : 'left',
          },
          '::selection': _selectionCss(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EpubSource>(
      future: _source,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        return EpubViewer(
          epubController: _controller,
          epubSource: snapshot.data!,
          initialCfi: widget.state.currentCfi,
          // Keep the initial WebView configuration stable. Runtime preference
          // changes are applied through EpubController to avoid reloading EPUB.js.
          displaySettings: _initialDisplaySettings,
          onEpubLoaded: () {
            _isLoaded = true;
            // The WebView can finish loading after the initial display settings
            // are installed. Reapply the theme so custom selection CSS is
            // present immediately, including after a hot restart.
            _applyThemeSafely(widget.state);
            _syncDiscussionIndicators();
            final continuous = widget.state.preferences.scroll ?? true;
            AppLogger.i(
              'EpubJsReader',
              'EPUB loaded: ${widget.state.book.title}; continuous=$continuous',
            );
          },
          onChaptersLoaded: widget.onChaptersLoaded,
          onInitialPositionLoaded: () {
            _initialPositionReady = true;
          },
          clearSelectionOnPageChange: false,
          onRelocated: (location) {
            widget.onLocationChanged?.call(location);
            AppLogger.d(
              'EpubJsReader',
              'Relocated: progress=${location.progress.toStringAsFixed(4)} cfi=${location.startCfi}',
            );
            if (_initialPositionReady) {
              context.read<ReaderBloc>().add(
                UpdateLocator(location.startCfi, location.progress),
              );
            } else {
              AppLogger.d(
                'EpubJsReader',
                'Ignoring startup relocation while restoring saved position',
              );
            }
          },
          selectionContextMenu: EpubContextMenu(
            items: [
              EpubContextMenuItem(
                id: 101,
                title: 'Discuss',
                action: () {
                  final selection = _lastSelection;
                  if (selection != null)
                    widget.onDiscussSelection?.call(selection);
                },
              ),
              EpubContextMenuItem(
                id: 103,
                title: 'Save quote',
                action: () {
                  final selection = _lastSelection;
                  if (selection != null)
                    widget.onSaveQuoteSelection?.call(selection);
                },
              ),
            ],
          ),
          onTextSelected: (selection) => _lastSelection = selection,
          onAnnotationClicked: (cfiRange, rect) =>
              widget.onDiscussionIndicatorTapped?.call(cfiRange),
          onAnnotationLongPressed: (cfiRange, rect) =>
              widget.onDiscussionIndicatorLongPressed?.call(cfiRange, rect),
          onSelectionChanging: () => widget.showControls.value = false,
          onDeselection: () => widget.showControls.value = true,
        );
      },
    );
  }
}
