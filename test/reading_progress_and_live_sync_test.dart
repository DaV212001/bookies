import 'package:flutter_test/flutter_test.dart';
import 'package:bookies/domain/entities/live_participant_progress.dart';
import 'package:bookies/domain/entities/live_passage_reaction.dart';
import 'package:bookies/features/reader/bloc/reader_bloc.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/data/models/book.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reading Progress & Live Sync Architecture Tests', () {
    late LocalDataService localDataService;
    late ReaderBloc readerBloc;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      localDataService = LocalDataService();
      await localDataService.init();
      readerBloc = ReaderBloc(localDataService);
    });

    tearDown(() {
      readerBloc.close();
    });

    test('LiveParticipantsUpdatedEvent populates live social track roster', () async {
      final book = Book(
        id: 'book-1',
        title: 'Dune',
        author: 'Frank Herbert',
        localPath: 'assets/books/dune.epub',
        fingerprint: 'fp-1',
      );

      readerBloc.add(LoadBook(book));
      await expectLater(
        readerBloc.stream,
        emitsThrough(isA<ReaderLoaded>()),
      );

      final participants = [
        LiveParticipantProgress(
          userId: 'user-1',
          displayName: 'Paul Atreides',
          progression: 0.25,
          cfi: 'cfi-1',
          lastUpdated: DateTime.now(),
        ),
        LiveParticipantProgress(
          userId: 'user-2',
          displayName: 'Chani',
          progression: 0.65,
          cfi: 'cfi-2',
          lastUpdated: DateTime.now(),
        ),
      ];

      readerBloc.add(LiveParticipantsUpdatedEvent(participants));

      await expectLater(
        readerBloc.stream,
        emits(predicate<ReaderState>((state) {
          if (state is! ReaderLoaded) return false;
          return state.liveParticipants.length == 2 &&
              state.liveParticipants.first.displayName == 'Paul Atreides' &&
              state.liveParticipants.last.displayName == 'Chani';
        })),
      );
    });

    test('LivePassageReactionReceivedEvent updates live reactions stream in state', () async {
      final book = Book(
        id: 'book-1',
        title: 'Dune',
        author: 'Frank Herbert',
        localPath: 'assets/books/dune.epub',
        fingerprint: 'fp-1',
      );

      readerBloc.add(LoadBook(book));
      await expectLater(
        readerBloc.stream,
        emitsThrough(isA<ReaderLoaded>()),
      );

      final reaction = LivePassageReaction(
        userId: 'user-2',
        displayName: 'Chani',
        cfi: 'cfi-reaction-1',
        emoji: '🔥',
        quoteText: 'The sleeper has awakened.',
        timestamp: DateTime.now(),
      );

      readerBloc.add(LivePassageReactionReceivedEvent(reaction));

      await expectLater(
        readerBloc.stream,
        emits(predicate<ReaderState>((state) {
          if (state is! ReaderLoaded) return false;
          return state.liveReactions.isNotEmpty &&
              state.liveReactions.first.emoji == '🔥' &&
              state.liveReactions.first.displayName == 'Chani';
        })),
      );
    });

    test('UpdateLocator updates current CFI and progression monotonically', () async {
      final book = Book(
        id: 'book-1',
        title: 'Dune',
        author: 'Frank Herbert',
        localPath: 'assets/books/dune.epub',
        fingerprint: 'fp-1',
      );

      readerBloc.add(LoadBook(book));
      await expectLater(
        readerBloc.stream,
        emitsThrough(isA<ReaderLoaded>()),
      );

      readerBloc.add(const UpdateLocator('cfi-page-5', 0.15));

      await expectLater(
        readerBloc.stream,
        emits(predicate<ReaderState>((state) {
          if (state is! ReaderLoaded) return false;
          return state.currentCfi == 'cfi-page-5' && state.progression == 0.15;
        })),
      );
    });
  });
}
