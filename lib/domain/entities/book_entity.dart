import 'package:equatable/equatable.dart';

class BookEntity extends Equatable {
  final String id;
  final String title;
  final String author;
  final String fingerprint;
  final String? coverUrl;
  final String? isbn;
  final String? localPath;

  const BookEntity({
    required this.id,
    required this.title,
    required this.author,
    required this.fingerprint,
    this.coverUrl,
    this.isbn,
    this.localPath,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        fingerprint,
        coverUrl,
        isbn,
        localPath,
      ];
}
