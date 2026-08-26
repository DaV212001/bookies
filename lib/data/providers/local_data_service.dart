import 'dart:convert';
import 'package:bookies/data/models/book.dart';
import 'package:bookies/data/models/community.dart';
import 'package:bookies/data/models/discussion.dart';
import 'package:bookies/data/models/highlight.dart';
import 'package:bookies/data/models/quote_rating.dart';
import 'package:bookies/data/models/thread_scope.dart';
import 'package:bookies/data/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class LocalDataService extends ChangeNotifier {
  final _uuid = const Uuid();
  late SharedPreferences _prefs;

  late User currentUser;
  List<Book> _books = [];
  List<Highlight> _highlights = [];
  List<Discussion> _discussions = [];
  List<QuoteRating> _favoriteQuotes = [];
  List<Community> communities = [];
  List<String> _joinedCommunityIds = [];
  Map<String, String> _selectedCommunityIdsByBook = {};

  Future<LocalDataService> init() async {
    _prefs = await SharedPreferences.getInstance();

    currentUser = User(
      id: 'user-1',
      username: 'bookworm',
      displayName: 'Alice Reader',
      avatarUrl: 'https://i.pravatar.cc/150?u=a042581f4e29026704d',
    );

    communities.add(
      Community(
        id: 'comm-1',
        name: 'The Secret History',
        description: 'A reading community for The Secret History.',
        bookId: 'mock-book-1',
        memberCount: 142,
      ),
    );

    _loadData();
    _seedInitialDataIfNeeded();
    return this;
  }

  void _loadData() {
    final communitiesJson = _prefs.getStringList('communities');
    if (communitiesJson != null) {
      communities = communitiesJson
          .map((jsonStr) => Community.fromJson(jsonDecode(jsonStr)))
          .toList();
    }
    final booksJson = _prefs.getStringList('books') ?? [];
    _books = booksJson
        .map((jsonStr) => Book.fromJson(jsonDecode(jsonStr)))
        .toList();

    final highlightsJson = _prefs.getStringList('highlights') ?? [];
    _highlights = highlightsJson
        .map((jsonStr) => Highlight.fromJson(jsonDecode(jsonStr)))
        .toList();

    final discussionsJson = _prefs.getStringList('discussions') ?? [];
    _discussions = discussionsJson
        .map((jsonStr) => Discussion.fromJson(jsonDecode(jsonStr)))
        .toList();

    final quotesJson = _prefs.getStringList('favorite_quotes') ?? [];
    _favoriteQuotes = quotesJson
        .map((jsonStr) => QuoteRating.fromJson(jsonDecode(jsonStr)))
        .toList();

    final knownIds = communities.map((community) => community.id).toSet();
    final storedMemberships = _prefs.getStringList('joined_communities');
    _joinedCommunityIds = (storedMemberships ?? const ['comm-1'])
        .where(knownIds.contains)
        .toSet()
        .toList();

    final selectionsJson = _prefs.getString('selected_communities_by_book');
    if (selectionsJson != null) {
      final decoded = jsonDecode(selectionsJson) as Map<String, dynamic>;
      _selectedCommunityIdsByBook = decoded.map(
        (bookId, communityId) => MapEntry(bookId, communityId as String),
      );
    }
  }

  void _seedInitialDataIfNeeded() {
    if (_discussions.isEmpty) {
      _discussions.addAll([
        Discussion(
          id: 'disc-1',
          highlightId: 'cfi-passage-1',
          bookId: 'mock-book-1',
          communityId: 'comm-1',
          userId: 'user-2',
          user: User(
            id: 'user-2',
            username: 'julian',
            displayName: 'Julian Morrow',
            avatarUrl: 'https://i.pravatar.cc/150?u=julian',
          ),
          title: 'Symbolism of the Ancient Oak',
          content:
              'Notice how the opening description of the forest sets the tragic tone of the entire narrative.',
          scope: ThreadScope.passage,
          chapterTitle: 'Chapter 1: The Gathering',
          chapterIndex: 1,
          quoteText:
              'Beauty is terror. Whatever we call beautiful, we quiver before it.',
          rating: 4.8,
          upvotes: 24,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        Discussion(
          id: 'disc-2',
          highlightId: 'chapter-1',
          bookId: 'mock-book-1',
          communityId: 'comm-1',
          userId: 'user-3',
          user: User(
            id: 'user-3',
            username: 'henry',
            displayName: 'Henry Winter',
            avatarUrl: 'https://i.pravatar.cc/150?u=henry',
          ),
          title: 'Chapter 1 Character Development',
          content:
              'What are your thoughts on Richard’s unreliable narration in the first chapter?',
          scope: ThreadScope.chapter,
          chapterTitle: 'Chapter 1: The Gathering',
          chapterIndex: 1,
          rating: 4.9,
          upvotes: 42,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Discussion(
          id: 'disc-3',
          highlightId: 'book-overall',
          bookId: 'mock-book-1',
          communityId: 'comm-1',
          userId: 'user-4',
          user: User(
            id: 'user-4',
            username: 'camilla',
            displayName: 'Camilla Macaulay',
            avatarUrl: 'https://i.pravatar.cc/150?u=camilla',
          ),
          title: 'Global Book Theme: Aestheticism & Guilt',
          content:
              'Let’s talk about the overarching theme of aestheticism vs morality throughout the book.',
          scope: ThreadScope.book,
          rating: 5.0,
          upvotes: 89,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ]);
      _saveDiscussions();
    }

    if (_favoriteQuotes.isEmpty) {
      _favoriteQuotes.addAll([
        QuoteRating(
          id: 'quote-1',
          bookId: 'mock-book-1',
          bookTitle: 'The Secret History',
          chapterTitle: 'Chapter 1',
          quoteText:
              'Does such a thing as "the fatal flaw" exist outside of literature? I used to think not. Now I think it does.',
          authorName: 'Donna Tartt',
          addedByUsername: 'Julian Morrow',
          upvotes: 56,
          isUpvotedByMe: true,
          averageRating: 4.9,
        ),
        QuoteRating(
          id: 'quote-2',
          bookId: 'mock-book-1',
          bookTitle: 'The Secret History',
          chapterTitle: 'Chapter 4',
          quoteText:
              'It is better to fail in originality than to succeed in imitation.',
          authorName: 'Herman Melville',
          addedByUsername: 'Alice Reader',
          upvotes: 38,
          isUpvotedByMe: false,
          averageRating: 4.7,
        ),
      ]);
      _saveQuotes();
    }
  }

  Future<void> _saveJoinedCommunities() async {
    await _prefs.setStringList('joined_communities', _joinedCommunityIds);
  }

  Future<void> _saveSelectedCommunities() async {
    await _prefs.setString(
      'selected_communities_by_book',
      jsonEncode(_selectedCommunityIdsByBook),
    );
  }

  Future<void> _saveCommunities() async {
    await _prefs.setStringList(
      'communities',
      communities.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> _saveBooks() async {
    final booksJson = _books.map((b) => jsonEncode(b.toJson())).toList();
    await _prefs.setStringList('books', booksJson);
  }

  Future<void> _saveHighlights() async {
    final highlightsJson = _highlights
        .map((h) => jsonEncode(h.toJson()))
        .toList();
    await _prefs.setStringList('highlights', highlightsJson);
  }

  Future<void> _saveDiscussions() async {
    final discussionsJson = _discussions
        .map((d) => jsonEncode(d.toJson()))
        .toList();
    await _prefs.setStringList('discussions', discussionsJson);
  }

  Future<void> _saveQuotes() async {
    final quotesJson = _favoriteQuotes
        .map((q) => jsonEncode(q.toJson()))
        .toList();
    await _prefs.setStringList('favorite_quotes', quotesJson);
  }

  // --- Books ---
  List<Book> getBooks() => List.unmodifiable(_books);

  Future<void> addBook(Book book) async {
    _books.add(book);
    await _saveBooks();
  }

  Future<void> updateBook(Book updatedBook) async {
    final index = _books.indexWhere((b) => b.id == updatedBook.id);
    if (index != -1) {
      _books[index] = updatedBook;
      await _saveBooks();
    }
  }

  Future<void> saveProgress(String bookId, String locatorJson) async {
    await _prefs.setString('progress_$bookId', locatorJson);
    notifyListeners();
  }

  String? getProgress(String bookId) {
    return _prefs.getString('progress_$bookId');
  }

  // --- App Theme Preferences ---
  Future<void> saveAppTheme(String themeName) async {
    await _prefs.setString('app_theme', themeName);
  }

  String? getAppTheme() {
    return _prefs.getString('app_theme');
  }

  // --- Reading Preferences ---
  Future<void> saveReadingPreferences(String prefsJson) async {
    await _prefs.setString('reading_preferences', prefsJson);
  }

  String? getReadingPreferences() {
    return _prefs.getString('reading_preferences');
  }

  // --- Highlights ---
  List<Highlight> getHighlightsForBook(String bookId) {
    return _highlights.where((h) => h.bookId == bookId).toList();
  }

  Future<Highlight> addHighlight(Highlight highlight) async {
    _highlights.add(highlight);
    await _saveHighlights();
    notifyListeners();
    return highlight;
  }

  // --- Discussions ---
  List<Discussion> getDiscussionsForHighlight(String highlightId) {
    return _discussions.where((d) => d.highlightId == highlightId).toList();
  }

  List<Discussion> getDiscussionsForCfi(String cfi, {String? communityId}) {
    return _discussions
        .where(
          (d) =>
              d.highlightId == cfi &&
              (communityId == null ||
                  d.communityId.isEmpty ||
                  d.communityId == communityId),
        )
        .toList();
  }

  List<Discussion> getDiscussionsByScope(
    String bookId,
    ThreadScope? scope, {
    String? communityId,
  }) {
    return _discussions
        .where(
          (discussion) =>
              (discussion.bookId == bookId || discussion.bookId.isEmpty) &&
              (communityId == null ||
                  discussion.communityId.isEmpty ||
                  discussion.communityId == communityId) &&
              (scope == null || discussion.scope == scope),
        )
        .toList();
  }

  List<Discussion> getChapterDiscussions(String bookId, String chapterTitle) {
    return _discussions
        .where(
          (d) =>
              d.scope == ThreadScope.chapter &&
              (d.chapterTitle?.toLowerCase() == chapterTitle.toLowerCase() ||
                  d.highlightId == chapterTitle),
        )
        .toList();
  }

  Future<Discussion> createThread({
    required String highlightId,
    required String bookId,
    String communityId = '',
    required String title,
    required String content,
    required ThreadScope scope,
    String? chapterTitle,
    int? chapterIndex,
    String? quoteText,
    double? rating,
  }) async {
    final newDiscussion = Discussion(
      id: _uuid.v4(),
      highlightId: highlightId,
      bookId: bookId,
      communityId: communityId,
      userId: currentUser.id,
      user: currentUser,
      title: title.isEmpty ? scope.label : title,
      content: content,
      scope: scope,
      chapterTitle: chapterTitle,
      chapterIndex: chapterIndex,
      quoteText: quoteText,
      rating: rating,
      createdAt: DateTime.now(),
    );
    _discussions.insert(0, newDiscussion);
    await _saveDiscussions();
    notifyListeners();
    return newDiscussion;
  }

  Future<Discussion> addDiscussion(String highlightId, String content) async {
    return createThread(
      highlightId: highlightId,
      bookId: '',
      title: 'Note',
      content: content,
      scope: ThreadScope.passage,
    );
  }

  Future<void> upvoteThread(String threadId) async {
    final index = _discussions.indexWhere((d) => d.id == threadId);
    if (index != -1) {
      _discussions[index].upvotes += 1;
      await _saveDiscussions();
      notifyListeners();
    }
  }

  // --- Favorite Quotes & Ratings ---
  List<QuoteRating> getFavoriteQuotes(String bookId) {
    return _favoriteQuotes.where((quote) => quote.bookId == bookId).toList();
  }

  Future<QuoteRating> addFavoriteQuote({
    required String bookId,
    required String bookTitle,
    required String chapterTitle,
    required String quoteText,
    required String authorName,
  }) async {
    final quote = QuoteRating(
      id: _uuid.v4(),
      bookId: bookId,
      bookTitle: bookTitle,
      chapterTitle: chapterTitle,
      quoteText: quoteText,
      authorName: authorName,
      addedByUsername: currentUser.displayName,
      upvotes: 1,
      isUpvotedByMe: true,
    );
    _favoriteQuotes.insert(0, quote);
    await _saveQuotes();
    notifyListeners();
    return quote;
  }

  Future<void> upvoteQuote(String quoteId) async {
    final index = _favoriteQuotes.indexWhere((q) => q.id == quoteId);
    if (index != -1) {
      final item = _favoriteQuotes[index];
      if (item.isUpvotedByMe) {
        item.upvotes -= 1;
        item.isUpvotedByMe = false;
      } else {
        item.upvotes += 1;
        item.isUpvotedByMe = true;
      }
      await _saveQuotes();
      notifyListeners();
    }
  }

  // --- Community Membership ---
  bool isMemberOfCommunity(String communityId) {
    return _joinedCommunityIds.contains(communityId);
  }

  Future<void> joinCommunity(String communityId) async {
    if (!communities.any((community) => community.id == communityId)) return;
    if (!isMemberOfCommunity(communityId)) {
      _joinedCommunityIds.add(communityId);
      await _saveJoinedCommunities();
      notifyListeners();
    }
  }

  Future<void> leaveCommunity(String communityId) async {
    _joinedCommunityIds.remove(communityId);
    _selectedCommunityIdsByBook.removeWhere(
      (bookId, selectedId) => selectedId == communityId,
    );
    await _saveJoinedCommunities();
    await _saveSelectedCommunities();
    notifyListeners();
  }

  Future<Community> createCommunity({
    required String name,
    required String description,
    required String bookId,
  }) async {
    final newComm = Community(
      id: _uuid.v4(),
      name: name,
      description: description,
      bookId: bookId,
      memberCount: 1,
    );
    communities.add(newComm);
    await _saveCommunities();
    await joinCommunity(newComm.id);
    notifyListeners();
    return newComm;
  }

  List<Community> getCommunitiesForBook(String bookId) => communities
      .where((community) => community.bookId == bookId)
      .toList(growable: false);

  List<Community> getJoinedCommunitiesForBook(String bookId) =>
      getCommunitiesForBook(bookId)
          .where((community) => isMemberOfCommunity(community.id))
          .toList(growable: false);

  Community? getDefaultCommunityForBook(String bookId) {
    final joined = getJoinedCommunitiesForBook(bookId);
    if (joined.isEmpty) return null;
    for (final joinedId in _joinedCommunityIds) {
      for (final community in joined) {
        if (community.id.toLowerCase() == joinedId.toLowerCase()) {
          return community;
        }
      }
    }
    return joined.first;
  }

  Community? getSelectedCommunityForBook(String bookId) {
    final selectedId = _selectedCommunityIdsByBook[bookId];
    if (selectedId != null) {
      for (final community in getJoinedCommunitiesForBook(bookId)) {
        if (community.id == selectedId) return community;
      }
    }
    return getDefaultCommunityForBook(bookId);
  }

  Future<void> selectCommunityForBook({
    required String bookId,
    required String communityId,
  }) async {
    final isJoinedForBook = getJoinedCommunitiesForBook(bookId)
        .any((community) => community.id == communityId);
    if (!isJoinedForBook) return;
    _selectedCommunityIdsByBook[bookId] = communityId;
    await _saveSelectedCommunities();
    notifyListeners();
  }
}
