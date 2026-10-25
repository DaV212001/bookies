import 'package:bookies/domain/entities/quote_rating_entity.dart';

class QuoteRating {
  final String id;
  final String bookId;
  final String bookTitle;
  final String chapterTitle;
  final String quoteText;
  final String authorName;
  final String addedByUsername;
  int upvotes;
  bool isUpvotedByMe;
  double averageRating;

  QuoteRating({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.chapterTitle,
    required this.quoteText,
    required this.authorName,
    required this.addedByUsername,
    this.upvotes = 0,
    this.isUpvotedByMe = false,
    this.averageRating = 5.0,
  });

  QuoteRatingEntity toDomain() => QuoteRatingEntity(
        id: id,
        bookId: bookId,
        bookTitle: bookTitle,
        chapterTitle: chapterTitle,
        quoteText: quoteText,
        authorName: authorName,
        addedByUsername: addedByUsername,
        upvotes: upvotes,
        isUpvotedByMe: isUpvotedByMe,
        averageRating: averageRating,
      );

  factory QuoteRating.fromDomain(QuoteRatingEntity entity) => QuoteRating(
        id: entity.id,
        bookId: entity.bookId,
        bookTitle: entity.bookTitle,
        chapterTitle: entity.chapterTitle ?? '',
        quoteText: entity.quoteText,
        authorName: entity.authorName,
        addedByUsername: entity.addedByUsername,
        upvotes: entity.upvotes,
        isUpvotedByMe: entity.isUpvotedByMe,
        averageRating: entity.averageRating,
      );

  factory QuoteRating.fromJson(Map<String, dynamic> json) {
    return QuoteRating(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      bookTitle: json['bookTitle'] as String? ?? 'Book',
      chapterTitle: json['chapterTitle'] as String? ?? 'Excerpt',
      quoteText: json['quoteText'] as String,
      authorName: json['authorName'] as String? ?? 'Author',
      addedByUsername: json['addedByUsername'] as String? ?? 'Reader',
      upvotes: json['upvotes'] as int? ?? 0,
      isUpvotedByMe: json['isUpvotedByMe'] as bool? ?? false,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 5.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'chapterTitle': chapterTitle,
      'quoteText': quoteText,
      'authorName': authorName,
      'addedByUsername': addedByUsername,
      'upvotes': upvotes,
      'isUpvotedByMe': isUpvotedByMe,
      'averageRating': averageRating,
    };
  }
}
