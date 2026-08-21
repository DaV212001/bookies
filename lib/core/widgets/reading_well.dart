import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class ReadingWell extends StatelessWidget {
  final Widget child;

  const ReadingWell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSpacing.readingWell,
        ),
        child: child,
      ),
    );
  }
}
