import '../entities/catalog_book_entity.dart';
import '../entities/book_entity.dart';

abstract class CatalogRepository {
  /// Fetch curated, trending, or editorial picks from scraped catalog
  Future<List<CatalogBookEntity>> getDiscoverCatalog({
    String? genre,
    String? query,
    int page = 1,
    int limit = 20,
  });

  /// Download an EPUB from the catalog CDN and register into the reader library
  Future<BookEntity> downloadAndImportBook({
    required CatalogBookEntity catalogBook,
    void Function(double progress)? onProgress,
  });

  /// Search catalog books by title, author, or keyword
  Future<List<CatalogBookEntity>> searchCatalog(String query);
}
