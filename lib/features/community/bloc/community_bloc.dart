import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bookies/domain/entities/book_entity.dart';
import 'package:bookies/domain/entities/community_entity.dart';
import 'package:bookies/domain/repositories/book_repository.dart';
import 'package:bookies/domain/repositories/community_repository.dart';
import 'community_event.dart';
import 'community_state.dart';

export 'community_event.dart';
export 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityRepository _communityRepository;
  final BookRepository _bookRepository;
  StreamSubscription<List<CommunityEntity>>? _communitiesSubscription;

  CommunityBloc({
    required CommunityRepository communityRepository,
    required BookRepository bookRepository,
  })  : _communityRepository = communityRepository,
        _bookRepository = bookRepository,
        super(const CommunityInitial()) {
    on<LoadCommunities>(_onLoadCommunities);
    on<SearchCommunities>(_onSearchCommunities);
    on<ToggleSortOrder>(_onToggleSortOrder);
    on<SetCommunityFilterTab>(_onSetCommunityFilterTab);
    on<CreateNewCommunity>(_onCreateNewCommunity);
    on<JoinCommunityRequested>(_onJoinCommunityRequested);
    on<LeaveCommunityRequested>(_onLeaveCommunityRequested);
    on<CommunitiesUpdated>(_onCommunitiesUpdated);
  }

  Future<void> _onLoadCommunities(
    LoadCommunities event,
    Emitter<CommunityState> emit,
  ) async {
    emit(const CommunityLoading());
    try {
      final books = await _bookRepository.getLibraryBooks();
      final communities = await _communityRepository.getCommunities();
      final joined = await _communityRepository.getJoinedCommunities();
      final joinedIds = joined.map((c) => c.id).toSet();

      await _communitiesSubscription?.cancel();
      _communitiesSubscription =
          _communityRepository.watchCommunities().listen((updated) {
        add(CommunitiesUpdated(updated));
      });

      final initialTab = joinedIds.isNotEmpty
          ? CommunityFilterTab.myCommunities
          : CommunityFilterTab.explore;

      final items = _filterAndSort(
        communities: communities,
        books: books,
        joinedIds: joinedIds,
        query: '',
        popularFirst: false,
        filterTab: initialTab,
      );

      emit(CommunityLoaded(
        allCommunities: communities,
        books: books,
        joinedCommunityIds: joinedIds,
        filteredItems: items,
        searchQuery: '',
        popularFirst: false,
        filterTab: initialTab,
      ));
    } catch (e) {
      emit(CommunityError(e.toString()));
    }
  }

  Future<void> _onCommunitiesUpdated(
    CommunitiesUpdated event,
    Emitter<CommunityState> emit,
  ) async {
    if (state is CommunityLoaded) {
      final current = state as CommunityLoaded;
      Set<String> joinedIds = current.joinedCommunityIds;
      try {
        final joined = await _communityRepository.getJoinedCommunities();
        joinedIds = joined.map((c) => c.id).toSet();
      } catch (_) {}

      final items = _filterAndSort(
        communities: event.communities,
        books: current.books,
        joinedIds: joinedIds,
        query: current.searchQuery,
        popularFirst: current.popularFirst,
        filterTab: current.filterTab,
      );

      emit(current.copyWith(
        allCommunities: event.communities,
        joinedCommunityIds: joinedIds,
        filteredItems: items,
      ));
    }
  }

  void _onSetCommunityFilterTab(
    SetCommunityFilterTab event,
    Emitter<CommunityState> emit,
  ) {
    if (state is CommunityLoaded) {
      final current = state as CommunityLoaded;
      final items = _filterAndSort(
        communities: current.allCommunities,
        books: current.books,
        joinedIds: current.joinedCommunityIds,
        query: current.searchQuery,
        popularFirst: current.popularFirst,
        filterTab: event.tab,
      );

      emit(current.copyWith(
        filterTab: event.tab,
        filteredItems: items,
      ));
    }
  }

  void _onSearchCommunities(
    SearchCommunities event,
    Emitter<CommunityState> emit,
  ) {
    if (state is CommunityLoaded) {
      final current = state as CommunityLoaded;
      final items = _filterAndSort(
        communities: current.allCommunities,
        books: current.books,
        joinedIds: current.joinedCommunityIds,
        query: event.query,
        popularFirst: event.popularFirst,
        filterTab: current.filterTab,
      );

      emit(current.copyWith(
        filteredItems: items,
        searchQuery: event.query,
        popularFirst: event.popularFirst,
      ));
    }
  }

  void _onToggleSortOrder(
    ToggleSortOrder event,
    Emitter<CommunityState> emit,
  ) {
    if (state is CommunityLoaded) {
      final current = state as CommunityLoaded;
      final newPopularFirst = !current.popularFirst;
      final items = _filterAndSort(
        communities: current.allCommunities,
        books: current.books,
        joinedIds: current.joinedCommunityIds,
        query: current.searchQuery,
        popularFirst: newPopularFirst,
        filterTab: current.filterTab,
      );

      emit(current.copyWith(
        filteredItems: items,
        popularFirst: newPopularFirst,
      ));
    }
  }

  Future<void> _onCreateNewCommunity(
    CreateNewCommunity event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.createCommunity(
        name: event.name,
        description: event.description,
        bookId: event.bookId,
        importMembersFromCommunityId: event.importMembersFromCommunityId,
      );
      // Repository stream triggers CommunitiesUpdated
    } catch (e) {
      emit(CommunityError(e.toString()));
    }
  }

  Future<void> _onJoinCommunityRequested(
    JoinCommunityRequested event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.joinCommunity(event.communityId);
      if (state is CommunityLoaded) {
        final current = state as CommunityLoaded;
        final updatedJoined = Set<String>.from(current.joinedCommunityIds)..add(event.communityId);
        final items = _filterAndSort(
          communities: current.allCommunities,
          books: current.books,
          joinedIds: updatedJoined,
          query: current.searchQuery,
          popularFirst: current.popularFirst,
          filterTab: current.filterTab,
        );
        emit(current.copyWith(
          joinedCommunityIds: updatedJoined,
          filteredItems: items,
        ));
      }
    } catch (e) {
      emit(CommunityError(e.toString()));
    }
  }

  Future<void> _onLeaveCommunityRequested(
    LeaveCommunityRequested event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _communityRepository.leaveCommunity(event.communityId);
      if (state is CommunityLoaded) {
        final current = state as CommunityLoaded;
        final updatedJoined = Set<String>.from(current.joinedCommunityIds)..remove(event.communityId);
        final items = _filterAndSort(
          communities: current.allCommunities,
          books: current.books,
          joinedIds: updatedJoined,
          query: current.searchQuery,
          popularFirst: current.popularFirst,
          filterTab: current.filterTab,
        );
        emit(current.copyWith(
          joinedCommunityIds: updatedJoined,
          filteredItems: items,
        ));
      }
    } catch (e) {
      emit(CommunityError(e.toString()));
    }
  }

  List<CommunityWithBook> _filterAndSort({
    required List<CommunityEntity> communities,
    required List<BookEntity> books,
    required Set<String> joinedIds,
    required String query,
    required bool popularFirst,
    required CommunityFilterTab filterTab,
  }) {
    final booksById = {for (final book in books) book.id: book};
    final items = <CommunityWithBook>[
      for (final community in communities)
        (
          community: community,
          book: booksById[community.bookId],
          isJoined: joinedIds.contains(community.id),
        ),
    ];

    final tabFiltered = items.where((item) {
      switch (filterTab) {
        case CommunityFilterTab.myCommunities:
          return item.isJoined;
        case CommunityFilterTab.explore:
          return !item.isJoined;
        case CommunityFilterTab.all:
          return true;
      }
    }).toList();

    final q = query.trim().toLowerCase();
    final filtered = tabFiltered.where((item) {
      if (q.isEmpty) return true;
      return item.community.name.toLowerCase().contains(q) ||
          item.community.description.toLowerCase().contains(q) ||
          (item.book?.title.toLowerCase().contains(q) ?? false);
    }).toList();

    if (popularFirst) {
      filtered.sort(
        (a, b) => b.community.memberCount.compareTo(a.community.memberCount),
      );
    }

    return List.unmodifiable(filtered);
  }

  @override
  Future<void> close() {
    _communitiesSubscription?.cancel();
    return super.close();
  }
}
