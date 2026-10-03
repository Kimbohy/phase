import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/alarm_setting.dart';
import '../../core/utils/time_utils.dart';
import '../../providers.dart';

class AlarmsScreen extends ConsumerWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planning = ref.watch(planningProvider);
    final alarms = ref.watch(alarmsProvider);

    // Seulement les blocs qui ont une alarme enregistrée.
    final entries = [
      for (final block in planning.blocks)
        if (alarms[block.id] != null) (block, alarms[block.id]!),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Alarmes')),
      body: entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Aucune alarme.\nDans « Aujourd'hui », touche l'icône d'alarme d'un bloc.",
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              children: [
                for (final (block, alarm) in entries)
                  SwitchListTile(
                    title: Text(block.name),
                    subtitle: Text(_subtitle(block.startMin, alarm)),
                    value: alarm.enabled,
                    onChanged: (value) => ref
                        .read(alarmsProvider.notifier)
                        .put(alarm.copyWith(enabled: value)),
                  ),
              ],
            ),
    );
  }

  String _subtitle(int startMin, AlarmSetting alarm) {
    final time = formatMinutes(startMin - alarm.offsetMin);
    return alarm.offsetMin == 0
        ? 'À $time'
        : '$time (${alarm.offsetMin} min avant)';
  }
}
