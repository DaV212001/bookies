import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_readium/flutter_readium.dart';

import 'package:bookies/core/utils/app_logger.dart';
import 'package:bookies/core/utils/epub_cover_extractor.dart';
import 'package:bookies/core/utils/epub_sync_fingerprinter.dart';
import 'package:bookies/data/models/book.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/domain/entities/book_entity.dart';
import 'package:bookies/domain/repositories/book_repository.dart';

class LocalBookRepository implements BookRepository {
  final LocalDataService _localDataService;

  LocalBookRepository(this._localDataService);

  Future<String> _computeFingerprint(File file) async {
    try {
      return await EpubSyncFingerprinter.computeFingerprint(file);
    } catch (e) {
      AppLogger.w('LocalBookRepository', 'Failed to compute sync fingerprint for ${file.path}: $e');
      final length = await file.length();
      return 'pathhash_${file.path.hashCode}_$length';
    }
  }

  @override
  Future<List<BookEntity>> getLibraryBooks() async {
    final books = _localDataService.getBooks();
    final appDocsDir = await getApplicationDocumentsDirectory();

    // Backfill covers if missing
    for (int i = 0; i < books.length; i++) {
      final book = books[i];
      final hasValidCover =
          book.coverUrl != null && File(book.coverUrl!).existsSync();

      if (!hasValidCover &&
          book.localPath != null &&
          File(book.localPath!).existsSync()) {
        final targetCoverPath = '${appDocsDir.path}/${book.id}_cover.png';
        final extractedPath = await EpubCoverExtractor.extractCover(
          File(book.localPath!),
          targetCoverPath,
        );

        if (extractedPath != null) {
          final updatedBook = Book(
            id: book.id,
            title: book.title,
            author: book.author,
            fingerprint: book.fingerprint,
            coverUrl: extractedPath,
            isbn: book.isbn,
            localPath: book.localPath,
          );
          await _localDataService.updateBook(updatedBook);
          books[i] = updatedBook;
        }
      }
    }

    return books.map((b) => b.toDomain()).toList();
  }

  @override
  Future<BookEntity> importBook(String sourceFilePath) async {
    final file = File(sourceFilePath);
    if (!await file.exists()) {
      throw Exception('Source file not found at: $sourceFilePath');
    }

    // Compute airtight structural sync fingerprint of the source file
    final sourceFingerprint = await _computeFingerprint(file);

    // Check if this exact book edition is already in the library
    final existingBooks = _localDataService.getBooks();
    final duplicate = existingBooks.where((b) {
      if (b.fingerprint.isNotEmpty && b.fingerprint == sourceFingerprint) return true;
      if (b.localPath != null && b.localPath == sourceFilePath) return true;
      return false;
    }).firstOrNull;

    if (duplicate != null) {
      AppLogger.i('LocalBookRepository', 'Book already exists in library: ${duplicate.title} (${duplicate.id})');
      return duplicate.toDomain();
    }

    final appDocsDir = await getApplicationDocumentsDirectory();
    final rawFileName = file.uri.pathSegments.last;

    String ext = '.epub';
    String baseName = rawFileName;
    if (rawFileName.contains('.')) {
      final lastDotIndex = rawFileName.lastIndexOf('.');
      ext = rawFileName.substring(lastDotIndex);
      baseName = rawFileName.substring(0, lastDotIndex);
    }
    final sanitizedBase = baseName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final sanitizedFileName = '$sanitizedBase$ext';
    final targetPath = '${appDocsDir.path}/$sanitizedFileName';

    // If copying from outside app directory, copy; if already inside, keep
    final savedFile = file.path == targetPath ? file : await file.copy(targetPath);

    // Readium metadata extraction
    final publication = await FlutterReadium().loadPublication(savedFile.path);

    // Cover image extraction
    final bookId = DateTime.now().millisecondsSinceEpoch.toString();
    final targetCoverPath = '${appDocsDir.path}/${bookId}_cover.png';
    final extractedCoverPath = await EpubCoverExtractor.extractCover(
      savedFile,
      targetCoverPath,
    );

    final newBook = Book(
      id: bookId,
      title: publication.metadata.title.isEmpty
          ? 'Unknown Title'
          : publication.metadata.title,
      author: (publication.metadata.authors.firstOrNull ??
                  Contributor(
                    localizedName: LocalizedString(
                      translations: {'en': Translation('')},
                    ),
                  ))
              .localizedName
              ?.string ??
          'Unknown Author',
      fingerprint: sourceFingerprint,
      coverUrl: extractedCoverPath,
      localPath: savedFile.path,
    );

    await _localDataService.addBook(newBook);
    return newBook.toDomain();
  }

  @override
  Future<List<BookEntity>> scanAndSyncFolder(String folderPath) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) {
      AppLogger.w('LocalBookRepository', 'Auto-sync folder does not exist: $folderPath');
      return [];
    }

    AppLogger.i('LocalBookRepository', 'Scanning auto-sync folder for EPUBs: $folderPath');
    final newlyImported = <BookEntity>[];

    try {
      final entries = dir.listSync(recursive: false, followLinks: false);
      for (final entity in entries) {
        if (entity is File && entity.path.toLowerCase().endsWith('.epub')) {
          try {
            final book = await importBook(entity.path);
            newlyImported.add(book);
          } catch (e) {
            AppLogger.w('LocalBookRepository', 'Failed to auto-import ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      AppLogger.e('LocalBookRepository', 'Error while scanning sync folder $folderPath: $e');
    }

    return newlyImported;
  }

  @override
  Future<String?> getAutoSyncFolder() async {
    return _localDataService.getAutoSyncFolder();
  }

  @override
  Future<void> setAutoSyncFolder(String? folderPath) async {
    await _localDataService.setAutoSyncFolder(folderPath);
  }

  @override
  Future<void> syncReadingProgress({
    required String bookId,
    required String cfi,
    required double progression,
  }) async {
    final progressJson = jsonEncode({
      'cfi': cfi,
      'progression': progression,
    });
    await _localDataService.saveProgress(bookId, progressJson, notify: false);
  }

  @override
  Future<Map<String, dynamic>?> getReadingProgress(String bookId) async {
    final raw = _localDataService.getProgress(bookId);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (e) {
      AppLogger.w('LocalBookRepository', 'Failed to parse progress for $bookId: $e');
    }
    return null;
  }

  @override
  Future<void> deleteBook(String bookId) async {
    // Local deletion
  }
}
