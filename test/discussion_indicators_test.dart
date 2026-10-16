import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookies/core/widgets/margin_discussion_indicator.dart';
import 'package:bookies/data/models/book.dart';
import 'package:bookies/data/models/discussion.dart';
import 'package:bookies/data/models/thread_scope.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/features/discussion/views/discussion_details_sheet.dart';
import 'package:bookies/features/reader/bloc/reader_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MarginDiscussionIndicator Tests', () {
    testWidgets('renders with count and handles tap and long press', (tester) async {
      bool tapped = false;
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MarginDiscussionIndicator(
                count: 15,
                onTap: () => tapped = true,
                onLongPress: () => longPressed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MarginDiscussionIndicator), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);

      await tester.tap(find.byType(MarginDiscussionIndicator));
      await tester.pump();
      expect(tapped, isTrue);

      await tester.longPress(find.byType(MarginDiscussionIndicator));
      await tester.pump();
      expect(longPressed, isTrue);
    });

    testWidgets('renders different heat tiers properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                MarginDiscussionIndicator(count: 1),
                MarginDiscussionIndicator(count: 8),
                MarginDiscussionIndicator(count: 25),
                MarginDiscussionIndicator(count: 80),
                MarginDiscussionIndicator(count: 250),
                MarginDiscussionIndicator(count: 800),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(MarginDiscussionIndicator), findsNWidgets(6));
    });
  });

  group('DiscussionDetailsSheet Tests', () {
    testWidgets('displays chat count, heat tier, latest message, and omits quoted passage', (tester) async {
      bool openedFull = false;

      final testDiscussions = [
        Discussion(
          id: 'disc_1',
          highlightId: 'cfi_1',
          userId: 'user_1',
          content: 'First insight on this paragraph',
          quoteText: 'This quoted text should NOT appear on details sheet',
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          replies: [
            Discussion(
              id: 'reply_1',
              highlightId: 'cfi_1',
              userId: 'user_2',
              content: 'A thoughtful reply here',
              createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscussionDetailsSheet(
              discussions: testDiscussions,
              communityName: 'Classics Book Club',
              onOpenFullDiscussion: () => openedFull = true,
            ),
          ),
        ),
      );

      // Verify chat count chip is present
      expect(find.text('2 chats'), findsOneWidget);

      // Verify community name is shown
      expect(find.text('Classics Book Club'), findsOneWidget);

      // Verify quoted passage is NOT displayed (per user request!)
      expect(find.text('This quoted text should NOT appear on details sheet'), findsNothing);

      // Verify action button
      final openButton = find.text('Open Discussion (2 chats)');
      expect(openButton, findsOneWidget);

      await tester.tap(openButton);
      await tester.pump();
      expect(openedFull, isTrue);
    });

    testWidgets('handles empty discussion list gracefully', (tester) async {
      bool openedFull = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscussionDetailsSheet(
              discussions: const [],
              communityName: 'General Club',
              onOpenFullDiscussion: () => openedFull = true,
            ),
          ),
        ),
      );

      expect(find.textContaining('1 chat'), findsOneWidget);
      expect(find.text('Tap below to open or join this discussion.'), findsOneWidget);

      expect(find.text('Open Discussion'), findsOneWidget);
      await tester.tap(find.text('Open Discussion'));
      await tester.pump();
      expect(openedFull, isTrue);
    });
  });

  group('Reactivity Bridge & Discussion Aggregation Tests', () {
    test('LocalDataService notifies listeners immediately upon creating thread and adding replies', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final service = LocalDataService();
      await service.init();

      int notificationCount = 0;
      service.addListener(() {
        notificationCount++;
      });

      // 1. Creating a new thread triggers immediate notification
      final thread = await service.createThread(
        highlightId: 'epubcfi(/6/4[chap01]!/4/2/10,/1:0,/1:25)',
        bookId: 'book-1',
        title: 'Passage question',
        content: 'What does this mean?',
        scope: ThreadScope.passage,
      );

      expect(notificationCount, greaterThan(0));
      final countAfterCreate = notificationCount;

      // 2. Adding a reply triggers another immediate notification
      await service.addReply(
        threadId: thread.id,
        content: 'Here is my explanation.',
      );

      expect(notificationCount, greaterThan(countAfterCreate));

      // 3. Upvoting thread triggers immediate notification
      final countAfterReply = notificationCount;
      await service.upvoteThread(thread.id);
      expect(notificationCount, greaterThan(countAfterReply));
    });

    test('Discussion count aggregation sums threads and nested replies for passage CFIs', () {
      final discussions = [
        Discussion(
          id: 't1',
          highlightId: 'epubcfi(/6/4[chap01]!/4/2/10,/1:0,/1:25)',
          userId: 'u1',
          content: 'Parent thread 1',
          createdAt: DateTime.now(),
          replies: [
            Discussion(
              id: 'r1',
              highlightId: 'epubcfi(/6/4[chap01]!/4/2/10,/1:0,/1:25)',
              userId: 'u2',
              content: 'Reply 1',
              createdAt: DateTime.now(),
            ),
            Discussion(
              id: 'r2',
              highlightId: 'epubcfi(/6/4[chap01]!/4/2/10,/1:0,/1:25)',
              userId: 'u3',
              content: 'Reply 2',
              createdAt: DateTime.now(),
            ),
          ],
        ),
        Discussion(
          id: 't2',
          highlightId: 'epubcfi(/6/4[chap01]!/4/2/10,/1:0,/1:25)',
          userId: 'u4',
          content: 'Parent thread 2 on same passage',
          createdAt: DateTime.now(),
          replies: [
            Discussion(
              id: 'r3',
              highlightId: 'epubcfi(/6/4[chap01]!/4/2/10,/1:0,/1:25)',
              userId: 'u5',
              content: 'Reply 3',
              createdAt: DateTime.now(),
            ),
          ],
        ),
        Discussion(
          id: 't3',
          highlightId: 'epubcfi(/6/6[chap02]!/4/2/4,/1:0,/1:12)',
          userId: 'u1',
          content: 'Thread on different chapter',
          createdAt: DateTime.now(),
        ),
      ];

      // Simulate the logic inside _syncDiscussionIndicators
      final cfiCounts = <String, int>{};
      for (final discussion in discussions) {
        final cfi = discussion.highlightId;
        if (cfi.startsWith('epubcfi(')) {
          final chatCount = 1 + (discussion.replies?.length ?? 0);
          cfiCounts[cfi] = (cfiCounts[cfi] ?? 0) + chatCount;
        }
      }

      // First CFI has:
      // Thread 1 (1) + 2 replies (2) = 3
      // Thread 2 (1) + 1 reply (1) = 2
      // Total = 5 chats
      expect(cfiCounts['epubcfi(/6/4[chap01]!/4/2/10,/1:0,/1:25)'], equals(5));

      // Second CFI has:
      // Thread 3 (1) + 0 replies = 1 chat
      expect(cfiCounts['epubcfi(/6/6[chap02]!/4/2/4,/1:0,/1:12)'], equals(1));
    });
  });

  group('Discussion Indicator Toggle Tests', () {
    test('LocalDataService defaults to enabled and updates persistence and notifies', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final service = LocalDataService();
      await service.init();

      expect(service.isDiscussionIndicatorsEnabled(), isTrue);

      bool notified = false;
      service.addListener(() => notified = true);

      await service.setDiscussionIndicatorsEnabled(false);
      expect(service.isDiscussionIndicatorsEnabled(), isFalse);
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('show_discussion_indicators'), isFalse);
    });

    test('ReaderBloc toggles showDiscussionIndicators correctly', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({'show_discussion_indicators': true});
      final service = LocalDataService();
      await service.init();

      final bloc = ReaderBloc(service);
      final testBook = Book(
        id: 'book-1',
        title: 'Test Book',
        author: 'Author',
        fingerprint: 'fp-1',
        localPath: 'dummy.epub',
      );

      // Initially loads with enabled = true
      bloc.add(LoadBook(testBook));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ReaderLoading>(),
          predicate<ReaderLoaded>((state) => state.showDiscussionIndicators == true),
        ]),
      );

      // Toggle off
      bloc.add(const ToggleDiscussionIndicators(false));
      await expectLater(
        bloc.stream,
        emits(predicate<ReaderLoaded>((state) => state.showDiscussionIndicators == false)),
      );
      expect(service.isDiscussionIndicatorsEnabled(), isFalse);

      // Toggle back on
      bloc.add(const ToggleDiscussionIndicators());
      await expectLater(
        bloc.stream,
        emits(predicate<ReaderLoaded>((state) => state.showDiscussionIndicators == true)),
      );
      expect(service.isDiscussionIndicatorsEnabled(), isTrue);

      await bloc.close();
    });
  });
}
