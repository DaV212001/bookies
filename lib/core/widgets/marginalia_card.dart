import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class MarginaliaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const MarginaliaCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.m), // 24.0
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg), // 12.0
        border: Border.all(
          color: colorScheme.outline, // 0xFFC5C6CD in light theme
          width: 1.0,
        ),
      ),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyMedium!,
        child: child,
      ),
    );
  }
}
