import 'dart:async';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/domain/entities/live_reading_session_entity.dart';
import 'package:bookies/domain/repositories/live_session_repository.dart';

class LocalLiveSessionRepository implements LiveSessionRepository {
  final LocalDataService _localDataService;
  final Map<String, StreamController<LiveReadingSessionEntity?>> _sessionControllers = {};

  LocalLiveSessionRepository(this._localDataService);

  @override
  Stream<LiveReadingSessionEntity?> watchActiveSession(String communityId) {
    if (!_sessionControllers.containsKey(communityId)) {
      _sessionControllers[communityId] =
          StreamController<LiveReadingSessionEntity?>.broadcast();
    }
    // Emit current active session
    final current = _localDataService.getActiveLiveReadingSession(communityId);
    Timer.run(() {
      _sessionControllers[communityId]?.add(current?.toDomain());
    });
    return _sessionControllers[communityId]!.stream;
  }

  @override
  Future<LiveReadingSessionEntity> startSession({
    required String communityId,
    required String bookId,
    required String title,
    String? currentCfi,
    String? chapterTitle,
    int? chapterIndex,
    LiveReadingAccessMode accessMode = LiveReadingAccessMode.allMembers,
    Set<String> allowedUserIds = const {},
  }) async {
    final session = await _localDataService.startLiveReadingSession(
      communityId: communityId,
      bookId: bookId,
      title: title,
      currentCfi: currentCfi,
      chapterTitle: chapterTitle,
      chapterIndex: chapterIndex,
      accessMode: accessMode,
      allowedUserIds: allowedUserIds,
    );
    final entity = session.toDomain();
    _sessionControllers[communityId]?.add(entity);
    return entity;
  }

  @override
  Future<void> endSession(String communityId) async {
    await _localDataService.endLiveReadingSession(communityId);
    _sessionControllers[communityId]?.add(null);
  }

  @override
  Future<void> broadcastCfiProgress({
    required String communityId,
    required String cfi,
    required double progression,
  }) async {
    final current = _localDataService.getActiveLiveReadingSession(communityId);
    if (current != null) {
      final updated = current.copyWith(currentCfi: cfi);
      await _localDataService.updateLiveReadingSession(updated);
      _sessionControllers[communityId]?.add(updated.toDomain());
    }
  }

  @override
  Future<void> joinSession({
    required String communityId,
    required String userId,
  }) async {
    await _localDataService.joinLiveReadingSession(communityId, userId);
    final updated = _localDataService.getActiveLiveReadingSession(communityId);
    _sessionControllers[communityId]?.add(updated?.toDomain());
  }

  @override
  Future<void> leaveSession({
    required String communityId,
    required String userId,
  }) async {
    await _localDataService.leaveLiveReadingSession(communityId, userId);
    final updated = _localDataService.getActiveLiveReadingSession(communityId);
    _sessionControllers[communityId]?.add(updated?.toDomain());
  }

  @override
  Future<void> toggleCommenter({
    required String communityId,
    required String userId,
  }) async {
    await _localDataService.toggleLiveCommenter(communityId, userId);
    final updated = _localDataService.getActiveLiveReadingSession(communityId);
    _sessionControllers[communityId]?.add(updated?.toDomain());
  }

  void dispose() {
    for (final controller in _sessionControllers.values) {
      controller.close();
    }
    _sessionControllers.clear();
  }
}
