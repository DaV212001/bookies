import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:path_provider/path_provider.dart';

import '../../../data/models/book.dart';
import '../../../data/providers/local_data_service.dart';
import '../../../data/repositories/local_book_repository.dart';
import '../../../domain/repositories/book_repository.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/epub_cover_extractor.dart';
import 'library_view_filter.dart';

export 'library_view_filter.dart';

part 'library_event.dart';
part 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final LocalDataService _dataService;
  final BookRepository _bookRepository;

  LibraryBloc(
    this._dataService, {
    BookRepository? bookRepository,
  })  : _bookRepository = bookRepository ?? LocalBookRepository(_dataService),
        super(LibraryInitial()) {
    on<LoadLibrary>(_onLoadLibrary);
    on<ImportBook>(_onImportBook);
    on<SetAutoSyncFolder>(_onSetAutoSyncFolder);
    on<ScanAutoSyncFolder>(_onScanAutoSyncFolder);
    on<UpdateLibraryView>(_onUpdateLibraryView);
  }

  void _onLoadLibrary(LoadLibrary event, Emitter<LibraryState> emit) async {
    AppLogger.i('LibraryBloc', 'Handling LoadLibrary event');
    emit(LibraryLoading());
    try {
      final autoSyncFolder = _dataService.getAutoSyncFolder();
      if (autoSyncFolder != null && autoSyncFolder.isNotEmpty) {
        AppLogger.i('LibraryBloc', 'Auto-sync folder configured: $autoSyncFolder. Running background sync...');
        await _bookRepository.scanAndSyncFolder(autoSyncFolder);
      }

      final books = List<Book>.from(_dataService.getBooks());
      AppLogger.i(
        'LibraryBloc',
        'Loaded ${books.length} book(s) from local data service',
      );

      final appDocsDir = await getApplicationDocumentsDirectory();

      // Backfill covers for existing books if missing
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
            await _dataService.updateBook(updatedBook);
            books[i] = updatedBook;
            AppLogger.i(
              'LibraryBloc',
              'Backfilled cover for existing book "${book.title}" -> $extractedPath',
            );
          }
        }
      }

      emit(LibraryLoaded(books, autoSyncFolder: autoSyncFolder));
    } catch (e, stackTrace) {
      AppLogger.e('LibraryBloc', 'Error loading library', e, stackTrace);
      emit(LibraryError('Failed to load library: $e'));
    }
  }

  void _onSetAutoSyncFolder(SetAutoSyncFolder event, Emitter<LibraryState> emit) async {
    AppLogger.i('LibraryBloc', 'Setting auto-sync folder to: ${event.folderPath}');
    try {
      await _dataService.setAutoSyncFolder(event.folderPath);
      if (event.folderPath != null && event.folderPath!.isNotEmpty) {
        await _bookRepository.scanAndSyncFolder(event.folderPath!);
      }
      final books = List<Book>.from(_dataService.getBooks());
      final currentState = state;
      final query = currentState is LibraryLoaded ? currentState.query : '';
      final sortOrder = currentState is LibraryLoaded ? currentState.sortOrder : LibrarySortOrder.recent;
      emit(LibraryLoaded(
        books,
        query: query,
        sortOrder: sortOrder,
        autoSyncFolder: event.folderPath,
      ));
    } catch (e, stackTrace) {
      AppLogger.e('LibraryBloc', 'Error setting auto-sync folder', e, stackTrace);
      emit(LibraryError('Failed to update sync folder: $e'));
    }
  }

  void _onScanAutoSyncFolder(ScanAutoSyncFolder event, Emitter<LibraryState> emit) async {
    final folder = _dataService.getAutoSyncFolder();
    if (folder == null || folder.isEmpty) return;

    AppLogger.i('LibraryBloc', 'Manually triggering scan of auto-sync folder: $folder');
    try {
      await _bookRepository.scanAndSyncFolder(folder);
      final books = List<Book>.from(_dataService.getBooks());
      final currentState = state;
      final query = currentState is LibraryLoaded ? currentState.query : '';
      final sortOrder = currentState is LibraryLoaded ? currentState.sortOrder : LibrarySortOrder.recent;
      emit(LibraryLoaded(
        books,
        query: query,
        sortOrder: sortOrder,
        autoSyncFolder: folder,
      ));
    } catch (e, stackTrace) {
      AppLogger.e('LibraryBloc', 'Error scanning auto-sync folder', e, stackTrace);
    }
  }

  void _onImportBook(ImportBook event, Emitter<LibraryState> emit) async {
    AppLogger.i(
      'LibraryBloc',
      'Handling ImportBook event for path: ${event.filePath}',
    );
    final currentState = state;
    List<Book> existingBooks = [];
    var query = '';
    var sortOrder = LibrarySortOrder.recent;
    String? autoSyncFolder;
    if (currentState is LibraryLoaded) {
      existingBooks = currentState.books;
      query = currentState.query;
      sortOrder = currentState.sortOrder;
      autoSyncFolder = currentState.autoSyncFolder;
    }

    emit(LibraryLoading());
    try {
      // Delegate import logic to BookRepository which computes cryptographic SHA-256 fingerprint
      await _bookRepository.importBook(event.filePath);

      final updatedList = _dataService.getBooks();
      AppLogger.i(
        'LibraryBloc',
        'Book import complete. Total library books: ${updatedList.length}',
      );
      emit(LibraryLoaded(
        updatedList,
        query: query,
        sortOrder: sortOrder,
        autoSyncFolder: autoSyncFolder,
      ));
    } catch (e, stackTrace) {
      AppLogger.e('LibraryBloc', 'Failed to import book', e, stackTrace);
      emit(LibraryError('Failed to import book: $e'));
      // Restore previous library state
      if (existingBooks.isNotEmpty) {
        emit(LibraryLoaded(
          existingBooks,
          query: query,
          sortOrder: sortOrder,
          autoSyncFolder: autoSyncFolder,
        ));
      }
    }
  }

  void _onUpdateLibraryView(
    UpdateLibraryView event,
    Emitter<LibraryState> emit,
  ) {
    final currentState = state;
    if (currentState is LibraryLoaded) {
      emit(
        LibraryLoaded(
          currentState.books,
          query: event.query ?? currentState.query,
          sortOrder: event.sortOrder ?? currentState.sortOrder,
          autoSyncFolder: currentState.autoSyncFolder,
        ),
      );
    }
  }
}
