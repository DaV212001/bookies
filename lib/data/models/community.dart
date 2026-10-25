import 'package:bookies/domain/entities/community_entity.dart';

class Community {
  final String id;
  final String name;
  final String description;
  final String bookId; // The reference book for this community
  final int memberCount;
  final String creatorId;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.bookId,
    required this.memberCount,
    this.creatorId = 'user-1',
  });

  CommunityEntity toDomain() => CommunityEntity(
        id: id,
        name: name,
        description: description,
        bookId: bookId,
        memberCount: memberCount,
        creatorId: creatorId,
      );

  factory Community.fromDomain(CommunityEntity entity) => Community(
        id: entity.id,
        name: entity.name,
        description: entity.description,
        bookId: entity.bookId,
        memberCount: entity.memberCount,
        creatorId: entity.creatorId,
      );

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      bookId: json['bookId'] as String,
      memberCount: json['memberCount'] as int,
      creatorId: (json['creatorId'] as String?) ?? 'user-1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'bookId': bookId,
      'memberCount': memberCount,
      'creatorId': creatorId,
    };
  }
}
