import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../data/providers/local_data_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _spoilerProtection = true;
  bool _discussionNotifications = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<LocalDataService>();
    final user = dataService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Profile'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // --- User Profile Header Card ---
          _buildProfileCard(context, theme, user),
          const SizedBox(height: 24),

          // --- Theme & Appearance ---
          _buildSectionTitle(theme, 'Appearance & Theme'),
          const SizedBox(height: 12),
          _buildThemeSelector(context, theme),
          const SizedBox(height: 24),

          // --- Reading Defaults ---
          _buildSectionTitle(theme, 'Reading Defaults'),
          const SizedBox(height: 12),
          _buildCardGroup(theme, [
            ListTile(
              leading: const Icon(LucideIcons.bookOpen),
              title: const Text('Default Reading Mode'),
              subtitle: const Text('Paginated Horizontal Paging'),
              trailing: const Icon(LucideIcons.chevronRight, size: 20),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Default reading mode saved to Paginated.'),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(LucideIcons.type),
              title: const Text('Default Typography'),
              subtitle: const Text('Publisher Default Font / 100% Size'),
              trailing: const Icon(LucideIcons.chevronRight, size: 20),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Open any book in Reader to customize fine-grained fonts.',
                    ),
                  ),
                );
              },
            ),
          ]),
          const SizedBox(height: 24),

          // --- Spoiler & Social Controls ---
          _buildSectionTitle(theme, 'Spoiler & Community Settings'),
          const SizedBox(height: 12),
          _buildCardGroup(theme, [
            SwitchListTile(
              secondary: const Icon(LucideIcons.shieldCheck),
              title: const Text('Spoiler Guard'),
              subtitle: const Text(
                'Hide discussion threads beyond your current reading progress',
              ),
              value: _spoilerProtection,
              onChanged: (val) {
                setState(() => _spoilerProtection = val);
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(LucideIcons.messageSquare),
              title: const Text('In-Margin Discussion Indicators'),
              subtitle: const Text(
                'Display community indicators on book margins',
              ),
              value: dataService.isDiscussionIndicatorsEnabled(),
              onChanged: (val) async {
                await dataService.setDiscussionIndicatorsEnabled(val);
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(LucideIcons.bell),
              title: const Text('Discussion Replies'),
              subtitle: const Text(
                'Receive notifications when readers reply to your notes',
              ),
              value: _discussionNotifications,
              onChanged: (val) {
                setState(() => _discussionNotifications = val);
              },
            ),
          ]),
          const SizedBox(height: 24),

          // --- Design System & Developer Tools ---
          _buildSectionTitle(theme, 'Design System & Tools'),
          const SizedBox(height: 12),
          _buildCardGroup(theme, [
            ListTile(
              leading: Icon(
                LucideIcons.palette,
                color: theme.colorScheme.primary,
              ),
              title: const Text(
                'Component Gallery',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Explore UI tokens, buttons, quote cards, and modal dialogs',
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Gallery',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () => context.push('/gallery'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(LucideIcons.hardDrive),
              title: const Text('Storage & Cache'),
              subtitle: const Text('Local EPUB storage & temporary data'),
              trailing: const Icon(LucideIcons.chevronRight, size: 20),
              onTap: () {
                _showStorageDialog(context);
              },
            ),
          ]),
          const SizedBox(height: 24),

          // --- About & App Info ---
          _buildSectionTitle(theme, 'About Bookies'),
          const SizedBox(height: 12),
          _buildCardGroup(theme, [
            const ListTile(
              leading: Icon(LucideIcons.info),
              title: Text('Bookies EPUB Reader'),
              subtitle: Text('Powered by Flutter & Readium Engine 0.3.1'),
              trailing: Text('v1.0.0'),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildCardGroup(ThemeData theme, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    ThemeData theme,
    dynamic user,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer.withOpacity(0.6),
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(user.avatarUrl),
                backgroundColor: theme.colorScheme.primary,
                child: user.avatarUrl.isEmpty
                    ? Text(
                        user.displayName[0],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatBadge(theme, '12 Books'),
                        const SizedBox(width: 8),
                        _buildStatBadge(theme, '4 Threads'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton.filledTonal(
            icon: const Icon(LucideIcons.pencil),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile editing coming soon!')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, ThemeData theme) {
    final themeCubit = context.watch<ThemeCubit>();
    final currentMode = themeCubit.state.mode;

    final themeOptions = [
      _ThemeOptionData(
        mode: AppThemeMode.parchment,
        name: 'Parchment',
        tagline: 'Light',
        icon: LucideIcons.sun,
        bg: AppColors.parchmentBackground,
        fg: AppColors.parchmentTextPrimary,
        border: AppColors.parchmentBorder,
      ),
      _ThemeOptionData(
        mode: AppThemeMode.sepia,
        name: 'Sepia',
        tagline: 'Warm',
        icon: LucideIcons.coffee,
        bg: AppColors.sepiaBackground,
        fg: AppColors.sepiaTextPrimary,
        border: AppColors.sepiaBorder,
      ),
      _ThemeOptionData(
        mode: AppThemeMode.charcoal,
        name: 'Charcoal',
        tagline: 'Night',
        icon: LucideIcons.moon,
        bg: AppColors.charcoalBackground,
        fg: AppColors.charcoalTextPrimary,
        border: AppColors.charcoalBorder,
      ),
      _ThemeOptionData(
        mode: AppThemeMode.oled,
        name: 'OLED',
        tagline: 'Black',
        icon: LucideIcons.smartphone,
        bg: const Color(0xFF000000),
        fg: const Color(0xFFE5E7EB),
        border: const Color(0xFF27272A),
      ),
      _ThemeOptionData(
        mode: AppThemeMode.system,
        name: 'System',
        tagline: 'Auto',
        icon: LucideIcons.laptop,
        bg: theme.colorScheme.surface,
        fg: theme.colorScheme.onSurface,
        border: theme.colorScheme.outline,
      ),
    ];

    final sortedOptions = [
      ...themeOptions.where((opt) => opt.mode == currentMode),
      ...themeOptions.where((opt) => opt.mode != currentMode),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.palette,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'App Theme',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getModeLabel(currentMode),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // clipBehavior: Clip.none,
            child: Row(
              children: [
                for (int i = 0; i < sortedOptions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  _ThemeOptionCard(
                    key: ValueKey(sortedOptions[i].mode),
                    name: sortedOptions[i].name,
                    tagline: sortedOptions[i].tagline,
                    icon: sortedOptions[i].icon,
                    bg: sortedOptions[i].bg,
                    fg: sortedOptions[i].fg,
                    border: sortedOptions[i].border,
                    isSelected: sortedOptions[i].mode == currentMode,
                    onTap: () =>
                        themeCubit.setThemeMode(sortedOptions[i].mode),
                  ),
                ],
              ],
            ),
          ),
          _buildThemeShowcase(theme, currentMode),
        ],
      ),
    );
  }

  Widget _buildThemeShowcase(ThemeData theme, AppThemeMode mode) {
    String title = '';
    String description = '';
    Color bg = theme.colorScheme.surface;
    Color fg = theme.colorScheme.onSurface;

    switch (mode) {
      case AppThemeMode.parchment:
        title = 'Parchment Light';
        description =
            'High contrast, natural paper texture feel optimized for daylight reading.';
        bg = AppColors.parchmentBackground;
        fg = AppColors.parchmentTextPrimary;
        break;
      case AppThemeMode.sepia:
        title = 'Warm Sepia';
        description =
            'Soft amber glow that minimizes eye fatigue during long reading sessions.';
        bg = AppColors.sepiaBackground;
        fg = AppColors.sepiaTextPrimary;
        break;
      case AppThemeMode.charcoal:
        title = 'Charcoal Night';
        description =
            'Deep slate tones designed for low-light environment reading comfort.';
        bg = AppColors.charcoalBackground;
        fg = AppColors.charcoalTextPrimary;
        break;
      case AppThemeMode.oled:
        title = 'OLED Pitch Black';
        description =
            'True pitch black background that maximizes contrast & saves battery life.';
        bg = const Color(0xFF000000);
        fg = const Color(0xFFE5E7EB);
        break;
      case AppThemeMode.system:
        title = 'System Mode';
        description =
            'Automatically matches your system light or dark preferences.';
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurface;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: fg.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Live Preview',
                  style: TextStyle(
                    color: fg,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '"In a quiet sanctuary, every page turned brings us closer to understanding."',
            style: TextStyle(
              color: fg,
              fontStyle: FontStyle.italic,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(color: fg.withOpacity(0.75), fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _getModeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.parchment:
        return 'Parchment Light';
      case AppThemeMode.sepia:
        return 'Warm Sepia';
      case AppThemeMode.charcoal:
        return 'Charcoal Night';
      case AppThemeMode.oled:
        return 'OLED Pitch Black';
      case AppThemeMode.system:
        return 'System Mode';
    }
  }

  void _showStorageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Storage & Cache'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Downloaded EPUB Books: ~14.2 MB'),
            SizedBox(height: 6),
            Text('Discussion Cache: ~1.1 MB'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Temporary cache cleared successfully!'),
                ),
              );
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionData {
  final AppThemeMode mode;
  final String name;
  final String tagline;
  final IconData icon;
  final Color bg;
  final Color fg;
  final Color border;

  const _ThemeOptionData({
    required this.mode,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.border,
  });
}

class _ThemeOptionCard extends StatelessWidget {
  final String name;
  final String tagline;
  final IconData icon;
  final Color bg;
  final Color fg;
  final Color border;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    super.key,
    required this.name,
    required this.tagline,
    required this.icon,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 104,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? primary
                : theme.colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.25),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            // Miniature Page Canvas Preview
            Container(
              height: 80,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border.withOpacity(0.6)),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mini header bar
                      Container(
                        height: 3,
                        width: 24,
                        decoration: BoxDecoration(
                          color: fg.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Mini text preview lines
                      Text(
                        'Quiet words...',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fg,
                          fontSize: 9,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      // Mini progress bar
                      Container(
                        height: 3,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: fg.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: 0.65,
                            child: Container(
                              decoration: BoxDecoration(
                                color: fg.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Top right checkmark badge when selected
                  if (isSelected)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.check,
                          size: 10,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Title + Icon Label
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: isSelected
                      ? primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected ? primary : theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
