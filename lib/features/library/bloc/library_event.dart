part of 'library_bloc.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

class LoadLibrary extends LibraryEvent {}

class ImportBook extends LibraryEvent {
  final String filePath;

  const ImportBook(this.filePath);

  @override
  List<Object> get props => [filePath];
}

class SetAutoSyncFolder extends LibraryEvent {
  final String? folderPath;

  const SetAutoSyncFolder(this.folderPath);

  @override
  List<Object?> get props => [folderPath];
}

class ScanAutoSyncFolder extends LibraryEvent {}

class UpdateLibraryView extends LibraryEvent {
  final String? query;
  final LibrarySortOrder? sortOrder;

  const UpdateLibraryView({this.query, this.sortOrder});

  @override
  List<Object?> get props => [query, sortOrder];
}
