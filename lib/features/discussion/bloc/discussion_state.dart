part of 'discussion_bloc.dart';

abstract class DiscussionState extends Equatable {
  const DiscussionState();
  
  @override
  List<Object> get props => [];
}

class DiscussionInitial extends DiscussionState {}

class DiscussionLoading extends DiscussionState {}

class DiscussionLoaded extends DiscussionState {
  final String cfi;
  final List<Discussion> comments;

  const DiscussionLoaded(this.cfi, this.comments);

  @override
  List<Object> get props => [cfi, comments];
}

class DiscussionSpoilerWarning extends DiscussionState {
  final String cfi;

  const DiscussionSpoilerWarning(this.cfi);

  @override
  List<Object> get props => [cfi];
}

class DiscussionError extends DiscussionState {
  final String message;

  const DiscussionError(this.message);

  @override
  List<Object> get props => [message];
}
