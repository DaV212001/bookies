part of 'library_bloc.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object> get props => [];
}

class LoadLibrary extends LibraryEvent {}

class ImportBook extends LibraryEvent {
  final String filePath;

  const ImportBook(this.filePath);

  @override
  List<Object> get props => [filePath];
}
