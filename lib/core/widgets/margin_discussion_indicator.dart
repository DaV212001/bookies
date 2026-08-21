import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MarginDiscussionIndicator extends StatelessWidget {
  final VoidCallback? onTap;

  const MarginDiscussionIndicator({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final readerColors = Theme.of(context).extension<ReaderColors>();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20.0,
        height: 20.0,
        decoration: BoxDecoration(
          color: readerColors?.annotationFill,
          shape: BoxShape.circle,
          border: Border.all(
            color: readerColors?.annotationBorder ?? Colors.transparent,
            width: 1.0,
          ),
        ),
        // Just an icon or indicator center
        child: Icon(
          Icons.chat_bubble_outline,
          size: 10.0,
          color: readerColors?.annotationBorder,
        ),
      ),
    );
  }
}
