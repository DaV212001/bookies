import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class DiscussionModal extends StatelessWidget {
  final Widget content;

  const DiscussionModal({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: AppSpacing.containerMax,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: content,
        ),
      ),
    );
  }
  
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // For dynamic height if needed
      builder: (context) {
        // Apply a backdrop blur if needed by wrapping in BackdropFilter, 
        // but for now simple modal bottom sheet works nicely.
        return DiscussionModal(content: child);
      },
    );
  }
}
