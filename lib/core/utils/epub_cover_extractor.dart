import 'dart:io';
import 'dart:typed_data';
import 'package:epubx/epubx.dart' as epubx;
import 'package:image/image.dart' as img;
import 'package:bookies/core/utils/app_logger.dart';

class EpubCoverExtractor {
  /// Extracts the cover image from an EPUB file and saves it to [targetPath].
  /// Returns the path to the extracted image file if successful, or `null` if no cover was found.
  static Future<String?> extractCover(File epubFile, String targetPath) async {
    try {
      AppLogger.i('EpubCoverExtractor', 'Attempting to extract cover from: ${epubFile.path}');
      if (!await epubFile.exists()) {
        AppLogger.w('EpubCoverExtractor', 'File does not exist: ${epubFile.path}');
        return null;
      }

      final bytes = await epubFile.readAsBytes();
      final epubBook = await epubx.EpubReader.readBook(bytes);

      // Attempt 1: epubBook.CoverImage parsed by epubx
      if (epubBook.CoverImage != null) {
        AppLogger.i('EpubCoverExtractor', 'Found cover image via epubBook.CoverImage');
        final pngBytes = Uint8List.fromList(img.encodePng(epubBook.CoverImage!));
        final coverFile = File(targetPath);
        await coverFile.writeAsBytes(pngBytes);
        AppLogger.i('EpubCoverExtractor', 'Saved cover image (${pngBytes.length} bytes) to: $targetPath');
        return coverFile.path;
      }

      // Attempt 2: Search in Content.Images for a cover file entry
      final images = epubBook.Content?.Images;
      if (images != null && images.isNotEmpty) {
        AppLogger.d('EpubCoverExtractor', 'Searching Content.Images (${images.length} images)...');
        String? coverKey;

        // Priority match for filenames with 'cover'
        for (final key in images.keys) {
          final lowerKey = key.toLowerCase();
          if (lowerKey.contains('cover')) {
            coverKey = key;
            break;
          }
        }

        // Fallback to first image if no key contains 'cover'
        coverKey ??= images.keys.first;

        final imageFile = images[coverKey];
        if (imageFile != null && imageFile.Content != null && imageFile.Content!.isNotEmpty) {
          final imageBytes = Uint8List.fromList(imageFile.Content!);
          final coverFile = File(targetPath);
          await coverFile.writeAsBytes(imageBytes);
          AppLogger.i('EpubCoverExtractor', 'Saved image from Content.Images["$coverKey"] (${imageBytes.length} bytes) to: $targetPath');
          return coverFile.path;
        }
      }

      AppLogger.w('EpubCoverExtractor', 'No cover image found in EPUB publication.');
    } catch (e, stackTrace) {
      AppLogger.e('EpubCoverExtractor', 'Error extracting cover image from EPUB', e, stackTrace);
    }
    return null;
  }
}
