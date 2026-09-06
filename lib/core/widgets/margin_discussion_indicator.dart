import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MarginDiscussionIndicator extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final int count;

  const MarginDiscussionIndicator({
    super.key,
    this.onTap,
    this.onLongPress,
    this.count = 1,
  });

  int _heatTier(int count) {
    if (count <= 2) return 1;
    if (count <= 9) return 2;
    if (count <= 29) return 3;
    if (count <= 99) return 4;
    if (count <= 499) return 5;
    return 6;
  }

  double _opacityForTier(int tier) {
    switch (tier) {
      case 1:
        return 0.35;
      case 2:
        return 0.50;
      case 3:
        return 0.70;
      case 4:
        return 0.85;
      case 5:
        return 0.95;
      case 6:
      default:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final readerColors = Theme.of(context).extension<ReaderColors>();
    final tier = _heatTier(count);
    final opacity = _opacityForTier(tier);
    final borderColor = readerColors?.annotationBorder ?? const Color(0xFF9B4500);
    final fillColor = readerColors?.annotationFill ?? const Color(0xFFFFDBCA);

    return Tooltip(
      message: '$count ${count == 1 ? 'chat' : 'chats'}',
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: 20.0,
          height: 20.0,
          decoration: BoxDecoration(
            color: fillColor.withValues(alpha: opacity * 0.7),
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor.withValues(alpha: opacity),
              width: tier >= 4 ? 1.5 : 1.0,
            ),
            boxShadow: tier == 6
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.4),
                      blurRadius: 4.0,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            Icons.chat_bubble_outline,
            size: 10.0,
            color: borderColor.withValues(alpha: opacity.clamp(0.4, 1.0)),
          ),
        ),
      ),
    );
  }
}
