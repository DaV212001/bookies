import 'package:equatable/equatable.dart';
import 'user_entity.dart';

enum CommunityRole {
  creator,
  admin,
  member,
}

extension CommunityRoleExtension on CommunityRole {
  String get label {
    switch (this) {
      case CommunityRole.creator:
        return 'Creator';
      case CommunityRole.admin:
        return 'Admin';
      case CommunityRole.member:
        return 'Reader';
    }
  }

  bool get isElevated =>
      this == CommunityRole.creator || this == CommunityRole.admin;
}

enum CommunityMemberStatus {
  active,
  restricted,
  banned,
}

extension CommunityMemberStatusExtension on CommunityMemberStatus {
  String get label {
    switch (this) {
      case CommunityMemberStatus.active:
        return 'Active';
      case CommunityMemberStatus.restricted:
        return 'Restricted';
      case CommunityMemberStatus.banned:
        return 'Banned';
    }
  }
}

enum CommunityPermission {
  startLiveReading,
  joinLiveReading,
  commentInLiveReading,
  manageMembers,
  createThreads,
  postReplies,
  pinDiscussions,
  moderateChat,
}

extension CommunityPermissionExtension on CommunityPermission {
  String get label {
    switch (this) {
      case CommunityPermission.startLiveReading:
        return 'Start Live Reading Sessions';
      case CommunityPermission.joinLiveReading:
        return 'Join Live Reading Sessions';
      case CommunityPermission.commentInLiveReading:
        return 'Live Comments & Reactions';
      case CommunityPermission.manageMembers:
        return 'Manage Readers & Roles';
      case CommunityPermission.createThreads:
        return 'Create Discussion Threads';
      case CommunityPermission.postReplies:
        return 'Post Replies & Chat';
      case CommunityPermission.pinDiscussions:
        return 'Pin Discussions';
      case CommunityPermission.moderateChat:
        return 'Moderate & Delete Messages';
    }
  }

  String get description {
    switch (this) {
      case CommunityPermission.startLiveReading:
        return 'Can host a synchronized live reading session.';
      case CommunityPermission.joinLiveReading:
        return 'Can attend and follow live reading sessions.';
      case CommunityPermission.commentInLiveReading:
        return 'Can send comments and reactions during live reading.';
      case CommunityPermission.manageMembers:
        return 'Can invite readers, change roles, restrict, or ban members.';
      case CommunityPermission.createThreads:
        return 'Can create global, chapter, and passage discussion threads.';
      case CommunityPermission.postReplies:
        return 'Can send messages and reply in discussions.';
      case CommunityPermission.pinDiscussions:
        return 'Can pin important topics to the community tab.';
      case CommunityPermission.moderateChat:
        return 'Can delete or flag inappropriate responses.';
    }
  }

  String get category {
    switch (this) {
      case CommunityPermission.startLiveReading:
      case CommunityPermission.joinLiveReading:
      case CommunityPermission.commentInLiveReading:
        return 'Live Reading';
      case CommunityPermission.createThreads:
      case CommunityPermission.postReplies:
      case CommunityPermission.pinDiscussions:
        return 'Discussions';
      case CommunityPermission.manageMembers:
      case CommunityPermission.moderateChat:
        return 'Administration';
    }
  }
}

class CommunityMemberEntity extends Equatable {
  final String communityId;
  final UserEntity user;
  final CommunityRole role;
  final CommunityMemberStatus status;
  final Set<CommunityPermission> customPermissions;
  final DateTime joinedAt;
  final String? restrictedReason;
  final DateTime? restrictedUntil;

  const CommunityMemberEntity({
    required this.communityId,
    required this.user,
    required this.role,
    this.status = CommunityMemberStatus.active,
    this.customPermissions = const {},
    required this.joinedAt,
    this.restrictedReason,
    this.restrictedUntil,
  });

  bool hasPermission(CommunityPermission permission) {
    if (status == CommunityMemberStatus.banned) return false;
    if (role == CommunityRole.creator) return true;
    if (status == CommunityMemberStatus.restricted) return false;
    if (customPermissions.contains(permission)) return true;
    if (role == CommunityRole.admin) return true;
    return permission == CommunityPermission.joinLiveReading ||
        permission == CommunityPermission.commentInLiveReading ||
        permission == CommunityPermission.createThreads ||
        permission == CommunityPermission.postReplies;
  }

  @override
  List<Object?> get props => [
        communityId,
        user,
        role,
        status,
        customPermissions,
        joinedAt,
        restrictedReason,
        restrictedUntil,
      ];
}
