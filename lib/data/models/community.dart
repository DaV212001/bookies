import 'package:bookies/domain/entities/community_entity.dart';

class Community {
  final String id;
  final String name;
  final String description;
  final String bookId; // The reference book for this community
  final int memberCount;
  final String creatorId;
  final String? canonicalFingerprint;
  final String? editionTitle;
  final String? downloadUrl;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.bookId,
    required this.memberCount,
    this.creatorId = 'user-1',
    this.canonicalFingerprint,
    this.editionTitle,
    this.downloadUrl,
  });

  CommunityEntity toDomain() => CommunityEntity(
        id: id,
        name: name,
        description: description,
        bookId: bookId,
        memberCount: memberCount,
        creatorId: creatorId,
        canonicalFingerprint: canonicalFingerprint,
        editionTitle: editionTitle,
        downloadUrl: downloadUrl,
      );

  factory Community.fromDomain(CommunityEntity entity) => Community(
        id: entity.id,
        name: entity.name,
        description: entity.description,
        bookId: entity.bookId,
        memberCount: entity.memberCount,
        creatorId: entity.creatorId,
        canonicalFingerprint: entity.canonicalFingerprint,
        editionTitle: entity.editionTitle,
        downloadUrl: entity.downloadUrl,
      );

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      bookId: json['bookId'] as String,
      memberCount: json['memberCount'] as int,
      creatorId: (json['creatorId'] as String?) ?? 'user-1',
      canonicalFingerprint: json['canonicalFingerprint'] as String?,
      editionTitle: json['editionTitle'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
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
      'canonicalFingerprint': canonicalFingerprint,
      'editionTitle': editionTitle,
      'downloadUrl': downloadUrl,
    };
  }
}
