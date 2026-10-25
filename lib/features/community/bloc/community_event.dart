import 'package:equatable/equatable.dart';
import 'package:bookies/domain/entities/community_entity.dart';

abstract class CommunityEvent extends Equatable {
  const CommunityEvent();

  @override
  List<Object?> get props => [];
}

class LoadCommunities extends CommunityEvent {
  const LoadCommunities();
}

class SearchCommunities extends CommunityEvent {
  final String query;
  final bool popularFirst;

  const SearchCommunities({required this.query, this.popularFirst = false});

  @override
  List<Object?> get props => [query, popularFirst];
}

class ToggleSortOrder extends CommunityEvent {
  const ToggleSortOrder();
}

class CreateNewCommunity extends CommunityEvent {
  final String name;
  final String description;
  final String bookId;
  final String? importMembersFromCommunityId;

  const CreateNewCommunity({
    required this.name,
    required this.description,
    required this.bookId,
    this.importMembersFromCommunityId,
  });

  @override
  List<Object?> get props => [
        name,
        description,
        bookId,
        importMembersFromCommunityId,
      ];
}

class JoinCommunityRequested extends CommunityEvent {
  final String communityId;

  const JoinCommunityRequested(this.communityId);

  @override
  List<Object?> get props => [communityId];
}

class LeaveCommunityRequested extends CommunityEvent {
  final String communityId;

  const LeaveCommunityRequested(this.communityId);

  @override
  List<Object?> get props => [communityId];
}

class CommunitiesUpdated extends CommunityEvent {
  final List<CommunityEntity> communities;

  const CommunitiesUpdated(this.communities);

  @override
  List<Object?> get props => [communities];
}
