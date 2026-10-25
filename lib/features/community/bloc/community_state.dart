import 'package:equatable/equatable.dart';
import 'package:bookies/domain/entities/book_entity.dart';
import 'package:bookies/domain/entities/community_entity.dart';

typedef CommunityWithBook = ({CommunityEntity community, BookEntity? book});

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
  final List<CommunityWithBook> filteredItems;
  final String searchQuery;
  final bool popularFirst;

  const CommunityLoaded({
    required this.allCommunities,
    required this.books,
    required this.filteredItems,
    this.searchQuery = '',
    this.popularFirst = false,
  });

  CommunityLoaded copyWith({
    List<CommunityEntity>? allCommunities,
    List<BookEntity>? books,
    List<CommunityWithBook>? filteredItems,
    String? searchQuery,
    bool? popularFirst,
  }) {
    return CommunityLoaded(
      allCommunities: allCommunities ?? this.allCommunities,
      books: books ?? this.books,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      popularFirst: popularFirst ?? this.popularFirst,
    );
  }

  @override
  List<Object?> get props => [
        allCommunities,
        books,
        filteredItems,
        searchQuery,
        popularFirst,
      ];
}

class CommunityError extends CommunityState {
  final String message;

  const CommunityError(this.message);

  @override
  List<Object?> get props => [message];
}
