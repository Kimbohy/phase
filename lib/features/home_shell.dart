import 'package:flutter/material.dart';

import 'import/import_screen.dart';
import 'planning/planning_screen.dart';
import 'today/today_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [TodayScreen(), PlanningScreen(), ImportScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack garde chaque écran en vie : on ne perd pas le texte saisi.
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: "Aujourd'hui"),
          NavigationDestination(icon: Icon(Icons.view_week), label: 'Planning'),
          NavigationDestination(icon: Icon(Icons.download), label: 'Import'),
        ],
      ),
    );
  }
}
