import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bookies/core/widgets/responsive_text.dart';
import 'package:bookies/data/models/book.dart';
import 'package:bookies/domain/entities/catalog_book_entity.dart';
import 'package:bookies/features/discover/bloc/catalog_bloc.dart';
import 'package:bookies/features/library/bloc/library_bloc.dart';

class DiscoverView extends StatefulWidget {
  const DiscoverView({super.key});

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _tags = const [
    '#AllCuration',
    '#DarkAcademia',
    '#SciFiEpics',
    '#ClassicPoetry',
    '#PhilosophicalFiction',
    '#ModernClassics',
    '#EssayCollections',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<CatalogBloc>().add(SearchCatalogEvent(query));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return BlocConsumer<CatalogBloc, CatalogState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
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
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<CatalogBloc>().add(FetchCatalogEvent(genre: state.selectedGenre));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const AlwaysScrollableScrollPhysics(),
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
                      _buildGenrePills(theme, state.selectedGenre),

                      const SizedBox(height: 28),

                      // Dynamic Content: Search Results OR Curated Discover Sections
                      if (state.searchQuery.isNotEmpty)
                        _buildSearchResultsSection(theme, state)
                      else if (state.status == CatalogStatus.loading && state.featuredBooks.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        _buildDiscoverSection(theme, isDesktop, state),
                        const SizedBox(height: 40),
                        _buildCuratorQuoteCard(theme),
                      ],

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: TextField(
          controller: _searchController,
          onSubmitted: _onSearch,
          textInputAction: TextInputAction.search,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
          ),
          decoration: InputDecoration(
            hintText: 'Search by title, author, or keyword (OceanOfPDF / OpenLibrary)...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            prefixIcon: Icon(
              LucideIcons.search,
              color: theme.colorScheme.outline,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _onSearch('');
                      setState(() {});
                    },
                  )
                : null,
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

  Widget _buildGenrePills(ThemeData theme, String activeGenre) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tags.map((tag) {
          final isSelected = tag == activeGenre;
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
              onSelected: (_) {
                context.read<CatalogBloc>().add(SelectGenreFilterEvent(tag));
              },
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              selectedColor: theme.colorScheme.secondary,
              checkmarkColor: theme.colorScheme.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
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

  Widget _buildSearchResultsSection(ThemeData theme, CatalogState state) {
    if (state.status == CatalogStatus.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(LucideIcons.bookX, size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text(
                'No books found for "${state.searchQuery}"',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Try searching with a different title or author name.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SEARCH RESULTS (${state.searchResults.length})',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: theme.colorScheme.secondary,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                _onSearch('');
                setState(() {});
              },
              icon: const Icon(LucideIcons.x, size: 16),
              label: const Text('Clear Search'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 768;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 3 : 1,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isDesktop ? 2.5 : 3.0,
              ),
              itemCount: state.searchResults.length,
              itemBuilder: (context, index) {
                final book = state.searchResults[index];
                return _buildCatalogBookCard(theme, book, state);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDiscoverSection(ThemeData theme, bool isDesktop, CatalogState state) {
    final books = state.featuredBooks;
    final trendingBook = books.isNotEmpty ? books[0] : null;
    final staffPickBook = books.length > 1 ? books[1] : null;
    final otherBooks = books.length > 2 ? books.sublist(2) : <CatalogBookEntity>[];

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
        if (trendingBook != null)
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildTrendingBentoCard(theme, trendingBook, state)),
                const SizedBox(width: 24),
                if (staffPickBook != null)
                  Expanded(flex: 1, child: _buildStaffPickBentoCard(theme, staffPickBook, state)),
              ],
            )
          else
            Column(
              children: [
                _buildTrendingBentoCard(theme, trendingBook, state),
                if (staffPickBook != null) ...[
                  const SizedBox(height: 20),
                  _buildStaffPickBentoCard(theme, staffPickBook, state),
                ],
              ],
            ),

        if (otherBooks.isNotEmpty) ...[
          const SizedBox(height: 24),
          if (isDesktop)
            Row(
              children: otherBooks.take(3).map((book) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildCatalogBookCard(theme, book, state),
                  ),
                );
              }).toList(),
            )
          else
            Column(
              children: otherBooks.take(3).map((book) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCatalogBookCard(theme, book, state),
                );
              }).toList(),
            ),
        ],
      ],
    );
  }

  Widget _buildTrendingBentoCard(ThemeData theme, CatalogBookEntity book, CatalogState state) {
    final isDownloaded = state.isDownloaded(book.id);
    final isDownloading = state.isDownloading(book.id);
    final progress = state.downloadProgress[book.id] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
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
                  child: book.coverUrl != null
                      ? Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderCover(theme),
                        )
                      : _buildPlaceholderCover(theme),
                ),
              ),

              if (isWide) const SizedBox(width: 24) else const SizedBox(height: 16),

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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
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
                                '${book.activeReadersCount > 0 ? book.activeReadersCount : 1240} Active Readers',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          book.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${book.author}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.description ?? 'A curated selection from the library archive.',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (isDownloading)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(value: progress > 0 ? progress : null),
                          const SizedBox(height: 6),
                          Text(
                            'Downloading EPUB ${(progress * 100).toInt()}%...',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              if (isDownloaded) {
                                final downloadedEntity = state.downloadedBooks[book.id]!;
                                context.push('/reader', extra: Book.fromDomain(downloadedEntity));
                              } else {
                                context.read<CatalogBloc>().add(DownloadCatalogBookEvent(book));
                                context.read<LibraryBloc>().add(LoadLibrary());
                              }
                            },
                            icon: Icon(
                              isDownloaded ? LucideIcons.bookOpen : LucideIcons.download,
                              size: 16,
                            ),
                            label: Text(isDownloaded ? 'Read Now' : 'Download Book'),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onSecondary,
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

  Widget _buildStaffPickBentoCard(ThemeData theme, CatalogBookEntity book, CatalogState state) {
    final isDownloaded = state.isDownloaded(book.id);
    final isDownloading = state.isDownloading(book.id);
    final progress = state.downloadProgress[book.id] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
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
                child: book.coverUrl != null
                    ? Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderCover(theme),
                      )
                    : _buildPlaceholderCover(theme),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              book.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'by ${book.author}',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (isDownloading)
            LinearProgressIndicator(value: progress > 0 ? progress : null)
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  if (isDownloaded) {
                    final downloadedEntity = state.downloadedBooks[book.id]!;
                    context.push('/reader', extra: Book.fromDomain(downloadedEntity));
                  } else {
                    context.read<CatalogBloc>().add(DownloadCatalogBookEvent(book));
                    context.read<LibraryBloc>().add(LoadLibrary());
                  }
                },
                icon: Icon(
                  isDownloaded ? LucideIcons.bookOpen : LucideIcons.download,
                  size: 16,
                ),
                label: Text(isDownloaded ? 'Read Now' : 'Download Book'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCatalogBookCard(
    ThemeData theme,
    CatalogBookEntity book,
    CatalogState state,
  ) {
    final isDownloaded = state.isDownloaded(book.id);
    final isDownloading = state.isDownloading(book.id);
    final progress = state.downloadProgress[book.id] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 58,
              height: 82,
              child: book.coverUrl != null
                  ? Image.network(
                      book.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderCover(theme, size: 24),
                    )
                  : _buildPlaceholderCover(theme, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ResponsiveText.title(
                  book.title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  minFontSize: 12,
                ),
                const SizedBox(height: 2),
                ResponsiveText.body(
                  book.author,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  minFontSize: 10.5,
                ),
                const SizedBox(height: 8),
                if (isDownloading)
                  LinearProgressIndicator(value: progress > 0 ? progress : null)
                else
                  InkWell(
                    onTap: () {
                      if (isDownloaded) {
                        final downloadedEntity = state.downloadedBooks[book.id]!;
                        context.push('/reader', extra: Book.fromDomain(downloadedEntity));
                      } else {
                        context.read<CatalogBloc>().add(DownloadCatalogBookEvent(book));
                        context.read<LibraryBloc>().add(LoadLibrary());
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDownloaded ? LucideIcons.bookOpen : LucideIcons.download,
                          size: 14,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isDownloaded ? 'READ NOW' : 'DOWNLOAD BOOK',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCover(ThemeData theme, {double size = 40}) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          LucideIcons.bookOpen,
          size: size,
          color: theme.colorScheme.primary,
        ),
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
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.bookmark, size: 18),
                    tooltip: 'Save Quote',
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.share2, size: 18),
                    tooltip: 'Share',
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
