import 'package:equatable/equatable.dart';
import 'package:bookies/domain/entities/catalog_book_entity.dart';

abstract class CatalogEvent extends Equatable {
  const CatalogEvent();

  @override
  List<Object?> get props => [];
}

class FetchCatalogEvent extends CatalogEvent {
  final String? genre;
  const FetchCatalogEvent({this.genre});

  @override
  List<Object?> get props => [genre];
}

class SearchCatalogEvent extends CatalogEvent {
  final String query;
  const SearchCatalogEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectGenreFilterEvent extends CatalogEvent {
  final String genre;
  const SelectGenreFilterEvent(this.genre);

  @override
  List<Object?> get props => [genre];
}

class DownloadCatalogBookEvent extends CatalogEvent {
  final CatalogBookEntity book;
  const DownloadCatalogBookEvent(this.book);

  @override
  List<Object?> get props => [book];
}

class UpdateDownloadProgressEvent extends CatalogEvent {
  final String bookId;
  final double progress;
  const UpdateDownloadProgressEvent({required this.bookId, required this.progress});

  @override
  List<Object?> get props => [bookId, progress];
}
