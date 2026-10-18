import 'package:bookies/data/models/book.dart';
import 'package:bookies/features/library/bloc/library_view_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Book _book(String id, String title, String author) => Book(
      id: id,
      title: title,
      author: author,
      fingerprint: id,
    );

void main() {
  final books = [
    _book('1', 'Zebra Tales', 'Ada'),
    _book('2', 'A Study in Scarlet', 'Zoe'),
    _book('3', 'The Odyssey', 'Homer'),
  ];

  test('filters and sorts a copy without mutating the source collection', () {
    final displayed = filterAndSortBooks(
      books,
      query: 'a',
      sortOrder: LibrarySortOrder.title,
    );

    expect(displayed.map((book) => book.title), [
      'A Study in Scarlet',
      'Zebra Tales',
    ]);
    expect(books.map((book) => book.title), [
      'Zebra Tales',
      'A Study in Scarlet',
      'The Odyssey',
    ]);
  });

  test('preserves recent ordering when no explicit sort is selected', () {
    final displayed = filterAndSortBooks(
      books,
      query: '',
      sortOrder: LibrarySortOrder.recent,
    );

    expect(displayed.map((book) => book.id), ['1', '2', '3']);
  });
}
