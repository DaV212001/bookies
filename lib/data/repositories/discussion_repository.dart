import 'package:bookies/data/models/chat_message.dart';
import 'package:bookies/data/models/discussion.dart';
import 'package:bookies/data/models/thread_scope.dart';

abstract class DiscussionRepository {
  /// Stream messages in real-time for a specific thread
  Stream<List<ChatMessage>> watchMessages(String threadId);

  /// Fetch initial or paginated messages for a specific thread
  Future<List<ChatMessage>> getMessages(String threadId, {int limit = 50});

  /// Send a message into a thread (with optimistic support and reply anchoring)
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String content,
    String? replyToId,
    String? replyToContent,
    String? replyToAuthor,
    bool isSpoiler = false,
    String? quoteText,
    String? chapterTitle,
    int? chapterIndex,
    String? cfi,
  });

  /// Toggle an emoji reaction on a message
  Future<void> toggleReaction({
    required String threadId,
    required String messageId,
    required String emoji,
    required String userId,
  });

  /// Create a new discussion thread
  Future<Discussion> createThread({
    required String highlightId,
    required String bookId,
    String communityId = '',
    required String title,
    required String content,
    required ThreadScope scope,
    String? chapterTitle,
    int? chapterIndex,
    String? quoteText,
    double? rating,
    String? parentTopicId,
  });

  /// Upvote a discussion thread
  Future<void> upvoteThread(String threadId);
}
