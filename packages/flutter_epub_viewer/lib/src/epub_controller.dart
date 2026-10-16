import 'dart:async';

import 'package:flutter_epub_viewer/src/epub_metadata.dart';
import 'package:flutter_epub_viewer/src/models/epub_display_settings.dart';
import 'package:flutter_epub_viewer/src/models/epub_location.dart';
import 'package:flutter_epub_viewer/src/models/epub_search_result.dart';
import 'package:flutter_epub_viewer/src/models/epub_text_extract_res.dart';
import 'package:flutter_epub_viewer/src/utils.dart';
import 'package:flutter/material.dart';
import 'platform/epub_web_view.dart';
import 'models/epub_chapter.dart';
import 'models/epub_theme.dart';

class EpubController {
  /// Platform bridge to the epub.js runtime.
  ///
  /// Backed by flutter_inappwebview on mobile/desktop and by a native
  /// `<iframe>` + `dart:js_interop` on the web.
  EpubWebViewController? webViewController;

  /// Maximum time to wait for a request/response call before giving up.
  ///
  /// Guarantees request methods never hang forever if the JS side fails to
  /// reply (previously a stuck `Completer` leaked indefinitely). Adjustable for
  /// slow devices or large books.
  Duration requestTimeout = const Duration(seconds: 20);

  ///List of chapters from epub
  List<EpubChapter> _chapters = [];

  setWebViewController(EpubWebViewController controller) {
    webViewController = controller;
  }

  Future<dynamic> _request(String name, [List<dynamic> args = const []]) {
    checkEpubLoaded();
    // `Future.timeout` throws a [TimeoutException] (dart:async) if the JS side
    // never replies, so a request never hangs forever.
    return webViewController!.callAsync(name, args).timeout(requestTimeout);
  }

  ///Move epub view to specific area using Cfi string, XPath/XPointer, or chapter href
  Future<void> display({
    ///Cfi String, XPath/XPointer string, or chapter href of the desired location
    ///If the string starts with '/', it will be treated as XPath/XPointer
    required String cfi,
  }) async {
    checkEpubLoaded();
    await webViewController?.callMethod('toCfi', [cfi]);
  }

  ///Moves to next page in epub view
  Future<void> next() async {
    checkEpubLoaded();
    await webViewController?.callMethod('next');
  }

  ///Moves to previous page in epub view
  Future<void> prev() async {
    checkEpubLoaded();
    await webViewController?.callMethod('previous');
  }

  ///Returns current location of epub viewer
  Future<EpubLocation> getCurrentLocation() async {
    final result = await _request('getCurrentLocation');
    return EpubLocation.fromJson(Utils.asStringMap(result));
  }

  ///Returns list of [EpubChapter] from epub,
  /// should be called after onChaptersLoaded callback, otherwise returns empty list
  List<EpubChapter> getChapters() {
    checkEpubLoaded();
    return _chapters;
  }

  Future<List<EpubChapter>> parseChapters() async {
    if (_chapters.isNotEmpty) return _chapters;
    final result = await _request('getChapters');
    _chapters = parseChapterList(result);
    return _chapters;
  }

  Future<EpubMetadata> getMetadata() async {
    final result = await _request('getBookInfo');
    return EpubMetadata.fromJson(Utils.asStringMap(result));
  }

  ///Search in epub using query string
  ///Returns a list of [EpubSearchResult]
  Future<List<EpubSearchResult>> search({
    ///Search query string
    required String query,
  }) async {
    if (query.isEmpty) return [];
    final result = await _request('searchInBook', [query]);
    return List<EpubSearchResult>.from(
      (result as List).map((e) => EpubSearchResult.fromJson(Utils.asStringMap(e))),
    );
  }

  ///Adds a highlight to epub viewer
  Future<void> addHighlight({
    ///Cfi string of the desired location
    required String cfi,

    ///Color of the highlight
    Color color = Colors.yellow,

    ///Opacity of the highlight
    double opacity = 0.3,
  }) async {
    var colorHex = color.toHex();
    var opacityString = opacity.toString();
    checkEpubLoaded();
    await webViewController?.callMethod('addHighlight', [cfi, colorHex, opacityString]);
  }

  ///Adds a underline annotation with an optional discussion count badge and quote text
  Future<void> addUnderline({required String cfi, int count = 1, String? quoteText}) async {
    checkEpubLoaded();
    await webViewController?.callMethod('addUnderLine', [cfi, count, quoteText]);
  }

  /// Updates the discussion count and heat level for an existing underline annotation
  Future<void> updateDiscussionCount({required String cfi, required int count}) async {
    checkEpubLoaded();
    await webViewController?.callMethod('updateDiscussionCount', [cfi, count]);
  }

  ///Removes a highlight from epub viewer
  Future<void> removeHighlight({required String cfi}) async {
    checkEpubLoaded();
    await webViewController?.callMethod('removeHighlight', [cfi]);
  }

  ///Removes a underline from epub viewer
  Future<void> removeUnderline({required String cfi}) async {
    checkEpubLoaded();
    await webViewController?.callMethod('removeUnderLine', [cfi]);
  }

  ///Clears all discussion underlines and badges from the epub viewer
  Future<void> clearUnderlines() async {
    checkEpubLoaded();
    await webViewController?.callMethod('clearUnderlines');
  }

  ///Clears any active text selection in the epub viewer
  Future<void> clearSelection() async {
    checkEpubLoaded();
    await webViewController?.callMethod('clearSelection');
  }

  ///Set [EpubSpread] value
  setSpread({required EpubSpread spread}) async {
    await webViewController?.callMethod('setSpread', [spread.name]);
  }

  ///Set [EpubFlow] value
  setFlow({required EpubFlow flow}) async {
    await webViewController?.callMethod('setFlow', [flow.name]);
  }

  ///Set [EpubManager] value
  setManager({required EpubManager manager}) async {
    await webViewController?.callMethod('setManager', [
      manager == EpubManager.defaultManager ? 'default' : manager.name,
    ]);
  }

  ///Adjust font size in epub viewer
  setFontSize({required double fontSize}) async {
    await webViewController?.callMethod('setFontSize', [fontSize]);
  }

  updateTheme({required EpubTheme theme}) async {
    final decoration = theme.backgroundDecoration;
    final backgroundColor = decoration is BoxDecoration
        ? decoration.color?.toHex()
        : null;
    String? foregroundColor = theme.foregroundColor?.toHex();
    await webViewController?.callMethod('updateTheme', [
      backgroundColor,
      foregroundColor,
      theme.customCss,
    ]);
  }

  ///Extract text from a given cfi range
  Future<EpubTextExtractRes> extractText({
    ///start cfi
    required startCfi,

    ///end cfi
    required endCfi,
  }) async {
    final result = await _request('getTextFromCfi', [startCfi, endCfi]);
    return EpubTextExtractRes.fromJson(Utils.asStringMap(result));
  }

  ///Get bounding rectangle for a given CFI range
  ///Returns viewer-relative coordinates in pixels, or null if it cannot be determined
  Future<Rect?> getRectFromCfi(String cfiRange) async {
    final result = await _request('getRectFromCfi', [cfiRange]);
    if (result == null) return null;
    final r = Utils.asStringMap(result);
    return Rect.fromLTRB(
      (r['left'] as num).toDouble(),
      (r['top'] as num).toDouble(),
      (r['right'] as num).toDouble(),
      (r['bottom'] as num).toDouble(),
    );
  }

  ///Extracts text content from current page
  Future<EpubTextExtractRes> extractCurrentPageText() async {
    final result = await _request('getCurrentPageText');
    return EpubTextExtractRes.fromJson(Utils.asStringMap(result));
  }

  ///Given a percentage moves to the corresponding page
  ///Progress percentage should be between 0.0 and 1.0
  Future<void> toProgressPercentage(double progressPercent) async {
    assert(
      progressPercent >= 0.0 && progressPercent <= 1.0,
      'Progress percentage must be between 0.0 and 1.0',
    );
    checkEpubLoaded();
    await webViewController?.callMethod('toProgress', [progressPercent]);
  }

  ///Moves to the first page of the epub
  Future<void> moveToFistPage() async {
    await toProgressPercentage(0.0);
  }

  ///Moves to the last page of the epub
  Future<void> moveToLastPage() async {
    await toProgressPercentage(1.0);
  }

  checkEpubLoaded() {
    if (webViewController == null) {
      throw Exception(
        "Epub viewer is not loaded, wait for onEpubLoaded callback",
      );
    }
  }
}
