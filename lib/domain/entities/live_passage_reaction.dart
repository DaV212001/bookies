import 'package:equatable/equatable.dart';

class LivePassageReaction extends Equatable {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String cfi;
  final String emoji;
  final String? quoteText;
  final DateTime timestamp;

  const LivePassageReaction({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.cfi,
    required this.emoji,
    this.quoteText,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        userId,
        displayName,
        avatarUrl,
        cfi,
        emoji,
        quoteText,
        timestamp,
      ];
}
