import '../models/block.dart';
import '../models/planning.dart';
import '../utils/time_utils.dart';

/// Transforme un [Planning] en texte au format d'import.
class PlanningExporter {
  const PlanningExporter();

  String export(Planning planning) {
    final buffer = StringBuffer('# ${planning.name}\n');

    // On regroupe les blocs qui ont exactement les mêmes jours.
    final groups = <String, List<Block>>{};
    final daysOfGroup = <String, Set<int>>{};
    for (final block in planning.blocks) {
      final key = (block.days.toList()..sort()).join();
      groups.putIfAbsent(key, () => []).add(block);
      daysOfGroup[key] = block.days;
    }

    for (final entry in groups.entries) {
      buffer.writeln('\n[${_daysHeader(daysOfGroup[entry.key]!)}]');
      final sorted = [...entry.value]
        ..sort((a, b) => a.startMin.compareTo(b.startMin));
      for (final b in sorted) {
        final options = b.pomodoro == null
            ? ''
            : ' | pomodoro=${b.pomodoro!.focusMin}/${b.pomodoro!.breakMin}';
        buffer.writeln(
          '${formatMinutes(b.startMin)}-${formatMinutes(b.endMin)} | ${b.name}$options',
        );
      }
    }
    return buffer.toString();
  }

  /// {1,2,3,4,5} -> "Lun-Ven" ; {6} -> "Sam" ; {1,3} -> "Lun, Mer".
  String _daysHeader(Set<int> days) {
    if (days.length == 7) return 'Tous';
    final sorted = days.toList()..sort();

    final parts = <String>[];
    var i = 0;
    while (i < sorted.length) {
      var j = i;
      while (j + 1 < sorted.length && sorted[j + 1] == sorted[j] + 1) {
        j++;
      }
      if (j - i >= 2) {
        parts.add('${dayShortName(sorted[i])}-${dayShortName(sorted[j])}');
      } else {
        for (var k = i; k <= j; k++) {
          parts.add(dayShortName(sorted[k]));
        }
      }
      i = j + 1;
    }
    return parts.join(', ');
  }
}
