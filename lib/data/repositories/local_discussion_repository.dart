import 'package:bookies/data/models/chat_message.dart';
import 'package:bookies/data/models/discussion.dart';
import 'package:bookies/data/models/thread_scope.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/data/repositories/discussion_repository.dart';

/// Local implementation of DiscussionRepository backed by LocalDataService.
/// When a backend is introduced, a RemoteDiscussionRepository can be created
/// implementing the same DiscussionRepository contract without touching UI or Blocs.
class LocalDiscussionRepository implements DiscussionRepository {
  final LocalDataService _localDataService;

  LocalDiscussionRepository(this._localDataService);

  @override
  Stream<List<ChatMessage>> watchMessages(String threadId) {
    return _localDataService.watchMessages(threadId);
  }

  @override
  Future<List<ChatMessage>> getMessages(String threadId, {int limit = 50}) {
    return _localDataService.getMessages(threadId, limit: limit);
  }

  @override
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
  }) {
    return _localDataService.addChatMessage(
      threadId: threadId,
      content: content,
      replyToId: replyToId,
      replyToContent: replyToContent,
      replyToAuthor: replyToAuthor,
      isSpoiler: isSpoiler,
      quoteText: quoteText,
      chapterTitle: chapterTitle,
      chapterIndex: chapterIndex,
      cfi: cfi,
    );
  }

  @override
  Future<void> toggleReaction({
    required String threadId,
    required String messageId,
    required String emoji,
    required String userId,
  }) {
    return _localDataService.toggleReaction(
      threadId: threadId,
      messageId: messageId,
      emoji: emoji,
      userId: userId,
    );
  }

  @override
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
  }) {
    return _localDataService.createThread(
      highlightId: highlightId,
      bookId: bookId,
      communityId: communityId,
      title: title,
      content: content,
      scope: scope,
      chapterTitle: chapterTitle,
      chapterIndex: chapterIndex,
      quoteText: quoteText,
      rating: rating,
      parentTopicId: parentTopicId,
    );
  }

  @override
  Future<void> upvoteThread(String threadId) {
    return _localDataService.upvoteThread(threadId);
  }
}
