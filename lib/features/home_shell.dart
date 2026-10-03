import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'alarms/alarms_screen.dart';
import 'import/import_screen.dart';
import 'planning/planning_screen.dart';
import 'today/today_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _screens = [
    TodayScreen(),
    PlanningScreen(),
    AlarmsScreen(),
    ImportScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Au démarrage, on recrée les alarmes (au cas où le système les aurait perdues).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alarmsProvider.notifier).reschedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: "Aujourd'hui"),
          NavigationDestination(icon: Icon(Icons.view_week), label: 'Planning'),
          NavigationDestination(icon: Icon(Icons.alarm), label: 'Alarmes'),
          NavigationDestination(icon: Icon(Icons.download), label: 'Import'),
        ],
      ),
    );
  }
}
