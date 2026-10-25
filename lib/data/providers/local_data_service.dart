import 'dart:async';
import 'dart:convert';
import 'package:bookies/data/models/book.dart';
import 'package:bookies/data/models/chat_message.dart';
import 'package:bookies/data/models/community.dart';
import 'package:bookies/data/models/community_member.dart';
import 'package:bookies/data/models/discussion.dart';
import 'package:bookies/data/models/highlight.dart';
import 'package:bookies/data/models/live_reading_session.dart';
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
  final Map<String, StreamController<List<ChatMessage>>>
  _threadStreamControllers = {};
  final Map<String, List<ChatMessage>> _threadMessages = {};
  final List<User> _directoryUsers = [];
  final Map<String, List<CommunityMember>> _communityMembersByCommunityId = {};
  final Map<String, LiveReadingSession> _activeLiveSessions = {};
  final ValueNotifier<int> communityCatalogRevision = ValueNotifier(0);

  Future<LocalDataService> init() async {
    _prefs = await SharedPreferences.getInstance();

    currentUser = User(
      id: 'user-1',
      username: 'bookworm',
      displayName: 'Alice Reader',
      avatarUrl: 'https://i.pravatar.cc/150?u=a042581f4e29026704d',
    );

    _directoryUsers.addAll([
      currentUser,
      User(
        id: 'user-2',
        username: 'julian',
        displayName: 'Julian Morrow',
        avatarUrl: 'https://i.pravatar.cc/150?u=julian',
      ),
      User(
        id: 'user-3',
        username: 'henry',
        displayName: 'Henry Winter',
        avatarUrl: 'https://i.pravatar.cc/150?u=henry',
      ),
      User(
        id: 'user-4',
        username: 'camilla',
        displayName: 'Camilla Macaulay',
        avatarUrl: 'https://i.pravatar.cc/150?u=camilla',
      ),
      User(
        id: 'user-5',
        username: 'charles',
        displayName: 'Charles Macaulay',
        avatarUrl: 'https://i.pravatar.cc/150?u=charles',
      ),
      User(
        id: 'user-6',
        username: 'francis',
        displayName: 'Francis Abernathy',
        avatarUrl: 'https://i.pravatar.cc/150?u=francis',
      ),
      User(
        id: 'user-7',
        username: 'richard',
        displayName: 'Richard Papen',
        avatarUrl: 'https://i.pravatar.cc/150?u=richard',
      ),
    ]);

    communities.add(
      Community(
        id: 'comm-1',
        name: 'The Secret History',
        description: 'A reading community for The Secret History.',
        bookId: 'mock-book-1',
        memberCount: 6,
        creatorId: 'user-1',
      ),
    );

    _loadData();
    _seedInitialDataIfNeeded();
    _sortAllCommunityMembers();
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
    _seedCommunityMembersIfNeeded();
    _loadLiveSessions();
  }

  void _seedCommunityMembersIfNeeded() {
    for (final comm in communities) {
      final membersKey = 'members_${comm.id}';
      final membersJson = _prefs.getStringList(membersKey);
      if (membersJson != null && membersJson.isNotEmpty) {
        _communityMembersByCommunityId[comm.id] = membersJson
            .map((j) => CommunityMember.fromJson(jsonDecode(j)))
            .toList();
      } else if (comm.id == 'comm-1') {
        _communityMembersByCommunityId[comm.id] = [
          CommunityMember(
            id: 'mem-1',
            communityId: comm.id,
            user: currentUser,
            role: CommunityRole.creator,
            status: CommunityMemberStatus.active,
            joinedAt: DateTime.now().subtract(const Duration(days: 30)),
          ),
          CommunityMember(
            id: 'mem-2',
            communityId: comm.id,
            user: _directoryUsers.firstWhere((u) => u.id == 'user-2'),
            role: CommunityRole.admin,
            status: CommunityMemberStatus.active,
            joinedAt: DateTime.now().subtract(const Duration(days: 28)),
          ),
          CommunityMember(
            id: 'mem-3',
            communityId: comm.id,
            user: _directoryUsers.firstWhere((u) => u.id == 'user-3'),
            role: CommunityRole.member,
            status: CommunityMemberStatus.active,
            joinedAt: DateTime.now().subtract(const Duration(days: 20)),
          ),
          CommunityMember(
            id: 'mem-4',
            communityId: comm.id,
            user: _directoryUsers.firstWhere((u) => u.id == 'user-4'),
            role: CommunityRole.member,
            status: CommunityMemberStatus.active,
            joinedAt: DateTime.now().subtract(const Duration(days: 15)),
          ),
          CommunityMember(
            id: 'mem-5',
            communityId: comm.id,
            user: _directoryUsers.firstWhere((u) => u.id == 'user-5'),
            role: CommunityRole.member,
            status: CommunityMemberStatus.restricted,
            restrictionReason: 'Repeated off-topic spoilers in Chapter 2.',
            restrictedAt: DateTime.now().subtract(const Duration(days: 2)),
            joinedAt: DateTime.now().subtract(const Duration(days: 14)),
          ),
          CommunityMember(
            id: 'mem-6',
            communityId: comm.id,
            user: _directoryUsers.firstWhere((u) => u.id == 'user-6'),
            role: CommunityRole.member,
            status: CommunityMemberStatus.active,
            joinedAt: DateTime.now().subtract(const Duration(days: 10)),
          ),
        ];
        _saveCommunityMembers(comm.id);
      } else {
        _communityMembersByCommunityId[comm.id] = [
          CommunityMember(
            id: _uuid.v4(),
            communityId: comm.id,
            user: currentUser,
            role: CommunityRole.creator,
            status: CommunityMemberStatus.active,
            joinedAt: DateTime.now(),
          ),
        ];
        _saveCommunityMembers(comm.id);
      }
    }
  }

  void _loadLiveSessions() {
    for (final comm in communities) {
      final sessionJson = _prefs.getString('live_session_${comm.id}');
      if (sessionJson != null) {
        try {
          _activeLiveSessions[comm.id] = LiveReadingSession.fromJson(
            jsonDecode(sessionJson),
          );
        } catch (_) {}
      }
    }
  }

  Future<void> _saveCommunityMembers(String communityId) async {
    final list = _communityMembersByCommunityId[communityId] ?? [];
    await _prefs.setStringList(
      'members_$communityId',
      list.map((m) => jsonEncode(m.toJson())).toList(),
    );
  }

  Future<void> _saveLiveSession(String communityId) async {
    final session = _activeLiveSessions[communityId];
    if (session == null) {
      await _prefs.remove('live_session_$communityId');
    } else {
      await _prefs.setString(
        'live_session_$communityId',
        jsonEncode(session.toJson()),
      );
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
    _markCommunityCatalogChanged();
  }

  Future<void> updateBook(Book updatedBook) async {
    final index = _books.indexWhere((b) => b.id == updatedBook.id);
    if (index != -1) {
      _books[index] = updatedBook;
      await _saveBooks();
      _markCommunityCatalogChanged();
    }
  }

  Future<void> saveProgress(
    String bookId,
    String locatorJson, {
    bool notify = false,
  }) async {
    await _prefs.setString('progress_$bookId', locatorJson);
    if (notify) {
      notifyListeners();
    }
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

  bool isDiscussionIndicatorsEnabled() {
    return _prefs.getBool('show_discussion_indicators') ?? true;
  }

  Future<void> setDiscussionIndicatorsEnabled(bool enabled) async {
    await _prefs.setBool('show_discussion_indicators', enabled);
    notifyListeners();
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
    String? parentTopicId,
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
      parentTopicId: parentTopicId,
      createdAt: DateTime.now(),
    );
    _discussions.insert(0, newDiscussion);
    notifyListeners();
    await _saveDiscussions();
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
      notifyListeners();
      await _saveDiscussions();
    }
  }

  Future<Discussion?> addReply({
    required String threadId,
    required String content,
  }) async {
    final index = _discussions.indexWhere((d) => d.id == threadId);
    if (index != -1) {
      final parent = _discussions[index];
      final newReply = Discussion(
        id: _uuid.v4(),
        highlightId: parent.highlightId,
        bookId: parent.bookId,
        communityId: parent.communityId,
        userId: currentUser.id,
        user: currentUser,
        title: 'Reply',
        content: content,
        scope: parent.scope,
        chapterTitle: parent.chapterTitle,
        chapterIndex: parent.chapterIndex,
        quoteText: parent.quoteText,
        createdAt: DateTime.now(),
      );
      final existingReplies = parent.replies ?? [];
      _discussions[index] = Discussion(
        id: parent.id,
        highlightId: parent.highlightId,
        bookId: parent.bookId,
        communityId: parent.communityId,
        userId: parent.userId,
        user: parent.user,
        title: parent.title,
        content: parent.content,
        scope: parent.scope,
        chapterTitle: parent.chapterTitle,
        chapterIndex: parent.chapterIndex,
        quoteText: parent.quoteText,
        rating: parent.rating,
        upvotes: parent.upvotes,
        createdAt: parent.createdAt,
        replies: [...existingReplies, newReply],
        parentTopicId: parent.parentTopicId,
      );
      notifyListeners();
      await _saveDiscussions();
      return newReply;
    }
    return null;
  }

  // --- Topics & Subtopics ---
  List<Discussion> getTopicsForBook(String bookId, {String? communityId}) {
    return _discussions
        .where(
          (d) =>
              (d.bookId == bookId || d.bookId.isEmpty) &&
              (communityId == null ||
                  d.communityId.isEmpty ||
                  d.communityId == communityId) &&
              (d.scope == ThreadScope.topic ||
                  (d.scope == ThreadScope.book && d.title.isNotEmpty)),
        )
        .toList();
  }

  List<Discussion> getSubtopics(String parentTopicId) {
    return _discussions
        .where(
          (d) =>
              d.scope == ThreadScope.subtopic &&
              d.parentTopicId == parentTopicId,
        )
        .toList();
  }

  // --- Chat Messages & Streaming ---
  Future<List<ChatMessage>> getMessages(
    String threadId, {
    int limit = 50,
  }) async {
    if (_threadMessages.containsKey(threadId)) {
      return List.unmodifiable(_threadMessages[threadId]!);
    }

    final raw = _prefs.getStringList('messages_$threadId');
    if (raw != null && raw.isNotEmpty) {
      final list =
          raw
              .map(
                (str) => ChatMessage.fromJson(
                  jsonDecode(str) as Map<String, dynamic>,
                ),
              )
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _threadMessages[threadId] = list;
      return List.unmodifiable(list);
    }

    // Populate from discussions or seed initial conversation
    final List<ChatMessage> initial = [];
    final discussion =
        _discussions.where((d) => d.id == threadId).firstOrNull ??
        _discussions.where((d) => d.highlightId == threadId).firstOrNull;

    if (discussion != null) {
      initial.add(
        ChatMessage(
          id: discussion.id,
          threadId: threadId,
          userId: discussion.userId,
          user: discussion.user,
          content: discussion.content,
          createdAt: discussion.createdAt,
          status: MessageStatus.sent,
          quoteText: discussion.quoteText,
          chapterTitle: discussion.chapterTitle,
          chapterIndex: discussion.chapterIndex,
          cfi: discussion.highlightId,
        ),
      );

      if (discussion.replies != null) {
        for (final reply in discussion.replies!) {
          initial.add(
            ChatMessage(
              id: reply.id,
              threadId: threadId,
              userId: reply.userId,
              user: reply.user,
              content: reply.content,
              createdAt: reply.createdAt,
              status: MessageStatus.sent,
              quoteText: reply.quoteText,
              chapterTitle: reply.chapterTitle,
              chapterIndex: reply.chapterIndex,
              cfi: reply.highlightId,
            ),
          );
        }
      }

      final siblings = _discussions.where(
        (d) => d.highlightId == discussion.highlightId && d.id != discussion.id,
      );
      for (final sib in siblings) {
        initial.add(
          ChatMessage(
            id: sib.id,
            threadId: threadId,
            userId: sib.userId,
            user: sib.user,
            content: sib.content,
            createdAt: sib.createdAt,
            status: MessageStatus.sent,
            quoteText: sib.quoteText,
            chapterTitle: sib.chapterTitle,
            chapterIndex: sib.chapterIndex,
            cfi: sib.highlightId,
          ),
        );
      }
    } else if (threadId.startsWith('general:')) {
      final bookId = threadId.replaceFirst('general:', '');
      final bookThreads = _discussions
          .where((d) => d.bookId == bookId)
          .toList();
      for (final t in bookThreads) {
        initial.add(
          ChatMessage(
            id: t.id,
            threadId: threadId,
            userId: t.userId,
            user: t.user,
            content: t.content,
            createdAt: t.createdAt,
            status: MessageStatus.sent,
            quoteText: t.quoteText,
            chapterTitle: t.chapterTitle,
            chapterIndex: t.chapterIndex,
            cfi: t.highlightId,
          ),
        );
      }
    }

    if (initial.length <= 1) {
      final baseTime =
          discussion?.createdAt ??
          DateTime.now().subtract(const Duration(hours: 3));
      initial.addAll([
        ChatMessage(
          id: '${threadId}_seed_1',
          threadId: threadId,
          userId: 'user-2',
          user: User(
            id: 'user-2',
            username: 'julian',
            displayName: 'Julian Morrow',
            avatarUrl: 'https://i.pravatar.cc/150?u=julian',
          ),
          content:
              'Fascinating perspective! It really changes how you interpret the narrative.',
          createdAt: baseTime.add(const Duration(minutes: 18)),
          status: MessageStatus.sent,
          reactions: {
            '👍': ['user-1', 'user-3'],
          },
        ),
        ChatMessage(
          id: '${threadId}_seed_2',
          threadId: threadId,
          userId: 'user-3',
          user: User(
            id: 'user-3',
            username: 'henry',
            displayName: 'Henry Winter',
            avatarUrl: 'https://i.pravatar.cc/150?u=henry',
          ),
          content:
              'I agree with Julian. In classical literature this tension is always present between fate and desire.',
          replyToId: '${threadId}_seed_1',
          replyToContent:
              'Fascinating perspective! It really changes how you interpret...',
          replyToAuthor: 'Julian Morrow',
          createdAt: baseTime.add(const Duration(minutes: 34)),
          status: MessageStatus.sent,
          reactions: {
            '❤️': ['user-2'],
          },
        ),
      ]);
    }

    initial.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _threadMessages[threadId] = initial;
    await _saveMessagesForThread(threadId);
    return List.unmodifiable(initial);
  }

  Stream<List<ChatMessage>> watchMessages(String threadId) {
    if (!_threadStreamControllers.containsKey(threadId) ||
        _threadStreamControllers[threadId]!.isClosed) {
      _threadStreamControllers[threadId] =
          StreamController<List<ChatMessage>>.broadcast();
    }
    getMessages(threadId).then((msgs) {
      if (_threadStreamControllers.containsKey(threadId) &&
          !_threadStreamControllers[threadId]!.isClosed) {
        _threadStreamControllers[threadId]!.add(List.unmodifiable(msgs));
      }
    });
    return _threadStreamControllers[threadId]!.stream;
  }

  Future<ChatMessage> addChatMessage({
    required String threadId,
    required String content,
    String? replyToId,
    String? replyToContent,
    String? replyToAuthor,
    bool isSpoiler = false,
    String? quoteText,
    String? chapterTitle,
    int? chapterIndex,
    String? cfi,
  }) async {
    final messages = (await getMessages(threadId)).toList();
    final newMsg = ChatMessage(
      id: _uuid.v4(),
      threadId: threadId,
      userId: currentUser.id,
      user: currentUser,
      content: content,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
      replyToId: replyToId,
      replyToContent: replyToContent,
      replyToAuthor: replyToAuthor,
      isSpoiler: isSpoiler,
      quoteText: quoteText,
      chapterTitle: chapterTitle,
      chapterIndex: chapterIndex,
      cfi: cfi,
    );
    messages.add(newMsg);
    _threadMessages[threadId] = messages;
    await _saveMessagesForThread(threadId);

    // Keep discussion replies synchronized
    final parentIndex = _discussions.indexWhere((d) => d.id == threadId);
    if (parentIndex != -1) {
      final parent = _discussions[parentIndex];
      final currentReplies = parent.replies ?? [];
      _discussions[parentIndex] = parent.copyWith(
        replies: [
          ...currentReplies,
          Discussion(
            id: newMsg.id,
            highlightId: parent.highlightId,
            bookId: parent.bookId,
            communityId: parent.communityId,
            userId: currentUser.id,
            user: currentUser,
            title: 'Reply',
            content: content,
            scope: parent.scope,
            chapterTitle: chapterTitle ?? parent.chapterTitle,
            chapterIndex: chapterIndex ?? parent.chapterIndex,
            quoteText: quoteText ?? parent.quoteText,
            createdAt: newMsg.createdAt,
          ),
        ],
      );
      await _saveDiscussions();
    }

    if (_threadStreamControllers.containsKey(threadId) &&
        !_threadStreamControllers[threadId]!.isClosed) {
      _threadStreamControllers[threadId]!.add(List.unmodifiable(messages));
    }
    notifyListeners();
    return newMsg;
  }

  Future<void> toggleReaction({
    required String threadId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    final messages = (await getMessages(threadId)).toList();
    final idx = messages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      final msg = messages[idx];
      final currentReactions = Map<String, List<String>>.from(
        msg.reactions.map((k, v) => MapEntry(k, List<String>.from(v))),
      );
      final users = currentReactions[emoji] ?? [];
      if (users.contains(userId)) {
        users.remove(userId);
        if (users.isEmpty) {
          currentReactions.remove(emoji);
        } else {
          currentReactions[emoji] = users;
        }
      } else {
        users.add(userId);
        currentReactions[emoji] = users;
      }
      messages[idx] = msg.copyWith(reactions: currentReactions);
      _threadMessages[threadId] = messages;
      await _saveMessagesForThread(threadId);

      if (_threadStreamControllers.containsKey(threadId) &&
          !_threadStreamControllers[threadId]!.isClosed) {
        _threadStreamControllers[threadId]!.add(List.unmodifiable(messages));
      }
      notifyListeners();
    }
  }

  Future<void> _saveMessagesForThread(String threadId) async {
    final list = _threadMessages[threadId] ?? [];
    final jsonList = list.map((m) => jsonEncode(m.toJson())).toList();
    await _prefs.setStringList('messages_$threadId', jsonList);
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

  // --- Community Membership & Member Management ---
  bool isMemberOfCommunity(String communityId) {
    return _joinedCommunityIds.contains(communityId);
  }

  void _syncCommunityMemberCount(String communityId) {
    final commIdx = communities.indexWhere((c) => c.id == communityId);
    if (commIdx != -1) {
      final members = _communityMembersByCommunityId[communityId] ?? [];
      final activeCount = members.where((m) => !m.isBanned).length;
      final old = communities[commIdx];
      communities[commIdx] = Community(
        id: old.id,
        name: old.name,
        description: old.description,
        bookId: old.bookId,
        memberCount: activeCount > 0 ? activeCount : old.memberCount,
        creatorId: old.creatorId,
      );
      _saveCommunities();
      _markCommunityCatalogChanged();
    }
  }

  void _markCommunityCatalogChanged() {
    communityCatalogRevision.value++;
  }

  static int _compareCommunityMembers(CommunityMember a, CommunityMember b) {
    if (a.isCreator && !b.isCreator) return -1;
    if (!a.isCreator && b.isCreator) return 1;
    if (a.role == CommunityRole.admin && b.role != CommunityRole.admin) {
      return -1;
    }
    if (a.role != CommunityRole.admin && b.role == CommunityRole.admin) {
      return 1;
    }
    return a.user.displayName.compareTo(b.user.displayName);
  }

  void _sortCommunityMembers(String communityId) {
    _communityMembersByCommunityId[communityId]?.sort(_compareCommunityMembers);
  }

  void _sortAllCommunityMembers() {
    for (final communityId in _communityMembersByCommunityId.keys) {
      _sortCommunityMembers(communityId);
    }
  }

  Future<void> joinCommunity(String communityId) async {
    if (!communities.any((community) => community.id == communityId)) return;
    if (!isMemberOfCommunity(communityId)) {
      _joinedCommunityIds.add(communityId);
      await _saveJoinedCommunities();
      await addMember(communityId, currentUser, role: CommunityRole.member);
      notifyListeners();
    }
  }

  Future<void> leaveCommunity(String communityId) async {
    _joinedCommunityIds.remove(communityId);
    _selectedCommunityIdsByBook.removeWhere(
      (bookId, selectedId) => selectedId == communityId,
    );
    await removeMember(communityId, currentUser.id);
    await _saveJoinedCommunities();
    await _saveSelectedCommunities();
    notifyListeners();
  }

  Future<Community> createCommunity({
    required String name,
    required String description,
    required String bookId,
    String? importMembersFromCommunityId,
    bool copyRoles = true,
    bool copyPermissions = true,
    bool skipRestrictedOrBanned = true,
  }) async {
    final newId = _uuid.v4();
    final newComm = Community(
      id: newId,
      name: name,
      description: description,
      bookId: bookId,
      memberCount: 1,
      creatorId: currentUser.id,
    );
    communities.add(newComm);
    _markCommunityCatalogChanged();
    if (!_joinedCommunityIds.contains(newId)) {
      _joinedCommunityIds.add(newId);
      await _saveJoinedCommunities();
    }
    await _saveCommunities();
    await addMember(newId, currentUser, role: CommunityRole.creator);

    if (importMembersFromCommunityId != null &&
        importMembersFromCommunityId.isNotEmpty) {
      await importMembers(
        targetCommunityId: newId,
        sourceCommunityId: importMembersFromCommunityId,
        copyRoles: copyRoles,
        copyPermissions: copyPermissions,
        skipRestrictedOrBanned: skipRestrictedOrBanned,
      );
    }

    notifyListeners();
    return communities.firstWhere((c) => c.id == newId, orElse: () => newComm);
  }

  Future<int> importMembers({
    required String targetCommunityId,
    required String sourceCommunityId,
    bool copyRoles = true,
    bool copyPermissions = true,
    bool skipRestrictedOrBanned = true,
  }) async {
    final sourceMembers =
        _communityMembersByCommunityId[sourceCommunityId] ?? [];
    if (sourceMembers.isEmpty) return 0;

    final targetList = _communityMembersByCommunityId.putIfAbsent(
      targetCommunityId,
      () => [],
    );
    final existingUserIds = targetList.map((m) => m.user.id).toSet();

    int importedCount = 0;
    for (final src in sourceMembers) {
      if (existingUserIds.contains(src.user.id)) continue;
      if (skipRestrictedOrBanned && (src.isRestricted || src.isBanned)) {
        continue;
      }

      targetList.add(
        CommunityMember(
          id: _uuid.v4(),
          communityId: targetCommunityId,
          user: src.user,
          role: copyRoles
              ? (src.isCreator ? CommunityRole.admin : src.role)
              : CommunityRole.member,
          status: CommunityMemberStatus.active,
          joinedAt: DateTime.now(),
          customPermissions: copyPermissions ? src.customPermissions : null,
        ),
      );
      importedCount++;
    }

    if (importedCount > 0) {
      _sortCommunityMembers(targetCommunityId);
      _syncCommunityMemberCount(targetCommunityId);
      await _saveCommunityMembers(targetCommunityId);
      notifyListeners();
    }
    return importedCount;
  }

  List<CommunityMember> getCommunityMembers(
    String communityId, {
    String? query,
    CommunityMemberStatus? status,
    CommunityRole? role,
  }) {
    final list = _communityMembersByCommunityId[communityId] ?? [];
    final normalizedQuery = query?.trim().toLowerCase();
    return list
        .where((m) {
          if (status != null && m.status != status) return false;
          if (role != null && m.role != role) return false;
          if (normalizedQuery != null && normalizedQuery.isNotEmpty) {
            final matchName = m.user.displayName
                .toLowerCase()
                .contains(normalizedQuery);
            final matchUsername = m.user.username
                .toLowerCase()
                .contains(normalizedQuery);
            return matchName || matchUsername;
          }
          return true;
        })
        .toList(growable: false);
  }

  CommunityMember? getMember(String communityId, String userId) {
    final list = _communityMembersByCommunityId[communityId] ?? [];
    return list.where((m) => m.user.id == userId).firstOrNull;
  }

  bool isCommunityCreator(String communityId, [String? userId]) {
    final targetId = userId ?? currentUser.id;
    final comm = communities.where((c) => c.id == communityId).firstOrNull;
    if (comm != null && comm.creatorId == targetId) return true;
    final member = getMember(communityId, targetId);
    return member?.isCreator ?? false;
  }

  bool isCommunityAdmin(String communityId, [String? userId]) {
    final targetId = userId ?? currentUser.id;
    if (isCommunityCreator(communityId, targetId)) return true;
    final member = getMember(communityId, targetId);
    return member?.isAdmin ?? false;
  }

  bool canManageCommunity(String communityId, [String? userId]) {
    return isCommunityAdmin(communityId, userId);
  }

  Future<CommunityMember> addMember(
    String communityId,
    User user, {
    CommunityRole role = CommunityRole.member,
  }) async {
    final list = _communityMembersByCommunityId.putIfAbsent(
      communityId,
      () => [],
    );
    final existingIdx = list.indexWhere((m) => m.user.id == user.id);
    if (existingIdx != -1) {
      if (role == CommunityRole.creator && !list[existingIdx].isCreator) {
        list[existingIdx] = list[existingIdx].copyWith(
          role: CommunityRole.creator,
        );
        _sortCommunityMembers(communityId);
        await _saveCommunityMembers(communityId);
      }
      return list[existingIdx];
    }
    final member = CommunityMember(
      id: _uuid.v4(),
      communityId: communityId,
      user: user,
      role: role,
      status: CommunityMemberStatus.active,
      joinedAt: DateTime.now(),
    );
    list.add(member);
    _sortCommunityMembers(communityId);
    _syncCommunityMemberCount(communityId);
    await _saveCommunityMembers(communityId);
    notifyListeners();
    return member;
  }

  Future<void> updateMemberRole(
    String communityId,
    String userId,
    CommunityRole newRole,
  ) async {
    final list = _communityMembersByCommunityId[communityId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.user.id == userId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(role: newRole);
      _sortCommunityMembers(communityId);
      await _saveCommunityMembers(communityId);
      notifyListeners();
    }
  }

  Future<void> updateMemberPermissions(
    String communityId,
    String userId,
    Set<CommunityPermission>? permissions,
  ) async {
    final list = _communityMembersByCommunityId[communityId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.user.id == userId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        customPermissions: permissions,
        clearCustomPermissions: permissions == null,
      );
      await _saveCommunityMembers(communityId);
      notifyListeners();
    }
  }

  Future<void> restrictMember(
    String communityId,
    String userId, {
    String? reason,
  }) async {
    final list = _communityMembersByCommunityId[communityId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.user.id == userId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        status: CommunityMemberStatus.restricted,
        restrictionReason: reason ?? 'Restricted by community moderator.',
        restrictedAt: DateTime.now(),
      );
      await _saveCommunityMembers(communityId);
      notifyListeners();
    }
  }

  Future<void> unrestrictMember(String communityId, String userId) async {
    final list = _communityMembersByCommunityId[communityId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.user.id == userId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        status: CommunityMemberStatus.active,
        restrictionReason: null,
        restrictedAt: null,
      );
      await _saveCommunityMembers(communityId);
      notifyListeners();
    }
  }

  Future<void> banMember(
    String communityId,
    String userId, {
    String? reason,
  }) async {
    final list = _communityMembersByCommunityId[communityId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.user.id == userId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        status: CommunityMemberStatus.banned,
        restrictionReason:
            reason ?? 'Banned from community for rule violations.',
        restrictedAt: DateTime.now(),
      );
      _syncCommunityMemberCount(communityId);
      await _saveCommunityMembers(communityId);
      notifyListeners();
    }
  }

  Future<void> unbanMember(String communityId, String userId) async {
    final list = _communityMembersByCommunityId[communityId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.user.id == userId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        status: CommunityMemberStatus.active,
        restrictionReason: null,
        restrictedAt: null,
      );
      _syncCommunityMemberCount(communityId);
      await _saveCommunityMembers(communityId);
      notifyListeners();
    }
  }

  Future<void> removeMember(String communityId, String userId) async {
    final list = _communityMembersByCommunityId[communityId];
    if (list == null) return;
    list.removeWhere((m) => m.user.id == userId);
    _syncCommunityMemberCount(communityId);
    await _saveCommunityMembers(communityId);
    notifyListeners();
  }

  List<User> getAvailableUsersToInvite(String communityId) {
    final memberUserIds = (_communityMembersByCommunityId[communityId] ?? [])
        .map((m) => m.user.id)
        .toSet();
    return _directoryUsers.where((u) => !memberUserIds.contains(u.id)).toList();
  }

  // --- Live Reading Sessions ---
  LiveReadingSession? getActiveLiveReadingSession(String communityId) {
    return _activeLiveSessions[communityId];
  }

  Future<LiveReadingSession> startLiveReadingSession({
    required String communityId,
    required String bookId,
    required String title,
    String? currentCfi,
    String? chapterTitle,
    int? chapterIndex,
    LiveReadingAccessMode accessMode = LiveReadingAccessMode.allMembers,
    Set<String> allowedUserIds = const {},
  }) async {
    final session = LiveReadingSession(
      id: _uuid.v4(),
      communityId: communityId,
      bookId: bookId,
      title: title,
      host: currentUser,
      currentCfi: currentCfi,
      chapterTitle: chapterTitle,
      chapterIndex: chapterIndex,
      isActive: true,
      startedAt: DateTime.now(),
      accessMode: accessMode,
      allowedUserIds: allowedUserIds,
      commenterUserIds: {currentUser.id},
      participantUserIds: {currentUser.id},
    );
    _activeLiveSessions[communityId] = session;
    await _saveLiveSession(communityId);
    notifyListeners();
    return session;
  }

  Future<void> endLiveReadingSession(String communityId) async {
    _activeLiveSessions.remove(communityId);
    await _saveLiveSession(communityId);
    notifyListeners();
  }

  Future<void> updateLiveReadingSession(LiveReadingSession session) async {
    _activeLiveSessions[session.communityId] = session;
    await _saveLiveSession(session.communityId);
    notifyListeners();
  }

  bool canUserJoinLiveReading(String communityId, String userId) {
    final session = _activeLiveSessions[communityId];
    if (session == null || !session.isActive) return false;
    final member = getMember(communityId, userId);
    final isElevated = member?.isElevated ?? false;
    final isRestricted = member?.isRestricted ?? false;
    final isBanned = member?.isBanned ?? false;
    return session.canUserJoin(
      userId,
      isElevated: isElevated,
      isRestricted: isRestricted,
      isBanned: isBanned,
    );
  }

  bool canUserCommentInLiveReading(String communityId, String userId) {
    final session = _activeLiveSessions[communityId];
    if (session == null || !session.isActive) return false;
    final member = getMember(communityId, userId);
    final isElevated = member?.isElevated ?? false;
    final isRestricted = member?.isRestricted ?? false;
    final isBanned = member?.isBanned ?? false;
    return session.canUserComment(
      userId,
      isElevated: isElevated,
      isRestricted: isRestricted,
      isBanned: isBanned,
    );
  }

  Future<void> joinLiveReadingSession(String communityId, String userId) async {
    final session = _activeLiveSessions[communityId];
    if (session == null) return;
    if (canUserJoinLiveReading(communityId, userId)) {
      final updated = session.copyWith(
        participantUserIds: {...session.participantUserIds, userId},
      );
      await updateLiveReadingSession(updated);
    }
  }

  Future<void> leaveLiveReadingSession(
    String communityId,
    String userId,
  ) async {
    final session = _activeLiveSessions[communityId];
    if (session == null) return;
    final newParticipants = Set<String>.from(session.participantUserIds)
      ..remove(userId);
    final updated = session.copyWith(participantUserIds: newParticipants);
    await updateLiveReadingSession(updated);
  }

  Future<void> toggleLiveCommenter(String communityId, String userId) async {
    final session = _activeLiveSessions[communityId];
    if (session == null) return;
    final newCommenters = Set<String>.from(session.commenterUserIds);
    if (newCommenters.contains(userId)) {
      newCommenters.remove(userId);
    } else {
      newCommenters.add(userId);
    }
    final updated = session.copyWith(commenterUserIds: newCommenters);
    await updateLiveReadingSession(updated);
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
    final isJoinedForBook = getJoinedCommunitiesForBook(
      bookId,
    ).any((community) => community.id == communityId);
    if (!isJoinedForBook) return;
    _selectedCommunityIdsByBook[bookId] = communityId;
    await _saveSelectedCommunities();
    notifyListeners();
  }

  @override
  void dispose() {
    communityCatalogRevision.dispose();
    for (final controller in _threadStreamControllers.values) {
      controller.close();
    }
    super.dispose();
  }
}
