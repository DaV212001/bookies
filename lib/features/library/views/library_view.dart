import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';

import 'package:bookies/features/library/bloc/library_bloc.dart';
import 'package:bookies/core/widgets/primary_button.dart';
import 'package:bookies/core/utils/app_logger.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/data/models/book.dart';
import 'package:bookies/core/widgets/create_community_dialog.dart';

enum LibraryViewMode { grid, list }

enum LibrarySortOrder { recent, title, author }

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  LibraryViewMode _viewMode = LibraryViewMode.grid;
  LibrarySortOrder _sortOrder = LibrarySortOrder.recent;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickAndImportBook(BuildContext context) async {
    AppLogger.i('FilePickerUI', 'Initiating EPUB file selection process...');

    FilePickerResult? result;
    try {
      AppLogger.d(
        'FilePickerUI',
        'Calling FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ["epub"])',
      );
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        'FilePickerUI',
        'Primary FilePicker.pickFiles failed with custom type filter',
        e,
        stackTrace,
      );

      try {
        AppLogger.w(
          'FilePickerUI',
          'Attempting fallback: FilePicker.pickFiles(type: FileType.any)',
        );
        result = await FilePicker.pickFiles(type: FileType.any);
      } catch (fallbackError, fallbackStack) {
        AppLogger.e(
          'FilePickerUI',
          'Fallback FilePicker.pickFiles(type: FileType.any) also failed',
          fallbackError,
          fallbackStack,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File picker failed: $fallbackError'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
        return;
      }
    }

    if (result == null) {
      AppLogger.w(
        'FilePickerUI',
        'FilePicker returned null (User cancelled or no file selected)',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File selection cancelled')),
        );
      }
      return;
    }

    if (result.files.isEmpty) {
      AppLogger.w('FilePickerUI', 'FilePicker returned empty files list');
      return;
    }

    final file = result.files.single;
    AppLogger.i(
      'FilePickerUI',
      'Selected file detail -> Name: ${file.name}, Path: ${file.path}, Size: ${file.size} bytes',
    );

    final path = file.path;
    if (path == null || path.isEmpty) {
      AppLogger.e(
        'FilePickerUI',
        'Selected file path is NULL or empty! FilePicker result lacks local file path access.',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not obtain local file path from selected file.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!path.toLowerCase().endsWith('.epub')) {
      AppLogger.w(
        'FilePickerUI',
        'Selected file does not have .epub extension: $path',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected file is not an EPUB file: ${file.name}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    AppLogger.i(
      'FilePickerUI',
      'File path validated successfully: $path. Dispatching ImportBook event to LibraryBloc',
    );
    if (context.mounted) {
      context.read<LibraryBloc>().add(ImportBook(path));
    }
  }

  double _getProgression(LocalDataService dataService, String bookId) {
    try {
      final progressJson = dataService.getProgress(bookId);
      if (progressJson != null && progressJson.isNotEmpty) {
        final map = jsonDecode(progressJson);
        if (map is Map<String, dynamic>) {
          // ReaderBloc stores the current value at the top level. Keep
          // supporting the older epub.js locations format as well.
          final progression = map['progression'];
          if (progression is num) return progression.toDouble().clamp(0.0, 1.0);

          final locations = map['locations'];
          if (locations is Map<String, dynamic>) {
            final totalProgression = locations['totalProgression'];
            if (totalProgression is num) {
              return totalProgression.toDouble().clamp(0.0, 1.0);
            }
          }
        }
      }
    } catch (_) {}
    return 0.0;
  }

  List<Book> _filterAndSortBooks(List<Book> books) {
    var filtered = books.where((book) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return book.title.toLowerCase().contains(q) ||
          book.author.toLowerCase().contains(q);
    }).toList();

    switch (_sortOrder) {
      case LibrarySortOrder.title:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case LibrarySortOrder.author:
        filtered.sort((a, b) => a.author.compareTo(b.author));
        break;
      case LibrarySortOrder.recent:
        // Already in recent insertion order
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<LocalDataService>();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search title or author...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bookies',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
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
        actions: [
          IconButton(
            icon: Icon(_isSearching ? LucideIcons.x : LucideIcons.search),
            tooltip: _isSearching ? 'Close Search' : 'Search Library',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: BlocConsumer<LibraryBloc, LibraryState>(
        listener: (context, state) {
          if (state is LibraryError) {
            AppLogger.e(
              'LibraryView',
              'Library error state received: ${state.message}',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Import Error: ${state.message}'),
                backgroundColor: Colors.red.shade800,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is LibraryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LibraryError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.triangleAlert,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Library',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Retry',
                      onPressed: () =>
                          context.read<LibraryBloc>().add(LoadLibrary()),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is LibraryLoaded) {
            final allBooks = state.books;
            final displayedBooks = _filterAndSortBooks(allBooks);

            if (allBooks.isEmpty) {
              return _buildEmptySanctuary(context, theme);
            }

            int currentlyReadingCount = allBooks.where((b) {
              final prog = _getProgression(dataService, b.id);
              return prog > 0.0 && prog < 1.0;
            }).length;

            return CustomScrollView(
              slivers: [
                // Reading Streak Banner Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: _buildReadingStreakCard(theme),
                  ),
                ),

                // Library Section Header & Controls
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Library',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${allBooks.length} Books • $currentlyReadingCount Reading',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Sort Dropdown
                            PopupMenuButton<LibrarySortOrder>(
                              initialValue: _sortOrder,
                              tooltip: 'Sort Order',
                              onSelected: (val) {
                                setState(() {
                                  _sortOrder = val;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getSortLabel(_sortOrder),
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      LucideIcons.chevronDown,
                                      size: 16,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: LibrarySortOrder.recent,
                                  child: Text('Recent'),
                                ),
                                const PopupMenuItem(
                                  value: LibrarySortOrder.title,
                                  child: Text('Title'),
                                ),
                                const PopupMenuItem(
                                  value: LibrarySortOrder.author,
                                  child: Text('Author'),
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            // View Mode Toggle
                            IconButton(
                              icon: Icon(
                                _viewMode == LibraryViewMode.grid
                                    ? LucideIcons.list
                                    : LucideIcons.layoutGrid,
                                size: 20,
                              ),
                              tooltip: _viewMode == LibraryViewMode.grid
                                  ? 'List View'
                                  : 'Grid View',
                              onPressed: () {
                                setState(() {
                                  _viewMode = _viewMode == LibraryViewMode.grid
                                      ? LibraryViewMode.list
                                      : LibraryViewMode.grid;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Book Collection Grid/List
                displayedBooks.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'No books match "$_searchQuery"',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : _viewMode == LibraryViewMode.grid
                    ? SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.58,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 16,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final book = displayedBooks[index];
                            final prog = _getProgression(dataService, book.id);
                            return _buildBookGridCard(
                              context,
                              theme,
                              book,
                              prog,
                            );
                          }, childCount: displayedBooks.length),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final book = displayedBooks[index];
                            final prog = _getProgression(dataService, book.id);
                            return _buildBookListTile(
                              context,
                              theme,
                              book,
                              prog,
                            );
                          }, childCount: displayedBooks.length),
                        ),
                      ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAndImportBook(context),
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: theme.colorScheme.onSecondary,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Import Book'),
      ),
    );
  }

  String _getSortLabel(LibrarySortOrder sort) {
    switch (sort) {
      case LibrarySortOrder.title:
        return 'Title';
      case LibrarySortOrder.author:
        return 'Author';
      case LibrarySortOrder.recent:
        return 'Recent';
    }
  }

  Widget _buildReadingStreakCard(ThemeData theme) {
    final secondary = theme.colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              LucideIcons.bookOpen,
              size: 110,
              color: theme.colorScheme.onSurface.withOpacity(0.04),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: secondary.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.flame, color: secondary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '12 Day Streak',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'You\'re on a roll! 45 minutes to reach today\'s goal.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDayBadge(theme, 'S', isCompleted: false),
                  _buildDayBadge(theme, 'M', isCompleted: true),
                  _buildDayBadge(theme, 'T', isCompleted: true),
                  _buildDayBadge(theme, 'W', isCompleted: true),
                  _buildDayBadge(theme, 'T', isCompleted: true),
                  _buildDayBadge(theme, 'F', isCompleted: false),
                  _buildDayBadge(theme, 'S', isCompleted: false),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayBadge(
    ThemeData theme,
    String label, {
    required bool isCompleted,
  }) {
    final secondary = theme.colorScheme.secondary;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isCompleted ? secondary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted
              ? secondary
              : theme.colorScheme.outline.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isCompleted
                ? theme.colorScheme.onSecondary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackGridCover(ThemeData theme, Book book) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.bookOpen,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                book.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookGridCard(
    BuildContext context,
    ThemeData theme,
    Book book,
    double progress,
  ) {
    final hasCover = book.coverUrl != null && File(book.coverUrl!).existsSync();

    return GestureDetector(
      onTap: () => context.push('/reader', extra: book),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image / Fallback Container
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasCover)
                    Image.file(
                      File(book.coverUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackGridCover(theme, book),
                    )
                  else
                    _buildFallbackGridCover(theme, book),

                  // Reading Progress Indicator Pin at cover bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(color: theme.colorScheme.secondary),
                      ),
                    ),
                  ),
                  
                  // Context Menu
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildBookContextMenu(context, theme, book),
                  ),
                ],
              ),
            ),

            // Book Meta Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (progress > 0.0) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${(progress * 100).toInt()}% completed',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookListTile(
    BuildContext context,
    ThemeData theme,
    Book book,
    double progress,
  ) {
    final hasCover = book.coverUrl != null && File(book.coverUrl!).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/reader', extra: book),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 52,
                  height: 72,
                  color: theme.colorScheme.primaryContainer,
                  child: hasCover
                      ? Image.file(
                          File(book.coverUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Center(
                            child: Icon(
                              LucideIcons.bookOpen,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            LucideIcons.bookOpen,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: theme.colorScheme.secondary,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toInt()}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              _buildBookContextMenu(context, theme, book),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySanctuary(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.bookOpenCheck,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'The Reading Room',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A sanctuary for your digital library. Calm, focused, and free of distractions.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Import Your First Book',
              onPressed: () => _pickAndImportBook(context),
            ),
            const SizedBox(height: 16),
            Text(
              'DRM-FREE EPUB SUPPORT',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookContextMenu(BuildContext context, ThemeData theme, Book book) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: Icon(
          LucideIcons.moreVertical,
          size: 18,
          color: theme.colorScheme.onSurface,
        ),
      ),
      onSelected: (value) {
        if (value == 'create_community') {
          CreateCommunityDialog.show(context, book: book);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'create_community',
          child: Row(
            children: [
              Icon(LucideIcons.users, size: 18),
              SizedBox(width: 12),
              Text('Create Community'),
            ],
          ),
        ),
      ],
    );
  }
}
