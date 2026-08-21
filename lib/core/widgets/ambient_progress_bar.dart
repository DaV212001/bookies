import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AmbientProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0

  const AmbientProgressBar({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final readerColors = Theme.of(context).extension<ReaderColors>();
    
    return Container(
      width: double.infinity,
      height: 4.0,
      alignment: Alignment.centerLeft,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth * progress.clamp(0.0, 1.0),
            height: 4.0,
            color: readerColors?.progressFill ?? Colors.transparent,
          );
        },
      ),
    );
  }
}
