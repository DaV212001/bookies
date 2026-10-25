import 'package:bookies/data/models/user.dart';
import 'package:bookies/domain/entities/live_reading_session_entity.dart';

export 'package:bookies/domain/entities/live_reading_session_entity.dart'
    show LiveReadingAccessMode, LiveReadingAccessModeExtension;

class LiveReadingSession {
  final String id;
  final String communityId;
  final String bookId;
  final String title;
  final User host;
  final String? currentCfi;
  final String? chapterTitle;
  final int? chapterIndex;
  final bool isActive;
  final DateTime startedAt;
  final LiveReadingAccessMode accessMode;
  final Set<String> allowedUserIds;
  final Set<String> commenterUserIds;
  final Set<String> participantUserIds;

  const LiveReadingSession({
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

  LiveReadingSessionEntity toDomain() => LiveReadingSessionEntity(
        id: id,
        communityId: communityId,
        bookId: bookId,
        title: title,
        host: host.toDomain(),
        currentCfi: currentCfi,
        chapterTitle: chapterTitle,
        chapterIndex: chapterIndex,
        isActive: isActive,
        startedAt: startedAt,
        accessMode: accessMode,
        allowedUserIds: allowedUserIds,
        commenterUserIds: commenterUserIds,
        participantUserIds: participantUserIds,
      );

  factory LiveReadingSession.fromDomain(LiveReadingSessionEntity entity) =>
      LiveReadingSession(
        id: entity.id,
        communityId: entity.communityId,
        bookId: entity.bookId,
        title: entity.title,
        host: User.fromDomain(entity.host),
        currentCfi: entity.currentCfi,
        chapterTitle: entity.chapterTitle,
        chapterIndex: entity.chapterIndex,
        isActive: entity.isActive,
        startedAt: entity.startedAt,
        accessMode: entity.accessMode,
        allowedUserIds: entity.allowedUserIds,
        commenterUserIds: entity.commenterUserIds,
        participantUserIds: entity.participantUserIds,
      );

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

  LiveReadingSession copyWith({
    String? id,
    String? communityId,
    String? bookId,
    String? title,
    User? host,
    String? currentCfi,
    String? chapterTitle,
    int? chapterIndex,
    bool? isActive,
    DateTime? startedAt,
    LiveReadingAccessMode? accessMode,
    Set<String>? allowedUserIds,
    Set<String>? commenterUserIds,
    Set<String>? participantUserIds,
  }) {
    return LiveReadingSession(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      host: host ?? this.host,
      currentCfi: currentCfi ?? this.currentCfi,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      isActive: isActive ?? this.isActive,
      startedAt: startedAt ?? this.startedAt,
      accessMode: accessMode ?? this.accessMode,
      allowedUserIds: allowedUserIds ?? this.allowedUserIds,
      commenterUserIds: commenterUserIds ?? this.commenterUserIds,
      participantUserIds: participantUserIds ?? this.participantUserIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'bookId': bookId,
      'title': title,
      'host': host.toJson(),
      'currentCfi': currentCfi,
      'chapterTitle': chapterTitle,
      'chapterIndex': chapterIndex,
      'isActive': isActive,
      'startedAt': startedAt.toIso8601String(),
      'accessMode': accessMode.name,
      'allowedUserIds': allowedUserIds.toList(),
      'commenterUserIds': commenterUserIds.toList(),
      'participantUserIds': participantUserIds.toList(),
    };
  }

  factory LiveReadingSession.fromJson(Map<String, dynamic> json) {
    return LiveReadingSession(
      id: json['id'] as String,
      communityId: json['communityId'] as String,
      bookId: json['bookId'] as String,
      title: json['title'] as String,
      host: User.fromJson(json['host'] as Map<String, dynamic>),
      currentCfi: json['currentCfi'] as String?,
      chapterTitle: json['chapterTitle'] as String?,
      chapterIndex: json['chapterIndex'] as int?,
      isActive: json['isActive'] as bool? ?? true,
      startedAt: DateTime.parse(json['startedAt'] as String),
      accessMode: LiveReadingAccessMode.values.firstWhere(
        (e) => e.name == json['accessMode'],
        orElse: () => LiveReadingAccessMode.allMembers,
      ),
      allowedUserIds:
          ((json['allowedUserIds'] as List?) ?? []).cast<String>().toSet(),
      commenterUserIds:
          ((json['commenterUserIds'] as List?) ?? (json['speakerUserIds'] as List?) ?? []).cast<String>().toSet(),
      participantUserIds:
          ((json['participantUserIds'] as List?) ?? []).cast<String>().toSet(),
    );
  }
}
