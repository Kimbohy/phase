import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/block.dart';
import '../../core/utils/time_utils.dart';
import '../../providers.dart';
import 'block_editor_screen.dart';

class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planning = ref.watch(planningProvider);

    return DefaultTabController(
      length: 7,
      initialIndex: DateTime.now().weekday - 1,
      // Builder : donne un context situé SOUS le DefaultTabController,
      // nécessaire pour retrouver l'onglet sélectionné.
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(planning.name),
              bottom: TabBar(
                tabs: [for (final name in dayShortNames) Tab(text: name)],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              tooltip: 'Ajouter un bloc',
              onPressed: () {
                final day = DefaultTabController.of(context).index + 1;
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BlockEditorScreen(initialDay: day),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
            body: TabBarView(
              children: [
                for (var day = 1; day <= 7; day++)
                  _DayList(blocks: planning.blocksForDay(day)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({required this.blocks});

  final List<Block> blocks;

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      return const Center(child: Text('Aucun bloc ce jour-là'));
    }
    return ListView(
      children: [
        for (final block in blocks)
          ListTile(
            title: Text(block.name),
            subtitle: Text(
              '${formatMinutes(block.startMin)} – ${formatMinutes(block.endMin)}'
              '${block.pomodoro != null ? '  ·  pomodoro ${block.pomodoro!.focusMin}/${block.pomodoro!.breakMin}' : ''}',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BlockEditorScreen(block: block),
              ),
            ),
          ),
      ],
    );
  }
}
