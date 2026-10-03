import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/block.dart';
import '../../core/utils/time_utils.dart';
import '../../providers.dart';
import '../alarms/alarm_sheet.dart';

/// Une ligne de la timeline du jour.
class BlockTile extends ConsumerWidget {
  const BlockTile({super.key, required this.block, required this.isCurrent});

  final Block block;
  final bool isCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final pomodoro = block.pomodoro;
    final hasAlarm = ref.watch(alarmsProvider)[block.id]?.enabled ?? false;

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
      subtitle: Text(
        '${formatMinutes(block.startMin)} – ${formatMinutes(block.endMin)}'
        '${pomodoro != null ? '  ·  ${pomodoro.focusMin}/${pomodoro.breakMin}' : ''}',
      ),
      trailing: IconButton(
        tooltip: 'Alarme',
        icon: Icon(hasAlarm ? Icons.alarm_on : Icons.alarm_add),
        onPressed: () => showAlarmSheet(context, block),
      ),
    );
  }
}
