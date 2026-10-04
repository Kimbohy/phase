import '../models/planning.dart';
import 'phase_state.dart';

class PlanningEngine {
  const PlanningEngine();

  PhaseState compute(Planning planning, DateTime now) {
    if (planning.blocks.isEmpty) return const PhaseState.empty();

    final occurrences = _occurrences(planning, now);

    Occurrence? current;
    for (final o in occurrences) {
      // début inclus, fin exclue
      if (!o.start.isAfter(now) && o.end.isAfter(now)) {
        current = o;
        break;
      }
    }

    Occurrence? next;
    for (final o in occurrences) {
      if (o.start.isAfter(now)) {
        next = o;
        break;
      }
    }

    if (current != null) {
      final total = current.end.difference(current.start).inMilliseconds;
      final elapsed = now.difference(current.start).inMilliseconds;
      final sub = _subPhase(current, now);
      return PhaseState(
        kind: PhaseKind.block,
        title: current.block.name,
        blockId: current.block.id,
        end: current.end,
        progress: (elapsed / total).clamp(0.0, 1.0),
        next: next,
        sub: sub,
        nextBoundary: sub?.endsAt ?? current.end,
      );
    }

    // Aucun bloc en cours : intervalle libre (s'il existe un bloc à venir).
    if (next == null) return const PhaseState.empty();

    DateTime? previousEnd;
    for (final o in occurrences) {
      if (!o.end.isAfter(now) &&
          (previousEnd == null || o.end.isAfter(previousEnd))) {
        previousEnd = o.end;
      }
    }

    var progress = 0.0;
    if (previousEnd != null) {
      final total = next.start.difference(previousEnd).inMilliseconds;
      final elapsed = now.difference(previousEnd).inMilliseconds;
      if (total > 0) progress = (elapsed / total).clamp(0.0, 1.0);
    }

    return PhaseState(
      kind: PhaseKind.free,
      end: next.start,
      progress: progress,
      next: next,
      nextBoundary: next.start,
    );
  }

  /// Les blocs ET les intervalles libres de la journée de [now], dans l'ordre.
  /// Les lignes couvrent la journée entière : de 00:00 à 24:00, sans trou.
  List<TimelineEntry> dayTimeline(Planning planning, DateTime now) {
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = DateTime(now.year, now.month, now.day + 1);

    // Les occurrences qui touchent cette journée, rognées aux bornes de la journée
    // (un bloc qui passe minuit est coupé en deux : la fin d'hier, le début d'aujourd'hui).
    final entries = <TimelineEntry>[];
    for (final o in _occurrences(planning, now)) {
      if (!o.end.isAfter(dayStart) || !o.start.isBefore(dayEnd)) continue;
      entries.add(
        TimelineEntry(
          start: o.start.isBefore(dayStart) ? dayStart : o.start,
          end: o.end.isAfter(dayEnd) ? dayEnd : o.end,
          block: o.block,
        ),
      );
    }
    entries.sort((a, b) => a.start.compareTo(b.start));

    // On intercale les intervalles libres dans les trous.
    final result = <TimelineEntry>[];
    var cursor = dayStart;
    for (final e in entries) {
      if (e.start.isAfter(cursor)) {
        result.add(TimelineEntry(start: cursor, end: e.start));
      }
      result.add(e);
      if (e.end.isAfter(cursor)) cursor = e.end;
    }
    if (cursor.isBefore(dayEnd)) {
      result.add(TimelineEntry(start: cursor, end: dayEnd));
    }
    return result;
  }

  /// Toutes les occurrences d'hier à dans 7 jours, triées par début.
  /// Hier est inclus pour les blocs qui passent minuit.
  List<Occurrence> _occurrences(Planning planning, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final result = <Occurrence>[];

    for (var offset = -1; offset <= 7; offset++) {
      // DateTime(...) accepte un jour hors limites (ex. 32) et normalise.
      final date = DateTime(today.year, today.month, today.day + offset);
      for (final block in planning.blocks) {
        if (!block.days.contains(date.weekday)) continue;
        final start = DateTime(
          date.year,
          date.month,
          date.day,
          0,
          block.startMin,
        );
        final end = DateTime(
          date.year,
          date.month,
          date.day,
          0,
          block.startMin + block.durationMin,
        );
        result.add(Occurrence(block, start, end));
      }
    }

    result.sort((a, b) => a.start.compareTo(b.start));
    return result;
  }

  /// Calcule la sous-phase pomodoro (null si le bloc n'en a pas).
  ///
  /// Règle : la durée est découpée en cycles (focus + pause). Dans le DERNIER
  /// cycle, c'est-à-dire quand il reste moins qu'un cycle complet, tout le
  /// temps restant est du focus : le dernier focus « absorbe » la fin du bloc,
  /// donc il n'y a jamais de pause à la fin.
  SubPhase? _subPhase(Occurrence occurrence, DateTime now) {
    final pomodoro = occurrence.block.pomodoro;
    if (pomodoro == null) return null;

    final total = occurrence.end.difference(occurrence.start);
    final focus = Duration(minutes: pomodoro.focusMin);
    final pause = Duration(minutes: pomodoro.breakMin);
    final cycle = focus + pause;
    if (focus >= total) return null;

    final elapsed = now.difference(occurrence.start);
    final totalFocus =
        (total.inSeconds + cycle.inSeconds - 1) ~/ cycle.inSeconds;

    var cycleStart = Duration.zero;
    var index = 1;
    while (true) {
      if (total - cycleStart <= cycle) {
        return SubPhase(
          isFocus: true,
          index: index,
          total: totalFocus,
          endsAt: occurrence.end,
        );
      }
      final focusEnd = cycleStart + focus;
      final cycleEnd = cycleStart + cycle;
      if (elapsed < focusEnd) {
        return SubPhase(
          isFocus: true,
          index: index,
          total: totalFocus,
          endsAt: occurrence.start.add(focusEnd),
        );
      }
      if (elapsed < cycleEnd) {
        return SubPhase(
          isFocus: false,
          index: index,
          total: totalFocus,
          endsAt: occurrence.start.add(cycleEnd),
        );
      }
      cycleStart = cycleEnd;
      index++;
    }
  }
}
