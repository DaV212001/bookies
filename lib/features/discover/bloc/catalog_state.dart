import 'package:equatable/equatable.dart';
import 'package:bookies/domain/entities/book_entity.dart';
import 'package:bookies/domain/entities/catalog_book_entity.dart';

enum CatalogStatus { initial, loading, success, failure }

class CatalogState extends Equatable {
  final CatalogStatus status;
  final List<CatalogBookEntity> featuredBooks;
  final List<CatalogBookEntity> searchResults;
  final String selectedGenre;
  final String searchQuery;
  final Map<String, double> downloadProgress; // bookId -> progress (0.0 to 1.0)
  final Map<String, BookEntity> downloadedBooks; // bookId -> BookEntity
  final String? errorMessage;

  const CatalogState({
    this.status = CatalogStatus.initial,
    this.featuredBooks = const [],
    this.searchResults = const [],
    this.selectedGenre = '#AllCuration',
    this.searchQuery = '',
    this.downloadProgress = const {},
    this.downloadedBooks = const {},
    this.errorMessage,
  });

  bool isDownloading(String bookId) =>
      downloadProgress.containsKey(bookId) &&
      (downloadProgress[bookId] ?? 0.0) < 1.0;

  bool isDownloaded(String bookId) => downloadedBooks.containsKey(bookId);

  CatalogState copyWith({
    CatalogStatus? status,
    List<CatalogBookEntity>? featuredBooks,
    List<CatalogBookEntity>? searchResults,
    String? selectedGenre,
    String? searchQuery,
    Map<String, double>? downloadProgress,
    Map<String, BookEntity>? downloadedBooks,
    String? errorMessage,
  }) {
    return CatalogState(
      status: status ?? this.status,
      featuredBooks: featuredBooks ?? this.featuredBooks,
      searchResults: searchResults ?? this.searchResults,
      selectedGenre: selectedGenre ?? this.selectedGenre,
      searchQuery: searchQuery ?? this.searchQuery,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedBooks: downloadedBooks ?? this.downloadedBooks,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        featuredBooks,
        searchResults,
        selectedGenre,
        searchQuery,
        downloadProgress,
        downloadedBooks,
        errorMessage,
      ];
}
