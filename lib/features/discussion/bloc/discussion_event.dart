part of 'discussion_bloc.dart';

abstract class DiscussionEvent extends Equatable {
  const DiscussionEvent();

  @override
  List<Object> get props => [];
}

class LoadThread extends DiscussionEvent {
  final String cfi;
  final String currentReaderCfi; // Used to check if spoiler

  const LoadThread({required this.cfi, required this.currentReaderCfi});

  @override
  List<Object> get props => [cfi, currentReaderCfi];
}

class PostComment extends DiscussionEvent {
  final String cfi;
  final String text;

  const PostComment({required this.cfi, required this.text});

  @override
  List<Object> get props => [cfi, text];
}
