import 'dart:async';
import 'package:bookies/core/network/api_client.dart';
import 'package:bookies/core/network/socket_service.dart';
import 'package:bookies/core/utils/app_logger.dart';
import 'package:bookies/data/models/chat_message.dart';
import 'package:bookies/data/models/discussion.dart';
import 'package:bookies/data/models/thread_scope.dart';
import 'package:bookies/data/models/user.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/data/repositories/discussion_repository.dart';
import 'package:bookies/data/repositories/local_discussion_repository.dart';

class ApiDiscussionRepository implements DiscussionRepository {
  final ApiClient _apiClient;
  final SocketService? _socketService;
  final LocalDiscussionRepository _localFallback;

  final Map<String, StreamController<List<ChatMessage>>> _streamControllers = {};
  final Map<String, List<ChatMessage>> _threadCache = {};

  static const String _tag = 'ApiDiscussionRepository';

  ApiDiscussionRepository({
    required ApiClient apiClient,
    SocketService? socketService,
    required LocalDataService localDataService,
  })  : _apiClient = apiClient,
        _socketService = socketService,
        _localFallback = LocalDiscussionRepository(localDataService) {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    _socketService?.on('new_chat_message', (data) {
      if (data is Map<String, dynamic>) {
        final threadId = data['threadId']?.toString();
        if (threadId != null && _streamControllers.containsKey(threadId)) {
          final message = _mapJsonToChatMessage(data);
          final current = _threadCache[threadId] ?? [];
          if (!current.any((m) => m.id == message.id)) {
            final updated = [...current, message];
            _threadCache[threadId] = updated;
            _streamControllers[threadId]?.add(updated);
          }
        }
      }
    });
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String threadId) {
    if (!_streamControllers.containsKey(threadId) ||
        _streamControllers[threadId]!.isClosed) {
      _streamControllers[threadId] =
          StreamController<List<ChatMessage>>.broadcast();

      // Connect to socket room for thread
      _socketService?.joinRoom('thread_$threadId');

      // Fetch initial messages
      getMessages(threadId).then((messages) {
        if (!_streamControllers[threadId]!.isClosed) {
          _threadCache[threadId] = messages;
          _streamControllers[threadId]!.add(messages);
        }
      }).catchError((_) {
        // Fallback to local
        _localFallback.watchMessages(threadId).listen((localMsgs) {
          if (!_streamControllers[threadId]!.isClosed) {
            _threadCache[threadId] = localMsgs;
            _streamControllers[threadId]!.add(localMsgs);
          }
        });
      });
    }

    return _streamControllers[threadId]!.stream;
  }

  @override
  Future<List<ChatMessage>> getMessages(String threadId, {int limit = 50}) async {
    try {
      final response = await _apiClient.dio.get(
        '/discussions/$threadId/messages',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data is List) {
        final messages = (response.data as List)
            .map((item) => _mapJsonToChatMessage(item))
            .toList();
        _threadCache[threadId] = messages;
        return messages;
      }
    } catch (e) {
      AppLogger.w(_tag, 'Failed to fetch messages for $threadId: $e');
    }

    return _localFallback.getMessages(threadId, limit: limit);
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
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/discussions/$threadId/messages',
        data: {
          'content': content.trim(),
          if (replyToId != null) 'replyToId': replyToId,
          if (replyToContent != null) 'replyToContent': replyToContent,
          if (replyToAuthor != null) 'replyToAuthor': replyToAuthor,
          'isSpoiler': isSpoiler,
          if (quoteText != null) 'quoteText': quoteText,
          if (chapterTitle != null) 'chapterTitle': chapterTitle,
          if (chapterIndex != null) 'chapterIndex': chapterIndex,
          if (cfi != null) 'cfi': cfi,
        },
      );

      final message = _mapJsonToChatMessage(response.data);

      // Broadcast over socket and update local cache
      _socketService?.emit('chat_message_sent', {
        'threadId': threadId,
        'message': response.data,
      });

      final current = _threadCache[threadId] ?? [];
      final updated = [...current, message];
      _threadCache[threadId] = updated;
      _streamControllers[threadId]?.add(updated);

      return message;
    } catch (e) {
      AppLogger.w(_tag, 'Remote sendMessage failed, saving locally: $e');
      return _localFallback.sendMessage(
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
  }

  @override
  Future<void> toggleReaction({
    required String threadId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    try {
      await _apiClient.dio.post(
        '/discussions/messages/$messageId/reactions',
        data: {'emoji': emoji},
      );
    } catch (e) {
      AppLogger.w(_tag, 'Remote toggleReaction failed, applying locally: $e');
      await _localFallback.toggleReaction(
        threadId: threadId,
        messageId: messageId,
        emoji: emoji,
        userId: userId,
      );
    }
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
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/discussions',
        data: {
          'highlightId': highlightId,
          'bookId': bookId,
          if (communityId.isNotEmpty) 'communityId': communityId,
          'title': title.trim(),
          'content': content.trim(),
          'scope': scope.name,
          if (chapterTitle != null) 'chapterTitle': chapterTitle,
          if (chapterIndex != null) 'chapterIndex': chapterIndex,
          if (quoteText != null) 'quoteText': quoteText,
          if (rating != null) 'rating': rating,
          if (parentTopicId != null) 'parentTopicId': parentTopicId,
        },
      );

      return _mapJsonToDiscussion(response.data);
    } catch (e) {
      AppLogger.w(_tag, 'Remote createThread failed, falling back to local: $e');
      return _localFallback.createThread(
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
  }

  @override
  Future<void> upvoteThread(String threadId) async {
    try {
      await _apiClient.dio.post('/discussions/$threadId/upvote');
    } catch (e) {
      await _localFallback.upvoteThread(threadId);
    }
  }

  ChatMessage _mapJsonToChatMessage(dynamic json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? {};
    final reactionsJson = json['reactions'] as Map<String, dynamic>? ?? {};

    final reactionsMap = <String, List<String>>{};
    reactionsJson.forEach((key, val) {
      if (val is List) {
        reactionsMap[key] = List<String>.from(val.map((x) => x.toString()));
      }
    });

    final authorId = userJson['id']?.toString() ?? json['userId']?.toString() ?? '';
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      threadId: json['threadId']?.toString() ?? '',
      userId: authorId,
      user: User(
        id: authorId,
        username: userJson['username']?.toString() ?? 'reader',
        displayName: userJson['displayName']?.toString() ?? 'Reader',
        avatarUrl: userJson['avatarUrl']?.toString() ?? '',
      ),
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      replyToId: json['replyToId']?.toString(),
      replyToContent: json['replyToContent']?.toString(),
      replyToAuthor: json['replyToAuthor']?.toString(),
      isSpoiler: json['isSpoiler'] as bool? ?? false,
      quoteText: json['quoteText']?.toString(),
      chapterTitle: json['chapterTitle']?.toString(),
      chapterIndex: json['chapterIndex'] as int?,
      cfi: json['cfi']?.toString(),
      reactions: reactionsMap,
    );
  }

  Discussion _mapJsonToDiscussion(dynamic json) {
    final authorId = json['userId']?.toString() ?? 'user-1';
    return Discussion(
      id: json['id']?.toString() ?? '',
      highlightId: json['highlightId']?.toString() ?? '',
      bookId: json['bookId']?.toString() ?? '',
      communityId: json['communityId']?.toString() ?? '',
      userId: authorId,
      user: User(
        id: authorId,
        username: 'reader',
        displayName: 'Reader',
      ),
      title: json['title']?.toString() ?? 'Discussion',
      content: json['content']?.toString() ?? '',
      scope: ThreadScope.values.firstWhere(
        (s) => s.name.toLowerCase() == json['scope']?.toString().toLowerCase(),
        orElse: () => ThreadScope.passage,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      rating: (json['rating'] as num?)?.toDouble(),
      upvotes: json['upvotes'] as int? ?? 0,
      parentTopicId: json['parentTopicId']?.toString(),
      chapterTitle: json['chapterTitle']?.toString(),
      chapterIndex: json['chapterIndex'] as int?,
      quoteText: json['quoteText']?.toString(),
    );
  }

  void dispose() {
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
  }
}
