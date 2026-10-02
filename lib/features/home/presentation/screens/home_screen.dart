import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../analytics/presentation/screens/analytics_dashboard.dart';
import '../../../rankings/presentation/screens/rankings_screen.dart';
import '../../../sync/presentation/screens/settings_screen.dart';
import '../../../tracker/presentation/screens/library_screen.dart';
import '../../../search/presentation/screens/game_search_screen.dart';

import '../controllers/home_nav_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<Widget> _destinations = const [
    LibraryScreen(),
    RankingsScreen(),
    AnalyticsDashboard(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentIndex = ref.watch(homeNavIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _destinations,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        elevation: 3,
        shadowColor: Colors.black,
        surfaceTintColor: colorScheme.primary,
        indicatorColor: colorScheme.primaryContainer,
        onDestinationSelected: (index) {
          ref.read(homeNavIndexProvider.notifier).state = index;
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports, color: colorScheme.onPrimaryContainer),
            label: 'Library',
          ),
          NavigationDestination(
            icon: const Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard, color: colorScheme.onPrimaryContainer),
            label: 'Rankings',
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights, color: colorScheme.onPrimaryContainer),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: colorScheme.onPrimaryContainer),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GameSearchScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Game',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }
}
