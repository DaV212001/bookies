import '../entities/live_reading_session_entity.dart';

abstract class LiveSessionRepository {
  /// Stream active live session state and attendee changes via Socket.IO
  Stream<LiveReadingSessionEntity?> watchActiveSession(String communityId);

  /// Start a new live reading session as host
  Future<LiveReadingSessionEntity> startSession({
    required String communityId,
    required String bookId,
    required String title,
    String? currentCfi,
    String? chapterTitle,
    int? chapterIndex,
    LiveReadingAccessMode accessMode = LiveReadingAccessMode.allMembers,
    Set<String> allowedUserIds = const {},
  });

  /// End the live session
  Future<void> endSession(String communityId);

  /// Broadcast host's current reading CFI location and progression to all attendees
  Future<void> broadcastCfiProgress({
    required String communityId,
    required String cfi,
    required double progression,
  });

  /// Join session as an attendee
  Future<void> joinSession({
    required String communityId,
    required String userId,
  });

  /// Leave active session
  Future<void> leaveSession({
    required String communityId,
    required String userId,
  });

  /// Toggle commenter privilege for an attendee
  Future<void> toggleCommenter({
    required String communityId,
    required String userId,
  });
}
