import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/time_utils.dart';
import '../../providers.dart';

class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planning = ref.watch(planningProvider);

    return DefaultTabController(
      length: 7,
      initialIndex: DateTime.now().weekday - 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(planning.name),
          bottom: TabBar(
            tabs: [for (final name in dayShortNames) Tab(text: name)],
          ),
        ),
        body: TabBarView(
          children: [
            for (var day = 1; day <= 7; day++)
              _DayList(blocks: planning.blocksForDay(day)),
          ],
        ),
      ),
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({required this.blocks});

  final List blocks;

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      return const Center(child: Text('Aucun bloc ce jour-là'));
    }
    return ListView(
      children: [
        for (final b in blocks)
          ListTile(
            title: Text(b.name as String),
            subtitle: Text(
              '${formatMinutes(b.startMin as int)} – ${formatMinutes(b.endMin as int)}'
              '${b.pomodoro != null ? '  ·  pomodoro ${b.pomodoro.focusMin}/${b.pomodoro.breakMin}' : ''}',
            ),
          ),
      ],
    );
  }
}
