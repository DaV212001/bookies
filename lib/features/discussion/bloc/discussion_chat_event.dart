import 'package:equatable/equatable.dart';
import 'package:bookies/data/models/chat_message.dart';
import 'package:bookies/data/models/discussion.dart';

abstract class DiscussionChatEvent extends Equatable {
  const DiscussionChatEvent();

  @override
  List<Object?> get props => [];
}

class InitializeChat extends DiscussionChatEvent {
  final Discussion discussion;
  final String bookId;
  final String? communityId;
  final String? currentReaderCfi;
  final int? currentReaderChapter;

  const InitializeChat({
    required this.discussion,
    required this.bookId,
    this.communityId,
    this.currentReaderCfi,
    this.currentReaderChapter,
  });

  @override
  List<Object?> get props => [
        discussion,
        bookId,
        communityId,
        currentReaderCfi,
        currentReaderChapter,
      ];
}

class SendMessage extends DiscussionChatEvent {
  final String content;
  final bool isSpoiler;

  const SendMessage({
    required this.content,
    this.isSpoiler = false,
  });

  @override
  List<Object?> get props => [content, isSpoiler];
}

class SelectReplyMessage extends DiscussionChatEvent {
  final ChatMessage? message;

  const SelectReplyMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class ToggleReaction extends DiscussionChatEvent {
  final String messageId;
  final String emoji;

  const ToggleReaction({required this.messageId, required this.emoji});

  @override
  List<Object?> get props => [messageId, emoji];
}

class RevealSpoilerWarning extends DiscussionChatEvent {
  const RevealSpoilerWarning();
}

class OnMessagesReceived extends DiscussionChatEvent {
  final List<ChatMessage> messages;

  const OnMessagesReceived(this.messages);

  @override
  List<Object?> get props => [messages];
}
