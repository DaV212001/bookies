import 'package:bookies/data/models/user.dart';
import 'package:bookies/domain/entities/community_member_entity.dart';

export 'package:bookies/domain/entities/community_member_entity.dart'
    show
        CommunityRole,
        CommunityRoleExtension,
        CommunityMemberStatus,
        CommunityMemberStatusExtension,
        CommunityPermission,
        CommunityPermissionExtension;

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

  CommunityMemberEntity toDomain() => CommunityMemberEntity(
        communityId: communityId,
        user: user.toDomain(),
        role: role,
        status: status,
        customPermissions: customPermissions ?? const {},
        joinedAt: joinedAt,
        restrictedReason: restrictionReason,
        restrictedUntil: restrictedAt,
      );

  factory CommunityMember.fromDomain(CommunityMemberEntity entity, {String? id}) =>
      CommunityMember(
        id: id ?? entity.user.id,
        communityId: entity.communityId,
        user: User.fromDomain(entity.user),
        role: entity.role,
        status: entity.status,
        joinedAt: entity.joinedAt,
        customPermissions: entity.customPermissions,
        restrictionReason: entity.restrictedReason,
        restrictedAt: entity.restrictedUntil,
      );

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
