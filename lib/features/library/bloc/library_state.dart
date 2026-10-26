part of 'library_bloc.dart';

abstract class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object?> get props => [];
}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final List<Book> books;
  final List<Book> displayedBooks;
  final String query;
  final LibrarySortOrder sortOrder;
  final String? autoSyncFolder;

  LibraryLoaded(
    List<Book> books, {
    this.query = '',
    this.sortOrder = LibrarySortOrder.recent,
    this.autoSyncFolder,
  }) : books = List.unmodifiable(books),
       displayedBooks = filterAndSortBooks(
         books,
         query: query,
         sortOrder: sortOrder,
       );

  LibraryLoaded copyWith({
    List<Book>? books,
    String? query,
    LibrarySortOrder? sortOrder,
    String? autoSyncFolder,
    bool clearAutoSyncFolder = false,
  }) {
    return LibraryLoaded(
      books ?? this.books,
      query: query ?? this.query,
      sortOrder: sortOrder ?? this.sortOrder,
      autoSyncFolder: clearAutoSyncFolder ? null : (autoSyncFolder ?? this.autoSyncFolder),
    );
  }

  @override
  List<Object?> get props => [books, displayedBooks, query, sortOrder, autoSyncFolder];
}

class LibraryError extends LibraryState {
  final String message;

  const LibraryError(this.message);

  @override
  List<Object> get props => [message];
}
