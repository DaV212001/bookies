import 'package:equatable/equatable.dart';

class LiveParticipantProgress extends Equatable {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final double progression; // 0.0 to 1.0
  final String? cfi;
  final String? chapterTitle;
  final int? chapterIndex;
  final DateTime lastUpdated;

  const LiveParticipantProgress({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.progression,
    this.cfi,
    this.chapterTitle,
    this.chapterIndex,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        userId,
        displayName,
        avatarUrl,
        progression,
        cfi,
        chapterTitle,
        chapterIndex,
        lastUpdated,
      ];
}
