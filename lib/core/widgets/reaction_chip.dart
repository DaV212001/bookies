import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class ReactionChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const ReactionChip({
    super.key,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final readerColors = Theme.of(context).extension<ReaderColors>();
    final activeFill = AppColors.secondary;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isActive ? activeFill : readerColors?.reactionBackground,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isActive ? activeFill : (readerColors?.reactionBorder ?? Colors.transparent),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isActive ? Colors.white : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
