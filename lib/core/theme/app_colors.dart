import 'package:flutter/material.dart';

class AppColors {
  // Foundation Color Scheme
  static const Color primary = Color(0xFF091426);
  static const Color primaryContainer = Color(0xFF1E293B);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF9B4500);
  static const Color secondaryContainer = Color(0xFFFD8A42);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF45474C);
  static const Color outline = Color(0xFF75777D);
  static const Color outlineVariant = Color(0xFFC5C6CD);
  static const Color error = Color(0xFFBA1A1A);

  // Themes specific
  static const Color parchmentBackground = Color(0xFFF8F9FF);
  static const Color parchmentSurface = Color(0xFFFFFFFF);
  static const Color parchmentTextPrimary = Color(0xFF0B1C30);
  static const Color parchmentBorder = Color(0xFFC5C6CD);

  static const Color sepiaBackground = Color(0xFFF2E9D0);
  static const Color sepiaSurface = Color(0xFFEAE0C5);
  static const Color sepiaTextPrimary = Color(0xFF2D241E);
  static const Color sepiaBorder = Color(0xFFD0BFA1);

  static const Color charcoalBackground = Color(0xFF121826);
  static const Color charcoalSurface = Color(0xFF1E293B);
  static const Color charcoalTextPrimary = Color(0xFFF8F9FF);
  static const Color charcoalBorder = Color(0xFF3C475A);

  // Reader Components
  static const Color highlightLightFill = Color(0x73FFDBCA);
  static const Color highlightLightUnderline = Color(0xFF9B4500);
  
  static const Color annotationMarkerFill = Color(0xFFFFDBCA);
  static const Color annotationMarkerBorder = Color(0xFF9B4500);
  
  static const Color quoteCardLeftBorder = Color(0xFF9B4500);
  
  static const Color discussionAnchorFill = Color(0xFF091426);
  static const Color discussionAnchorText = Color(0xFFFD8A42);
  
  static const Color readingProgressFill = Color(0xFF9B4500);
  
  static const Color inlineReactionBackground = Color(0xFFF8F9FF);
  static const Color inlineReactionBorder = Color(0xFFC5C6CD);
}

class ReaderColors extends ThemeExtension<ReaderColors> {
  final Color highlightFill;
  final Color highlightUnderline;
  final Color annotationFill;
  final Color annotationBorder;
  final Color quoteBorder;
  final Color discussionFill;
  final Color discussionText;
  final Color progressFill;
  final Color reactionBackground;
  final Color reactionBorder;

  const ReaderColors({
    required this.highlightFill,
    required this.highlightUnderline,
    required this.annotationFill,
    required this.annotationBorder,
    required this.quoteBorder,
    required this.discussionFill,
    required this.discussionText,
    required this.progressFill,
    required this.reactionBackground,
    required this.reactionBorder,
  });

  @override
  ThemeExtension<ReaderColors> copyWith({
    Color? highlightFill,
    Color? highlightUnderline,
    Color? annotationFill,
    Color? annotationBorder,
    Color? quoteBorder,
    Color? discussionFill,
    Color? discussionText,
    Color? progressFill,
    Color? reactionBackground,
    Color? reactionBorder,
  }) {
    return ReaderColors(
      highlightFill: highlightFill ?? this.highlightFill,
      highlightUnderline: highlightUnderline ?? this.highlightUnderline,
      annotationFill: annotationFill ?? this.annotationFill,
      annotationBorder: annotationBorder ?? this.annotationBorder,
      quoteBorder: quoteBorder ?? this.quoteBorder,
      discussionFill: discussionFill ?? this.discussionFill,
      discussionText: discussionText ?? this.discussionText,
      progressFill: progressFill ?? this.progressFill,
      reactionBackground: reactionBackground ?? this.reactionBackground,
      reactionBorder: reactionBorder ?? this.reactionBorder,
    );
  }

  @override
  ThemeExtension<ReaderColors> lerp(ThemeExtension<ReaderColors>? other, double t) {
    if (other is! ReaderColors) {
      return this;
    }
    return ReaderColors(
      highlightFill: Color.lerp(highlightFill, other.highlightFill, t)!,
      highlightUnderline: Color.lerp(highlightUnderline, other.highlightUnderline, t)!,
      annotationFill: Color.lerp(annotationFill, other.annotationFill, t)!,
      annotationBorder: Color.lerp(annotationBorder, other.annotationBorder, t)!,
      quoteBorder: Color.lerp(quoteBorder, other.quoteBorder, t)!,
      discussionFill: Color.lerp(discussionFill, other.discussionFill, t)!,
      discussionText: Color.lerp(discussionText, other.discussionText, t)!,
      progressFill: Color.lerp(progressFill, other.progressFill, t)!,
      reactionBackground: Color.lerp(reactionBackground, other.reactionBackground, t)!,
      reactionBorder: Color.lerp(reactionBorder, other.reactionBorder, t)!,
    );
  }
}
