import 'package:equatable/equatable.dart';

class CatalogBookEntity extends Equatable {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String? description;
  final String? downloadUrl;
  final int activeReadersCount;
  final List<String> genres;
  final double? rating;

  const CatalogBookEntity({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.description,
    this.downloadUrl,
    this.activeReadersCount = 0,
    this.genres = const [],
    this.rating,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        coverUrl,
        description,
        downloadUrl,
        activeReadersCount,
        genres,
        rating,
      ];
}
