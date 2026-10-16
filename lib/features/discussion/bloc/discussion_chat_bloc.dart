import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter_readium/flutter_readium.dart';
import 'package:uuid/uuid.dart';

import 'package:bookies/data/models/chat_message.dart';
import 'package:bookies/data/models/user.dart';
import 'package:bookies/data/repositories/discussion_repository.dart';
import 'discussion_chat_event.dart';
import 'discussion_chat_state.dart';

class DiscussionChatBloc
    extends Bloc<DiscussionChatEvent, DiscussionChatState> {
  final DiscussionRepository _repository;
  final User currentUser;
  final _uuid = const Uuid();
  StreamSubscription<List<ChatMessage>>? _messageSubscription;
  String _activeThreadId = '';

  DiscussionChatBloc({
    required DiscussionRepository repository,
    required this.currentUser,
  })  : _repository = repository,
        super(const DiscussionChatState()) {
    on<InitializeChat>(_onInitializeChat);
    on<SendMessage>(_onSendMessage);
    on<SelectReplyMessage>(_onSelectReplyMessage);
    on<ToggleReaction>(_onToggleReaction);
    on<RevealSpoilerWarning>(_onRevealSpoilerWarning);
    on<OnMessagesReceived>(_onMessagesReceived);
  }

  void _onInitializeChat(
    InitializeChat event,
    Emitter<DiscussionChatState> emit,
  ) async {
    await _messageSubscription?.cancel();

    // Resolve thread identifier
    _activeThreadId = event.discussion.highlightId.startsWith('general:')
        ? event.discussion.highlightId
        : (event.discussion.id.isNotEmpty
            ? event.discussion.id
            : event.discussion.highlightId);

    // Progression & Spoiler Evaluation
    bool isSpoiler = false;
    if (event.discussion.chapterIndex != null &&
        event.currentReaderChapter != null) {
      isSpoiler = event.discussion.chapterIndex! > event.currentReaderChapter!;
    } else if (event.currentReaderCfi?.isNotEmpty == true &&
        event.discussion.highlightId.isNotEmpty &&
        !event.discussion.highlightId.startsWith('general:')) {
      try {
        final targetLocator =
            Locator.fromJsonString(event.discussion.highlightId);
        final currentLocator =
            Locator.fromJsonString(event.currentReaderCfi!);
        final targetProgress =
            targetLocator?.locations?.totalProgression ?? 0.0;
        final currentProgress =
            currentLocator?.locations?.totalProgression ?? 0.0;
        isSpoiler = targetProgress > (currentProgress + 0.001);
      } catch (_) {
        // Fallback
        isSpoiler = false;
      }
    }

    emit(
      state.copyWith(
        status: DiscussionChatStatus.loading,
        discussion: event.discussion,
        isSpoilerThread: isSpoiler,
        spoilerRevealed: !isSpoiler,
      ),
    );

    try {
      final initialMessages = await _repository.getMessages(_activeThreadId);
      final sorted = initialMessages.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      emit(
        state.copyWith(
          status: DiscussionChatStatus.loaded,
          messages: sorted,
        ),
      );

      _messageSubscription =
          _repository.watchMessages(_activeThreadId).listen((messages) {
        add(OnMessagesReceived(messages));
      });
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscussionChatStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onSendMessage(
    SendMessage event,
    Emitter<DiscussionChatState> emit,
  ) async {
    final text = event.content.trim();
    if (text.isEmpty || state.discussion == null) return;

    final replyingTo = state.replyingTo;

    // Optimistic UI Message
    final optimisticMessage = ChatMessage(
      id: _uuid.v4(),
      threadId: _activeThreadId,
      userId: currentUser.id,
      user: currentUser,
      content: text,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
      replyToId: replyingTo?.id,
      replyToContent: replyingTo?.content,
      replyToAuthor: replyingTo?.user?.displayName,
      isSpoiler: event.isSpoiler,
      quoteText: state.discussion?.quoteText,
      chapterTitle: state.discussion?.chapterTitle,
      chapterIndex: state.discussion?.chapterIndex,
      cfi: state.discussion?.highlightId,
    );

    final updated = [optimisticMessage, ...state.messages];
    emit(
      state.copyWith(
        messages: updated,
        isSending: true,
        clearReplyingTo: true,
      ),
    );

    try {
      await _repository.sendMessage(
        threadId: _activeThreadId,
        content: text,
        replyToId: replyingTo?.id,
        replyToContent: replyingTo?.content,
        replyToAuthor: replyingTo?.user?.displayName,
        isSpoiler: event.isSpoiler,
        quoteText: state.discussion?.quoteText,
        chapterTitle: state.discussion?.chapterTitle,
        chapterIndex: state.discussion?.chapterIndex,
        cfi: state.discussion?.highlightId,
      );
      emit(state.copyWith(isSending: false));
    } catch (e) {
      emit(
        state.copyWith(
          isSending: false,
          errorMessage: 'Failed to send: $e',
        ),
      );
    }
  }

  void _onSelectReplyMessage(
    SelectReplyMessage event,
    Emitter<DiscussionChatState> emit,
  ) {
    emit(state.copyWith(replyingTo: event.message, clearReplyingTo: event.message == null));
  }

  void _onToggleReaction(
    ToggleReaction event,
    Emitter<DiscussionChatState> emit,
  ) async {
    try {
      await _repository.toggleReaction(
        threadId: _activeThreadId,
        messageId: event.messageId,
        emoji: event.emoji,
        userId: currentUser.id,
      );
    } catch (_) {}
  }

  void _onRevealSpoilerWarning(
    RevealSpoilerWarning event,
    Emitter<DiscussionChatState> emit,
  ) {
    emit(state.copyWith(spoilerRevealed: true));
  }

  void _onMessagesReceived(
    OnMessagesReceived event,
    Emitter<DiscussionChatState> emit,
  ) {
    final sorted = event.messages.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    emit(
      state.copyWith(
        status: DiscussionChatStatus.loaded,
        messages: sorted,
      ),
    );
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}
