import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({
    Key? key,
    required this.navigationShell,
  }) : super(key: key ?? const ValueKey<String>('MainLayout'));

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.library),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.compass),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.users),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
