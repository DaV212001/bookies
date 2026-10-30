import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PassageSelectionContextMenu extends StatelessWidget {
  final String selectedText;
  final VoidCallback onStartThread;
  final VoidCallback onSaveQuote;
  final VoidCallback onHighlight;
  final VoidCallback onDismiss;
  final VoidCallback? onCopy;

  const PassageSelectionContextMenu({
    super.key,
    required this.selectedText,
    required this.onStartThread,
    required this.onSaveQuote,
    required this.onHighlight,
    required this.onDismiss,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    const accentOchre = Color(0xFFB45309);
    final surfaceColor = isDark ? const Color(0xFF1E242B) : const Color(0xFFFCFBF9);
    final headerColor = isDark ? const Color(0xFF262E37) : const Color(0xFFF7F3EE);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE7E1D8);
    final innerBorderColor = isDark ? Colors.white10 : const Color(0xFFEDE7DE);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF78716C);
    final quoteTextColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF332F2B);
    final buttonTextColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF332F2B);

    return Container(
      constraints: BoxConstraints(
        maxWidth: (screenWidth - 32).clamp(280.0, 480.0),
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: accentOchre.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header: Accent indicator + Tag + Quote Preview + Dismiss button
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            decoration: BoxDecoration(
              color: headerColor,
              border: Border(
                bottom: BorderSide(
                  color: innerBorderColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 3,
                          height: 12,
                          decoration: BoxDecoration(
                            color: accentOchre,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'SELECTED PASSAGE',
                          style: TextStyle(
                            color: accentOchre,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: onDismiss,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.x,
                          size: 15,
                          color: textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '“${selectedText.trim()}”',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    height: 1.35,
                    color: quoteTextColor,
                  ),
                ),
              ],
            ),
          ),

          // Action Toolbar Strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Start Thread (Prominent Primary Action)
                _buildThreadButton(
                  context,
                  accentColor: accentOchre,
                  onTap: onStartThread,
                ),

                _buildDivider(isDark),

                // 2. Highlight
                _buildActionButton(
                  context,
                  icon: LucideIcons.highlighter,
                  label: 'Highlight',
                  textColor: buttonTextColor,
                  onTap: onHighlight,
                ),

                _buildDivider(isDark),

                // 3. Save Quote
                _buildActionButton(
                  context,
                  icon: LucideIcons.bookmark,
                  label: 'Save',
                  textColor: buttonTextColor,
                  onTap: onSaveQuote,
                ),

                _buildDivider(isDark),

                // 4. Copy
                _buildActionButton(
                  context,
                  icon: LucideIcons.copy,
                  label: 'Copy',
                  textColor: buttonTextColor,
                  onTap: () {
                    if (onCopy != null) {
                      onCopy!();
                    } else {
                      Clipboard.setData(ClipboardData(text: selectedText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Passage copied to clipboard'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      onDismiss();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadButton(
    BuildContext context, {
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.28),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.messageSquarePlus,
              size: 14,
              color: accentColor,
            ),
            const SizedBox(width: 5),
            Text(
              'Start Thread',
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 18,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: isDark ? Colors.white12 : const Color(0xFFE5DFD7),
    );
  }
}
