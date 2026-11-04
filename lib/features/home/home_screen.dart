import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toefl_prep/ads/ad_service.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/features/home/guide_tab.dart';
import 'package:toefl_prep/features/home/practice_tab.dart';
import 'package:toefl_prep/features/home/progress_tab.dart';
import 'package:toefl_prep/features/home/tests_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.about,
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.push('/about'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [TestsTab(), PracticeTab(), GuideTab(), ProgressTab()],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ref.watch(adServiceProvider).banner(),
          NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (tab) => setState(() => _tab = tab),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.assignment_outlined),
                label: l10n.tabTests,
              ),
              NavigationDestination(
                icon: const Icon(Icons.fitness_center),
                label: l10n.tabPractice,
              ),
              NavigationDestination(
                icon: const Icon(Icons.lightbulb_outline),
                label: l10n.tabGuide,
              ),
              NavigationDestination(
                icon: const Icon(Icons.insights),
                label: l10n.tabProgress,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
