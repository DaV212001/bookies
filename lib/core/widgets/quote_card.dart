import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class QuoteCard extends StatelessWidget {
  final String text;

  const QuoteCard({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final readerColors = Theme.of(context).extension<ReaderColors>();
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m), // 24.0
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: readerColors?.quoteBorder ?? Colors.transparent,
            width: 4.0,
          ),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
