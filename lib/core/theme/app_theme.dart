import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get parchmentLight {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.parchmentBackground,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        onPrimary: AppColors.onPrimary,
        onPrimaryContainer: const Color(0xFFF8F9FF),
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondary: AppColors.onSecondary,
        onSecondaryContainer: const Color(0xFFFFFFFF),
        surface: AppColors.parchmentSurface,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerHighest: const Color(0xFFD3E4FE),
        onSurface: AppColors.parchmentTextPrimary,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.parchmentBorder,
        outlineVariant: AppColors.outlineVariant,
        error: AppColors.error,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: const Color(0xFFB45309).withValues(alpha: 0.3), // Warm Ochre highlight tint
        selectionHandleColor: const Color(0xFFB45309), // Ochre teardrop handle pin color
        cursorColor: const Color(0xFFB45309),
      ),
      textTheme: AppTypography.getTextTheme().apply(
        bodyColor: AppColors.parchmentTextPrimary,
        displayColor: AppColors.parchmentTextPrimary,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        ReaderColors(
          highlightFill: AppColors.highlightLightFill,
          highlightUnderline: AppColors.highlightLightUnderline,
          annotationFill: AppColors.annotationMarkerFill,
          annotationBorder: AppColors.annotationMarkerBorder,
          quoteBorder: AppColors.quoteCardLeftBorder,
          discussionFill: AppColors.discussionAnchorFill,
          discussionText: AppColors.discussionAnchorText,
          progressFill: AppColors.readingProgressFill,
          reactionBackground: AppColors.inlineReactionBackground,
          reactionBorder: AppColors.inlineReactionBorder,
        ),
      ],
    );
  }

  static ThemeData get sepiaWarm {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.sepiaBackground,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF4A2810),
        primaryContainer: const Color(0xFFE2D4B7),
        onPrimary: AppColors.onPrimary,
        onPrimaryContainer: const Color(0xFF2D241E),
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondary: AppColors.onSecondary,
        onSecondaryContainer: const Color(0xFFFFFFFF),
        surface: AppColors.sepiaSurface,
        surfaceContainerLow: const Color(0xFFE8DCBD),
        surfaceContainerLowest: const Color(0xFFF7F1DF),
        surfaceContainerHighest: const Color(0xFFDFD1AA),
        onSurface: AppColors.sepiaTextPrimary,
        onSurfaceVariant: const Color(0xFF6B5848),
        outline: AppColors.sepiaBorder,
        outlineVariant: const Color(0xFFC5B496),
        error: AppColors.error,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF4A2810),
        foregroundColor: Color(0xFFF7F1DF),
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: const Color(0xFFB45309).withValues(alpha: 0.35),
        selectionHandleColor: const Color(0xFFB45309),
        cursorColor: const Color(0xFFB45309),
      ),
      textTheme: AppTypography.getTextTheme().apply(
        bodyColor: AppColors.sepiaTextPrimary,
        displayColor: AppColors.sepiaTextPrimary,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        ReaderColors(
          highlightFill: AppColors.highlightLightFill,
          highlightUnderline: AppColors.highlightLightUnderline,
          annotationFill: AppColors.annotationMarkerFill,
          annotationBorder: AppColors.annotationMarkerBorder,
          quoteBorder: AppColors.quoteCardLeftBorder,
          discussionFill: AppColors.discussionAnchorFill,
          discussionText: AppColors.discussionAnchorText,
          progressFill: AppColors.readingProgressFill,
          reactionBackground: AppColors.inlineReactionBackground,
          reactionBorder: AppColors.inlineReactionBorder,
        ),
      ],
    );
  }

  static ThemeData get charcoalNight {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.charcoalBackground,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFFF8F9FF),
        primaryContainer: const Color(0xFF1E293B),
        onPrimary: AppColors.primary,
        onPrimaryContainer: const Color(0xFFF8F9FF),
        secondary: const Color(0xFFFD8A42),
        secondaryContainer: const Color(0xFF522200),
        onSecondary: const Color(0xFFFFFFFF),
        onSecondaryContainer: const Color(0xFFFFDBC9),
        surface: AppColors.charcoalSurface,
        surfaceContainerLow: const Color(0xFF161E2E),
        surfaceContainerLowest: const Color(0xFF0F172A),
        surfaceContainerHighest: const Color(0xFF334155),
        onSurface: AppColors.charcoalTextPrimary,
        onSurfaceVariant: const Color(0xFF94A3B8),
        outline: AppColors.charcoalBorder,
        outlineVariant: const Color(0xFF334155),
        error: AppColors.error,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFD8A42),
        foregroundColor: Color(0xFF121826),
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: const Color(0xFFFD8A42).withValues(alpha: 0.35),
        selectionHandleColor: const Color(0xFFFD8A42),
        cursorColor: const Color(0xFFFD8A42),
      ),
      textTheme: AppTypography.getTextTheme().apply(
        bodyColor: AppColors.charcoalTextPrimary,
        displayColor: AppColors.charcoalTextPrimary,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        ReaderColors(
          highlightFill: AppColors.highlightLightFill,
          highlightUnderline: AppColors.highlightLightUnderline,
          annotationFill: AppColors.annotationMarkerFill,
          annotationBorder: AppColors.annotationMarkerBorder,
          quoteBorder: AppColors.quoteCardLeftBorder,
          discussionFill: AppColors.discussionAnchorFill,
          discussionText: AppColors.discussionAnchorText,
          progressFill: AppColors.readingProgressFill,
          reactionBackground: AppColors.charcoalSurface,
          reactionBorder: AppColors.charcoalBorder,
        ),
      ],
    );
  }

  static ThemeData get oledDark {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF000000),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFFF8F9FF),
        primaryContainer: const Color(0xFF121212),
        onPrimary: AppColors.primary,
        onPrimaryContainer: const Color(0xFFF8F9FF),
        secondary: const Color(0xFFFD8A42),
        secondaryContainer: const Color(0xFF522200),
        onSecondary: const Color(0xFFFFFFFF),
        onSecondaryContainer: const Color(0xFFFFDBC9),
        surface: const Color(0xFF121212),
        surfaceContainerLow: const Color(0xFF0A0A0A),
        surfaceContainerLowest: const Color(0xFF000000),
        surfaceContainerHighest: const Color(0xFF1E1E1E),
        onSurface: const Color(0xFFE5E7EB),
        onSurfaceVariant: const Color(0xFF9CA3AF),
        outline: const Color(0xFF27272A),
        outlineVariant: const Color(0xFF18181B),
        error: AppColors.error,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFD8A42),
        foregroundColor: Color(0xFF000000),
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: const Color(0xFFFD8A42).withValues(alpha: 0.35),
        selectionHandleColor: const Color(0xFFFD8A42),
        cursorColor: const Color(0xFFFD8A42),
      ),
      textTheme: AppTypography.getTextTheme().apply(
        bodyColor: const Color(0xFFE5E7EB),
        displayColor: const Color(0xFFE5E7EB),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        ReaderColors(
          highlightFill: AppColors.highlightLightFill,
          highlightUnderline: AppColors.highlightLightUnderline,
          annotationFill: AppColors.annotationMarkerFill,
          annotationBorder: AppColors.annotationMarkerBorder,
          quoteBorder: AppColors.quoteCardLeftBorder,
          discussionFill: AppColors.discussionAnchorFill,
          discussionText: AppColors.discussionAnchorText,
          progressFill: AppColors.readingProgressFill,
          reactionBackground: Color(0xFF121212),
          reactionBorder: Color(0xFF27272A),
        ),
      ],
    );
  }
}
