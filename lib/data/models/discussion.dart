import 'package:bookies/data/models/user.dart';
import 'package:bookies/data/models/thread_scope.dart';
import 'package:bookies/data/models/chat_message.dart';

class Discussion {
  final String id;
  final String highlightId; // Also used as CFI or passage anchor
  final String bookId;
  final String communityId;
  final String userId;
  final User? user;
  final String title;
  final String content;
  final ThreadScope scope;
  final String? chapterTitle;
  final int? chapterIndex;
  final String? quoteText;
  final double? rating;
  int upvotes;
  final DateTime createdAt;
  final List<Discussion>? replies;
  final String? parentTopicId;

  Discussion({
    required this.id,
    required this.highlightId,
    this.bookId = '',
    this.communityId = '',
    required this.userId,
    this.user,
    this.title = '',
    required this.content,
    this.scope = ThreadScope.passage,
    this.chapterTitle,
    this.chapterIndex,
    this.quoteText,
    this.rating,
    this.upvotes = 0,
    required this.createdAt,
    this.replies,
    this.parentTopicId,
  });

  Discussion copyWith({
    String? id,
    String? highlightId,
    String? bookId,
    String? communityId,
    String? userId,
    User? user,
    String? title,
    String? content,
    ThreadScope? scope,
    String? chapterTitle,
    int? chapterIndex,
    String? quoteText,
    double? rating,
    int? upvotes,
    DateTime? createdAt,
    List<Discussion>? replies,
    String? parentTopicId,
  }) {
    return Discussion(
      id: id ?? this.id,
      highlightId: highlightId ?? this.highlightId,
      bookId: bookId ?? this.bookId,
      communityId: communityId ?? this.communityId,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      title: title ?? this.title,
      content: content ?? this.content,
      scope: scope ?? this.scope,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      quoteText: quoteText ?? this.quoteText,
      rating: rating ?? this.rating,
      upvotes: upvotes ?? this.upvotes,
      createdAt: createdAt ?? this.createdAt,
      replies: replies ?? this.replies,
      parentTopicId: parentTopicId ?? this.parentTopicId,
    );
  }

  ChatMessage toChatMessage([String? fallbackThreadId]) {
    return ChatMessage(
      id: id,
      threadId: fallbackThreadId ?? id,
      userId: userId,
      user: user,
      content: content,
      createdAt: createdAt,
      status: MessageStatus.sent,
      quoteText: quoteText,
      chapterTitle: chapterTitle,
      chapterIndex: chapterIndex,
      cfi: highlightId,
    );
  }

  factory Discussion.fromJson(Map<String, dynamic> json) {
    return Discussion(
      id: json['id'] as String,
      highlightId: json['highlightId'] as String,
      bookId: json['bookId'] as String? ?? '',
      communityId: json['communityId'] as String? ?? '',
      userId: json['userId'] as String,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      title: json['title'] as String? ?? '',
      content: json['content'] as String,
      scope: ThreadScope.fromString(json['scope'] as String?),
      chapterTitle: json['chapterTitle'] as String?,
      chapterIndex: json['chapterIndex'] as int?,
      quoteText: json['quoteText'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      upvotes: json['upvotes'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      replies: json['replies'] != null
          ? (json['replies'] as List)
              .map((e) => Discussion.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      parentTopicId: json['parentTopicId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'highlightId': highlightId,
      'bookId': bookId,
      'communityId': communityId,
      'userId': userId,
      'user': user?.toJson(),
      'title': title,
      'content': content,
      'scope': scope.name,
      'chapterTitle': chapterTitle,
      'chapterIndex': chapterIndex,
      'quoteText': quoteText,
      'rating': rating,
      'upvotes': upvotes,
      'createdAt': createdAt.toIso8601String(),
      'replies': replies?.map((e) => e.toJson()).toList(),
      'parentTopicId': parentTopicId,
    };
  }
}
