import '../engine/phase_state.dart';
import 'time_utils.dart';

/// "Ensuite : Ménage · 10:00" (ou "demain 07:00", "Lun 07:00").
String describeNext(PhaseState state, DateTime now) {
  final next = state.next;
  if (next == null) return '';

  final today = DateTime(now.year, now.month, now.day);
  final startDay = DateTime(next.start.year, next.start.month, next.start.day);
  final days = startDay.difference(today).inDays;
  final time = formatMinutes(next.start.hour * 60 + next.start.minute);

  final when = switch (days) {
    0 => time,
    1 => 'demain $time',
    _ => '${dayShortName(next.start.weekday)} $time',
  };
  return 'Ensuite : ${next.block.name} · $when';
}
