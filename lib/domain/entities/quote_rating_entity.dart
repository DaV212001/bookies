import 'package:equatable/equatable.dart';

class QuoteRatingEntity extends Equatable {
  final String id;
  final String bookId;
  final String bookTitle;
  final String? chapterTitle;
  final String quoteText;
  final String authorName;
  final String addedByUsername;
  final int upvotes;
  final bool isUpvotedByMe;
  final double averageRating;

  const QuoteRatingEntity({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    this.chapterTitle,
    required this.quoteText,
    required this.authorName,
    required this.addedByUsername,
    this.upvotes = 0,
    this.isUpvotedByMe = false,
    this.averageRating = 0.0,
  });

  @override
  List<Object?> get props => [
        id,
        bookId,
        bookTitle,
        chapterTitle,
        quoteText,
        authorName,
        addedByUsername,
        upvotes,
        isUpvotedByMe,
        averageRating,
      ];
}
