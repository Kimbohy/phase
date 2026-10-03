import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/engine/phase_state.dart';
import 'core/engine/planning_engine.dart';
import 'core/models/alarm_setting.dart';
import 'core/models/planning.dart';
import 'core/storage/alarm_repository.dart';
import 'core/storage/planning_repository.dart';
import 'core/models/block.dart';
import 'services/alarm_service.dart';
import 'services/widget_sync.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('À fournir dans main.dart'),
);

final planningRepositoryProvider = Provider<PlanningRepository>(
  (ref) => PlanningRepository(ref.watch(sharedPreferencesProvider)),
);

final alarmRepositoryProvider = Provider<AlarmRepository>(
  (ref) => AlarmRepository(ref.watch(sharedPreferencesProvider)),
);

/// Créé et initialisé dans main.dart.
final alarmServiceProvider = Provider<AlarmService>(
  (ref) => AlarmService(FlutterLocalNotificationsPlugin()),
);

/// Le planning courant. Toute modification passe par ce Notifier.
class PlanningNotifier extends Notifier<Planning> {
  @override
  Planning build() => ref.watch(planningRepositoryProvider).load();

  Future<void> setPlanning(Planning planning) async {
    state = planning;
    await ref.read(planningRepositoryProvider).save(planning);
    await WidgetSync.push(planning);
    // Retire les alarmes des blocs disparus et replanifie le reste.
    await ref.read(alarmsProvider.notifier).syncWithPlanning(planning);
  }

  Future<void> upsertBlock(Block block) => setPlanning(state.withBlock(block));

  Future<void> deleteBlock(String id) => setPlanning(state.withoutBlock(id));
}

final planningProvider = NotifierProvider<PlanningNotifier, Planning>(
  PlanningNotifier.new,
);

/// Les alarmes : blocId -> réglage.
class AlarmsNotifier extends Notifier<Map<String, AlarmSetting>> {
  @override
  Map<String, AlarmSetting> build() =>
      ref.watch(alarmRepositoryProvider).load();

  Future<void> put(AlarmSetting setting) async {
    state = {...state, setting.blockId: setting};
    await _persistAndReschedule();
  }

  Future<void> syncWithPlanning(Planning planning) async {
    final ids = planning.blocks.map((b) => b.id).toSet();
    state = {
      for (final entry in state.entries)
        if (ids.contains(entry.key)) entry.key: entry.value,
    };
    await _persistAndReschedule();
  }

  /// À appeler au démarrage de l'app.
  Future<void> reschedule() => _persistAndReschedule();

  Future<void> _persistAndReschedule() async {
    await ref.read(alarmRepositoryProvider).save(state);
    await ref
        .read(alarmServiceProvider)
        .rescheduleAll(ref.read(planningProvider), state);
  }
}

final alarmsProvider =
    NotifierProvider<AlarmsNotifier, Map<String, AlarmSetting>>(
      AlarmsNotifier.new,
    );

final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

final phaseProvider = Provider<PhaseState>((ref) {
  final now = ref.watch(clockProvider).value ?? DateTime.now();
  final planning = ref.watch(planningProvider);
  return const PlanningEngine().compute(planning, now);
});
