import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:phase/core/engine/planning_engine.dart';
import 'package:phase/core/models/planning.dart';

void main() {
  final data = jsonDecode(
    File('test/test_vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  final plannings = (data['plannings'] as Map<String, dynamic>).map(
    (name, json) =>
        MapEntry(name, Planning.fromJson(json as Map<String, dynamic>)),
  );

  for (final raw in data['cases'] as List<dynamic>) {
    final testCase = raw as Map<String, dynamic>;

    test(testCase['name'] as String, () {
      final state = const PlanningEngine().compute(
        plannings[testCase['planning']]!,
        DateTime.parse(testCase['now'] as String),
      );
      final expected = testCase['expected'] as Map<String, dynamic>;

      expect(state.kind.name, expected['kind']);
      expect(state.title, expected['title']);
      expect(state.sub?.testLabel, expected['sub']);
      expect(state.next?.block.name, expected['next']);
    });
  }

  test('la progression est entre 0 et 1', () {
    final state = const PlanningEngine().compute(
      plannings['semaine']!,
      DateTime.parse('2026-10-05T09:00:00'),
    );
    expect(state.progress, greaterThan(0));
    expect(state.progress, lessThan(1));
  });
}
