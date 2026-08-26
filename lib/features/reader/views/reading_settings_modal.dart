import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_cubit.dart';
import '../bloc/reader_bloc.dart';

class ReadingSettingsModal extends StatelessWidget {
  const ReadingSettingsModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ReaderBloc>(),
        child: const ReadingSettingsModal(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: BlocBuilder<ReaderBloc, ReaderState>(
          builder: (context, state) {
          if (state is! ReaderLoaded) {
            return const SizedBox.shrink();
          }

          final prefs = state.preferences;
          final isScroll = prefs.scroll ?? false;
          final fontSizeRatio = prefs.fontSize ?? 1.0;
          final fontSizePercent = (fontSizeRatio * 100).round();
          final fontFamily = prefs.fontFamily ?? 'Original';
          final lineHeight = prefs.lineHeight ?? 1.5;
          final textAlign = prefs.textAlign ?? TextAlign.left;
          final usePublisherStyles = prefs.publisherStyles ?? false;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reading Settings',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- Reading Mode (Scroll vs Paginated) ---
                _buildSectionHeader(theme, 'Reading Layout'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ModeTile(
                        icon: LucideIcons.bookOpen,
                        label: 'Paginated',
                        subtitle: 'Horizontal Paging',
                        isSelected: !isScroll,
                        onTap: () {
                          context.read<ReaderBloc>().add(const ToggleScrollMode(false));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ModeTile(
                        icon: LucideIcons.scroll,
                        label: 'Continuous',
                        subtitle: 'Vertical Scroll',
                        isSelected: isScroll,
                        onTap: () {
                          context.read<ReaderBloc>().add(const ToggleScrollMode(true));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Themes ---
                _buildSectionHeader(theme, 'Theme & Colors'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ThemeSwatch(
                      name: 'Parchment',
                      bg: AppColors.parchmentBackground,
                      fg: AppColors.parchmentTextPrimary,
                      border: AppColors.parchmentBorder,
                      isSelected: state.activeTheme == 'parchment',
                      onTap: () {
                        context.read<ReaderBloc>().add(const ChangeTheme('parchment'));
                        context.read<ThemeCubit>().setThemeMode(AppThemeMode.parchment);
                      },
                    ),
                    _ThemeSwatch(
                      name: 'Sepia',
                      bg: AppColors.sepiaBackground,
                      fg: AppColors.sepiaTextPrimary,
                      border: AppColors.sepiaBorder,
                      isSelected: state.activeTheme == 'sepia',
                      onTap: () {
                        context.read<ReaderBloc>().add(const ChangeTheme('sepia'));
                        context.read<ThemeCubit>().setThemeMode(AppThemeMode.sepia);
                      },
                    ),
                    _ThemeSwatch(
                      name: 'Charcoal',
                      bg: AppColors.charcoalBackground,
                      fg: AppColors.charcoalTextPrimary,
                      border: AppColors.charcoalBorder,
                      isSelected: state.activeTheme == 'charcoal',
                      onTap: () {
                        context.read<ReaderBloc>().add(const ChangeTheme('charcoal'));
                        context.read<ThemeCubit>().setThemeMode(AppThemeMode.charcoal);
                      },
                    ),
                    _ThemeSwatch(
                      name: 'OLED',
                      bg: const Color(0xFF000000),
                      fg: const Color(0xFFE5E7EB),
                      border: const Color(0xFF27272A),
                      isSelected: state.activeTheme == 'oled',
                      onTap: () {
                        context.read<ReaderBloc>().add(const ChangeTheme('oled'));
                        context.read<ThemeCubit>().setThemeMode(AppThemeMode.oled);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Text Size ---
                _buildSectionHeader(theme, 'Text Size'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(LucideIcons.minus),
                        onPressed: fontSizeRatio > 0.6
                            ? () {
                                final next = (fontSizeRatio - 0.1).clamp(0.5, 3.0);
                                context.read<ReaderBloc>().add(ChangeFontSize(next));
                              }
                            : null,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '$fontSizePercent%',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Slider(
                              value: fontSizeRatio.clamp(0.6, 2.5),
                              min: 0.6,
                              max: 2.5,
                              divisions: 19,
                              onChanged: (val) {
                                context.read<ReaderBloc>().add(ChangeFontSize(val));
                              },
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(LucideIcons.plus),
                        onPressed: fontSizeRatio < 2.5
                            ? () {
                                final next = (fontSizeRatio + 0.1).clamp(0.5, 3.0);
                                context.read<ReaderBloc>().add(ChangeFontSize(next));
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- Font Family ---
                _buildSectionHeader(theme, 'Font Family'),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FontChip(
                        label: 'Original',
                        fontFamilyName: null,
                        isSelected: fontFamily == 'Original' || prefs.fontFamily == null,
                        onTap: () {
                          final newPrefs = prefs.copyWith(fontFamily: null);
                          context.read<ReaderBloc>().add(UpdateEPUBPreferences(newPrefs));
                        },
                      ),
                      const SizedBox(width: 8),
                      _FontChip(
                        label: 'Sans-Serif',
                        fontFamilyName: 'sans-serif',
                        isSelected: fontFamily == 'sans-serif',
                        onTap: () {
                          final newPrefs = prefs.copyWith(fontFamily: 'sans-serif', publisherStyles: false);
                          context.read<ReaderBloc>().add(UpdateEPUBPreferences(newPrefs));
                        },
                      ),
                      const SizedBox(width: 8),
                      _FontChip(
                        label: 'Serif',
                        fontFamilyName: 'serif',
                        isSelected: fontFamily == 'serif',
                        onTap: () {
                          final newPrefs = prefs.copyWith(fontFamily: 'serif', publisherStyles: false);
                          context.read<ReaderBloc>().add(UpdateEPUBPreferences(newPrefs));
                        },
                      ),
                      const SizedBox(width: 8),
                      _FontChip(
                        label: 'Monospace',
                        fontFamilyName: 'monospace',
                        isSelected: fontFamily == 'monospace',
                        onTap: () {
                          final newPrefs = prefs.copyWith(fontFamily: 'monospace', publisherStyles: false);
                          context.read<ReaderBloc>().add(UpdateEPUBPreferences(newPrefs));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- Line Height & Alignment ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(theme, 'Line Spacing'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [1.2, 1.5, 1.8, 2.0].map((lh) {
                              final isSelected = (lineHeight - lh).abs() < 0.05;
                              return ChoiceChip(
                                label: Text('${lh}x'),
                                selected: isSelected,
                                onSelected: (_) {
                                  final newPrefs = prefs.copyWith(lineHeight: lh, publisherStyles: false);
                                  context.read<ReaderBloc>().add(UpdateEPUBPreferences(newPrefs));
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(theme, 'Text Align'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _AlignButton(
                                icon: LucideIcons.alignLeft,
                                isSelected: textAlign == TextAlign.left,
                                onTap: () {
                                  final newPrefs = prefs.copyWith(textAlign: TextAlign.left, publisherStyles: false);
                                  context.read<ReaderBloc>().add(UpdateEPUBPreferences(newPrefs));
                                },
                              ),
                              _AlignButton(
                                icon: LucideIcons.alignJustify,
                                isSelected: textAlign == TextAlign.justify,
                                onTap: () {
                                  final newPrefs = prefs.copyWith(textAlign: TextAlign.justify, publisherStyles: false);
                                  context.read<ReaderBloc>().add(UpdateEPUBPreferences(newPrefs));
                                },
                              ),
                              _AlignButton(
                                icon: LucideIcons.alignCenter,
                                isSelected: textAlign == TextAlign.center,
                                onTap: () {
                                  final newPrefs = prefs.copyWith(textAlign: TextAlign.center, publisherStyles: false);
                                  context.read<ReaderBloc>().add(UpdateEPUBPreferences(newPrefs));
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Publisher Styles Toggle ---
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use Publisher Styles'),
                  subtitle: const Text('Overrides custom font and line spacing preferences'),
                  value: usePublisherStyles,
                  onChanged: (val) {
                    final newPrefs = prefs.copyWith(publisherStyles: val);
                    context.read<ReaderBloc>().add(UpdateEPUBPreferences(newPrefs));
                  },
                ),
              ],
            ),
          );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withOpacity(0.12)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? primary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    label,
                    maxLines: 1,
                    minFontSize: 10,
                    stepGranularity: 0.5,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? primary : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  final String name;
  final Color bg;
  final Color fg;
  final Color border;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeSwatch({
    required this.name,
    required this.bg,
    required this.fg,
    required this.border,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? primary : border,
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primary.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                'Aa',
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isSelected ? primary : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _FontChip extends StatelessWidget {
  final String label;
  final String? fontFamilyName;
  final bool isSelected;
  final VoidCallback onTap;

  const _FontChip({
    required this.label,
    this.fontFamilyName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: fontFamilyName,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

class _AlignButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AlignButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton.filledTonal(
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        foregroundColor: isSelected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurfaceVariant,
      ),
      onPressed: onTap,
    );
  }
}
