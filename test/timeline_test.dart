import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:phase/core/engine/phase_state.dart';
import 'package:phase/core/engine/planning_engine.dart';
import 'package:phase/core/models/planning.dart';

void main() {
  const engine = PlanningEngine();

  final data = jsonDecode(
    File('test/test_vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final plannings = data['plannings'] as Map<String, dynamic>;
  final semaine = Planning.fromJson(
    plannings['semaine'] as Map<String, dynamic>,
  );

  String describe(List<TimelineEntry> timeline) =>
      timeline.map((e) => e.block?.name ?? 'Libre').join(' | ');

  test('lundi : blocs et intervalles libres', () {
    final t = engine.dayTimeline(semaine, DateTime(2026, 10, 5, 12));
    expect(
      describe(t),
      'Libre | Réveil | Libre | Deep Work 1 | Ménage | Libre',
    );
  });

  test('vendredi : le bloc de nuit est coupé à minuit', () {
    final t = engine.dayTimeline(semaine, DateTime(2026, 10, 9, 12));
    expect(
      describe(t),
      'Libre | Réveil | Libre | Deep Work 1 | Ménage | Libre | Sommeil',
    );
    expect(t.last.end, DateTime(2026, 10, 10)); // coupé à 24:00
  });

  test('samedi : on voit la fin du bloc de la veille', () {
    final t = engine.dayTimeline(semaine, DateTime(2026, 10, 10, 12));
    expect(describe(t), 'Sommeil | Libre');
    expect(t.first.start, DateTime(2026, 10, 10)); // commence à 00:00
  });

  test('la timeline couvre la journée entière, sans trou', () {
    final t = engine.dayTimeline(semaine, DateTime(2026, 10, 5, 12));
    expect(t.first.start, DateTime(2026, 10, 5));
    expect(t.last.end, DateTime(2026, 10, 6));
    for (var i = 0; i < t.length - 1; i++) {
      expect(t[i].end, t[i + 1].start);
    }
  });

  test('une seule ligne est « en cours » à un instant donné', () {
    final now = DateTime(2026, 10, 5, 9, 0);
    final t = engine.dayTimeline(semaine, now);
    expect(t.where((e) => e.isCurrent(now)).length, 1);
  });

  test('planning vide : une seule ligne libre', () {
    final t = engine.dayTimeline(Planning.empty, DateTime(2026, 10, 5, 12));
    expect(t.length, 1);
    expect(t.single.isFree, isTrue);
  });
}
