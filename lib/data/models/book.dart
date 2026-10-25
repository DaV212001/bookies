import 'package:bookies/domain/entities/book_entity.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String fingerprint; // Unique hash to identify the book version
  final String? coverUrl;
  final String? isbn;
  final String? localPath;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.fingerprint,
    this.coverUrl,
    this.isbn,
    this.localPath,
  });

  BookEntity toDomain() => BookEntity(
        id: id,
        title: title,
        author: author,
        fingerprint: fingerprint,
        coverUrl: coverUrl,
        isbn: isbn,
        localPath: localPath,
      );

  factory Book.fromDomain(BookEntity entity) => Book(
        id: entity.id,
        title: entity.title,
        author: entity.author,
        fingerprint: entity.fingerprint,
        coverUrl: entity.coverUrl,
        isbn: entity.isbn,
        localPath: entity.localPath,
      );

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      fingerprint: json['fingerprint'] as String,
      coverUrl: json['coverUrl'] as String?,
      isbn: json['isbn'] as String?,
      localPath: json['localPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'fingerprint': fingerprint,
      'coverUrl': coverUrl,
      'isbn': isbn,
      'localPath': localPath,
    };
  }
}
