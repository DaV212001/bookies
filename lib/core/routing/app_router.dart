import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      path: '/gallery',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ComponentGalleryScreen(),
    ),
    GoRoute(
      path: '/reader',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final book = state.extra as Book?;
        return ReaderView(book: book);
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
