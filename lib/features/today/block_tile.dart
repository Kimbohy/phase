import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/block.dart';
import '../../core/utils/time_utils.dart';
import '../../providers.dart';
import '../alarms/alarm_sheet.dart';
import '../planning/block_editor_screen.dart';

/// Une ligne de bloc dans la timeline du jour.
/// L'icône d'alarme n'apparaît que si une alarme est ACTIVE : elle sert d'indicateur,
/// et un tap dessus permet de la modifier ou de la désactiver.
/// Pour créer une alarme, on passe par l'éditeur de bloc (tap sur la ligne).
class BlockTile extends ConsumerWidget {
  const BlockTile({super.key, required this.block, required this.isCurrent});

  final Block block;
  final bool isCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final pomodoro = block.pomodoro;
    final alarm = ref.watch(alarmsProvider)[block.id];
    final hasAlarm = alarm?.enabled ?? false;

    final details = <String>[
      '${formatMinutes(block.startMin)} – ${formatMinutes(block.endMin)}',
      if (pomodoro != null)
        'pomodoro ${pomodoro.focusMin}/${pomodoro.breakMin}',
      if (hasAlarm)
        alarm!.offsetMin == 0
            ? 'alarme à l\'heure'
            : 'alarme ${alarm.offsetMin} min avant',
    ];

    return ListTile(
      selected: isCurrent,
      selectedTileColor: scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        block.name,
        style: TextStyle(
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(details.join('  ·  ')),
      // Un tap sur la ligne ouvre l'éditeur (alarme comprise).
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BlockEditorScreen(block: block),
        ),
      ),
      trailing: hasAlarm
          ? IconButton(
              tooltip: 'Alarme active',
              icon: const Icon(Icons.alarm_on),
              onPressed: () => showAlarmSheet(context, block),
            )
          : null,
    );
  }
}
