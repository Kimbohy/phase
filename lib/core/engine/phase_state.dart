import '../models/block.dart';

/// Un bloc placé à une date précise (début et fin réels).
class Occurrence {
  const Occurrence(this.block, this.start, this.end);

  final Block block;
  final DateTime start;
  final DateTime end;
}

/// Sous-phase d'un pomodoro : un focus ou une pause.
class SubPhase {
  const SubPhase({
    required this.isFocus,
    required this.index,
    required this.total,
    required this.endsAt,
  });

  final bool isFocus;
  final int index; // numéro du focus (1, 2, 3...)
  final int total; // nombre total de focus dans le bloc
  final DateTime endsAt;

  /// Texte stable partagé avec les tests Kotlin : "focus 2/4" ou "pause 2/4".
  String get testLabel => '${isFocus ? 'focus' : 'pause'} $index/$total';

  /// Texte affiché à l'écran.
  String label(DateTime now) {
    if (isFocus) return 'Focus $index/$total';
    final minutes = (endsAt.difference(now).inSeconds / 60).ceil();
    return 'Pause · $minutes min';
  }
}

enum PhaseKind { block, free, empty }

/// Réponse du moteur à : « que se passe-t-il à cet instant ? »
class PhaseState {
  const PhaseState({
    required this.kind,
    this.title,
    this.blockId,
    this.end,
    this.progress = 0,
    this.next,
    this.sub,
    this.nextBoundary,
  });

  const PhaseState.empty() : this(kind: PhaseKind.empty);

  final PhaseKind kind;
  final String? title; // nom du bloc (null si libre ou vide)
  final String? blockId;
  final DateTime? end; // fin de la phase en cours
  final double progress; // 0.0 à 1.0
  final Occurrence? next;
  final SubPhase? sub;
  final DateTime? nextBoundary; // prochain instant où l'affichage change

  String get displayTitle => switch (kind) {
    PhaseKind.block => title ?? '',
    PhaseKind.free => 'Libre',
    PhaseKind.empty => 'Aucun planning',
  };
}
