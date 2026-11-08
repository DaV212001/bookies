import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookies/domain/entities/book_entity.dart';
import 'package:bookies/domain/entities/community_entity.dart';
import 'package:bookies/domain/entities/community_member_entity.dart';
import 'package:bookies/domain/entities/user_entity.dart';
import 'package:bookies/domain/repositories/book_repository.dart';
import 'package:bookies/domain/repositories/community_repository.dart';
import 'package:bookies/features/community/bloc/community_bloc.dart';

class MockBookRepo implements BookRepository {
  @override
  Future<List<BookEntity>> getLibraryBooks() async => [];
  @override
  Future<BookEntity?> getBookById(String id) async => null;
  @override
  Future<BookEntity> importBook(String path) async => throw UnimplementedError();
  @override
  Future<void> syncReadingProgress({required String bookId, required String cfi, required double progression}) async {}
  @override
  Future<Map<String, dynamic>?> getReadingProgress(String bookId) async => null;
  @override
  Future<void> deleteBook(String bookId) async {}
  @override
  Future<String?> getAutoSyncFolder() async => null;
  @override
  Future<void> setAutoSyncFolder(String? folderPath) async {}
  @override
  Future<List<BookEntity>> scanAndSyncFolder(String folderPath) async => [];
}

class MockCommunityRepo implements CommunityRepository {
  final List<CommunityEntity> _all = [
    const CommunityEntity(
      id: 'comm-1',
      name: 'Dune Desert Watchers',
      description: 'Discussing Dune',
      bookId: 'b-1',
      memberCount: 5,
      creatorId: 'user-1',
    ),
    const CommunityEntity(
      id: 'comm-2',
      name: 'Cyberpunk Sprawl',
      description: 'Discussing Neuromancer',
      bookId: 'b-2',
      memberCount: 3,
      creatorId: 'user-2',
    ),
  ];
  final Set<String> _joinedIds = {'comm-1'};
  final StreamController<List<CommunityEntity>> _controller = StreamController.broadcast();

  @override
  Stream<List<CommunityEntity>> watchCommunities() => _controller.stream;

  @override
  Future<List<CommunityEntity>> getCommunities() async => List.unmodifiable(_all);

  @override
  Future<List<CommunityEntity>> getJoinedCommunities() async =>
      _all.where((c) => _joinedIds.contains(c.id)).toList();

  @override
  Future<CommunityEntity> getCommunityById(String communityId) async =>
      _all.firstWhere((c) => c.id == communityId);

  @override
  Future<CommunityEntity> createCommunity({
    required String name,
    required String description,
    required String bookId,
    String? importMembersFromCommunityId,
  }) async {
    final newComm = CommunityEntity(
      id: 'comm-${_all.length + 1}',
      name: name,
      description: description,
      bookId: bookId,
      memberCount: 1,
      creatorId: 'user-1',
    );
    _all.add(newComm);
    _joinedIds.add(newComm.id);
    _controller.add(_all);
    return newComm;
  }

  @override
  Future<void> joinCommunity(String communityId) async {
    _joinedIds.add(communityId);
    _controller.add(_all);
  }

  @override
  Future<void> leaveCommunity(String communityId) async {
    _joinedIds.remove(communityId);
    _controller.add(_all);
  }

  @override
  Future<List<UserEntity>> getAvailableUsersToInvite(String communityId) async => [];
  @override
  Future<CommunityMemberEntity> addMember({
    required String communityId,
    required String userId,
    CommunityRole role = CommunityRole.member,
  }) async =>
      throw UnimplementedError();
  @override
  Future<void> removeMember({
    required String communityId,
    required String userId,
  }) async {}
  @override
  Future<List<CommunityMemberEntity>> getCommunityMembers(String communityId) async => [];
  @override
  Future<void> updateMemberRole({required String communityId, required String targetUserId, required CommunityRole newRole}) async {}
  @override
  Future<void> updateMemberPermissions({required String communityId, required String targetUserId, required Set<CommunityPermission> permissions}) async {}
  @override
  Future<void> restrictMember({required String communityId, required String targetUserId, required String reason, Duration? duration}) async {}
  @override
  Future<void> unrestrictMember({required String communityId, required String targetUserId}) async {}
  @override
  Future<void> kickMember({required String communityId, required String targetUserId}) async {}
  @override
  Future<void> banMember({required String communityId, required String targetUserId, required String reason}) async {}
  @override
  Future<void> unbanMember({required String communityId, required String targetUserId}) async {}

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('Community Filter & Tab Segmentation Tests', () {
    late MockBookRepo bookRepo;
    late MockCommunityRepo communityRepo;
    late CommunityBloc communityBloc;

    setUp(() {
      bookRepo = MockBookRepo();
      communityRepo = MockCommunityRepo();
      communityBloc = CommunityBloc(
        communityRepository: communityRepo,
        bookRepository: bookRepo,
      );
    });

    tearDown(() {
      communityBloc.close();
      communityRepo.dispose();
    });

    test('Initial Load correctly segments My Clubs vs Explore Public', () async {
      communityBloc.add(const LoadCommunities());

      await expectLater(
        communityBloc.stream,
        emitsThrough(predicate<CommunityState>((s) {
          if (s is! CommunityLoaded) return false;
          // Initial tab should be myClubs because comm-1 is joined
          expect(s.filterTab, CommunityFilterTab.myClubs);
          expect(s.myClubsCount, 1);
          expect(s.exploreCount, 1);
          expect(s.totalCount, 2);
          // Filtered list should only contain joined community (comm-1)
          expect(s.filteredItems.length, 1);
          expect(s.filteredItems.first.community.id, 'comm-1');
          expect(s.filteredItems.first.isJoined, isTrue);
          return true;
        })),
      );
    });

    test('Switching to Explore Public shows only unjoined communities', () async {
      communityBloc.add(const LoadCommunities());
      await expectLater(
        communityBloc.stream,
        emitsThrough(predicate<CommunityState>((s) => s is CommunityLoaded)),
      );

      communityBloc.add(const SetCommunityFilterTab(CommunityFilterTab.explore));

      await expectLater(
        communityBloc.stream,
        emitsThrough(predicate<CommunityState>((s) {
          if (s is! CommunityLoaded) return false;
          expect(s.filterTab, CommunityFilterTab.explore);
          expect(s.filteredItems.length, 1);
          expect(s.filteredItems.first.community.id, 'comm-2');
          expect(s.filteredItems.first.isJoined, isFalse);
          return true;
        })),
      );
    });

    test('Switching to All shows both joined and unjoined with isJoined flags', () async {
      communityBloc.add(const LoadCommunities());
      await expectLater(
        communityBloc.stream,
        emitsThrough(predicate<CommunityState>((s) => s is CommunityLoaded)),
      );

      communityBloc.add(const SetCommunityFilterTab(CommunityFilterTab.all));

      await expectLater(
        communityBloc.stream,
        emitsThrough(predicate<CommunityState>((s) {
          if (s is! CommunityLoaded) return false;
          expect(s.filterTab, CommunityFilterTab.all);
          expect(s.filteredItems.length, 2);
          expect(s.filteredItems.any((i) => i.community.id == 'comm-1' && i.isJoined == true), isTrue);
          expect(s.filteredItems.any((i) => i.community.id == 'comm-2' && i.isJoined == false), isTrue);
          return true;
        })),
      );
    });

    test('Joining a community updates counts and moves it to My Clubs', () async {
      communityBloc.add(const LoadCommunities());
      await expectLater(
        communityBloc.stream,
        emitsThrough(predicate<CommunityState>((s) => s is CommunityLoaded)),
      );

      communityBloc.add(const JoinCommunityRequested('comm-2'));

      await expectLater(
        communityBloc.stream,
        emitsThrough(predicate<CommunityState>((s) {
          if (s is! CommunityLoaded) return false;
          expect(s.myClubsCount, 2);
          expect(s.exploreCount, 0);
          expect(s.joinedCommunityIds.contains('comm-2'), isTrue);
          return true;
        })),
      );
    });
  });
}
