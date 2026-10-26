import '../entities/book_entity.dart';

abstract class BookRepository {
  /// Get all imported books in the local reader library
  Future<List<BookEntity>> getLibraryBooks();

  /// Import an EPUB file from local storage into the app library
  Future<BookEntity> importBook(String sourceFilePath);

  /// Scan a directory and automatically import any new EPUBs not yet in the library
  Future<List<BookEntity>> scanAndSyncFolder(String folderPath);

  /// Get the currently designated auto-sync folder path
  Future<String?> getAutoSyncFolder();

  /// Set or clear the auto-sync folder path
  Future<void> setAutoSyncFolder(String? folderPath);

  /// Synchronize reading progression with NestJS backend
  Future<void> syncReadingProgress({
    required String bookId,
    required String cfi,
    required double progression,
  });

  /// Retrieve last saved progress locator
  Future<Map<String, dynamic>?> getReadingProgress(String bookId);

  /// Delete a book and its cached covers/files
  Future<void> deleteBook(String bookId);
}
