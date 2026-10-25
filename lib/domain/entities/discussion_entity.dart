import 'package:equatable/equatable.dart';
import 'user_entity.dart';

enum DiscussionScope {
  passage,
  chapter,
  book,
  topic,
  subtopic;

  String get label {
    switch (this) {
      case DiscussionScope.passage:
        return 'Passage';
      case DiscussionScope.chapter:
        return 'Chapter';
      case DiscussionScope.book:
        return 'Book';
      case DiscussionScope.topic:
        return 'Topic';
      case DiscussionScope.subtopic:
        return 'Subtopic';
    }
  }

  static DiscussionScope fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'passage':
        return DiscussionScope.passage;
      case 'chapter':
        return DiscussionScope.chapter;
      case 'topic':
        return DiscussionScope.topic;
      case 'subtopic':
        return DiscussionScope.subtopic;
      case 'book':
      default:
        return DiscussionScope.book;
    }
  }
}

class DiscussionEntity extends Equatable {
  final String id;
  final String highlightId;
  final String bookId;
  final String communityId;
  final String userId;
  final UserEntity? user;
  final String title;
  final String content;
  final DiscussionScope scope;
  final String? chapterTitle;
  final int? chapterIndex;
  final String? quoteText;
  final double? rating;
  final int upvotes;
  final bool isUpvotedByMe;
  final DateTime createdAt;
  final String? parentTopicId;

  const DiscussionEntity({
    required this.id,
    required this.highlightId,
    this.bookId = '',
    this.communityId = '',
    required this.userId,
    this.user,
    required this.title,
    required this.content,
    required this.scope,
    this.chapterTitle,
    this.chapterIndex,
    this.quoteText,
    this.rating,
    this.upvotes = 0,
    this.isUpvotedByMe = false,
    required this.createdAt,
    this.parentTopicId,
  });

  @override
  List<Object?> get props => [
        id,
        highlightId,
        bookId,
        communityId,
        userId,
        user,
        title,
        content,
        scope,
        chapterTitle,
        chapterIndex,
        quoteText,
        rating,
        upvotes,
        isUpvotedByMe,
        createdAt,
        parentTopicId,
      ];
}
