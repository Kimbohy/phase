import 'package:flutter_test/flutter_test.dart';
import 'package:phase/core/parser/parse_result.dart';
import 'package:phase/core/parser/planning_exporter.dart';
import 'package:phase/core/parser/planning_parser.dart';

void main() {
  const parser = PlanningParser();

  test('planning simple avec titre, plage de jours et pomodoro', () {
    final result = parser.parse('''
# Ma semaine
[Lun-Ven]
07:00-07:45 | Réveil
08:15-10:00 | Deep Work 1 | pomodoro=25/5
''');

    expect(result.hasErrors, isFalse);
    expect(result.planning.name, 'Ma semaine');
    expect(result.planning.blocks.length, 2);
    expect(result.planning.blocks[0].days, {1, 2, 3, 4, 5});
    expect(result.planning.blocks[1].startMin, 495);
    expect(result.planning.blocks[1].pomodoro!.focusMin, 25);
  });

  test('heures tolérantes : 7h, 07h00, 7:00', () {
    final result = parser.parse('[Sam]\n7h-8:30 | A\n09h00-10h | B');
    expect(result.hasErrors, isFalse);
    expect(result.planning.blocks[0].startMin, 420);
    expect(result.planning.blocks[0].endMin, 510);
    expect(result.planning.blocks[1].endMin, 600);
  });

  test('jours en liste et [Tous]', () {
    expect(
      parser.parse('[Lun, Mer, Ven]\n08:00-09:00 | A').planning.blocks[0].days,
      {1, 3, 5},
    );
    expect(
      parser.parse('[Tous]\n08:00-09:00 | A').planning.blocks[0].days.length,
      7,
    );
  });

  test('bloc qui passe minuit', () {
    final block = parser
        .parse('[Ven]\n22:30-07:00 | Sommeil')
        .planning
        .blocks
        .single;
    expect(block.crossesMidnight, isTrue);
    expect(block.durationMin, 510);
  });

  test('erreur : bloc avant tout en-tête de jours', () {
    final result = parser.parse('08:00-09:00 | A');
    expect(result.hasErrors, isTrue);
    expect(result.issues.single.line, 1);
    expect(result.planning.blocks, isEmpty);
  });

  test('une ligne invalide n\'empêche pas les autres', () {
    final result = parser.parse('[Lun]\n25:00-26:00 | Faux\n08:00-09:00 | Bon');
    expect(result.hasErrors, isTrue);
    expect(result.issues.single.line, 2);
    expect(result.planning.blocks.single.name, 'Bon');
  });

  test('erreur : pomodoro mal formé', () {
    final result = parser.parse('[Lun]\n08:00-10:00 | A | pomodoro=25');
    expect(result.hasErrors, isTrue);
    expect(result.planning.blocks, isEmpty);
  });

  test('avertissement : chevauchement et option inconnue', () {
    final result = parser.parse(
      '[Lun]\n08:00-10:00 | A\n09:00-11:00 | B | couleur=rouge',
    );
    expect(result.hasErrors, isFalse);
    expect(result.issues.where((i) => i.level == IssueLevel.warning).length, 2);
  });

  test('les clôtures de code markdown sont ignorées', () {
    final result = parser.parse('```\n[Lun]\n08:00-09:00 | A\n```');
    expect(result.hasErrors, isFalse);
    expect(result.planning.blocks.length, 1);
  });

  test('export puis import redonne le même planning', () {
    const text = '''
# Test
[Lun-Ven]
07:00-07:45 | Réveil
08:15-10:00 | Deep Work 1 | pomodoro=25/5
[Sam]
09:00-12:00 | Projets
''';
    final first = parser.parse(text).planning;
    final exported = const PlanningExporter().export(first);
    final second = parser.parse(exported).planning;

    expect(second.toJson(), first.toJson());
  });
}
