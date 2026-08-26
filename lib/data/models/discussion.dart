import 'package:bookies/data/models/user.dart';
import 'package:bookies/data/models/thread_scope.dart';

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
  });

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
    };
  }
}
