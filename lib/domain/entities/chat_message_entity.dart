import 'package:equatable/equatable.dart';

class ChatMessageEntity extends Equatable {
  final String id;
  final String threadId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToAuthor;
  final bool isSpoiler;
  final String? quoteText;
  final String? chapterTitle;
  final int? chapterIndex;
  final String? cfi;
  final Map<String, List<String>> reactions; // emoji -> list of userIds

  const ChatMessageEntity({
    required this.id,
    required this.threadId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.replyToId,
    this.replyToContent,
    this.replyToAuthor,
    this.isSpoiler = false,
    this.quoteText,
    this.chapterTitle,
    this.chapterIndex,
    this.cfi,
    this.reactions = const {},
  });

  @override
  List<Object?> get props => [
        id,
        threadId,
        userId,
        content,
        createdAt,
        replyToId,
        replyToContent,
        replyToAuthor,
        isSpoiler,
        quoteText,
        chapterTitle,
        chapterIndex,
        cfi,
        reactions,
      ];
}
