import 'package:equatable/equatable.dart';

class CommunityEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String bookId;
  final int memberCount;
  final String creatorId;
  final String? canonicalFingerprint;
  final String? editionTitle;
  final String? downloadUrl;

  const CommunityEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.bookId,
    required this.memberCount,
    required this.creatorId,
    this.canonicalFingerprint,
    this.editionTitle,
    this.downloadUrl,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        bookId,
        memberCount,
        creatorId,
        canonicalFingerprint,
        editionTitle,
        downloadUrl,
      ];
}
