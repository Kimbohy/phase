import 'package:flutter/material.dart';

import '../../core/utils/time_utils.dart';

/// Une période libre dans la timeline. Si elle est en cours, elle montre
/// une jauge et le temps restant, pour voir où on en est de la journée.
class FreeTile extends StatelessWidget {
  const FreeTile({
    super.key,
    required this.start,
    required this.end,
    required this.isCurrent,
    required this.progress,
    required this.now,
  });

  final DateTime start;
  final DateTime end;
  final bool isCurrent;
  final double progress;
  final DateTime now;

  String _hm(DateTime d) => formatMinutes(d.hour * 60 + d.minute);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Une période qui finit à minuit pile s'affiche « 24:00 ».
    final endsAtMidnight =
        end.hour == 0 && end.minute == 0 && end.isAfter(start);
    final range = '${_hm(start)} – ${endsAtMidnight ? '24:00' : _hm(end)}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent ? scheme.tertiaryContainer : null,
        borderRadius: BorderRadius.circular(12),
        border: isCurrent ? null : Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Libre',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Text(range, style: textTheme.bodySmall),
            ],
          ),
          if (isCurrent) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, minHeight: 6),
            const SizedBox(height: 4),
            Text(
              'Il reste ${formatDuration(end.difference(now))}',
              style: textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
