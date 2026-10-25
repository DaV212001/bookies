import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/register_view.dart';
import '../../features/settings/views/settings_view.dart';
import '../../features/gallery/views/component_gallery_screen.dart';
import '../../features/library/views/library_view.dart';
import '../../features/discover/views/discover_view.dart';
import '../../features/community/views/community_view.dart';
import '../../features/reader/views/reader_view.dart';
import '../../data/models/book.dart';
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
