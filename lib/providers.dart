import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/engine/phase_state.dart';
import 'core/engine/planning_engine.dart';
import 'core/models/planning.dart';
import 'core/storage/planning_repository.dart';

import 'services/widget_sync.dart';

/// Fourni au démarrage dans main.dart (voir `overrides`).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('À fournir dans main.dart'),
);

final planningRepositoryProvider = Provider<PlanningRepository>(
  (ref) => PlanningRepository(ref.watch(sharedPreferencesProvider)),
);

/// Le planning courant. Toute modification passe par ce Notifier.
class PlanningNotifier extends Notifier<Planning> {
  @override
  Planning build() => ref.watch(planningRepositoryProvider).load();

  Future<void> setPlanning(Planning planning) async {
    state = planning;
    await ref.read(planningRepositoryProvider).save(planning);
    await WidgetSync.push(planning); // met à jour le widget
  }
}

final planningProvider = NotifierProvider<PlanningNotifier, Planning>(
  PlanningNotifier.new,
);

/// L'heure actuelle, rafraîchie chaque seconde.
final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

/// L'état courant du planning (recalculé quand l'heure ou le planning change).
final phaseProvider = Provider<PhaseState>((ref) {
  final now = ref.watch(clockProvider).value ?? DateTime.now();
  final planning = ref.watch(planningProvider);
  return const PlanningEngine().compute(planning, now);
});
