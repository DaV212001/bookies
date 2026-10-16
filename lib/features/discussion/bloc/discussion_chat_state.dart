import 'package:equatable/equatable.dart';
import 'package:bookies/data/models/chat_message.dart';
import 'package:bookies/data/models/discussion.dart';

enum DiscussionChatStatus { initial, loading, loaded, error }

class DiscussionChatState extends Equatable {
  final DiscussionChatStatus status;
  final Discussion? discussion;
  final List<ChatMessage> messages; // Ordered newest first for reverse ListView
  final ChatMessage? replyingTo;
  final bool isSpoilerThread;
  final bool spoilerRevealed;
  final String? errorMessage;
  final bool isSending;

  const DiscussionChatState({
    this.status = DiscussionChatStatus.initial,
    this.discussion,
    this.messages = const [],
    this.replyingTo,
    this.isSpoilerThread = false,
    this.spoilerRevealed = false,
    this.errorMessage,
    this.isSending = false,
  });

  DiscussionChatState copyWith({
    DiscussionChatStatus? status,
    Discussion? discussion,
    List<ChatMessage>? messages,
    ChatMessage? replyingTo,
    bool clearReplyingTo = false,
    bool? isSpoilerThread,
    bool? spoilerRevealed,
    String? errorMessage,
    bool? isSending,
  }) {
    return DiscussionChatState(
      status: status ?? this.status,
      discussion: discussion ?? this.discussion,
      messages: messages ?? this.messages,
      replyingTo: clearReplyingTo ? null : (replyingTo ?? this.replyingTo),
      isSpoilerThread: isSpoilerThread ?? this.isSpoilerThread,
      spoilerRevealed: spoilerRevealed ?? this.spoilerRevealed,
      errorMessage: errorMessage ?? this.errorMessage,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [
        status,
        discussion,
        messages,
        replyingTo,
        isSpoilerThread,
        spoilerRevealed,
        errorMessage,
        isSending,
      ];
}
