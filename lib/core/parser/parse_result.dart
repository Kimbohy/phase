import '../models/planning.dart';

enum IssueLevel { error, warning }

/// Un problème repéré dans le texte importé.
class ParseIssue {
  const ParseIssue(this.line, this.level, this.message);

  final int line; // numéro de ligne (à partir de 1)
  final IssueLevel level;
  final String message;

  @override
  String toString() => 'Ligne $line : $message';
}

/// Le planning obtenu (lignes valides) + la liste des problèmes.
class ParseResult {
  const ParseResult({required this.planning, required this.issues});

  final Planning planning;
  final List<ParseIssue> issues;

  bool get hasErrors => issues.any((i) => i.level == IssueLevel.error);
}
