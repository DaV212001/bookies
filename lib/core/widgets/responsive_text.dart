import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

/// Centralized responsive typography utility ensuring text never clips or
/// prematurely truncates across diverse device sizes while preserving visual hierarchy.
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final double minFontSize;
  final double stepGranularity;
  final TextAlign? textAlign;
  final TextOverflow overflow;
  final AutoSizeGroup? group;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.minFontSize = 12,
    this.stepGranularity = 0.5,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.group,
  });

  /// Large display titles (e.g. community headers, book titles in hero view).
  /// Scales between 18-20pt and 36pt, never dropping below headline size.
  const ResponsiveText.display(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 2,
    this.minFontSize = 18,
    this.stepGranularity = 0.5,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.group,
  });

  /// Section headings, modal titles, and prominent card headers.
  /// Scales between 15pt and 24pt.
  const ResponsiveText.headline(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 2,
    this.minFontSize = 15,
    this.stepGranularity = 0.5,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.group,
  });

  /// Item titles, book titles in cards, thread titles.
  /// Scales between 12.5pt and 18pt.
  const ResponsiveText.title(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 2,
    this.minFontSize = 12.5,
    this.stepGranularity = 0.5,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.group,
  });

  /// Author names, chapter subtitles, channel items.
  /// Scales between 10.5pt and 14pt.
  const ResponsiveText.body(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 2,
    this.minFontSize = 10.5,
    this.stepGranularity = 0.5,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.group,
  });

  /// Badges, presence counts, timestamps, chip labels.
  /// Scales between 9pt and 12pt.
  const ResponsiveText.label(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.minFontSize = 9.5,
    this.stepGranularity = 0.5,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.group,
  });

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      text,
      style: style,
      maxLines: maxLines,
      minFontSize: minFontSize,
      stepGranularity: stepGranularity,
      textAlign: textAlign,
      overflow: overflow,
      group: group,
    );
  }
}
