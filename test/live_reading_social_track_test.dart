import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookies/core/widgets/ambient_progress_bar.dart';
import 'package:bookies/core/widgets/passage_reaction_bubble.dart';
import 'package:bookies/domain/entities/live_participant_progress.dart';
import 'package:bookies/domain/entities/live_passage_reaction.dart';
import 'package:bookies/data/models/book.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/features/reader/bloc/reader_bloc.dart';

void main() {
  group('Live Reading Social Track & Progress Tests', () {
    testWidgets('AmbientProgressBar renders sleek 4px bar when no participants',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmbientProgressBar(progress: 0.35),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxHeight ?? 4.0, equals(4.0));
      expect(find.byType(CircleAvatar), findsNothing);
    });

    testWidgets(
        'AmbientProgressBar renders participant avatars at their reading progress',
        (tester) async {
      final participants = [
        LiveParticipantProgress(
          userId: 'user-1',
          displayName: 'Alice Reader',
          progression: 0.25,
          lastUpdated: DateTime.now(),
        ),
        LiveParticipantProgress(
          userId: 'user-2',
          displayName: 'Julian Morrow',
          progression: 0.70,
          lastUpdated: DateTime.now(),
        ),
      ];

      LiveParticipantProgress? tapped;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AmbientProgressBar(
              progress: 0.50,
              participants: participants,
              onParticipantTapped: (p) => tapped = p,
            ),
          ),
        ),
      );

      // Verify participant avatars exist
      expect(find.byType(CircleAvatar), findsNWidgets(2));
      expect(find.text('A'), findsOneWidget); // Alice's initial
      expect(find.text('J'), findsOneWidget); // Julian's initial

      // Tap Alice's avatar
      await tester.tap(find.text('A'));
      await tester.pump();
      expect(tapped?.displayName, equals('Alice Reader'));
    });
  });

  group('Live Passage Reaction Tests', () {
    testWidgets('PassageReactionBubble renders emoji and reader display name',
        (tester) async {
      final reaction = LivePassageReaction(
        userId: 'user-2',
        displayName: 'Julian',
        cfi: 'epubcfi(/6/4[chap2]!/4/2/10)',
        emoji: '🤯',
        quoteText: 'Beauty is terror',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PassageReactionBubble(reaction: reaction),
          ),
        ),
      );

      expect(find.text('🤯'), findsOneWidget);
      expect(find.text('Julian'), findsOneWidget);
      expect(find.textContaining('Beauty is terror'), findsOneWidget);
    });

    testWidgets('QuickPassageReactionPicker renders emojis and triggers callback',
        (tester) async {
      String? selectedEmoji;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickPassageReactionPicker(
              onEmojiSelected: (emoji) => selectedEmoji = emoji,
            ),
          ),
        ),
      );

      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('🤯'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);

      await tester.tap(find.text('🔥'));
      await tester.pump();
      expect(selectedEmoji, equals('🔥'));
    });
  });

  group('ReaderBloc Live Reading State Tests', () {
    late LocalDataService localDataService;
    late ReaderBloc readerBloc;

    setUp(() {
      localDataService = LocalDataService();
      readerBloc = ReaderBloc(localDataService);
    });

    tearDown(() {
      readerBloc.close();
    });

    test('LiveParticipantsUpdatedEvent updates live participants list in state',
        () async {
      final book = Book(
        id: 'test-book',
        title: 'Test Book',
        author: 'Author',
        fingerprint: 'fp-1',
        localPath: 'dummy.epub',
      );

      readerBloc.emit(ReaderLoaded(book: book, progression: 0.1));

      final participants = [
        LiveParticipantProgress(
          userId: 'user-3',
          displayName: 'Henry',
          progression: 0.42,
          lastUpdated: DateTime.now(),
        ),
      ];

      readerBloc.add(LiveParticipantsUpdatedEvent(participants));

      await expectLater(
        readerBloc.stream,
        emits(predicate<ReaderState>((state) {
          if (state is ReaderLoaded) {
            return state.liveParticipants.length == 1 &&
                state.liveParticipants.first.displayName == 'Henry' &&
                state.liveParticipants.first.progression == 0.42;
          }
          return false;
        })),
      );
    });

    test('LivePassageReactionReceivedEvent prepends reaction to live reactions',
        () async {
      final book = Book(
        id: 'test-book',
        title: 'Test Book',
        author: 'Author',
        fingerprint: 'fp-1',
        localPath: 'dummy.epub',
      );

      readerBloc.emit(ReaderLoaded(book: book, progression: 0.1));

      final reaction = LivePassageReaction(
        userId: 'user-1',
        displayName: 'Alice',
        cfi: 'cfi-123',
        emoji: '❤️',
        timestamp: DateTime.now(),
      );

      readerBloc.add(LivePassageReactionReceivedEvent(reaction));

      await expectLater(
        readerBloc.stream,
        emits(predicate<ReaderState>((state) {
          if (state is ReaderLoaded) {
            return state.liveReactions.length == 1 &&
                state.liveReactions.first.emoji == '❤️';
          }
          return false;
        })),
      );
    });
  });
}
