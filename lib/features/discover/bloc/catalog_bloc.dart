import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bookies/core/utils/app_logger.dart';
import 'package:bookies/domain/repositories/catalog_repository.dart';
import 'catalog_event.dart';
import 'catalog_state.dart';

export 'catalog_event.dart';
export 'catalog_state.dart';

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final CatalogRepository _catalogRepository;
  static const String _tag = 'CatalogBloc';

  CatalogBloc({required CatalogRepository catalogRepository})
      : _catalogRepository = catalogRepository,
        super(const CatalogState()) {
    on<FetchCatalogEvent>(_onFetchCatalog);
    on<SearchCatalogEvent>(_onSearchCatalog);
    on<SelectGenreFilterEvent>(_onSelectGenreFilter);
    on<DownloadCatalogBookEvent>(_onDownloadCatalogBook);
    on<UpdateDownloadProgressEvent>(_onUpdateDownloadProgress);
  }

  Future<void> _onFetchCatalog(
    FetchCatalogEvent event,
    Emitter<CatalogState> emit,
  ) async {
    emit(state.copyWith(status: CatalogStatus.loading));
    try {
      final books = await _catalogRepository.getDiscoverCatalog(
        genre: event.genre ?? state.selectedGenre,
      );
      emit(state.copyWith(
        status: CatalogStatus.success,
        featuredBooks: books,
        errorMessage: null,
      ));
    } catch (e) {
      AppLogger.e(_tag, 'Catalog fetch error: $e');
      emit(state.copyWith(
        status: CatalogStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSearchCatalog(
    SearchCatalogEvent event,
    Emitter<CatalogState> emit,
  ) async {
    final query = event.query.trim();
    emit(state.copyWith(searchQuery: query));

    if (query.isEmpty) {
      emit(state.copyWith(searchResults: const []));
      return;
    }

    emit(state.copyWith(status: CatalogStatus.loading));
    try {
      final results = await _catalogRepository.searchCatalog(query);
      emit(state.copyWith(
        status: CatalogStatus.success,
        searchResults: results,
        errorMessage: null,
      ));
    } catch (e) {
      AppLogger.e(_tag, 'Catalog search error: $e');
      emit(state.copyWith(
        status: CatalogStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSelectGenreFilter(
    SelectGenreFilterEvent event,
    Emitter<CatalogState> emit,
  ) async {
    emit(state.copyWith(selectedGenre: event.genre, status: CatalogStatus.loading));
    try {
      final books = await _catalogRepository.getDiscoverCatalog(
        genre: event.genre,
      );
      emit(state.copyWith(
        status: CatalogStatus.success,
        featuredBooks: books,
        errorMessage: null,
      ));
    } catch (e) {
      AppLogger.e(_tag, 'Genre filter error: $e');
      emit(state.copyWith(
        status: CatalogStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDownloadCatalogBook(
    DownloadCatalogBookEvent event,
    Emitter<CatalogState> emit,
  ) async {
    final book = event.book;
    final updatedProgress = Map<String, double>.from(state.downloadProgress);
    updatedProgress[book.id] = 0.05; // Initial progress
    emit(state.copyWith(downloadProgress: updatedProgress));

    try {
      final importedBook = await _catalogRepository.downloadAndImportBook(
        catalogBook: book,
        onProgress: (progress) {
          add(UpdateDownloadProgressEvent(bookId: book.id, progress: progress));
        },
      );

      final updatedDownloaded =
          Map<String, dynamic>.from(state.downloadedBooks);
      updatedDownloaded[book.id] = importedBook;

      final finalProgress = Map<String, double>.from(state.downloadProgress);
      finalProgress[book.id] = 1.0;

      emit(state.copyWith(
        downloadedBooks: Map.from(updatedDownloaded),
        downloadProgress: finalProgress,
      ));
    } catch (e) {
      AppLogger.e(_tag, 'Download book error: $e');
      final failedProgress = Map<String, double>.from(state.downloadProgress);
      failedProgress.remove(book.id);
      emit(state.copyWith(
        downloadProgress: failedProgress,
        errorMessage: 'Failed to download ${book.title}: $e',
      ));
    }
  }

  void _onUpdateDownloadProgress(
    UpdateDownloadProgressEvent event,
    Emitter<CatalogState> emit,
  ) {
    final progressMap = Map<String, double>.from(state.downloadProgress);
    progressMap[event.bookId] = event.progress;
    emit(state.copyWith(downloadProgress: progressMap));
  }
}
