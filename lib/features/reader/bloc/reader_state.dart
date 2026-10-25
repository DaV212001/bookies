part of 'reader_bloc.dart';

abstract class ReaderState extends Equatable {
  const ReaderState();
  
  @override
  List<Object?> get props => [];
}

class ReaderInitial extends ReaderState {}

class ReaderLoading extends ReaderState {}

class ReaderLoaded extends ReaderState {
  final Book book;
  final String? currentCfi;
  final double progression;
  final String activeTheme;
  final double fontSize;
  final EPUBPreferences preferences;
  final bool showDiscussionIndicators;
  final List<LiveParticipantProgress> liveParticipants;
  final List<LivePassageReaction> liveReactions;

  const ReaderLoaded({
    required this.book,
    this.currentCfi,
    this.progression = 0,
    this.activeTheme = 'parchment',
    this.fontSize = 20.0,
    this.preferences = const EPUBPreferences(
      scroll: true,
      fontSize: 1.0,
      publisherStyles: false,
      backgroundColor: Color(0xFFFBF9F5),
      textColor: Color(0xFF1F2937),
    ),
    this.showDiscussionIndicators = true,
    this.liveParticipants = const [],
    this.liveReactions = const [],
  });

  ReaderLoaded copyWith({
    Book? book,
    String? currentCfi,
    double? progression,
    String? activeTheme,
    double? fontSize,
    EPUBPreferences? preferences,
    bool? showDiscussionIndicators,
    List<LiveParticipantProgress>? liveParticipants,
    List<LivePassageReaction>? liveReactions,
  }) {
    return ReaderLoaded(
      book: book ?? this.book,
      currentCfi: currentCfi ?? this.currentCfi,
      progression: progression ?? this.progression,
      activeTheme: activeTheme ?? this.activeTheme,
      fontSize: fontSize ?? this.fontSize,
      preferences: preferences ?? this.preferences,
      showDiscussionIndicators:
          showDiscussionIndicators ?? this.showDiscussionIndicators,
      liveParticipants: liveParticipants ?? this.liveParticipants,
      liveReactions: liveReactions ?? this.liveReactions,
    );
  }

  @override
  List<Object?> get props => [
    book,
    currentCfi,
    progression,
    activeTheme,
    fontSize,
    preferences,
    showDiscussionIndicators,
    liveParticipants,
    liveReactions,
  ];
}

class ReaderError extends ReaderState {
  final String message;

  const ReaderError(this.message);

  @override
  List<Object?> get props => [message];
}
