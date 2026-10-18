part of 'library_bloc.dart';

abstract class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object> get props => [];
}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final List<Book> books;
  final List<Book> displayedBooks;
  final String query;
  final LibrarySortOrder sortOrder;

  LibraryLoaded(
    List<Book> books, {
    this.query = '',
    this.sortOrder = LibrarySortOrder.recent,
  }) : books = List.unmodifiable(books),
       displayedBooks = filterAndSortBooks(
         books,
         query: query,
         sortOrder: sortOrder,
       );

  @override
  List<Object> get props => [books, displayedBooks, query, sortOrder];
}

class LibraryError extends LibraryState {
  final String message;

  const LibraryError(this.message);

  @override
  List<Object> get props => [message];
}
