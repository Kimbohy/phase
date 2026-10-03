import 'package:flutter/material.dart';

import '../../core/models/block.dart';
import '../../core/utils/time_utils.dart';

/// Une ligne de la timeline du jour.
class BlockTile extends StatelessWidget {
  const BlockTile({super.key, required this.block, required this.isCurrent});

  final Block block;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pomodoro = block.pomodoro;

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
    );
  }
}
