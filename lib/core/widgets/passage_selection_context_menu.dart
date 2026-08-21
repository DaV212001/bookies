import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PassageSelectionContextMenu extends StatelessWidget {
  final String selectedText;
  final VoidCallback onExpandSelection;
  final VoidCallback onShortenSelection;
  final bool canExpand;
  final bool canShorten;
  final VoidCallback onStartThread;
  final VoidCallback onRatePassage;
  final VoidCallback onSaveQuote;
  final VoidCallback onHighlight;
  final VoidCallback onDismiss;

  const PassageSelectionContextMenu({
    super.key,
    required this.selectedText,
    required this.onExpandSelection,
    required this.onShortenSelection,
    this.canExpand = true,
    this.canShorten = true,
    required this.onStartThread,
    required this.onRatePassage,
    required this.onSaveQuote,
    required this.onHighlight,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      constraints: BoxConstraints(
        maxWidth: screenWidth - 32,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selected Passage Preview & Range Controls Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFB45309).withValues(alpha: 0.08), // Warm Ochre tint
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                ),
                left: const BorderSide(
                  color: Color(0xFFB45309), // Ochre left border highlight
                  width: 4,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.textSelect,
                          size: 14,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SELECTED PASSAGE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFFB45309),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Shorten Selection Button
                        _buildAdjustButton(
                          context,
                          icon: LucideIcons.minus,
                          label: 'Shorten',
                          onTap: canShorten ? onShortenSelection : null,
                        ),
                        const SizedBox(width: 6),
                        // Expand Selection Button
                        _buildAdjustButton(
                          context,
                          icon: LucideIcons.plus,
                          label: 'Expand',
                          onTap: canExpand ? onExpandSelection : null,
                        ),
                        const SizedBox(width: 8),
                        // Close / Dismiss Button
                        InkWell(
                          onTap: onDismiss,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              LucideIcons.x,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '"$selectedText"',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // Action Toolbar Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    context,
                    icon: LucideIcons.messageSquarePlus,
                    label: 'Start Thread',
                    color: const Color(0xFFB45309),
                    onTap: onStartThread,
                  ),
                  _buildDivider(theme),
                  _buildActionButton(
                    context,
                    icon: LucideIcons.star,
                    label: 'Rate',
                    onTap: onRatePassage,
                  ),
                  _buildDivider(theme),
                  _buildActionButton(
                    context,
                    icon: LucideIcons.quote,
                    label: 'Save Quote',
                    onTap: onSaveQuote,
                  ),
                  _buildDivider(theme),
                  _buildActionButton(
                    context,
                    icon: LucideIcons.highlighter,
                    label: 'Highlight',
                    onTap: onHighlight,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFFB45309).withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? const Color(0xFFB45309).withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: enabled ? const Color(0xFFB45309) : theme.disabledColor,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: enabled ? const Color(0xFFB45309) : theme.disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      height: 18,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: theme.colorScheme.outline.withValues(alpha: 0.2),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: effectiveColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
