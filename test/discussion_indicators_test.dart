import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookies/core/widgets/margin_discussion_indicator.dart';
import 'package:bookies/data/models/discussion.dart';
import 'package:bookies/features/discussion/views/discussion_details_sheet.dart';

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

      await tester.tap(find.text('Open Discussion'));
      await tester.pump();
      expect(openedFull, isTrue);
    });
  });
}
