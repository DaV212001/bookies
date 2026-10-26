import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/register_view.dart';
import '../../features/settings/views/settings_view.dart';
import '../../features/gallery/views/component_gallery_screen.dart';
import '../../features/library/views/library_view.dart';
import '../../features/discover/views/discover_view.dart';
import '../../features/community/views/community_view.dart';
import '../../features/community/views/community_detail_view.dart';
import '../../features/reader/views/reader_view.dart';
import '../../data/models/book.dart';
import '../../data/providers/local_data_service.dart';
import '../../domain/repositories/community_repository.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/entities/community_entity.dart';
import '../../domain/entities/catalog_book_entity.dart';
import 'main_layout.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _libraryNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'library');
final GlobalKey<NavigatorState> _discoverNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'discover');
final GlobalKey<NavigatorState> _communityNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'community');
final GlobalKey<NavigatorState> _settingsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'settings');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: '/register',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RegisterView(),
    ),
    GoRoute(
      path: '/gallery',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ComponentGalleryScreen(),
    ),
    GoRoute(
      path: '/reader',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        Book? book;
        String? initialCfi;
        if (state.extra is Book) {
          book = state.extra as Book;
        } else if (state.extra is Map<String, dynamic>) {
          final map = state.extra as Map<String, dynamic>;
          book = map['book'] as Book?;
          initialCfi = map['initialCfi'] as String?;
        }
        return ReaderView(book: book, initialCfi: initialCfi);
      },
    ),
    GoRoute(
      path: '/community/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final communityId = state.pathParameters['id'] ?? '';
        return CommunityDetailRouteScreen(communityId: communityId);
      },
    ),
    GoRoute(
      path: '/book/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final bookId = state.pathParameters['id'] ?? '';
        return BookDetailOrReaderRouteScreen(bookId: bookId);
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainLayout(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _libraryNavigatorKey,
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const LibraryView(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _discoverNavigatorKey,
          routes: [
            GoRoute(
              path: '/discover',
              builder: (context, state) => const DiscoverView(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _communityNavigatorKey,
          routes: [
            GoRoute(
              path: '/community',
              builder: (context, state) => const CommunitiesView(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _settingsNavigatorKey,
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsView(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class CommunityDetailRouteScreen extends StatelessWidget {
  final String communityId;

  const CommunityDetailRouteScreen({super.key, required this.communityId});

  @override
  Widget build(BuildContext context) {
    final dataService = context.watch<LocalDataService>();
    final community = dataService.communities
        .where((c) => c.id == communityId)
        .firstOrNull;

    if (community != null) {
      return CommunityDetailView(
        bookId: community.bookId,
        communityId: community.id,
        communityName: community.name,
        description: community.description,
      );
    }

    final communityRepo = context.read<CommunityRepository>();
    return FutureBuilder<CommunityEntity>(
      future: communityRepo.getCommunityById(communityId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Community')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.users, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Community not found or has been removed.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/community'),
                      child: const Text('Browse Communities'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final c = snapshot.data!;
        return CommunityDetailView(
          bookId: c.bookId,
          communityId: c.id,
          communityName: c.name,
          description: c.description,
        );
      },
    );
  }
}

class BookDetailOrReaderRouteScreen extends StatelessWidget {
  final String bookId;

  const BookDetailOrReaderRouteScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    final dataService = context.watch<LocalDataService>();
    final book =
        dataService.getBooks().where((b) => b.id == bookId).firstOrNull;

    if (book != null) {
      return ReaderView(book: book);
    }

    final catalogRepo = context.read<CatalogRepository>();
    return FutureBuilder<List<CatalogBookEntity>>(
      future: catalogRepo.getDiscoverCatalog(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final catalogBook =
            snapshot.data?.where((b) => b.id == bookId).firstOrNull;
        if (catalogBook != null) {
          return Scaffold(
            appBar: AppBar(title: Text(catalogBook.title)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.bookOpen,
                        size: 56, color: Colors.indigo),
                    const SizedBox(height: 16),
                    Text(
                      catalogBook.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(catalogBook.author,
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: const Icon(LucideIcons.downloadCloud),
                      label: const Text('Download & Read'),
                      onPressed: () async {
                        final imported = await catalogRepo
                            .downloadAndImportBook(catalogBook: catalogBook);
                        if (context.mounted) {
                          final localBook = dataService
                                  .getBooks()
                                  .where((b) => b.id == imported.id)
                                  .firstOrNull ??
                              Book(
                                id: imported.id,
                                title: imported.title,
                                author: imported.author,
                                localPath: imported.localPath,
                                coverUrl: imported.coverUrl,
                                fingerprint: imported.fingerprint,
                              );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ReaderView(book: localBook)),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Book Not Found')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.bookX, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Book was not found in your library.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Go to Library'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
