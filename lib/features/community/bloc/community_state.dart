import 'package:equatable/equatable.dart';
import 'package:bookies/domain/entities/book_entity.dart';
import 'package:bookies/domain/entities/community_entity.dart';
import 'community_event.dart';

typedef CommunityWithBook = ({
  CommunityEntity community,
  BookEntity? book,
  bool isJoined,
});

abstract class CommunityState extends Equatable {
  const CommunityState();

  @override
  List<Object?> get props => [];
}

class CommunityInitial extends CommunityState {
  const CommunityInitial();
}

class CommunityLoading extends CommunityState {
  const CommunityLoading();
}

class CommunityLoaded extends CommunityState {
  final List<CommunityEntity> allCommunities;
  final List<BookEntity> books;
  final Set<String> joinedCommunityIds;
  final List<CommunityWithBook> filteredItems;
  final String searchQuery;
  final bool popularFirst;
  final CommunityFilterTab filterTab;

  const CommunityLoaded({
    required this.allCommunities,
    required this.books,
    required this.filteredItems,
    this.joinedCommunityIds = const {},
    this.searchQuery = '',
    this.popularFirst = false,
    this.filterTab = CommunityFilterTab.myClubs,
  });

  int get myClubsCount =>
      allCommunities.where((c) => joinedCommunityIds.contains(c.id)).length;

  int get exploreCount =>
      allCommunities.where((c) => !joinedCommunityIds.contains(c.id)).length;

  int get totalCount => allCommunities.length;

  CommunityLoaded copyWith({
    List<CommunityEntity>? allCommunities,
    List<BookEntity>? books,
    Set<String>? joinedCommunityIds,
    List<CommunityWithBook>? filteredItems,
    String? searchQuery,
    bool? popularFirst,
    CommunityFilterTab? filterTab,
  }) {
    return CommunityLoaded(
      allCommunities: allCommunities ?? this.allCommunities,
      books: books ?? this.books,
      joinedCommunityIds: joinedCommunityIds ?? this.joinedCommunityIds,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      popularFirst: popularFirst ?? this.popularFirst,
      filterTab: filterTab ?? this.filterTab,
    );
  }

  @override
  List<Object?> get props => [
        allCommunities,
        books,
        joinedCommunityIds,
        filteredItems,
        searchQuery,
        popularFirst,
        filterTab,
      ];
}

class CommunityError extends CommunityState {
  final String message;

  const CommunityError(this.message);

  @override
  List<Object?> get props => [message];
}
