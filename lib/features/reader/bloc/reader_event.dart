part of 'reader_bloc.dart';

abstract class ReaderEvent extends Equatable {
  const ReaderEvent();

  @override
  List<Object?> get props => [];
}

class LoadBook extends ReaderEvent {
  final Book book;

  const LoadBook(this.book);

  @override
  List<Object?> get props => [book];
}

class UpdateLocator extends ReaderEvent {
  final String cfi;
  final double progression;

  const UpdateLocator(this.cfi, this.progression);

  @override
  List<Object?> get props => [cfi, progression];
}

class UpdateEPUBPreferences extends ReaderEvent {
  final EPUBPreferences preferences;

  const UpdateEPUBPreferences(this.preferences);

  @override
  List<Object?> get props => [preferences];
}

class ChangeTheme extends ReaderEvent {
  final String themeName; // 'parchment', 'sepia', 'charcoal', 'oled'

  const ChangeTheme(this.themeName);

  @override
  List<Object?> get props => [themeName];
}

class ChangeFontSize extends ReaderEvent {
  final double fontSize;

  const ChangeFontSize(this.fontSize);

  @override
  List<Object?> get props => [fontSize];
}

class ToggleScrollMode extends ReaderEvent {
  final bool isScrollMode;

  const ToggleScrollMode(this.isScrollMode);

  @override
  List<Object?> get props => [isScrollMode];
}

class ToggleDiscussionIndicators extends ReaderEvent {
  final bool? enabled;

  const ToggleDiscussionIndicators([this.enabled]);

  @override
  List<Object?> get props => [enabled];
}

class LiveParticipantsUpdatedEvent extends ReaderEvent {
  final List<LiveParticipantProgress> participants;

  const LiveParticipantsUpdatedEvent(this.participants);

  @override
  List<Object?> get props => [participants];
}

class LivePassageReactionReceivedEvent extends ReaderEvent {
  final LivePassageReaction reaction;

  const LivePassageReactionReceivedEvent(this.reaction);

  @override
  List<Object?> get props => [reaction];
}
