import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_readium/flutter_readium.dart';

import '../../../data/models/discussion.dart';
import '../../../data/providers/local_data_service.dart';

part 'discussion_event.dart';
part 'discussion_state.dart';

class DiscussionBloc extends Bloc<DiscussionEvent, DiscussionState> {
  final LocalDataService _dataService;

  DiscussionBloc(this._dataService) : super(DiscussionInitial()) {
    on<LoadThread>(_onLoadThread);
    on<PostComment>(_onPostComment);
  }

  void _onLoadThread(LoadThread event, Emitter<DiscussionState> emit) async {
    emit(DiscussionLoading());
    try {
      // Compare progressions using Readium Locator
      bool isSpoiler = false;
      if (event.currentReaderCfi.isNotEmpty && event.cfi.isNotEmpty) {
        try {
          final targetLocator = Locator.fromJsonString(event.cfi);
          final currentLocator = Locator.fromJsonString(event.currentReaderCfi);

          final targetProgress =
              targetLocator?.locations?.totalProgression ?? 0.0;
          final currentProgress =
              currentLocator?.locations?.totalProgression ?? 0.0;

          // Add a small buffer to avoid showing spoilers for the exact same page
          isSpoiler = targetProgress > (currentProgress + 0.001);
        } catch (_) {
          // Fallback to basic string comparison if parsing fails
          isSpoiler = event.cfi.compareTo(event.currentReaderCfi) > 0;
        }
      }

      if (isSpoiler) {
        emit(DiscussionSpoilerWarning(event.cfi));
      } else {
        final discussions = _dataService.getDiscussionsForCfi(event.cfi);
        emit(DiscussionLoaded(event.cfi, discussions));
      }
    } catch (e) {
      emit(DiscussionError(e.toString()));
    }
  }

  void _onPostComment(PostComment event, Emitter<DiscussionState> emit) async {
    if (state is DiscussionLoaded) {
      final currentState = state as DiscussionLoaded;
      emit(DiscussionLoading());
      try {
        final newDiscussion = await _dataService.addDiscussion(currentState.cfi, event.text);
        final updatedComments = List<Discussion>.from(currentState.comments)
          ..add(newDiscussion);
        emit(DiscussionLoaded(currentState.cfi, updatedComments));
      } catch (e) {
        emit(DiscussionError(e.toString()));
      }
    }
  }
}
