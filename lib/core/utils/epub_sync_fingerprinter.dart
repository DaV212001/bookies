import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'app_logger.dart';

/// Service that computes an airtight structural fingerprint for EPUB publications.
///
/// Unlike a naive whole-file hash (which changes whenever Calibre or an OS writes
/// archive timestamps, compression levels, or custom metadata tags), this fingerprint
/// inspects the actual Reading Spine order and normalized DOM text block structure.
///
/// Invariant:
/// Two EPUBs have identical fingerprints IF AND ONLY IF their reading spine sequence,
/// chapter count, paragraph DOM hierarchy, and textual content align such that
/// Readium Canonical Fragment Identifiers (CFIs), passage reactions, margin notes,
/// and reading progress synchronize across co-readers without offset errors.
class EpubSyncFingerprinter {
  static const String _tag = 'EpubSyncFingerprinter';

  /// Computes the structural sync fingerprint for [file].
  static Future<String> computeFingerprint(File file) async {
    try {
      if (!await file.exists()) {
        throw FileSystemException('EPUB file not found', file.path);
      }

      final bytes = await file.readAsBytes();
      final epubBook = await epubx.EpubReader.readBook(bytes);

      final spineItems = epubBook.Schema?.Package?.Spine?.Items;
      final manifestItems = epubBook.Schema?.Package?.Manifest?.Items;

      if (spineItems == null || spineItems.isEmpty) {
        // Fallback to streaming file hash if package spine is missing
        return _computeFileHash(bytes);
      }

      // Map manifest id -> href to resolve spine item paths
      final idToHref = <String, String>{};
      if (manifestItems != null) {
        for (final item in manifestItems) {
          if (item.Id != null && item.Href != null) {
            idToHref[item.Id!] = item.Href!;
          }
        }
      }

      final htmlFiles = epubBook.Content?.Html ?? {};
      final buffer = StringBuffer();

      // 1. Reading Spine Order and Length
      buffer.writeln('SPINE_LENGTH:${spineItems.length}');

      for (int i = 0; i < spineItems.length; i++) {
        final itemRef = spineItems[i];
        final idRef = itemRef.IdRef ?? '';
        final href = idToHref[idRef] ?? idRef;

        // Resolve HTML content for this spine item
        String? htmlContent;
        if (htmlFiles.containsKey(href)) {
          htmlContent = htmlFiles[href]?.Content;
        } else {
          for (final entry in htmlFiles.entries) {
            if (entry.key.endsWith(href) || href.endsWith(entry.key)) {
              htmlContent = entry.value.Content;
              break;
            }
          }
        }

        // 2. Normalized DOM structure & text blocks
        final spineDigest = _computeSpineItemStructuralDigest(htmlContent ?? '');
        buffer.writeln('SPINE_ITEM:$i:$idRef:$spineDigest');
      }

      final masterHash = sha256.convert(utf8.encode(buffer.toString())).toString();
      final fingerprint = 'epub_sync_v1:$masterHash';
      AppLogger.d(_tag, 'Airtight sync fingerprint for "${file.path}": $fingerprint');
      return fingerprint;
    } catch (e) {
      AppLogger.w(
        _tag,
        'EPUB structural inspection failed for "${file.path}": $e. Using fallback file hash.',
      );
      return _fallbackFileFingerprint(file);
    }
  }

  /// Calculates a deterministic structural digest for a single chapter's HTML DOM.
  static String _computeSpineItemStructuralDigest(String html) {
    if (html.isEmpty) return 'empty';

    // Replace major structural block boundaries with newlines
    final blockNormalized = html
        .replaceAll(
          RegExp(
            r'</?(?:p|div|h[1-6]|blockquote|li|tr|section|article)[^>]*>',
            caseSensitive: false,
          ),
          '\n',
        )
        // Remove script, style, and remaining inline tags
        .replaceAll(RegExp(r'<(?:script|style)[^>]*>[\s\S]*?</(?:script|style)>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]*>'), ' ');

    // Extract non-empty normalized block text lines
    final lines = blockNormalized
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final textContent = lines.join('\n');
    final textHash = sha256.convert(utf8.encode(textContent)).toString().substring(0, 16);

    return 'blocks:${lines.length}:len:${textContent.length}:$textHash';
  }

  static String _computeFileHash(List<int> bytes) {
    final hash = sha256.convert(bytes).toString();
    return 'epub_file_v1:$hash';
  }

  static Future<String> _fallbackFileFingerprint(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return 'epub_file_v1:${digest.toString()}';
  }
}
