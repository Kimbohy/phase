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
  final semaine = Planning.fromJson(
    (data['plannings'] as Map<String, dynamic>)['semaine']
        as Map<String, dynamic>,
  );

  String describe(List<TimelineEntry> timeline) =>
      timeline.map((e) => e.block?.name ?? 'Libre').join(' | ');

  List<TimelineEntry> visible(DateTime now) =>
      engine.onlyCurrentFree(engine.dayTimeline(semaine, now), now);

  test('période libre en cours : une seule ligne libre, à la fin', () {
    // Lundi 12:00 : on est dans l'intervalle libre de l'après-midi.
    expect(
      describe(visible(DateTime(2026, 10, 5, 12))),
      'Réveil | Deep Work 1 | Ménage | Libre',
    );
  });

  test('pendant un bloc : plus aucune ligne libre', () {
    expect(
      describe(visible(DateTime(2026, 10, 5, 9))),
      'Réveil | Deep Work 1 | Ménage',
    );
  });

  test('entre deux blocs : la ligne libre est à sa place chronologique', () {
    // Lundi 07:50 : libre entre Réveil (fin 07:45) et Deep Work 1 (début 08:15).
    expect(
      describe(visible(DateTime(2026, 10, 5, 7, 50))),
      'Réveil | Libre | Deep Work 1 | Ménage',
    );
  });
}
