import 'package:equatable/equatable.dart';

class CommunityEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String bookId;
  final int memberCount;
  final String creatorId;

  const CommunityEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.bookId,
    required this.memberCount,
    required this.creatorId,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        bookId,
        memberCount,
        creatorId,
      ];
}
