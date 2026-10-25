import '../entities/book_entity.dart';

abstract class BookRepository {
  /// Get all imported books in the local reader library
  Future<List<BookEntity>> getLibraryBooks();

  /// Import an EPUB file from local storage into the app library
  Future<BookEntity> importBook(String sourceFilePath);

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
