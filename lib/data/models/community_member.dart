import 'package:bookies/data/models/user.dart';

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

class CommunityMember {
  final String id;
  final String communityId;
  final User user;
  final CommunityRole role;
  final CommunityMemberStatus status;
  final DateTime joinedAt;
  final Set<CommunityPermission>? customPermissions;
  final String? restrictionReason;
  final DateTime? restrictedAt;

  const CommunityMember({
    required this.id,
    required this.communityId,
    required this.user,
    required this.role,
    this.status = CommunityMemberStatus.active,
    required this.joinedAt,
    this.customPermissions,
    this.restrictionReason,
    this.restrictedAt,
  });

  bool get isCreator => role == CommunityRole.creator;
  bool get isAdmin =>
      role == CommunityRole.admin || role == CommunityRole.creator;
  bool get isElevated => role.isElevated;
  bool get isActive => status == CommunityMemberStatus.active;
  bool get isRestricted => status == CommunityMemberStatus.restricted;
  bool get isBanned => status == CommunityMemberStatus.banned;

  bool hasPermission(CommunityPermission permission) {
    if (isBanned) return false;
    if (isRestricted) {
      if (permission == CommunityPermission.createThreads ||
          permission == CommunityPermission.commentInLiveReading ||
          permission == CommunityPermission.postReplies ||
          permission == CommunityPermission.startLiveReading) {
        return false;
      }
    }
    if (customPermissions != null) {
      return customPermissions!.contains(permission);
    }
    switch (role) {
      case CommunityRole.creator:
        return true;
      case CommunityRole.admin:
        return true;
      case CommunityRole.member:
        return permission == CommunityPermission.joinLiveReading ||
            permission == CommunityPermission.commentInLiveReading ||
            permission == CommunityPermission.createThreads ||
            permission == CommunityPermission.postReplies;
    }
  }

  CommunityMember copyWith({
    String? id,
    String? communityId,
    User? user,
    CommunityRole? role,
    CommunityMemberStatus? status,
    DateTime? joinedAt,
    Set<CommunityPermission>? customPermissions,
    bool clearCustomPermissions = false,
    String? restrictionReason,
    DateTime? restrictedAt,
  }) {
    return CommunityMember(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      user: user ?? this.user,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      customPermissions: clearCustomPermissions
          ? null
          : (customPermissions ?? this.customPermissions),
      restrictionReason: restrictionReason ?? this.restrictionReason,
      restrictedAt: restrictedAt ?? this.restrictedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'user': user.toJson(),
      'role': role.name,
      'status': status.name,
      'joinedAt': joinedAt.toIso8601String(),
      'customPermissions': customPermissions?.map((p) => p.name).toList(),
      'restrictionReason': restrictionReason,
      'restrictedAt': restrictedAt?.toIso8601String(),
    };
  }

  factory CommunityMember.fromJson(Map<String, dynamic> json) {
    return CommunityMember(
      id: json['id'] as String,
      communityId: json['communityId'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      role: CommunityRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => CommunityRole.member,
      ),
      status: CommunityMemberStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CommunityMemberStatus.active,
      ),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      customPermissions: json['customPermissions'] != null
          ? (json['customPermissions'] as List)
              .map(
                (e) => CommunityPermission.values.firstWhere(
                  (p) => p.name == e,
                  orElse: () => CommunityPermission.joinLiveReading,
                ),
              )
              .toSet()
          : null,
      restrictionReason: json['restrictionReason'] as String?,
      restrictedAt: json['restrictedAt'] != null
          ? DateTime.parse(json['restrictedAt'] as String)
          : null,
    );
  }
}
