import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/engine/phase_state.dart';
import '../../core/utils/labels.dart';
import '../../core/utils/time_utils.dart';
import '../../providers.dart';
import 'block_tile.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planning = ref.watch(planningProvider);
    final state = ref.watch(phaseProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final todayBlocks = planning.blocksForDay(now.weekday);

    return Scaffold(
      appBar: AppBar(title: const Text("Aujourd'hui")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PhaseCard(state: state, now: now),
          const SizedBox(height: 24),
          Text('Blocs du jour', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (todayBlocks.isEmpty) const Text('Aucun bloc aujourd\'hui.'),
          for (final block in todayBlocks)
            BlockTile(block: block, isCurrent: state.blockId == block.id),
        ],
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.state, required this.now});

  final PhaseState state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final end = state.end;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(state.displayTitle, style: textTheme.headlineSmall),
            if (state.kind != PhaseKind.empty) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: state.progress, minHeight: 8),
              const SizedBox(height: 8),
              if (end != null)
                Text('Il reste ${formatDuration(end.difference(now))}'),
            ],
            const SizedBox(height: 8),
            Text(
              state.kind == PhaseKind.empty
                  ? "Va dans l'onglet Import pour ajouter ton planning."
                  : describeNext(state, now),
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
