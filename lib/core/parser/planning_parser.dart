import '../models/block.dart';
import '../models/planning.dart';
import '../models/pomodoro.dart';
import '../utils/hash_utils.dart';
import '../utils/time_utils.dart';
import 'parse_result.dart';

/// Transforme le texte d'import en [Planning].
/// Principe : une ligne invalide est signalée mais n'empêche pas les autres.
class PlanningParser {
  const PlanningParser();

  static const _dayPrefixes = {
    'lun': 1,
    'mar': 2,
    'mer': 3,
    'jeu': 4,
    'ven': 5,
    'sam': 6,
    'dim': 7,
  };

  ParseResult parse(String text) {
    final issues = <ParseIssue>[];
    final blocks = <Block>[];
    final usedIds = <String>{};
    final lineOfBlock = <String, int>{};
    var planningName = Planning.empty.name;
    Set<int>? currentDays;
    var seenContent = false;

    final lines = text.split(RegExp(r'\r?\n'));
    for (var i = 0; i < lines.length; i++) {
      final lineNo = i + 1;
      final line = lines[i].trim();

      // Lignes vides et clôtures de code markdown (les LLM en ajoutent parfois).
      if (line.isEmpty || line.startsWith('```')) continue;

      // "# ..." : titre si c'est la première ligne utile, sinon commentaire.
      if (line.startsWith('#')) {
        if (!seenContent) {
          final title = line.replaceFirst(RegExp(r'^#+\s*'), '');
          if (title.isNotEmpty) planningName = title;
        }
        seenContent = true;
        continue;
      }
      seenContent = true;

      // En-tête de jours : [Lun-Ven]
      if (line.startsWith('[')) {
        if (!line.endsWith(']')) {
          issues.add(
            ParseIssue(
              lineNo,
              IssueLevel.error,
              'en-tête de jours : il manque le "]"',
            ),
          );
          currentDays = null;
          continue;
        }
        final days = _parseDays(line.substring(1, line.length - 1));
        if (days == null) {
          issues.add(
            ParseIssue(
              lineNo,
              IssueLevel.error,
              'jours non reconnus (exemples : [Lun-Ven], [Sam, Dim], [Tous])',
            ),
          );
        }
        currentDays = days;
        continue;
      }

      // Sinon : une ligne de bloc.
      final block = _parseBlockLine(line, lineNo, currentDays, usedIds, issues);
      if (block != null) {
        blocks.add(block);
        lineOfBlock[block.id] = lineNo;
      }
    }

    issues
      ..addAll(_findOverlaps(blocks, lineOfBlock))
      ..sort((a, b) => a.line.compareTo(b.line));

    return ParseResult(
      planning: Planning(name: planningName, blocks: blocks),
      issues: issues,
    );
  }

  Block? _parseBlockLine(
    String line,
    int lineNo,
    Set<int>? days,
    Set<String> usedIds,
    List<ParseIssue> issues,
  ) {
    void error(String message) =>
        issues.add(ParseIssue(lineNo, IssueLevel.error, message));
    void warning(String message) =>
        issues.add(ParseIssue(lineNo, IssueLevel.warning, message));

    if (days == null) {
      error('aucun jour défini avant ce bloc');
      return null;
    }

    final parts = line.split('|').map((p) => p.trim()).toList();
    if (parts.length < 2) {
      error('format attendu : HH:MM-HH:MM | Nom');
      return null;
    }

    // Les LLM écrivent parfois un tiret long : on le remplace.
    final range = parts[0].replaceAll('–', '-').replaceAll('—', '-').split('-');
    if (range.length != 2) {
      error('plage horaire attendue, par exemple 08:15-10:00');
      return null;
    }
    final start = parseTimeToMinutes(range[0]);
    final end = parseTimeToMinutes(range[1]);
    if (start == null || end == null) {
      error('heure invalide');
      return null;
    }
    if (start == end) {
      error("l'heure de début et de fin sont identiques");
      return null;
    }

    final name = parts[1];
    if (name.isEmpty) {
      error('nom du bloc manquant');
      return null;
    }
    if (name.length > 40) {
      error('nom trop long (40 caractères maximum)');
      return null;
    }

    final duration = end <= start ? 1440 - start + end : end - start;
    Pomodoro? pomodoro;
    var optionsOk = true;

    for (final option in parts.skip(2)) {
      if (option.isEmpty) continue;
      final eq = option.indexOf('=');
      final key = (eq == -1 ? option : option.substring(0, eq))
          .trim()
          .toLowerCase();
      final value = eq == -1 ? '' : option.substring(eq + 1).trim();

      if (key == 'pomodoro') {
        final match = RegExp(r'^(\d+)\s*/\s*(\d+)$').firstMatch(value);
        final focus = match == null ? 0 : int.parse(match.group(1)!);
        final pause = match == null ? 0 : int.parse(match.group(2)!);
        if (focus <= 0 || pause <= 0) {
          error('format attendu : pomodoro=25/5');
          optionsOk = false;
        } else {
          pomodoro = Pomodoro(focusMin: focus, breakMin: pause);
          if (focus >= duration) {
            warning('le focus est plus long que le bloc : pomodoro ignoré');
          }
        }
      } else {
        warning('option "$key" ignorée');
      }
    }
    if (!optionsOk) return null;

    // Identifiant stable ; si le même bloc apparaît deux fois, on suffixe.
    var id = makeBlockId(name, start, days);
    var suffix = 2;
    while (!usedIds.add(id)) {
      id = '${makeBlockId(name, start, days)}-$suffix';
      suffix++;
    }

    return Block(
      id: id,
      days: days,
      startMin: start,
      endMin: end,
      name: name,
      pomodoro: pomodoro,
    );
  }

  /// "Lun-Ven", "Lun, Mer, Ven", "Sam", "Tous".
  Set<int>? _parseDays(String text) {
    final t = text.trim().toLowerCase();
    if (t == 'tous' || t == 'tous les jours') return {1, 2, 3, 4, 5, 6, 7};

    final days = <int>{};
    for (final raw in t.split(',')) {
      final part = raw.trim();
      if (part.isEmpty) return null;

      if (part.contains('-')) {
        final ends = part.split('-');
        if (ends.length != 2) return null;
        final first = _dayNumber(ends[0]);
        final last = _dayNumber(ends[1]);
        if (first == null || last == null) return null;
        // Gère aussi les plages qui bouclent (ex. Sam-Lun).
        var d = first;
        while (true) {
          days.add(d);
          if (d == last) break;
          d = d % 7 + 1;
        }
      } else {
        final d = _dayNumber(part);
        if (d == null) return null;
        days.add(d);
      }
    }
    return days.isEmpty ? null : days;
  }

  /// "lundi", "Lun", "lun." -> 1. On ne regarde que les 3 premières lettres.
  int? _dayNumber(String text) {
    final t = text.trim().toLowerCase();
    if (t.length < 3) return null;
    return _dayPrefixes[t.substring(0, 3)];
  }

  /// Avertit quand deux blocs se chevauchent un même jour.
  List<ParseIssue> _findOverlaps(
    List<Block> blocks,
    Map<String, int> lineOfBlock,
  ) {
    final segments = <_Segment>[];
    for (final block in blocks) {
      for (final day in block.days) {
        if (block.crossesMidnight) {
          segments.add(_Segment(day, block.startMin, 1440, block));
          if (block.endMin > 0) {
            segments.add(_Segment(day % 7 + 1, 0, block.endMin, block));
          }
        } else {
          segments.add(_Segment(day, block.startMin, block.endMin, block));
        }
      }
    }

    final issues = <ParseIssue>[];
    final reported = <String>{};
    for (var day = 1; day <= 7; day++) {
      final list = segments.where((s) => s.day == day).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

      for (var i = 0; i < list.length; i++) {
        for (var j = i + 1; j < list.length; j++) {
          if (list[j].start >= list[i].end) {
            break; // triés : plus aucun chevauchement
          }
          if (identical(list[i].block, list[j].block)) continue;

          final a = list[i].block;
          final b = list[j].block;
          if (!reported.add('${a.id}|${b.id}|$day')) continue;

          final lineA = lineOfBlock[a.id] ?? 0;
          final lineB = lineOfBlock[b.id] ?? 0;
          issues.add(
            ParseIssue(
              lineA > lineB ? lineA : lineB,
              IssueLevel.warning,
              'lignes $lineA et $lineB : chevauchement le ${dayShortName(day)}',
            ),
          );
        }
      }
    }
    return issues;
  }
}

class _Segment {
  const _Segment(this.day, this.start, this.end, this.block);

  final int day;
  final int start;
  final int end;
  final Block block;
}
