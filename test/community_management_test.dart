import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookies/core/widgets/create_community_dialog.dart';
import 'package:bookies/data/models/book.dart';
import 'package:bookies/data/models/community_member.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/features/community/views/community_detail_view.dart';
import 'package:bookies/features/community/views/management/community_management_view.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

final List<int> kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  late LocalDataService localDataService;
  late Book testBook;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    localDataService = LocalDataService();
    await localDataService.init();

    testBook = Book(
      id: 'mock-book-1',
      title: 'The Secret History',
      author: 'Donna Tartt',
      fingerprint: 'secret-history-001',
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
        home: child,
      ),
    );
  }

  group('Community Reader Management & Live Reading Tests', () {
    testWidgets('CommunityManagementView renders tabs and members list', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapWithProviders(
          const CommunityManagementView(
            communityId: 'comm-1',
            communityName: 'The Secret History',
            bookId: 'mock-book-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title and absence of Creator Mode badge
      expect(find.text('Reader Management'), findsOneWidget);
      expect(find.text('Creator Mode'), findsNothing);
      expect(find.text('The Secret History'), findsOneWidget);

      // Check Tabs
      expect(find.widgetWithText(Tab, 'Readers (6)'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Live Reading'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Moderation (1)'), findsOneWidget);

      // Check seeded readers
      expect(find.text('Alice Reader'), findsOneWidget);
      expect(find.text('Julian Morrow'), findsOneWidget);
      expect(find.text('Henry Winter'), findsOneWidget);
      expect(find.text('Camilla Macaulay'), findsOneWidget);

      // Check role labels
      expect(find.text('Creator'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('Filter and search readers in CommunityManagementView', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapWithProviders(
          const CommunityManagementView(
            communityId: 'comm-1',
            communityName: 'The Secret History',
            bookId: 'mock-book-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search for 'Julian'
      await tester.enterText(find.byType(TextField), 'Julian');
      await tester.pumpAndSettle();

      expect(find.text('Julian Morrow'), findsOneWidget);
      expect(find.text('Henry Winter'), findsNothing);

      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(find.text('Henry Winter'), findsOneWidget);

      // Filter by 'Admins & Creator'
      await tester.tap(find.textContaining('Admins & Creator'));
      await tester.pumpAndSettle();

      expect(find.text('Julian Morrow'), findsOneWidget);
      expect(find.text('Henry Winter'), findsNothing);
    });

    testWidgets('Promote reader to Admin and demote back in CommunityManagementView', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapWithProviders(
          const CommunityManagementView(
            communityId: 'comm-1',
            communityName: 'The Secret History',
            bookId: 'mock-book-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Henry Winter (who is a regular member)
      await tester.tap(find.text('Henry Winter'));
      await tester.pumpAndSettle();

      // Bottom sheet should show 'Promote to Community Admin'
      expect(find.text('Promote to Community Admin'), findsOneWidget);
      await tester.tap(find.text('Promote to Community Admin'));
      await tester.pumpAndSettle();

      // Verify Henry is now Admin
      final updatedMember = localDataService.getMember('comm-1', 'user-3');
      expect(updatedMember?.role, CommunityRole.admin);

      // Now tap Henry again to demote
      await tester.tap(find.text('Henry Winter'));
      await tester.pumpAndSettle();

      expect(find.text('Demote to Reader'), findsOneWidget);
      await tester.tap(find.text('Demote to Reader'));
      await tester.pumpAndSettle();

      final demotedMember = localDataService.getMember('comm-1', 'user-3');
      expect(demotedMember?.role, CommunityRole.member);
    });

    testWidgets('Ban reader and unban via Moderation tab', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapWithProviders(
          const CommunityManagementView(
            communityId: 'comm-1',
            communityName: 'The Secret History',
            bookId: 'mock-book-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Camilla Macaulay to ban
      await tester.tap(find.text('Camilla Macaulay'));
      await tester.pumpAndSettle();

      expect(find.text('Ban Reader'), findsOneWidget);
      await tester.tap(find.text('Ban Reader'));
      await tester.pumpAndSettle();

      // RestrictMemberDialog opens
      expect(find.widgetWithText(FilledButton, 'Ban Member'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Ban Member'));
      await tester.pumpAndSettle();

      // Verify Camilla is banned
      final bannedMember = localDataService.getMember('comm-1', 'user-4');
      expect(bannedMember?.isBanned, isTrue);

      // Switch to Moderation tab
      await tester.tap(find.byType(Tab).last);
      await tester.pumpAndSettle();

      expect(find.text('Camilla Macaulay'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Unban Reader'), findsOneWidget);

      // Tap Unban
      await tester.tap(find.widgetWithText(FilledButton, 'Unban Reader'));
      await tester.pumpAndSettle();

      final unbannedMember = localDataService.getMember('comm-1', 'user-4');
      expect(unbannedMember?.isBanned, isFalse);
    });

    testWidgets('Start and end live reading session from Live Reading tab', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapWithProviders(
          const CommunityManagementView(
            communityId: 'comm-1',
            communityName: 'The Secret History',
            bookId: 'mock-book-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Live Reading tab
      await tester.tap(find.widgetWithText(Tab, 'Live Reading'));
      await tester.pumpAndSettle();

      expect(find.text('NO ACTIVE SESSION'), findsOneWidget);
      expect(find.text('Start Live Reading Session'), findsOneWidget);

      // Start session
      await tester.tap(find.text('Start Live Reading Session'));
      await tester.pumpAndSettle();

      // StartLiveSessionDialog opens
      expect(find.widgetWithText(FilledButton, 'Launch Session'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Launch Session'));
      await tester.pumpAndSettle();

      // Session should be active
      final activeSession = localDataService.getActiveLiveReadingSession('comm-1');
      expect(activeSession, isNotNull);
      expect(find.text('LIVE READING ACTIVE'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'End Session'), findsOneWidget);

      // End session
      await tester.tap(find.widgetWithText(FilledButton, 'End Session'));
      await tester.pumpAndSettle();

      // Confirmation dialog
      expect(find.text('End Live Reading?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'End Session').last);
      await tester.pumpAndSettle();

      expect(localDataService.getActiveLiveReadingSession('comm-1'), isNull);
    });

    testWidgets('Live reading participant and comment toggles work', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapWithProviders(
          const CommunityManagementView(
            communityId: 'comm-1',
            communityName: 'The Secret History',
            bookId: 'mock-book-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Live Reading tab
      await tester.tap(find.widgetWithText(Tab, 'Live Reading'));
      await tester.pumpAndSettle();

      // Find Henry Winter's tile
      final henryTile = find.ancestor(
        of: find.text('Henry Winter'),
        matching: find.byType(ListTile),
      );
      expect(henryTile, findsOneWidget);

      final henry = localDataService.getMember('comm-1', 'user-3');
      expect(henry?.hasPermission(CommunityPermission.commentInLiveReading), isTrue);

      // Disable live comments for Henry
      final disableCommentsButton = find.descendant(
        of: henryTile,
        matching: find.byTooltip('Disable live comments'),
      );
      await tester.ensureVisible(disableCommentsButton);
      await tester.tap(disableCommentsButton);
      await tester.pumpAndSettle();

      final updatedHenry = localDataService.getMember('comm-1', 'user-3');
      expect(updatedHenry?.hasPermission(CommunityPermission.commentInLiveReading), isFalse);
    });

    testWidgets('CommunityDetailView displays Reader Management button and Live Reading Banner', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Start active live session first
      await localDataService.startLiveReadingSession(
        communityId: 'comm-1',
        bookId: 'mock-book-1',
        title: 'Prologue & Chapter 1 Discussion',
      );

      await tester.pumpWidget(
        wrapWithProviders(
          const CommunityDetailView(
            bookId: 'mock-book-1',
            communityId: 'comm-1',
            communityName: 'The Secret History',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Reader Management button is in the header
      expect(find.text('Reader Management'), findsOneWidget);

      // Verify Live Reading banner is visible
      expect(find.text('LIVE READING'), findsOneWidget);
      expect(find.text('Prologue & Chapter 1 Discussion'), findsOneWidget);
      expect(find.text('Join Live'), findsOneWidget);
    });

    test('LocalDataService: createCommunity with importMembersFromCommunityId copies roster and preserves roles', () async {
      // In comm-1, user-2 (Francis) is admin, user-3 (Henry) is member
      final sourceMembers = localDataService.getCommunityMembers('comm-1');
      expect(sourceMembers.length, 6);

      // Ban user-5 in comm-1
      await localDataService.banMember('comm-1', 'user-5', reason: 'Test ban');
      expect(localDataService.getMember('comm-1', 'user-5')?.isBanned, isTrue);

      // Create new community for another book with import
      final newComm = await localDataService.createCommunity(
        name: 'The Iliad Study Group',
        description: 'Reading Homer',
        bookId: 'mock-book-2',
        importMembersFromCommunityId: 'comm-1',
        copyRoles: true,
        skipRestrictedOrBanned: true,
      );

      expect(newComm.name, 'The Iliad Study Group');
      final newMembers = localDataService.getCommunityMembers(newComm.id);

      // 6 members minus 1 banned member = 5 members
      expect(newMembers.length, 5);

      // Creator is user-1
      final creator = localDataService.getMember(newComm.id, 'user-1');
      expect(creator?.isCreator, isTrue);

      // Francis (user-2) preserved as Admin
      final francis = localDataService.getMember(newComm.id, 'user-2');
      expect(francis?.role, CommunityRole.admin);

      // Henry (user-3) is Member
      final henry = localDataService.getMember(newComm.id, 'user-3');
      expect(henry?.role, CommunityRole.member);

      // Banned user-5 is not in new community
      final bannedUser = localDataService.getMember(newComm.id, 'user-5');
      expect(bannedUser, isNull);
    });

    testWidgets('CommunityManagementView has Next Book button and Club Options menu', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapWithProviders(
          const CommunityManagementView(
            communityId: 'comm-1',
            communityName: 'The Secret History',
            bookId: 'mock-book-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Next Book button in Readers tab
      expect(find.widgetWithText(OutlinedButton, 'Next Book'), findsOneWidget);

      // Check Club Options menu
      expect(find.byTooltip('Club Options'), findsOneWidget);
      await tester.tap(find.byTooltip('Club Options'));
      await tester.pumpAndSettle();

      expect(find.text('Start Next Book Forum'), findsOneWidget);
      expect(find.text('Import Readers from Club...'), findsOneWidget);
    });

    testWidgets('Tapping Next Book opens CreateCommunityDialog with pre-selected source community', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapWithProviders(
          const CommunityManagementView(
            communityId: 'comm-1',
            communityName: 'The Secret History',
            bookId: 'mock-book-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Next Book'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateCommunityDialog), findsOneWidget);
      expect(find.text('Import Member Roster'), findsOneWidget);
      expect(find.text('Preserve Admin roles'), findsOneWidget);
    });
  });
}
