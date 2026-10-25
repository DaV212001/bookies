import '../entities/community_entity.dart';
import '../entities/community_member_entity.dart';
import '../entities/user_entity.dart';

abstract class CommunityRepository {
  /// Stream community list or watch changes
  Stream<List<CommunityEntity>> watchCommunities();

  /// Fetch all active communities
  Future<List<CommunityEntity>> getCommunities();

  /// Fetch communities joined by the current user
  Future<List<CommunityEntity>> getJoinedCommunities();

  /// Fetch single community details by ID
  Future<CommunityEntity> getCommunityById(String communityId);

  /// Create a new community forum for a book
  Future<CommunityEntity> createCommunity({
    required String name,
    required String description,
    required String bookId,
    String? importMembersFromCommunityId,
  });

  /// Join a community
  Future<void> joinCommunity(String communityId);

  /// Leave a community
  Future<void> leaveCommunity(String communityId);

  /// Fetch member roster with roles and moderation status
  Future<List<CommunityMemberEntity>> getCommunityMembers(String communityId);

  /// Update a reader's role (admin, member)
  Future<void> updateMemberRole({
    required String communityId,
    required String targetUserId,
    required CommunityRole newRole,
  });

  /// Update granular member permissions
  Future<void> updateMemberPermissions({
    required String communityId,
    required String targetUserId,
    required Set<CommunityPermission> permissions,
  });

  /// Apply temporary or permanent restriction
  Future<void> restrictMember({
    required String communityId,
    required String targetUserId,
    required String reason,
    Duration? duration,
  });

  /// Lift member restriction
  Future<void> unrestrictMember({
    required String communityId,
    required String targetUserId,
  });

  /// Ban reader from community
  Future<void> banMember({
    required String communityId,
    required String targetUserId,
    required String reason,
  });

  /// Search available users in directory to invite
  Future<List<UserEntity>> getAvailableUsersToInvite(String communityId);

  /// Add member directly to roster
  Future<CommunityMemberEntity> addMember({
    required String communityId,
    required String userId,
    CommunityRole role = CommunityRole.member,
  });

  /// Remove reader from roster
  Future<void> removeMember({
    required String communityId,
    required String userId,
  });
}
