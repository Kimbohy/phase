import 'package:flutter/material.dart';

/// Indication visuelle d'une période libre EN COURS : un point et un trait,
/// sans aucun texte. Comme le repère « maintenant » d'un agenda.
class FreeLine extends StatelessWidget {
  const FreeLine({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Semantics(
      // Lu par les lecteurs d'écran, jamais affiché.
      label: 'Maintenant : période libre',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Expanded(child: Container(height: 2, color: color)),
          ],
        ),
      ),
    );
  }
}
