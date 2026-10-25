import 'dart:async';
import 'package:bookies/core/network/api_client.dart';
import 'package:bookies/core/utils/app_logger.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/domain/entities/community_entity.dart';
import 'package:bookies/domain/entities/community_member_entity.dart';
import 'package:bookies/domain/entities/user_entity.dart';
import 'package:bookies/domain/repositories/community_repository.dart';

class ApiCommunityRepository implements CommunityRepository {
  final ApiClient _apiClient;
  final LocalDataService _localDataService;
  final StreamController<List<CommunityEntity>> _communitiesStreamController =
      StreamController<List<CommunityEntity>>.broadcast();

  static const String _tag = 'ApiCommunityRepository';

  ApiCommunityRepository({
    required ApiClient apiClient,
    required LocalDataService localDataService,
  })  : _apiClient = apiClient,
        _localDataService = localDataService;

  @override
  Stream<List<CommunityEntity>> watchCommunities() {
    Timer.run(() => getCommunities());
    return _communitiesStreamController.stream;
  }

  @override
  Future<List<CommunityEntity>> getCommunities() async {
    try {
      final response = await _apiClient.dio.get('/communities');
      if (response.statusCode == 200 && response.data is List) {
        final list = (response.data as List)
            .map((item) => _mapJsonToCommunity(item))
            .toList();
        _communitiesStreamController.add(list);
        return list;
      }
    } catch (e) {
      AppLogger.w(_tag, 'Failed to fetch communities from backend, using local: $e');
    }

    final localList =
        _localDataService.communities.map((c) => c.toDomain()).toList();
    _communitiesStreamController.add(localList);
    return localList;
  }

  @override
  Future<List<CommunityEntity>> getJoinedCommunities() async {
    try {
      final all = await getCommunities();
      final currentUserId = _localDataService.currentUser.id;
      final joined = <CommunityEntity>[];

      for (final comm in all) {
        try {
          final members = await getCommunityMembers(comm.id);
          if (members.any((m) => m.user.id == currentUserId && m.status != CommunityMemberStatus.banned)) {
            joined.add(comm);
          }
        } catch (_) {}
      }

      if (joined.isNotEmpty) return joined;
    } catch (e) {
      AppLogger.w(_tag, 'Failed to get joined communities: $e');
    }

    return _localDataService.communities
        .where((c) => _localDataService.isMemberOfCommunity(c.id))
        .map((c) => c.toDomain())
        .toList();
  }

  @override
  Future<CommunityEntity> getCommunityById(String communityId) async {
    try {
      final response = await _apiClient.dio.get('/communities/$communityId');
      if (response.statusCode == 200 && response.data != null) {
        return _mapJsonToCommunity(response.data);
      }
    } catch (e) {
      AppLogger.w(_tag, 'Failed to fetch community $communityId from backend: $e');
    }

    final local = _localDataService.communities
        .firstWhere((c) => c.id == communityId, orElse: () {
      throw Exception('Community not found: $communityId');
    });
    return local.toDomain();
  }

  @override
  Future<CommunityEntity> createCommunity({
    required String name,
    required String description,
    required String bookId,
    String? importMembersFromCommunityId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/communities',
        data: {
          'name': name.trim(),
          'description': description.trim(),
          'bookId': bookId,
          if (importMembersFromCommunityId != null)
            'importMembersFromCommunityId': importMembersFromCommunityId,
        },
      );

      final created = _mapJsonToCommunity(response.data);
      await getCommunities(); // Refresh stream
      return created;
    } catch (e) {
      AppLogger.w(_tag, 'Remote createCommunity failed, falling back to local: $e');
      final local = await _localDataService.createCommunity(
        name: name,
        description: description,
        bookId: bookId,
        importMembersFromCommunityId: importMembersFromCommunityId,
      );
      await getCommunities();
      return local.toDomain();
    }
  }

  @override
  Future<void> joinCommunity(String communityId) async {
    try {
      await _apiClient.dio.post('/communities/$communityId/join');
      await getCommunities();
    } catch (e) {
      AppLogger.w(_tag, 'Remote joinCommunity failed, applying local fallback: $e');
      await _localDataService.joinCommunity(communityId);
      await getCommunities();
    }
  }

  @override
  Future<void> leaveCommunity(String communityId) async {
    try {
      await _apiClient.dio.post('/communities/$communityId/leave');
      await getCommunities();
    } catch (e) {
      AppLogger.w(_tag, 'Remote leaveCommunity failed, applying local fallback: $e');
      await _localDataService.leaveCommunity(communityId);
      await getCommunities();
    }
  }

  @override
  Future<List<CommunityMemberEntity>> getCommunityMembers(String communityId) async {
    try {
      final response = await _apiClient.dio.get('/communities/$communityId/members');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => _mapJsonToMember(item, communityId))
            .toList();
      }
    } catch (e) {
      AppLogger.w(_tag, 'Failed to fetch members for $communityId from backend: $e');
    }

    return _localDataService
        .getCommunityMembers(communityId)
        .map((m) => m.toDomain())
        .toList();
  }

  @override
  Future<void> updateMemberRole({
    required String communityId,
    required String targetUserId,
    required CommunityRole newRole,
  }) async {
    try {
      final roleStr = newRole == CommunityRole.admin ? 'admin' : 'member';
      await _apiClient.dio.put(
        '/communities/$communityId/members/$targetUserId/role',
        data: {'role': roleStr},
      );
    } catch (e) {
      AppLogger.w(_tag, 'Remote updateMemberRole failed, applying local fallback: $e');
      await _localDataService.updateMemberRole(communityId, targetUserId, newRole.name == 'admin' ? CommunityRole.admin : CommunityRole.member as dynamic);
    }
  }

  @override
  Future<void> updateMemberPermissions({
    required String communityId,
    required String targetUserId,
    required Set<CommunityPermission> permissions,
  }) async {
    // Local data service fallback for granular custom permissions
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
    try {
      await _apiClient.dio.post(
        '/communities/$communityId/members/$targetUserId/restrict',
        data: {
          'reason': reason,
          if (duration != null) 'durationMinutes': duration.inMinutes,
        },
      );
    } catch (e) {
      AppLogger.w(_tag, 'Remote restrictMember failed, applying local fallback: $e');
      await _localDataService.restrictMember(communityId, targetUserId, reason: reason);
    }
  }

  @override
  Future<void> unrestrictMember({
    required String communityId,
    required String targetUserId,
  }) async {
    try {
      await _apiClient.dio.post('/communities/$communityId/members/$targetUserId/unrestrict');
    } catch (e) {
      AppLogger.w(_tag, 'Remote unrestrictMember failed, applying local fallback: $e');
      await _localDataService.unrestrictMember(communityId, targetUserId);
    }
  }

  @override
  Future<void> banMember({
    required String communityId,
    required String targetUserId,
    required String reason,
  }) async {
    try {
      await _apiClient.dio.post(
        '/communities/$communityId/members/$targetUserId/ban',
        data: {'reason': reason},
      );
    } catch (e) {
      AppLogger.w(_tag, 'Remote banMember failed, applying local fallback: $e');
      await _localDataService.banMember(communityId, targetUserId, reason: reason);
    }
  }

  @override
  Future<List<UserEntity>> getAvailableUsersToInvite(String communityId) async {
    return _localDataService
        .getAvailableUsersToInvite(communityId)
        .map((u) => u.toDomain())
        .toList();
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
    final local = await _localDataService.addMember(
      communityId,
      targetUser,
      role: role.name == 'admin' ? CommunityRole.admin : CommunityRole.member as dynamic,
    );
    return local.toDomain();
  }

  @override
  Future<void> removeMember({
    required String communityId,
    required String userId,
  }) async {
    await _localDataService.removeMember(communityId, userId);
  }

  CommunityEntity _mapJsonToCommunity(dynamic json) {
    return CommunityEntity(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      bookId: json['bookId']?.toString() ?? '',
      memberCount: json['_count']?['members'] as int? ??
          json['memberCount'] as int? ??
          1,
      creatorId: json['creatorId']?.toString() ?? '',
    );
  }

  CommunityMemberEntity _mapJsonToMember(dynamic json, String communityId) {
    final userJson = json['user'] as Map<String, dynamic>? ?? {};
    final roleStr = json['role']?.toString().toLowerCase();
    final statusStr = json['status']?.toString().toLowerCase();

    final role = roleStr == 'creator'
        ? CommunityRole.creator
        : roleStr == 'admin'
            ? CommunityRole.admin
            : CommunityRole.member;

    final status = statusStr == 'restricted'
        ? CommunityMemberStatus.restricted
        : statusStr == 'banned'
            ? CommunityMemberStatus.banned
            : CommunityMemberStatus.active;

    return CommunityMemberEntity(
      communityId: communityId,
      user: UserEntity(
        id: userJson['id']?.toString() ?? json['userId']?.toString() ?? '',
        username: userJson['username']?.toString() ?? 'reader',
        displayName: userJson['displayName']?.toString() ?? 'Reader',
        avatarUrl: userJson['avatarUrl']?.toString(),
      ),
      role: role,
      status: status,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      restrictedReason: json['restrictionReason']?.toString(),
      restrictedUntil: json['restrictedAt'] != null
          ? DateTime.tryParse(json['restrictedAt'].toString())
          : null,
    );
  }

  void dispose() {
    _communitiesStreamController.close();
  }
}
