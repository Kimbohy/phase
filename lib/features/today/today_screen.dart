import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/engine/phase_state.dart';
import '../../core/engine/planning_engine.dart';
import '../../core/models/planning.dart';
import '../../core/utils/labels.dart';
import '../../core/utils/time_utils.dart';
import '../../providers.dart';
import '../settings/settings_providers.dart';
import '../settings/settings_screen.dart';
import 'block_tile.dart';
import 'free_line.dart';
import 'free_tile.dart';

/// Au plus 3 lignes sont visibles AVANT la ligne active : elle est donc
/// au maximum en 4e position quand on ouvre l'écran.
const _maxRowsBeforeCurrent = 3;

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  final _scroll = ScrollController();

  /// Une clé par ligne (identifiée par son heure de début) pour retrouver
  /// sa position à l'écran. Elles doivent survivre aux reconstructions
  /// (l'écran est reconstruit chaque seconde), d'où ce dictionnaire.
  final _keys = <int, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    // Après le premier affichage : on place l'étape active.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToCurrent(animate: false),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(TimelineEntry entry) =>
      _keys.putIfAbsent(entry.start.millisecondsSinceEpoch, () => GlobalKey());

  /// Les lignes à afficher : tout, ou (par défaut) les blocs + la période libre en cours.
  List<TimelineEntry> _rowsFor(
    Planning planning,
    DateTime now,
    bool showFreeRows,
  ) {
    const engine = PlanningEngine();
    final timeline = engine.dayTimeline(planning, now);
    return showFreeRows ? timeline : engine.onlyCurrentFree(timeline, now);
  }

  /// Une ligne est « active » si l'heure est dedans ET si c'est bien la phase du moteur.
  bool _isCurrentEntry(TimelineEntry entry, PhaseState state, DateTime now) {
    if (!entry.isCurrent(now)) return false;
    return entry.isFree
        ? state.kind == PhaseKind.free
        : entry.block!.id == state.blockId;
  }

  void _scrollToCurrent({required bool animate}) {
    if (!_scroll.hasClients) return;

    final now = DateTime.now();
    final state = ref.read(phaseProvider);
    final rows = _rowsFor(
      ref.read(planningProvider),
      now,
      ref.read(showFreeRowsProvider),
    );
    final current = rows.indexWhere((e) => _isCurrentEntry(e, state, now));
    if (current < 0) return;

    // L'étape active est dans les premières lignes : on affiche le haut de l'écran.
    if (current <= _maxRowsBeforeCurrent) {
      if (animate) {
        unawaited(
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        );
      } else {
        _scroll.jumpTo(0);
      }
      return;
    }

    // Sinon : on place en haut la ligne située 3 lignes avant l'active.
    final anchor = rows[current - _maxRowsBeforeCurrent];
    final target = _keys[anchor.start.millisecondsSinceEpoch]?.currentContext;
    if (target == null) return;
    unawaited(
      Scrollable.ensureVisible(
        target,
        alignment: 0,
        duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
        curve: Curves.easeOut,
      ),
    );
  }

  Widget _row(
    TimelineEntry entry,
    PhaseState state,
    DateTime now,
    bool showFreeRows,
  ) {
    final isCurrent = _isCurrentEntry(entry, state, now);

    final Widget content;
    if (!entry.isFree) {
      content = BlockTile(block: entry.block!, isCurrent: isCurrent);
    } else if (showFreeRows) {
      content = FreeTile(
        start: entry.start,
        end: entry.end,
        isCurrent: isCurrent,
        progress: entry.progress(now),
        now: now,
      );
    } else {
      // Mode « trait » : seule la période libre EN COURS arrive jusqu'ici.
      content = const FreeLine();
    }

    return KeyedSubtree(
      key: _keyFor(entry),
      // Les lignes passées sont atténuées : on voit d'un coup d'œil où on en est.
      child: Opacity(opacity: entry.end.isAfter(now) ? 1 : 0.5, child: content),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planning = ref.watch(planningProvider);
    final state = ref.watch(phaseProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final showFreeRows = ref.watch(showFreeRowsProvider);
    final rows = _rowsFor(planning, now, showFreeRows);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Aujourd'hui"),
        actions: [
          IconButton(
            tooltip: 'Aller à maintenant',
            icon: const Icon(Icons.my_location),
            onPressed: () => _scrollToCurrent(animate: true),
          ),
          IconButton(
            tooltip: 'Réglages',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      // Une colonne dans un SingleChildScrollView : toutes les lignes existent,
      // donc on peut toujours retrouver la position d'une ligne.
      body: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PhaseCard(state: state, now: now),
            const SizedBox(height: 24),
            Text('Ma journée', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (planning.blocks.isEmpty)
              const Text('Aucun bloc. Importe un planning ou crée un bloc.')
            else
              for (final entry in rows) _row(entry, state, now, showFreeRows),
          ],
        ),
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.state, required this.now});

  final PhaseState state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final end = state.end;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(state.displayTitle, style: textTheme.headlineSmall),
            if (state.kind != PhaseKind.empty) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: state.progress, minHeight: 8),
              const SizedBox(height: 8),
              if (end != null)
                Text('Il reste ${formatDuration(end.difference(now))}'),
              if (state.sub != null) ...[
                const SizedBox(height: 4),
                Text(
                  state.sub!.label(now),
                  style: textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 8),
            Text(
              state.kind == PhaseKind.empty
                  ? "Va dans l'onglet Import pour ajouter ton planning."
                  : describeNext(state, now),
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
