import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bookies/core/widgets/responsive_text.dart';

class DiscoverView extends StatefulWidget {
  const DiscoverView({super.key});

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bookies',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Your Digital Sanctuary',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: theme.colorScheme.onSecondary,
        shape: const CircleBorder(),
        child: const Icon(LucideIcons.penSquare),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar Section
                _buildSearchBar(theme),

                const SizedBox(height: 16),

                // Genre / Topic Tags Horizontal Bar
                _buildGenrePills(theme),

                const SizedBox(height: 32),

                // DISCOVER SCREEN: Trending & Editorial Picks
                _buildDiscoverSection(theme, isDesktop),

                const SizedBox(height: 40),

                // CURATOR QUOTE OF THE DAY
                _buildCuratorQuoteCard(theme),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenrePills(ThemeData theme) {
    final tags = [
      '#AllCuration',
      '#DarkAcademia',
      '#SciFiEpics',
      '#ClassicPoetry',
      '#PhilosophicalFiction',
      '#ModernClassics',
      '#EssayCollections',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags.map((tag) {
          final isSelected = tag == '#AllCuration';
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                tag,
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onSecondary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {},
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withOpacity(0.4),
              selectedColor: theme.colorScheme.secondary,
              checkmarkColor: theme.colorScheme.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCuratorQuoteCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                    LucideIcons.quote,
                    size: 20,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CURATOR QUOTE OF THE DAY',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //   decoration: BoxDecoration(
              //     color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
              //     borderRadius: BorderRadius.circular(10),
              //   ),
              //   child: Text(
              //     'Daily Reflection',
              //     style: theme.textTheme.labelSmall?.copyWith(
              //       color: theme.colorScheme.secondary,
              //       fontSize: 11,
              //     ),
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 16),
          ResponsiveText.body(
            '"A room without books is like a body without a soul. In reading, we discover our truest companions across centuries."',
            style: theme.textTheme.titleMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.primary,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 5,
            minFontSize: 13,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '— Marcus Tullius Cicero',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: IconButton(
                        icon: const Icon(LucideIcons.bookmark, size: 18),
                        tooltip: 'Save Quote',
                        onPressed: () {},
                      ),
                    ),
                    Expanded(
                      child: IconButton(
                        icon: const Icon(LucideIcons.share2, size: 18),
                        tooltip: 'Share',
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: TextField(
          controller: _searchController,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
          ),
          decoration: InputDecoration(
            hintText: 'Search by title, author, or community thread...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            prefixIcon: Icon(
              LucideIcons.search,
              color: theme.colorScheme.outline,
            ),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.secondary,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverSection(ThemeData theme, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text(
          'CURATION',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Discover',
          style: theme.textTheme.displayMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),

        const SizedBox(height: 20),

        // Bento Grid Layout
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildTrendingBentoCard(theme)),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _buildStaffPickBentoCard(theme)),
            ],
          )
        else
          Column(
            children: [
              _buildTrendingBentoCard(theme),
              const SizedBox(height: 20),
              _buildStaffPickBentoCard(theme),
            ],
          ),

        const SizedBox(height: 24),

        // Small Grid Items
        if (isDesktop)
          Row(
            children: [
              Expanded(
                child: _buildSmallBookGridCard(
                  theme,
                  title: 'Klara and the Sun',
                  subtitle: '842 readers today',
                  actionText: 'DOWNLOAD BOOK',
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCVHL-GpK6FZbXybZZ24zzA3UPoMxNO9gTYUyfdtxGPvUb6z4maALR0u5sVAHgwso5_fXX4UvwGOT2KQEcrkK-UGNQEdhVImabTzk23jN4ze8220aMLxFAHaBEV5-ioHrASPvuyfgiD-SFNIjaPvWV9UAnPAhZs15cjIiouRu2N2URgc4Sn0NmNQsxW6leFu6NEZOpKDf4C8uqvqTGCwpR9zVRWA9o8rgMxm98EdUXhYdxFz4kMdJb9',
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildSmallBookGridCard(
                  theme,
                  title: 'Circe',
                  subtitle: 'High Annotation Activity',
                  actionText: 'DOWNLOAD BOOK',
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuBsdAVPP4bjoOSwMwUVX1AiRluOsFyCp7gW1Ae_9Jb6uIVQCBmsAbRRvVOUSMG_a52kMaElQjSR82ecn5oMnKalrJdMuYxvgXZE_KTUaQdML9cewnmZJ6B3lTyssGW_Yj4plmgS8AYsQlaNheGFjydKY1c-sj6YwUke28kwiuyGr9eTKfFooVkSrvgJO-QoN92vwlbRBfNTQEgiNy9BY37Z90Ll0Rbmy_Vl8LOyJBkFLje-xXra-Czp',
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildSmallBookGridCard(
                  theme,
                  title: 'Overstory',
                  subtitle: 'New Club Pick',
                  actionText: 'DOWNLOAD BOOK',
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDONIiNGZtWPM3D1H0s_q3PMePPezRfnsJ_JTMymFNm2BL4xJoO-FuzYbNuPtrO14m7_knZHS1beum7110ZWcAgwXH1_lgs-IiPSZXZdTo--D-xenwgywzJm3f7yxL_z2dK_zxQrSZSNPE9JPq8jcphNKg2KCPp6DUxAQknqZMpcMwlJfjOKYQEfPYUJfuuw06qcT-1GhUyN5SU7XWbqMbXtCXcuwgwV-pTc0Rek5OqqOoYBOeoOLhQ',
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _buildSmallBookGridCard(
                theme,
                title: 'Klara and the Sun',
                subtitle: '842 readers today',
                actionText: 'DOWNLOAD BOOK',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCVHL-GpK6FZbXybZZ24zzA3UPoMxNO9gTYUyfdtxGPvUb6z4maALR0u5sVAHgwso5_fXX4UvwGOT2KQEcrkK-UGNQEdhVImabTzk23jN4ze8220aMLxFAHaBEV5-ioHrASPvuyfgiD-SFNIjaPvWV9UAnPAhZs15cjIiouRu2N2URgc4Sn0NmNQsxW6leFu6NEZOpKDf4C8uqvqTGCwpR9zVRWA9o8rgMxm98EdUXhYdxFz4kMdJb9',
              ),
              const SizedBox(height: 12),
              _buildSmallBookGridCard(
                theme,
                title: 'Circe',
                subtitle: 'High Annotation Activity',
                actionText: 'DOWNLOAD BOOK',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBsdAVPP4bjoOSwMwUVX1AiRluOsFyCp7gW1Ae_9Jb6uIVQCBmsAbRRvVOUSMG_a52kMaElQjSR82ecn5oMnKalrJdMuYxvgXZE_KTUaQdML9cewnmZJ6B3lTyssGW_Yj4plmgS8AYsQlaNheGFjydKY1c-sj6YwUke28kwiuyGr9eTKfFooVkSrvgJO-QoN92vwlbRBfNTQEgiNy9BY37Z90Ll0Rbmy_Vl8LOyJBkFLje-xXra-Czp',
              ),
              const SizedBox(height: 12),
              _buildSmallBookGridCard(
                theme,
                title: 'Overstory',
                subtitle: 'New Club Pick',
                actionText: 'DOWNLOAD BOOK',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDONIiNGZtWPM3D1H0s_q3PMePPezRfnsJ_JTMymFNm2BL4xJoO-FuzYbNuPtrO14m7_knZHS1beum7110ZWcAgwXH1_lgs-IiPSZXZdTo--D-xenwgywzJm3f7yxL_z2dK_zxQrSZSNPE9JPq8jcphNKg2KCPp6DUxAQknqZMpcMwlJfjOKYQEfPYUJfuuw06qcT-1GhUyN5SU7XWbqMbXtCXcuwgwV-pTc0Rek5OqqOoYBOeoOLhQ',
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTrendingBentoCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.8),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 500;
          return Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: isWide ? 140 : double.infinity,
                  height: 200,
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuC7cpL27jzawVwPw3wJxDpwBU3uGQMUNJgC_jwFsuKEm3c6S6pxXrO15bNkcjfvyam6YqaZEbIouXlUJwUmWPuaq2TowE295nAdd7eU5DHIJPOJIYzaIscj8WU_yqRRI8fNo6ZqE1YhbRF7ZHVx1ZuabhhDAqjN6IAbfYmG14Ocs8kpM-nTrPsBahyWyrfgNpGpbHry9ufCxtIvl6oJ5b_CcKT5yRgJCqhZLGi3Bsz0U4c-2wgw607D',
                    fit: BoxFit.cover,
                    cacheHeight: 400,
                    errorBuilder: (context, error, stack) => Container(
                      color: theme.colorScheme.primaryContainer,
                      child: Center(
                        child: Icon(
                          LucideIcons.bookOpen,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (isWide)
                const SizedBox(width: 24)
              else
                const SizedBox(height: 16),

              // Details
              Expanded(
                flex: isWide ? 1 : 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer
                                    .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Trending Now',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '1.2k Active Members',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'The Secret History',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '"Does such a thing as \'the fatal flaw,\' that showy dark crack running through the middle of a life, exist outside of literature?"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {},
                          child: Row(
                            children: [
                              Text(
                                'Join Discussion',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                LucideIcons.arrowRight,
                                size: 16,
                                color: theme.colorScheme.secondary,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Download Book',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStaffPickBentoCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STAFF PICK',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 140,
                height: 190,
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCddjFf4fbvLs8U8t0jMYaXDI8s6YcStfqbRHqmZqIq9kVyx7r9HG-cTtN5NJeMqt6V1r972SxflFkk6AsY3d750E9Sp6iBJvJAWRm50RAGcHld94EA9HZH2qtjqbPAtt4mV_ux3iAScBSpcQ0guuvf0huH4AatDLwx2BHS6nLK0OR-osDCOMHUSUlHBELoySSRfuy4URvDDv1ZJ_NzLGn7rFkx2zjlKTuPr_qnZgsO25b9u7OMwbJr',
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                  errorBuilder: (context, error, stack) => Container(
                    color: theme.colorScheme.primaryContainer,
                    child: Center(
                      child: Icon(
                        LucideIcons.bookOpen,
                        size: 36,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Sea of Tranquility',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Recommended by The Curators Circle',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('View Details', style: theme.textTheme.labelLarge),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBookGridCard(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required String actionText,
    required String imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.8),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 60,
              height: 84,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                cacheWidth: 150,
                errorBuilder: (context, error, stack) => Container(
                  color: theme.colorScheme.primaryContainer,
                  child: Center(
                    child: Icon(
                      LucideIcons.bookOpen,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText.title(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                  maxLines: 2,
                  minFontSize: 12,
                ),
                const SizedBox(height: 2),
                ResponsiveText.body(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  minFontSize: 10.5,
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {},
                  child: Text(
                    actionText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
