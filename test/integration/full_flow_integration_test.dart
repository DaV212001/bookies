import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookies/domain/entities/book_entity.dart';
import 'package:bookies/domain/entities/catalog_book_entity.dart';
import 'package:bookies/domain/entities/community_entity.dart';
import 'package:bookies/domain/entities/community_member_entity.dart';
import 'package:bookies/domain/entities/live_participant_progress.dart';
import 'package:bookies/domain/entities/live_passage_reaction.dart';
import 'package:bookies/domain/entities/user_entity.dart';
import 'package:bookies/domain/repositories/auth_repository.dart';
import 'package:bookies/domain/repositories/book_repository.dart';
import 'package:bookies/domain/repositories/catalog_repository.dart';
import 'package:bookies/domain/repositories/community_repository.dart';
import 'package:bookies/features/auth/bloc/auth_bloc.dart';
import 'package:bookies/features/discover/bloc/catalog_bloc.dart';
import 'package:bookies/features/community/bloc/community_bloc.dart';
import 'package:bookies/features/reader/bloc/reader_bloc.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/data/models/book.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==========================================
// In-Memory Test Repositories (Domain Layer)
// ==========================================

class InMemoryAuthRepository implements AuthRepository {
  UserEntity? _currentUser;
  final StreamController<UserEntity?> _controller =
      StreamController<UserEntity?>.broadcast();

  @override
  Stream<UserEntity?> get authStateChanges => _controller.stream;

  @override
  Future<UserEntity?> getCurrentUser() async => _currentUser;

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    _currentUser = UserEntity(
      id: 'auth-user-01',
      username: email.split('@').first,
      displayName: 'Test Reader',
      email: email,
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserEntity> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    _currentUser = UserEntity(
      id: 'auth-user-02',
      username: username,
      displayName: displayName,
      email: email,
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserEntity> signInWithGoogle({
    String? idToken,
    String? email,
    String? displayName,
    String? avatarUrl,
  }) async {
    _currentUser = UserEntity(
      id: 'google-user-01',
      username: (email?.split('@').first ?? 'google_user'),
      displayName: displayName ?? 'Google User',
      email: email ?? 'google@bookies.app',
      avatarUrl: avatarUrl,
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<String?> getAccessToken() async =>
      _currentUser != null ? 'test-jwt-token' : null;

  void dispose() {
    _controller.close();
  }
}

class InMemoryCatalogRepository implements CatalogRepository {
  final List<CatalogBookEntity> _catalog = [
    const CatalogBookEntity(
      id: 'cat-1',
      title: 'Dune',
      author: 'Frank Herbert',
      description: 'Science fiction epic set on the desert planet Arrakis.',
      downloadUrl: 'http://localhost:3000/api/v1/catalog/cat-1/download',
      activeReadersCount: 42,
      genres: ['Sci-Fi', 'Classics'],
      rating: 4.8,
    ),
    const CatalogBookEntity(
      id: 'cat-2',
      title: 'Neuromancer',
      author: 'William Gibson',
      description: 'The seminal cyberpunk masterpiece.',
      downloadUrl: 'http://localhost:3000/api/v1/catalog/cat-2/download',
      activeReadersCount: 19,
      genres: ['Sci-Fi', 'Cyberpunk'],
      rating: 4.6,
    ),
    const CatalogBookEntity(
      id: 'cat-3',
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      description: 'Jazz age classic of wealth and tragedy.',
      downloadUrl: 'http://localhost:3000/api/v1/catalog/cat-3/download',
      activeReadersCount: 12,
      genres: ['Fiction', 'Classics'],
      rating: 4.4,
    ),
  ];

  @override
  Future<List<CatalogBookEntity>> getDiscoverCatalog({
    String? genre,
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    if (genre != null && genre.isNotEmpty && genre != '#AllCuration') {
      return _catalog
          .where((b) => b.genres.any((g) => g.toLowerCase() == genre.toLowerCase()))
          .toList();
    }
    return _catalog;
  }

  @override
  Future<List<CatalogBookEntity>> searchCatalog(String query) async {
    final q = query.toLowerCase();
    return _catalog
        .where((b) =>
            b.title.toLowerCase().contains(q) ||
            b.author.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<BookEntity> downloadAndImportBook({
    required CatalogBookEntity catalogBook,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.25);
    onProgress?.call(0.75);
    onProgress?.call(1.0);

    return BookEntity(
      id: catalogBook.id,
      title: catalogBook.title,
      author: catalogBook.author,
      fingerprint: 'fp-${catalogBook.id}',
      localPath: '/storage/books/${catalogBook.id}.epub',
    );
  }
}

class InMemoryBookRepository implements BookRepository {
  final List<BookEntity> _library = [];

  @override
  Future<List<BookEntity>> getLibraryBooks() async => List.unmodifiable(_library);

  @override
  Future<BookEntity> importBook(String sourceFilePath) async {
    final book = BookEntity(
      id: 'imported-${_library.length + 1}',
      title: 'Imported Book ${_library.length + 1}',
      author: 'Unknown Author',
      fingerprint: 'fp-import-${_library.length + 1}',
      localPath: sourceFilePath,
    );
    _library.add(book);
    return book;
  }

  @override
  Future<void> syncReadingProgress({
    required String bookId,
    required String cfi,
    required double progression,
  }) async {}

  @override
  Future<Map<String, dynamic>?> getReadingProgress(String bookId) async => null;

  @override
  Future<void> deleteBook(String bookId) async {
    _library.removeWhere((b) => b.id == bookId);
  }
}

class InMemoryCommunityRepository implements CommunityRepository {
  final List<CommunityEntity> _communities = [];
  final Map<String, List<CommunityMemberEntity>> _members = {};
  final StreamController<List<CommunityEntity>> _streamController =
      StreamController<List<CommunityEntity>>.broadcast();

  @override
  Stream<List<CommunityEntity>> watchCommunities() => _streamController.stream;

  @override
  Future<List<CommunityEntity>> getCommunities() async =>
      List.unmodifiable(_communities);

  @override
  Future<List<CommunityEntity>> getJoinedCommunities() async =>
      List.unmodifiable(_communities);

  @override
  Future<CommunityEntity> getCommunityById(String communityId) async {
    return _communities.firstWhere((c) => c.id == communityId);
  }

  @override
  Future<CommunityEntity> createCommunity({
    required String name,
    required String description,
    required String bookId,
    String? importMembersFromCommunityId,
  }) async {
    final community = CommunityEntity(
      id: 'comm-${_communities.length + 1}',
      name: name,
      description: description,
      bookId: bookId,
      memberCount: 1,
      creatorId: 'user-creator',
    );
    _communities.add(community);
    _streamController.add(List.unmodifiable(_communities));

    _members[community.id] = [
      CommunityMemberEntity(
        communityId: community.id,
        user: const UserEntity(
          id: 'user-creator',
          username: 'creator',
          displayName: 'Community Creator',
          email: 'creator@bookies.app',
        ),
        role: CommunityRole.creator,
        status: CommunityMemberStatus.active,
        joinedAt: DateTime.now(),
      )
    ];

    return community;
  }

  @override
  Future<void> joinCommunity(String communityId) async {
    final index = _communities.indexWhere((c) => c.id == communityId);
    if (index != -1) {
      final current = _communities[index];
      _communities[index] = CommunityEntity(
        id: current.id,
        name: current.name,
        description: current.description,
        bookId: current.bookId,
        memberCount: current.memberCount + 1,
        creatorId: current.creatorId,
      );
      _streamController.add(List.unmodifiable(_communities));
    }
  }

  @override
  Future<void> leaveCommunity(String communityId) async {}

  @override
  Future<List<CommunityMemberEntity>> getCommunityMembers(
      String communityId) async {
    return _members[communityId] ?? [];
  }

  @override
  Future<void> updateMemberRole({
    required String communityId,
    required String targetUserId,
    required CommunityRole newRole,
  }) async {
    final members = _members[communityId];
    if (members != null) {
      final idx = members.indexWhere((m) => m.user.id == targetUserId);
      if (idx != -1) {
        final current = members[idx];
        members[idx] = CommunityMemberEntity(
          communityId: current.communityId,
          user: current.user,
          role: newRole,
          status: current.status,
          customPermissions: current.customPermissions,
          joinedAt: current.joinedAt,
        );
      }
    }
  }

  @override
  Future<void> updateMemberPermissions({
    required String communityId,
    required String targetUserId,
    required Set<CommunityPermission> permissions,
  }) async {}

  @override
  Future<void> restrictMember({
    required String communityId,
    required String targetUserId,
    required String reason,
    Duration? duration,
  }) async {
    final members = _members[communityId];
    if (members != null) {
      final idx = members.indexWhere((m) => m.user.id == targetUserId);
      if (idx != -1) {
        final current = members[idx];
        members[idx] = CommunityMemberEntity(
          communityId: current.communityId,
          user: current.user,
          role: current.role,
          status: CommunityMemberStatus.restricted,
          customPermissions: current.customPermissions,
          joinedAt: current.joinedAt,
          restrictedReason: reason,
        );
      }
    }
  }

  @override
  Future<void> unrestrictMember({
    required String communityId,
    required String targetUserId,
  }) async {
    final members = _members[communityId];
    if (members != null) {
      final idx = members.indexWhere((m) => m.user.id == targetUserId);
      if (idx != -1) {
        final current = members[idx];
        members[idx] = CommunityMemberEntity(
          communityId: current.communityId,
          user: current.user,
          role: current.role,
          status: CommunityMemberStatus.active,
          customPermissions: current.customPermissions,
          joinedAt: current.joinedAt,
        );
      }
    }
  }

  @override
  Future<void> banMember({
    required String communityId,
    required String targetUserId,
    required String reason,
  }) async {}

  @override
  Future<List<UserEntity>> getAvailableUsersToInvite(String communityId) async =>
      const [];

  @override
  Future<CommunityMemberEntity> addMember({
    required String communityId,
    required String userId,
    CommunityRole role = CommunityRole.member,
  }) async {
    final member = CommunityMemberEntity(
      communityId: communityId,
      user: UserEntity(
        id: userId,
        username: userId,
        displayName: 'Invited Reader',
        email: '$userId@bookies.app',
      ),
      role: role,
      status: CommunityMemberStatus.active,
      joinedAt: DateTime.now(),
    );
    _members.putIfAbsent(communityId, () => []).add(member);
    return member;
  }

  @override
  Future<void> removeMember({
    required String communityId,
    required String userId,
  }) async {
    _members[communityId]?.removeWhere((m) => m.user.id == userId);
  }

  void dispose() {
    _streamController.close();
  }
}

// ==========================================
// Comprehensive End-to-End Flow Tests
// ==========================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Full Flow 1: Authentication & User Lifecycle', () {
    late InMemoryAuthRepository authRepo;
    late AuthBloc authBloc;

    setUp(() {
      authRepo = InMemoryAuthRepository();
      authBloc = AuthBloc(authRepository: authRepo);
    });

    tearDown(() {
      authBloc.close();
      authRepo.dispose();
    });

    test('Full lifecycle: Check -> Register -> Me -> Logout -> Login -> Google SSO', () async {
      // Step 1: Initial cold boot check
      authBloc.add(const CheckAuthStatusEvent());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.loading),
          predicate<AuthState>((s) => s.status == AuthStatus.unauthenticated),
        ]),
      );

      // Step 2: User registration
      authBloc.add(const RegisterWithEmailEvent(
        username: 'dune_fan',
        email: 'dune@bookies.app',
        password: 'Password123!',
        displayName: 'Paul Atreides',
      ));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.loading),
          predicate<AuthState>((s) =>
              s.status == AuthStatus.authenticated &&
              s.user?.username == 'dune_fan' &&
              s.user?.displayName == 'Paul Atreides'),
        ]),
      );

      // Step 3: Check auth status while logged in
      authBloc.add(const CheckAuthStatusEvent());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.loading),
          predicate<AuthState>((s) =>
              s.status == AuthStatus.authenticated &&
              s.user?.email == 'dune@bookies.app'),
        ]),
      );

      // Step 4: Logout
      authBloc.add(const LogoutEvent());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.loading),
          predicate<AuthState>((s) =>
              s.status == AuthStatus.unauthenticated && s.user == null),
        ]),
      );

      // Step 5: Password login
      authBloc.add(const LoginWithEmailEvent(
        email: 'dune@bookies.app',
        password: 'Password123!',
      ));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.loading),
          predicate<AuthState>((s) =>
              s.status == AuthStatus.authenticated &&
              s.user?.email == 'dune@bookies.app'),
        ]),
      );

      // Step 6: Google Single Sign-On
      authBloc.add(const SignInWithGoogleEvent(
        idToken: 'google-oauth-token-xyz',
        email: 'google.reader@gmail.com',
        displayName: 'Google Reader',
        avatarUrl: 'https://lh3.googleusercontent.com/avatar.png',
      ));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.loading),
          predicate<AuthState>((s) =>
              s.status == AuthStatus.authenticated &&
              s.user?.email == 'google.reader@gmail.com' &&
              s.user?.avatarUrl != null),
        ]),
      );
    });
  });

  group('Full Flow 2: Discover Catalog, Genre Filtering & Ingestion', () {
    late InMemoryCatalogRepository catalogRepo;
    late CatalogBloc catalogBloc;

    setUp(() {
      catalogRepo = InMemoryCatalogRepository();
      catalogBloc = CatalogBloc(catalogRepository: catalogRepo);
    });

    tearDown(() {
      catalogBloc.close();
    });

    test('Full lifecycle: Fetch featured -> Filter Sci-Fi -> Search keyword -> Download & Ingest', () async {
      // Step 1: Fetch discover catalog
      catalogBloc.add(const FetchCatalogEvent());
      await expectLater(
        catalogBloc.stream,
        emitsInOrder([
          predicate<CatalogState>((s) => s.status == CatalogStatus.loading),
          predicate<CatalogState>((s) =>
              s.status == CatalogStatus.success &&
              s.featuredBooks.length == 3 &&
              s.featuredBooks.first.title == 'Dune' &&
              s.featuredBooks.first.downloadUrl != null),
        ]),
      );

      // Step 2: Select genre filter 'Sci-Fi'
      catalogBloc.add(const SelectGenreFilterEvent('Sci-Fi'));
      await expectLater(
        catalogBloc.stream,
        emitsInOrder([
          predicate<CatalogState>((s) =>
              s.selectedGenre == 'Sci-Fi' && s.status == CatalogStatus.loading),
          predicate<CatalogState>((s) =>
              s.status == CatalogStatus.success &&
              s.featuredBooks.length == 2 &&
              s.featuredBooks.every((b) => b.genres.contains('Sci-Fi'))),
        ]),
      );

      // Step 3: Search keyword 'Gatsby'
      catalogBloc.add(const SearchCatalogEvent('Gatsby'));
      await expectLater(
        catalogBloc.stream,
        emitsThrough(predicate<CatalogState>((s) =>
            s.status == CatalogStatus.success &&
            s.searchResults.length == 1 &&
            s.searchResults.first.title == 'The Great Gatsby')),
      );

      // Step 4: Download and Ingest Book
      final duneBook = catalogBloc.state.featuredBooks.first;
      catalogBloc.add(DownloadCatalogBookEvent(duneBook));
      await expectLater(
        catalogBloc.stream,
        emitsThrough(predicate<CatalogState>((s) =>
            s.isDownloaded(duneBook.id) &&
            s.status == CatalogStatus.success)),
      );
    });
  });

  group('Full Flow 3: Community Lifecycle & Moderation RBAC', () {
    late InMemoryCommunityRepository communityRepo;
    late InMemoryBookRepository bookRepo;
    late CommunityBloc communityBloc;

    setUp(() {
      communityRepo = InMemoryCommunityRepository();
      bookRepo = InMemoryBookRepository();
      communityBloc = CommunityBloc(
        communityRepository: communityRepo,
        bookRepository: bookRepo,
      );
    });

    tearDown(() {
      communityBloc.close();
      communityRepo.dispose();
    });

    test('Full lifecycle: Create Community -> List -> Join -> Member Role Escalation & Restriction', () async {
      // Step 1: Initial load
      communityBloc.add(const LoadCommunities());
      await expectLater(
        communityBloc.stream,
        emitsInOrder([
          predicate<CommunityState>((s) => s is CommunityLoading),
          predicate<CommunityState>((s) => s is CommunityLoaded && s.allCommunities.isEmpty),
        ]),
      );

      // Step 2: Create a new community
      communityBloc.add(const CreateNewCommunity(
        name: 'Arrakis Dune Society',
        description: 'Deep discussions of Frank Herbert novels',
        bookId: 'cat-1',
      ));
      await expectLater(
        communityBloc.stream,
        emitsThrough(predicate<CommunityState>((s) {
          if (s is! CommunityLoaded) return false;
          return s.allCommunities.any((c) => c.name == 'Arrakis Dune Society');
        })),
      );

      final created = (communityBloc.state as CommunityLoaded)
          .allCommunities
          .firstWhere((c) => c.name == 'Arrakis Dune Society');

      // Step 3: Member joins the community
      communityBloc.add(JoinCommunityRequested(created.id));
      await expectLater(
        communityBloc.stream,
        emitsThrough(predicate<CommunityState>((s) {
          if (s is! CommunityLoaded) return false;
          final comm = s.allCommunities.firstWhere((c) => c.id == created.id);
          return comm.memberCount == 2;
        })),
      );

      // Step 4: Add reader member and verify RBAC role elevation
      final targetUserId = 'reader-42';
      final members = await communityRepo.getCommunityMembers(created.id);
      members.add(CommunityMemberEntity(
        communityId: created.id,
        user: const UserEntity(
          id: 'reader-42',
          username: 'chani',
          displayName: 'Chani of the Sietch',
          email: 'chani@dune.org',
        ),
        role: CommunityRole.member,
        status: CommunityMemberStatus.active,
        joinedAt: DateTime.now(),
      ));

      // Elevate reader-42 to Admin
      await communityRepo.updateMemberRole(
        communityId: created.id,
        targetUserId: targetUserId,
        newRole: CommunityRole.admin,
      );
      final elevatedMembers = await communityRepo.getCommunityMembers(created.id);
      final chani = elevatedMembers.firstWhere((m) => m.user.id == targetUserId);
      expect(chani.role, equals(CommunityRole.admin));
      expect(chani.hasPermission(CommunityPermission.manageMembers), isTrue);

      // Restrict member with reason
      await communityRepo.restrictMember(
        communityId: created.id,
        targetUserId: targetUserId,
        reason: 'Violated spoiler policy',
        duration: const Duration(hours: 24),
      );
      final restrictedMembers = await communityRepo.getCommunityMembers(created.id);
      final restrictedChani = restrictedMembers.firstWhere((m) => m.user.id == targetUserId);
      expect(restrictedChani.status, equals(CommunityMemberStatus.restricted));
      expect(restrictedChani.restrictedReason, equals('Violated spoiler policy'));
      expect(restrictedChani.hasPermission(CommunityPermission.commentInLiveReading), isFalse);

      // Lift restriction
      await communityRepo.unrestrictMember(
        communityId: created.id,
        targetUserId: targetUserId,
      );
      final unbannedMembers = await communityRepo.getCommunityMembers(created.id);
      final unbannedChani = unbannedMembers.firstWhere((m) => m.user.id == targetUserId);
      expect(unbannedChani.status, equals(CommunityMemberStatus.active));
    });
  });

  group('Full Flow 4: Immersive Live Reading, Social Co-Presence & Live Reactions', () {
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

    test('Full lifecycle: Open Book -> Sync Co-Presence Roster -> Emit Live Reactions -> Update Progress', () async {
      final book = Book(
        id: 'bookies-dune-01',
        title: 'Dune',
        author: 'Frank Herbert',
        localPath: 'assets/books/dune.epub',
        fingerprint: 'fp-dune-01',
      );

      // Step 1: Open EPUB in Reader
      readerBloc.add(LoadBook(book));
      await expectLater(
        readerBloc.stream,
        emitsThrough(predicate<ReaderState>((state) {
          return state is ReaderLoaded && state.book.id == book.id;
        })),
      );

      // Step 2: Connect to Live Session and receive Participant Roster
      final participants = [
        LiveParticipantProgress(
          userId: 'user-01',
          displayName: 'Paul Atreides',
          progression: 0.15,
          cfi: 'epubcfi(/6/4[chap1]!/4/2:0)',
          lastUpdated: DateTime.now(),
        ),
        LiveParticipantProgress(
          userId: 'user-02',
          displayName: 'Lady Jessica',
          progression: 0.45,
          cfi: 'epubcfi(/6/12[chap3]!/4/2:10)',
          lastUpdated: DateTime.now(),
        ),
        LiveParticipantProgress(
          userId: 'user-03',
          displayName: 'Baron Harkonnen',
          progression: 0.82,
          cfi: 'epubcfi(/6/24[chap7]!/4/2:40)',
          lastUpdated: DateTime.now(),
        ),
      ];

      readerBloc.add(LiveParticipantsUpdatedEvent(participants));
      await expectLater(
        readerBloc.stream,
        emits(predicate<ReaderState>((state) {
          if (state is! ReaderLoaded) return false;
          return state.liveParticipants.length == 3 &&
              state.liveParticipants[0].displayName == 'Paul Atreides' &&
              state.liveParticipants[1].progression == 0.45 &&
              state.liveParticipants[2].displayName == 'Baron Harkonnen';
        })),
      );

      // Step 3: Receive Live Passage Reactions
      final reaction1 = LivePassageReaction(
        userId: 'user-01',
        displayName: 'Paul Atreides',
        emoji: '🔥',
        cfi: 'epubcfi(/6/12[chap3]!/4/2:10)',
        quoteText: 'Fear is the mind-killer.',
        timestamp: DateTime.now(),
      );

      readerBloc.add(LivePassageReactionReceivedEvent(reaction1));
      await expectLater(
        readerBloc.stream,
        emits(predicate<ReaderState>((state) {
          if (state is! ReaderLoaded) return false;
          return state.liveReactions.length == 1 &&
              state.liveReactions.first.emoji == '🔥' &&
              state.liveReactions.first.quoteText == 'Fear is the mind-killer.';
        })),
      );

      // Step 4: Ambient reading progress update
      readerBloc.add(const UpdateLocator('epubcfi(/6/18[chap4]!/4/2:0)', 0.55));
      await expectLater(
        readerBloc.stream,
        emits(predicate<ReaderState>((state) {
          if (state is! ReaderLoaded) return false;
          return state.progression == 0.55;
        })),
      );
    });
  });
}
