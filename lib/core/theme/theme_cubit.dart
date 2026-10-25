import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/providers/local_data_service.dart';
import 'app_theme.dart';

enum AppThemeMode {
  parchment,
  sepia,
  charcoal,
  oled,
  system,
}

class ThemeState {
  final AppThemeMode mode;
  final ThemeData themeData;

  const ThemeState({
    required this.mode,
    required this.themeData,
  });

  ThemeState copyWith({
    AppThemeMode? mode,
    ThemeData? themeData,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      themeData: themeData ?? this.themeData,
    );
  }
}

class ThemeCubit extends Cubit<ThemeState> {
  final LocalDataService _dataService;

  ThemeCubit(this._dataService)
      : super(ThemeState(
          mode: AppThemeMode.parchment,
          themeData: AppTheme.parchmentLight,
        )) {
    _loadTheme();
  }

  void _loadTheme() {
    final savedTheme = _dataService.getAppTheme();
    if (savedTheme != null) {
      setThemeMode(_parseThemeMode(savedTheme));
    }
  }

  AppThemeMode _parseThemeMode(String name) {
    switch (name.toLowerCase()) {
      case 'sepia':
        return AppThemeMode.sepia;
      case 'charcoal':
      case 'dark':
        return AppThemeMode.charcoal;
      case 'oled':
      case 'black':
        return AppThemeMode.oled;
      case 'system':
        return AppThemeMode.system;
      case 'parchment':
      case 'light':
      default:
        return AppThemeMode.parchment;
    }
  }

  void setThemeMode(AppThemeMode mode) {
    ThemeData themeData;
    String modeName;

    switch (mode) {
      case AppThemeMode.sepia:
        themeData = AppTheme.sepiaWarm;
        modeName = 'sepia';
        break;
      case AppThemeMode.charcoal:
        themeData = AppTheme.charcoalNight;
        modeName = 'charcoal';
        break;
      case AppThemeMode.oled:
        themeData = AppTheme.oledDark;
        modeName = 'oled';
        break;
      case AppThemeMode.system:
        themeData = AppTheme.parchmentLight;
        modeName = 'system';
        break;
      case AppThemeMode.parchment:
        themeData = AppTheme.parchmentLight;
        modeName = 'parchment';
        break;
    }

    _dataService.saveAppTheme(modeName);
    emit(ThemeState(mode: mode, themeData: themeData));
  }
}
