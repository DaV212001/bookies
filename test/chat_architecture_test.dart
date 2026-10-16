import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookies/data/models/chat_message.dart';
import 'package:bookies/data/models/discussion.dart';
import 'package:bookies/data/models/thread_scope.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/data/repositories/local_discussion_repository.dart';
import 'package:bookies/features/discussion/bloc/discussion_chat_bloc.dart';
import 'package:bookies/features/discussion/bloc/discussion_chat_event.dart';
import 'package:bookies/features/discussion/bloc/discussion_chat_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThreadScope & Hierarchy Tests', () {
    test('supports all 5 discussion scopes and parses correctly', () {
      expect(ThreadScope.values.length, 5);
      expect(ThreadScope.fromString('book'), ThreadScope.book);
      expect(ThreadScope.fromString('chapter'), ThreadScope.chapter);
      expect(ThreadScope.fromString('passage'), ThreadScope.passage);
      expect(ThreadScope.fromString('topic'), ThreadScope.topic);
      expect(ThreadScope.fromString('subtopic'), ThreadScope.subtopic);

      expect(ThreadScope.topic.label, 'Topic');
      expect(ThreadScope.subtopic.label, 'Subtopic');
    });

    test('Discussion model supports parentTopicId and copyWith', () {
      final discussion = Discussion(
        id: 't-1',
        highlightId: 'hl-1',
        userId: 'u-1',
        title: 'Main Topic',
        content: 'Topic description',
        scope: ThreadScope.topic,
        createdAt: DateTime.now(),
      );

      final subtopic = discussion.copyWith(
        id: 'sub-1',
        title: 'Subtopic 1',
        scope: ThreadScope.subtopic,
        parentTopicId: 't-1',
      );

      expect(subtopic.id, 'sub-1');
      expect(subtopic.parentTopicId, 't-1');
      expect(subtopic.scope, ThreadScope.subtopic);

      final json = subtopic.toJson();
      final fromJson = Discussion.fromJson(json);
      expect(fromJson.parentTopicId, 't-1');
      expect(fromJson.scope, ThreadScope.subtopic);
    });
  });

  group('ChatMessage & Reaction Tests', () {
    test('serializes and deserializes ChatMessage correctly', () {
      final msg = ChatMessage(
        id: 'msg-1',
        threadId: 'th-1',
        userId: 'u-1',
        content: 'Hello book club',
        createdAt: DateTime.now(),
        replyToId: 'prev-1',
        replyToContent: 'Previous msg',
        replyToAuthor: 'Alice',
        isSpoiler: true,
        reactions: {
          '👍': ['u-1', 'u-2'],
          '❤️': ['u-3'],
        },
      );

      final json = msg.toJson();
      final parsed = ChatMessage.fromJson(json);

      expect(parsed.id, 'msg-1');
      expect(parsed.content, 'Hello book club');
      expect(parsed.replyToId, 'prev-1');
      expect(parsed.replyToContent, 'Previous msg');
      expect(parsed.replyToAuthor, 'Alice');
      expect(parsed.isSpoiler, isTrue);
      expect(parsed.reactions['👍']?.length, 2);
      expect(parsed.reactions['❤️']?.first, 'u-3');
    });
  });

  group('LocalDiscussionRepository & DiscussionChatBloc Tests', () {
    late LocalDataService dataService;
    late LocalDiscussionRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      dataService = LocalDataService();
      await dataService.init();
      repository = LocalDiscussionRepository(dataService);
    });

    test('Topic and subtopic creation and retrieval in LocalDataService', () async {
      final topic = await dataService.createThread(
        highlightId: 'topic-test-1',
        bookId: 'mock-book-1',
        title: 'Themes of Friendship',
        content: 'Discussion about character bonds',
        scope: ThreadScope.topic,
      );

      final subtopic = await dataService.createThread(
        highlightId: 'subtopic-test-1',
        bookId: 'mock-book-1',
        title: 'Camilla & Charles',
        content: 'Specific focus on the twins',
        scope: ThreadScope.subtopic,
        parentTopicId: topic.id,
      );

      final topics = dataService.getTopicsForBook('mock-book-1');
      expect(topics.any((t) => t.id == topic.id), isTrue);

      final subtopics = dataService.getSubtopics(topic.id);
      expect(subtopics.length, 1);
      expect(subtopics.first.id, subtopic.id);
      expect(subtopics.first.title, 'Camilla & Charles');
    });

    test('DiscussionChatBloc loads messages and performs optimistic send', () async {
      final thread = Discussion(
        id: 'chat-test-thread',
        highlightId: 'cfi-chat-test',
        bookId: 'mock-book-1',
        userId: dataService.currentUser.id,
        user: dataService.currentUser,
        title: 'Chapter 2 Reflection',
        content: 'What did you think of the turn of events?',
        scope: ThreadScope.chapter,
        chapterTitle: 'Chapter 2',
        chapterIndex: 2,
        createdAt: DateTime.now(),
      );

      final bloc = DiscussionChatBloc(
        repository: repository,
        currentUser: dataService.currentUser,
      );

      // Initialize chat
      bloc.add(
        InitializeChat(
          discussion: thread,
          bookId: 'mock-book-1',
          currentReaderChapter: 5, // Ahead of chapter 2, so no spoiler
        ),
      );

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DiscussionChatState>(
            (state) => state.status == DiscussionChatStatus.loaded && state.messages.isNotEmpty,
          ),
        ),
      );

      expect(bloc.state.isSpoilerThread, isFalse);

      // Send a reply
      bloc.add(const SendMessage(content: 'I was completely shocked!'));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DiscussionChatState>(
            (state) =>
                state.messages.any((m) => m.content == 'I was completely shocked!'),
          ),
        ),
      );

      // Verify toggle reaction
      final lastMsg = bloc.state.messages.firstWhere((m) => m.content == 'I was completely shocked!');
      bloc.add(ToggleReaction(messageId: lastMsg.id, emoji: '❤️'));

      await Future.delayed(const Duration(milliseconds: 100));

      final updatedMessages = await repository.getMessages('chat-test-thread');
      final updatedMsg = updatedMessages.firstWhere((m) => m.id == lastMsg.id);
      expect(updatedMsg.reactions['❤️']?.contains(dataService.currentUser.id), isTrue);

      await bloc.close();
    });

    test('DiscussionChatBloc detects spoiler threads correctly', () async {
      final thread = Discussion(
        id: 'spoiler-thread',
        highlightId: 'cfi-spoiler',
        bookId: 'mock-book-1',
        userId: 'other-user',
        title: 'Ending Revelation',
        content: 'Major plot twist at chapter 10!',
        scope: ThreadScope.chapter,
        chapterIndex: 10,
        createdAt: DateTime.now(),
      );

      final bloc = DiscussionChatBloc(
        repository: repository,
        currentUser: dataService.currentUser,
      );

      // Reader is only on chapter 3
      bloc.add(
        InitializeChat(
          discussion: thread,
          bookId: 'mock-book-1',
          currentReaderChapter: 3,
        ),
      );

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DiscussionChatState>(
            (state) => state.isSpoilerThread == true && state.spoilerRevealed == false,
          ),
        ),
      );

      // Reveal spoiler
      bloc.add(const RevealSpoilerWarning());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DiscussionChatState>((state) => state.spoilerRevealed == true),
        ),
      );

      await bloc.close();
    });
  });
}
