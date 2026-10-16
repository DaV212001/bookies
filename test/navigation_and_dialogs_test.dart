import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookies/core/widgets/create_community_dialog.dart';
import 'package:bookies/core/widgets/create_thread_dialog.dart';
import 'package:bookies/data/models/book.dart';
import 'package:bookies/data/models/thread_scope.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bookies/features/reader/bloc/reader_bloc.dart';
import 'package:bookies/features/community/views/community_detail_view.dart';
import 'package:bookies/features/reader/views/reader_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalDataService localDataService;
  late Book testBook;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    localDataService = LocalDataService();
    await localDataService.init();
    testBook = Book(
      id: 'book-dune',
      title: 'Dune',
      author: 'Frank Herbert',
      fingerprint: 'dune-fingerprint-001',
      localPath: 'assets/books/dune.epub',
    );
    await localDataService.addBook(testBook);
  });

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocalDataService>.value(
          value: localDataService,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('Decluttered Dialogs Tests', () {
    testWidgets('CreateCommunityDialog displays streamlined form with preselected book', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          CreateCommunityDialog(
            preselectedBook: testBook,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and badge
      expect(find.text('Create Community'), findsOneWidget);
      expect(find.text('Start a reading circle'), findsOneWidget);
      expect(find.text('Dune'), findsOneWidget);

      // Verify no irrelevant fields or duplicate text headers exist
      expect(find.text('Associated Book'), findsNothing); // Preselected, so no dropdown clutter
      expect(find.widgetWithText(FilledButton, 'Create'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
    });

    testWidgets('CreateThreadDialog opens in compact passage mode when initialQuoteText is provided', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          CreateThreadDialog(
            bookId: testBook.id,
            communityId: 'comm-1',
            communityName: 'The Dune Scholars',
            initialScope: ThreadScope.passage,
            initialQuoteText: 'Fear is the mind-killer.',
            initialHighlightId: 'cfi-123',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check passage title
      expect(find.text('Discuss Passage'), findsOneWidget);
      expect(find.text('The Dune Scholars'), findsOneWidget);
      expect(find.text('Fear is the mind-killer.'), findsOneWidget);

      // Check that 5-star rating widget is removed
      expect(find.byType(DropdownButtonFormField), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Post Discussion'), findsOneWidget);
    });
  });

  group('Seamless Reader & Community Navigation Tests', () {
    testWidgets('ReaderView accepts initialCfi constructor parameter', (tester) async {
      const targetCfi = 'epubcfi(/6/4[chap01]!/4/2/10)';
      final readerView = ReaderView(
        book: testBook,
        initialCfi: targetCfi,
      );

      expect(readerView.book?.id, 'book-dune');
      expect(readerView.initialCfi, targetCfi);
    });

    testWidgets('CommunityDetailView displays Read Book button and renders tabs cleanly', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          CommunityDetailView(
            bookId: testBook.id,
            communityId: 'comm-1',
            communityName: 'The Dune Scholars',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the header displays the community title and Read Book action
      expect(find.text('The Dune Scholars'), findsOneWidget);
      expect(find.text('Read Book'), findsOneWidget);

      // Verify tabs exist for bidirectional navigation
      expect(find.text('Global Discussion'), findsOneWidget);
      expect(find.text('Chapter Discussions'), findsOneWidget);
      expect(find.text('Highlights'), findsOneWidget);
      expect(find.text('Quotes'), findsOneWidget);
    });

    testWidgets('ReaderView center title opens community selection bottom sheet', (tester) async {
      await localDataService.createCommunity(
        name: 'The Dune Scholars',
        description: 'Dune discussion group',
        bookId: testBook.id,
      );
      final readerBloc = ReaderBloc(localDataService);
      readerBloc.emit(ReaderLoaded(
        book: testBook,
      ));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LocalDataService>.value(value: localDataService),
            BlocProvider<ReaderBloc>.value(value: readerBloc),
          ],
          child: MaterialApp(
            home: ReaderView(book: testBook),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify center title has book title and active community
      expect(find.text('Dune'), findsOneWidget);
      expect(find.text('The Dune Scholars'), findsOneWidget);

      // Tap the center community selector
      await tester.tap(find.text('The Dune Scholars'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify the bottom sheet opened with communities and Create New Community
      expect(find.text('Book Communities'), findsOneWidget);
      expect(find.text('The Dune Scholars'), findsWidgets);
      expect(find.text('Create New Community'), findsOneWidget);
    });
  });
}
