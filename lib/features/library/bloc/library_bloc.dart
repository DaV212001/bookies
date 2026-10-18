import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_readium/flutter_readium.dart';
import 'package:path_provider/path_provider.dart';

import '../../../data/models/book.dart';
import '../../../data/providers/local_data_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/epub_cover_extractor.dart';
import 'library_view_filter.dart';

export 'library_view_filter.dart';

part 'library_event.dart';
part 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final LocalDataService _dataService;

  LibraryBloc(this._dataService) : super(LibraryInitial()) {
    on<LoadLibrary>(_onLoadLibrary);
    on<ImportBook>(_onImportBook);
    on<UpdateLibraryView>(_onUpdateLibraryView);
  }

  void _onLoadLibrary(LoadLibrary event, Emitter<LibraryState> emit) async {
    AppLogger.i('LibraryBloc', 'Handling LoadLibrary event');
    emit(LibraryLoading());
    try {
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

      emit(LibraryLoaded(books));
    } catch (e, stackTrace) {
      AppLogger.e('LibraryBloc', 'Error loading library', e, stackTrace);
      emit(LibraryError('Failed to load library: $e'));
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
    if (currentState is LibraryLoaded) {
      existingBooks = currentState.books;
      query = currentState.query;
      sortOrder = currentState.sortOrder;
    }

    emit(LibraryLoading());
    try {
      final file = File(event.filePath);
      final exists = await file.exists();
      AppLogger.d(
        'LibraryBloc',
        'Source file exists check: $exists for path: ${event.filePath}',
      );
      if (!exists) {
        throw Exception("File not found at path: ${event.filePath}");
      }

      final fileSize = await file.length();
      AppLogger.i('LibraryBloc', 'Source file size: $fileSize bytes');

      // Copy to app documents directory with a sanitized filename
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
      AppLogger.i(
        'LibraryBloc',
        'Raw filename: "$rawFileName" sanitized to: "$sanitizedFileName"',
      );
      AppLogger.i('LibraryBloc', 'Copying file to target path: $targetPath');

      final savedFile = await file.copy(targetPath);
      final copiedExists = await savedFile.exists();
      final copiedSize = copiedExists ? await savedFile.length() : 0;
      AppLogger.i(
        'LibraryBloc',
        'Copied file exists: $copiedExists, size: $copiedSize bytes (source size: $fileSize bytes)',
      );

      if (!copiedExists || copiedSize == 0) {
        throw Exception(
          "Failed to write target EPUB file to path: $targetPath",
        );
      }

      // Extract metadata using Readium
      AppLogger.i(
        'LibraryBloc',
        'Calling FlutterReadium().loadPublication("${savedFile.path}")',
      );
      final publication = await FlutterReadium().loadPublication(
        savedFile.path,
      );
      AppLogger.i(
        'LibraryBloc',
        'FlutterReadium loaded publication successfully. Title: ${publication.metadata.title}',
      );

      // Extract cover image
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
        author:
            (publication.metadata.authors.firstOrNull ??
                    Contributor(
                      localizedName: LocalizedString(
                        translations: {'en': Translation("")},
                      ),
                    ))
                .localizedName
                ?.string ??
            'Unknown Author',
        fingerprint: 'hash_${DateTime.now().millisecondsSinceEpoch}',
        coverUrl: extractedCoverPath,
        localPath: savedFile.path,
      );

      AppLogger.i(
        'LibraryBloc',
        'Adding book to LocalDataService: ID=${newBook.id}, Title="${newBook.title}", Cover=${newBook.coverUrl}',
      );
      await _dataService.addBook(newBook);

      final updatedList = _dataService.getBooks();
      AppLogger.i(
        'LibraryBloc',
        'Book import complete. Total library books: ${updatedList.length}',
      );
      emit(LibraryLoaded(updatedList, query: query, sortOrder: sortOrder));
    } catch (e, stackTrace) {
      AppLogger.e(
        'LibraryBloc',
        'Failed to import book from path: ${event.filePath}',
        e,
        stackTrace,
      );

      emit(LibraryError(e.toString()));
      await Future.delayed(const Duration(milliseconds: 100));
      emit(LibraryLoaded(existingBooks, query: query, sortOrder: sortOrder));
    }
  }

  void _onUpdateLibraryView(
    UpdateLibraryView event,
    Emitter<LibraryState> emit,
  ) {
    final currentState = state;
    if (currentState is! LibraryLoaded) return;

    final query = event.query ?? currentState.query;
    final sortOrder = event.sortOrder ?? currentState.sortOrder;
    if (query == currentState.query && sortOrder == currentState.sortOrder) {
      return;
    }

    emit(LibraryLoaded(currentState.books, query: query, sortOrder: sortOrder));
  }
}
