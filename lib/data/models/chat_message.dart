import 'package:bookies/data/models/user.dart';
import 'package:bookies/domain/entities/chat_message_entity.dart';

enum MessageStatus {
  sending,
  sent,
  failed;

  static MessageStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'sending':
        return MessageStatus.sending;
      case 'failed':
        return MessageStatus.failed;
      case 'sent':
      default:
        return MessageStatus.sent;
    }
  }
}

class ChatMessage {
  final String id;
  final String threadId;
  final String userId;
  final User? user;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToAuthor;
  final bool isSpoiler;
  final Map<String, List<String>> reactions;
  final String? quoteText;
  final String? chapterTitle;
  final int? chapterIndex;
  final String? cfi;

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.userId,
    this.user,
    required this.content,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.replyToId,
    this.replyToContent,
    this.replyToAuthor,
    this.isSpoiler = false,
    this.reactions = const {},
    this.quoteText,
    this.chapterTitle,
    this.chapterIndex,
    this.cfi,
  });

  ChatMessageEntity toDomain() => ChatMessageEntity(
        id: id,
        threadId: threadId,
        userId: userId,
        content: content,
        createdAt: createdAt,
        replyToId: replyToId,
        replyToContent: replyToContent,
        replyToAuthor: replyToAuthor,
        isSpoiler: isSpoiler,
        quoteText: quoteText,
        chapterTitle: chapterTitle,
        chapterIndex: chapterIndex,
        cfi: cfi,
        reactions: reactions,
      );

  factory ChatMessage.fromDomain(ChatMessageEntity entity, {MessageStatus status = MessageStatus.sent}) =>
      ChatMessage(
        id: entity.id,
        threadId: entity.threadId,
        userId: entity.userId,
        content: entity.content,
        createdAt: entity.createdAt,
        status: status,
        replyToId: entity.replyToId,
        replyToContent: entity.replyToContent,
        replyToAuthor: entity.replyToAuthor,
        isSpoiler: entity.isSpoiler,
        quoteText: entity.quoteText,
        chapterTitle: entity.chapterTitle,
        chapterIndex: entity.chapterIndex,
        cfi: entity.cfi,
        reactions: entity.reactions,
      );

  ChatMessage copyWith({
    String? id,
    String? threadId,
    String? userId,
    User? user,
    String? content,
    DateTime? createdAt,
    MessageStatus? status,
    String? replyToId,
    String? replyToContent,
    String? replyToAuthor,
    bool? isSpoiler,
    Map<String, List<String>>? reactions,
    String? quoteText,
    String? chapterTitle,
    int? chapterIndex,
    String? cfi,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToAuthor: replyToAuthor ?? this.replyToAuthor,
      isSpoiler: isSpoiler ?? this.isSpoiler,
      reactions: reactions ?? this.reactions,
      quoteText: quoteText ?? this.quoteText,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      cfi: cfi ?? this.cfi,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>> parsedReactions = {};
    if (json['reactions'] != null && json['reactions'] is Map) {
      final raw = json['reactions'] as Map<String, dynamic>;
      parsedReactions = raw.map(
        (key, value) => MapEntry(
          key,
          (value as List).map((e) => e.toString()).toList(),
        ),
      );
    }

    return ChatMessage(
      id: json['id'] as String,
      threadId: json['threadId'] as String? ?? '',
      userId: json['userId'] as String,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: MessageStatus.fromString(json['status'] as String?),
      replyToId: json['replyToId'] as String?,
      replyToContent: json['replyToContent'] as String?,
      replyToAuthor: json['replyToAuthor'] as String?,
      isSpoiler: json['isSpoiler'] as bool? ?? false,
      reactions: parsedReactions,
      quoteText: json['quoteText'] as String?,
      chapterTitle: json['chapterTitle'] as String?,
      chapterIndex: json['chapterIndex'] as int?,
      cfi: json['cfi'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'threadId': threadId,
      'userId': userId,
      'user': user?.toJson(),
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'replyToId': replyToId,
      'replyToContent': replyToContent,
      'replyToAuthor': replyToAuthor,
      'isSpoiler': isSpoiler,
      'reactions': reactions,
      'quoteText': quoteText,
      'chapterTitle': chapterTitle,
      'chapterIndex': chapterIndex,
      'cfi': cfi,
    };
  }
}
