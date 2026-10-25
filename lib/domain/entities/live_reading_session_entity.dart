import 'package:equatable/equatable.dart';
import 'user_entity.dart';

enum LiveReadingAccessMode {
  allMembers,
  adminsOnly,
  custom,
}

extension LiveReadingAccessModeExtension on LiveReadingAccessMode {
  String get label {
    switch (this) {
      case LiveReadingAccessMode.allMembers:
        return 'All Community Readers';
      case LiveReadingAccessMode.adminsOnly:
        return 'Admins Only';
      case LiveReadingAccessMode.custom:
        return 'Selected Readers Only';
    }
  }

  String get description {
    switch (this) {
      case LiveReadingAccessMode.allMembers:
        return 'Any active member in the community can join and follow along.';
      case LiveReadingAccessMode.adminsOnly:
        return 'Restricted to community creator and designated admins.';
      case LiveReadingAccessMode.custom:
        return 'Only readers explicitly allowed by the session host can join.';
    }
  }
}

class LiveReadingSessionEntity extends Equatable {
  final String id;
  final String communityId;
  final String bookId;
  final String title;
  final UserEntity host;
  final String? currentCfi;
  final String? chapterTitle;
  final int? chapterIndex;
  final bool isActive;
  final DateTime startedAt;
  final LiveReadingAccessMode accessMode;
  final Set<String> allowedUserIds;
  final Set<String> commenterUserIds;
  final Set<String> participantUserIds;

  const LiveReadingSessionEntity({
    required this.id,
    required this.communityId,
    required this.bookId,
    required this.title,
    required this.host,
    this.currentCfi,
    this.chapterTitle,
    this.chapterIndex,
    this.isActive = true,
    required this.startedAt,
    this.accessMode = LiveReadingAccessMode.allMembers,
    this.allowedUserIds = const {},
    this.commenterUserIds = const {},
    this.participantUserIds = const {},
  });

  bool canUserJoin(
    String userId, {
    required bool isElevated,
    required bool isRestricted,
    required bool isBanned,
  }) {
    if (isBanned || isRestricted) return false;
    if (userId == host.id || isElevated) return true;
    switch (accessMode) {
      case LiveReadingAccessMode.allMembers:
        return true;
      case LiveReadingAccessMode.adminsOnly:
        return isElevated;
      case LiveReadingAccessMode.custom:
        return allowedUserIds.contains(userId);
    }
  }

  bool canUserComment(
    String userId, {
    required bool isElevated,
    required bool isRestricted,
    required bool isBanned,
  }) {
    if (isBanned || isRestricted) return false;
    if (userId == host.id || isElevated) return true;
    if (commenterUserIds.isNotEmpty) {
      return commenterUserIds.contains(userId);
    }
    return true;
  }

  @override
  List<Object?> get props => [
        id,
        communityId,
        bookId,
        title,
        host,
        currentCfi,
        chapterTitle,
        chapterIndex,
        isActive,
        startedAt,
        accessMode,
        allowedUserIds,
        commenterUserIds,
        participantUserIds,
      ];
}
