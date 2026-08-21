import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // Keep the app's UI typography compact while preserving its hierarchy.
  static const double _scale = 0.9;

  // Display styles - Playfair Display (Headings, Hero titles)
  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
    fontSize: 48.0 * _scale,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle get displayMedium => GoogleFonts.playfairDisplay(
    fontSize: 32.0 * _scale,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle get displaySmall => GoogleFonts.playfairDisplay(
    fontSize: 28.0 * _scale,
    fontWeight: FontWeight.w700,
  );

  // Headline styles - Playfair Display (Section headers, Book titles)
  static TextStyle get headlineLarge => GoogleFonts.playfairDisplay(
    fontSize: 28.0 * _scale,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get headlineMedium => GoogleFonts.playfairDisplay(
    fontSize: 24.0 * _scale,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get headlineSmall => GoogleFonts.playfairDisplay(
    fontSize: 20.0 * _scale,
    fontWeight: FontWeight.w600,
  );

  // Title styles - Playfair Display for Large / Inter for Medium & Small
  static TextStyle get titleLarge => GoogleFonts.playfairDisplay(
    fontSize: 22.0 * _scale,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get titleMedium =>
      GoogleFonts.inter(fontSize: 16.0 * _scale, fontWeight: FontWeight.w600);

  static TextStyle get titleSmall =>
      GoogleFonts.inter(fontSize: 14.0 * _scale, fontWeight: FontWeight.w600);

  // Body styles - Literata (Serif reading content, quotes, descriptions)
  static TextStyle get bodyLarge => GoogleFonts.literata(
    fontSize: 20.0 * _scale,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static TextStyle get bodyMedium => GoogleFonts.literata(
    fontSize: 16.0 * _scale,
    fontWeight: FontWeight.w400,
    height: 1.625,
  );

  static TextStyle get bodySmall => GoogleFonts.literata(
    fontSize: 14.0 * _scale,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Label / UI styles - Inter (Buttons, metadata, badges, captions)
  static TextStyle get labelLarge =>
      GoogleFonts.inter(fontSize: 14.0 * _scale, fontWeight: FontWeight.w600);

  static TextStyle get labelMedium =>
      GoogleFonts.inter(fontSize: 12.0 * _scale, fontWeight: FontWeight.w600);

  static TextStyle get labelSmall =>
      GoogleFonts.inter(fontSize: 11.0 * _scale, fontWeight: FontWeight.w600);

  static TextTheme getTextTheme() {
    return TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    );
  }
}
