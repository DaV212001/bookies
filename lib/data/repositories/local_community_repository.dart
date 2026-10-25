import 'dart:async';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/domain/entities/community_entity.dart';
import 'package:bookies/domain/entities/community_member_entity.dart';
import 'package:bookies/domain/entities/user_entity.dart';
import 'package:bookies/domain/repositories/community_repository.dart';

class LocalCommunityRepository implements CommunityRepository {
  final LocalDataService _localDataService;
  final StreamController<List<CommunityEntity>> _communitiesStreamController =
      StreamController<List<CommunityEntity>>.broadcast();

  LocalCommunityRepository(this._localDataService) {
    _localDataService.communityCatalogRevision.addListener(_onCatalogChanged);
  }

  void _onCatalogChanged() {
    _communitiesStreamController.add(
      _localDataService.communities.map((c) => c.toDomain()).toList(),
    );
  }

  @override
  Stream<List<CommunityEntity>> watchCommunities() {
    // Send immediate snapshot followed by stream updates
    Timer.run(() {
      if (!_communitiesStreamController.isClosed) {
        _communitiesStreamController.add(
          _localDataService.communities.map((c) => c.toDomain()).toList(),
        );
      }
    });
    return _communitiesStreamController.stream;
  }

  @override
  Future<List<CommunityEntity>> getCommunities() async {
    return _localDataService.communities.map((c) => c.toDomain()).toList();
  }

  @override
  Future<List<CommunityEntity>> getJoinedCommunities() async {
    final joined = _localDataService.communities
        .where((c) => _localDataService.isMemberOfCommunity(c.id))
        .map((c) => c.toDomain())
        .toList();
    return joined;
  }

  @override
  Future<CommunityEntity> getCommunityById(String communityId) async {
    final community = _localDataService.communities
        .firstWhere((c) => c.id == communityId, orElse: () {
      throw Exception('Community not found: $communityId');
    });
    return community.toDomain();
  }

  @override
  Future<CommunityEntity> createCommunity({
    required String name,
    required String description,
    required String bookId,
    String? importMembersFromCommunityId,
  }) async {
    final created = await _localDataService.createCommunity(
      name: name,
      description: description,
      bookId: bookId,
      importMembersFromCommunityId: importMembersFromCommunityId,
    );
    return created.toDomain();
  }

  @override
  Future<void> joinCommunity(String communityId) async {
    await _localDataService.joinCommunity(communityId);
  }

  @override
  Future<void> leaveCommunity(String communityId) async {
    await _localDataService.leaveCommunity(communityId);
  }

  @override
  Future<List<CommunityMemberEntity>> getCommunityMembers(String communityId) async {
    final members = _localDataService.getCommunityMembers(communityId);
    return members.map((m) => m.toDomain()).toList();
  }

  @override
  Future<void> updateMemberRole({
    required String communityId,
    required String targetUserId,
    required CommunityRole newRole,
  }) async {
    await _localDataService.updateMemberRole(
      communityId,
      targetUserId,
      newRole.name == 'admin' ? CommunityRole.admin : CommunityRole.member as dynamic,
    );
  }

  @override
  Future<void> updateMemberPermissions({
    required String communityId,
    required String targetUserId,
    required Set<CommunityPermission> permissions,
  }) async {
    await _localDataService.updateMemberPermissions(
      communityId,
      targetUserId,
      permissions,
    );
  }

  @override
  Future<void> restrictMember({
    required String communityId,
    required String targetUserId,
    required String reason,
    Duration? duration,
  }) async {
    await _localDataService.restrictMember(
      communityId,
      targetUserId,
      reason: reason,
    );
  }

  @override
  Future<void> unrestrictMember({
    required String communityId,
    required String targetUserId,
  }) async {
    await _localDataService.unrestrictMember(communityId, targetUserId);
  }

  @override
  Future<void> banMember({
    required String communityId,
    required String targetUserId,
    required String reason,
  }) async {
    await _localDataService.banMember(
      communityId,
      targetUserId,
      reason: reason,
    );
  }

  @override
  Future<List<UserEntity>> getAvailableUsersToInvite(String communityId) async {
    final users = _localDataService.getAvailableUsersToInvite(communityId);
    return users.map((u) => u.toDomain()).toList();
  }

  @override
  Future<CommunityMemberEntity> addMember({
    required String communityId,
    required String userId,
    CommunityRole role = CommunityRole.member,
  }) async {
    final users = _localDataService.getAvailableUsersToInvite(communityId);
    final targetUser = users.firstWhere(
      (u) => u.id == userId,
      orElse: () => _localDataService.currentUser,
    );
    final member = await _localDataService.addMember(
      communityId,
      targetUser,
      role: role.name == 'admin' ? CommunityRole.admin : CommunityRole.member as dynamic,
    );
    return member.toDomain();
  }

  @override
  Future<void> removeMember({
    required String communityId,
    required String userId,
  }) async {
    await _localDataService.removeMember(communityId, userId);
  }

  void dispose() {
    _localDataService.communityCatalogRevision.removeListener(_onCatalogChanged);
    _communitiesStreamController.close();
  }
}
