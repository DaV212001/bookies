import '../../../data/models/book.dart';

/// The available presentation orders for the library collection.
enum LibrarySortOrder { recent, title, author }

/// Derives the visible library collection when either the books, search query,
/// or selected sort order changes. Keeping this work outside widget builds
/// prevents unrelated rebuilds from repeatedly filtering and sorting books.
List<Book> filterAndSortBooks(
  Iterable<Book> books, {
  required String query,
  required LibrarySortOrder sortOrder,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final visibleBooks = books.where((book) {
    if (normalizedQuery.isEmpty) return true;
    return book.title.toLowerCase().contains(normalizedQuery) ||
        book.author.toLowerCase().contains(normalizedQuery);
  }).toList();

  switch (sortOrder) {
    case LibrarySortOrder.title:
      visibleBooks.sort((a, b) => a.title.compareTo(b.title));
    case LibrarySortOrder.author:
      visibleBooks.sort((a, b) => a.author.compareTo(b.author));
    case LibrarySortOrder.recent:
      break;
  }

  return List.unmodifiable(visibleBooks);
}
