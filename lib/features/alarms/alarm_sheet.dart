import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/alarm_setting.dart';
import '../../core/models/block.dart';
import '../../providers.dart';

Future<void> showAlarmSheet(BuildContext context, Block block) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _AlarmSheet(block: block),
  );
}

class _AlarmSheet extends ConsumerWidget {
  const _AlarmSheet({required this.block});

  final Block block;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting =
        ref.watch(alarmsProvider)[block.id] ??
        AlarmSetting(blockId: block.id, enabled: false, offsetMin: 0);

    Future<void> toggle(bool value) async {
      if (value) {
        // On demande les permissions au moment où l'utilisateur active une alarme.
        await ref.read(alarmServiceProvider).requestPermissions();
      }
      await ref
          .read(alarmsProvider.notifier)
          .put(setting.copyWith(enabled: value));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(block.name, style: Theme.of(context).textTheme.titleLarge),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Alarme'),
            subtitle: const Text('Chaque semaine, aux jours de ce bloc'),
            value: setting.enabled,
            onChanged: toggle,
          ),
          const SizedBox(height: 8),
          const Text('Sonner'),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text("À l'heure")),
              ButtonSegment(value: 5, label: Text('5 min')),
              ButtonSegment(value: 10, label: Text('10 min')),
              ButtonSegment(value: 15, label: Text('15 min')),
            ],
            selected: {setting.offsetMin},
            onSelectionChanged: (selection) => ref
                .read(alarmsProvider.notifier)
                .put(setting.copyWith(offsetMin: selection.first)),
          ),
        ],
      ),
    );
  }
}
