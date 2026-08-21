import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_readium/flutter_readium.dart';

import '../../../data/models/book.dart';
import '../../../data/providers/local_data_service.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';

part 'reader_event.dart';
part 'reader_state.dart';

class ReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  final LocalDataService _dataService;

  ReaderBloc(this._dataService) : super(ReaderInitial()) {
    on<LoadBook>(_onLoadBook);
    on<UpdateLocator>(_onUpdateLocator);
    on<UpdateEPUBPreferences>(_onUpdateEPUBPreferences);
    on<ToggleScrollMode>(_onToggleScrollMode);
    on<ChangeTheme>(_onChangeTheme);
    on<ChangeFontSize>(_onChangeFontSize);
  }

  EPUBPreferences _loadSavedPreferences() {
    Color bg = AppColors.parchmentBackground;
    Color fg = AppColors.parchmentTextPrimary;

    final savedAppTheme = _dataService.getAppTheme();
    if (savedAppTheme != null) {
      switch (savedAppTheme.toLowerCase()) {
        case 'sepia':
          bg = AppColors.sepiaBackground;
          fg = AppColors.sepiaTextPrimary;
          break;
        case 'charcoal':
        case 'dark':
          bg = AppColors.charcoalBackground;
          fg = AppColors.charcoalTextPrimary;
          break;
        case 'oled':
        case 'black':
          bg = const Color(0xFF000000);
          fg = const Color(0xFFE5E7EB);
          break;
        case 'parchment':
        case 'light':
        default:
          bg = AppColors.parchmentBackground;
          fg = AppColors.parchmentTextPrimary;
          break;
      }
    }

    try {
      final jsonStr = _dataService.getReadingPreferences();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(jsonStr);
        return EPUBPreferences.fromJson(map);
      }
    } catch (e) {
      AppLogger.w('ReaderBloc', 'Error parsing saved preferences: $e');
    }
    return EPUBPreferences(
      scroll: true,
      fontSize: 1.0,
      publisherStyles: false,
      backgroundColor: bg,
      textColor: fg,
    );
  }

  Future<void> _onLoadBook(LoadBook event, Emitter<ReaderState> emit) async {
    AppLogger.i(
      'ReaderBloc',
      'Opening publication for book: ${event.book.title} (path: ${event.book.localPath})',
    );
    emit(ReaderLoading());
    try {
      if (event.book.localPath == null || event.book.localPath!.isEmpty) {
        throw Exception("Book localPath is null or empty");
      }

      final prefs = _loadSavedPreferences();
      final savedProgress = _dataService.getProgress(event.book.id);
      String? initialCfi;
      double initialProgression = 0;
      if (savedProgress != null) {
        final decoded = jsonDecode(savedProgress);
        if (decoded is Map<String, dynamic>) {
          initialCfi = decoded['cfi'] as String?;
          initialProgression = (decoded['progression'] as num?)?.toDouble() ?? 0;
        }
      }

      String activeThemeName = 'parchment';
      if (prefs.backgroundColor != null) {
        final bgVal = prefs.backgroundColor!.value;
        if (bgVal == const Color(0xFF000000).value) {
          activeThemeName = 'oled';
        } else if (bgVal == AppColors.charcoalBackground.value || bgVal == const Color(0xFF1F2430).value) {
          activeThemeName = 'charcoal';
        } else if (bgVal == AppColors.sepiaBackground.value || bgVal == const Color(0xFFF4ECD8).value) {
          activeThemeName = 'sepia';
        } else {
          activeThemeName = 'parchment';
        }
      } else {
        activeThemeName = _dataService.getAppTheme() ?? 'parchment';
      }

      emit(
        ReaderLoaded(
          book: event.book,
          currentCfi: initialCfi,
          progression: initialProgression,
          preferences: prefs,
          activeTheme: activeThemeName,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        'ReaderBloc',
        'Failed to open publication: ${event.book.localPath}',
        e,
        stackTrace,
      );
      emit(ReaderError(e.toString()));
    }
  }

  void _onUpdateLocator(UpdateLocator event, Emitter<ReaderState> emit) {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      final furthestProgress = event.progression > currentState.progression
          ? event.progression
          : currentState.progression;

      // Always remember the user's latest location, including when rereading
      // an earlier chapter. Completion progress remains at the furthest point
      // reached until an explicit reset is implemented/requested.
      _dataService.saveProgress(
        currentState.book.id,
        jsonEncode({'cfi': event.cfi, 'progression': furthestProgress}),
      );

      emit(currentState.copyWith(
        currentCfi: event.cfi,
        progression: furthestProgress,
      ));
    }
  }

  Future<void> _onUpdateEPUBPreferences(
    UpdateEPUBPreferences event,
    Emitter<ReaderState> emit,
  ) async {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      try {
        await FlutterReadium().setEPUBPreferences(event.preferences);
        await _dataService.saveReadingPreferences(
          jsonEncode(event.preferences.toJson()),
        );
        AppLogger.i(
          'ReaderBloc',
          'Updated EPUB preferences: ${event.preferences.toJson()}',
        );
      } catch (e) {
        AppLogger.e('ReaderBloc', 'Failed to set EPUB preferences', e);
      }
      emit(currentState.copyWith(preferences: event.preferences));
    }
  }

  Future<void> _onToggleScrollMode(
    ToggleScrollMode event,
    Emitter<ReaderState> emit,
  ) async {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      final newPrefs = currentState.preferences.copyWith(
        scroll: event.isScrollMode,
      );
      AppLogger.i(
        'ReaderBloc',
        'Reading layout changed to ${event.isScrollMode ? 'continuous vertical scroll' : 'horizontal paginated'}',
      );
      add(UpdateEPUBPreferences(newPrefs));
    }
  }

  Future<void> _onChangeTheme(
    ChangeTheme event,
    Emitter<ReaderState> emit,
  ) async {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      Color bg;
      Color fg;
      switch (event.themeName.toLowerCase()) {
        case 'sepia':
          bg = AppColors.sepiaBackground;
          fg = AppColors.sepiaTextPrimary;
          break;
        case 'charcoal':
        case 'dark':
          bg = AppColors.charcoalBackground;
          fg = AppColors.charcoalTextPrimary;
          break;
        case 'oled':
        case 'black':
          bg = const Color(0xFF000000);
          fg = const Color(0xFFE5E7EB);
          break;
        case 'parchment':
        case 'light':
        default:
          bg = AppColors.parchmentBackground;
          fg = AppColors.parchmentTextPrimary;
          break;
      }

      await _dataService.saveAppTheme(event.themeName);

      final newPrefs = currentState.preferences.copyWith(
        backgroundColor: bg,
        textColor: fg,
        publisherStyles: false,
      );
      add(UpdateEPUBPreferences(newPrefs));
      emit(currentState.copyWith(activeTheme: event.themeName));
    }
  }

  Future<void> _onChangeFontSize(
    ChangeFontSize event,
    Emitter<ReaderState> emit,
  ) async {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      final ratio = (event.fontSize > 5.0
          ? event.fontSize / 16.0
          : event.fontSize).clamp(0.4, 2.5);
      final newPrefs = currentState.preferences.copyWith(
        fontSize: ratio,
        publisherStyles: false,
      );
      emit(currentState.copyWith(preferences: newPrefs, fontSize: ratio));
      try {
        await FlutterReadium().setEPUBPreferences(newPrefs);
        await _dataService.saveReadingPreferences(
          jsonEncode(newPrefs.toJson()),
        );
      } catch (e) {
        AppLogger.e('ReaderBloc', 'Failed to change font size', e);
      }
    }
  }
}
