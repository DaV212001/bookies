part of 'discussion_bloc.dart';

abstract class DiscussionEvent extends Equatable {
  const DiscussionEvent();

  @override
  List<Object?> get props => [];
}

class LoadThread extends DiscussionEvent {
  final String cfi;
  final String currentReaderCfi; // Used to check if spoiler
  final String? communityId;

  const LoadThread({
    required this.cfi,
    required this.currentReaderCfi,
    this.communityId,
  });

  @override
  List<Object?> get props => [cfi, currentReaderCfi, communityId];
}

class PostComment extends DiscussionEvent {
  final String cfi;
  final String text;
  final String bookId;
  final String communityId;

  const PostComment({
    required this.cfi,
    required this.text,
    required this.bookId,
    required this.communityId,
  });

  @override
  List<Object> get props => [cfi, text, bookId, communityId];
}
