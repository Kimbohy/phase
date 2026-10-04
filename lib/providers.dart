import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/engine/phase_state.dart';
import 'core/engine/planning_engine.dart';
import 'core/models/alarm_setting.dart';
import 'core/models/block.dart';
import 'core/models/planning.dart';
import 'core/parser/planning_exporter.dart';
import 'core/storage/alarm_repository.dart';
import 'core/storage/planning_repository.dart';
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

  /// Applique un planning : mémoire, stockage, widget, alarmes.
  Future<void> _apply(Planning planning) async {
    state = planning;
    await ref.read(planningRepositoryProvider).save(planning);
    await WidgetSync.push(planning);
    // Retire les alarmes des blocs disparus et replanifie le reste.
    await ref.read(alarmsProvider.notifier).syncWithPlanning(planning);
  }

  /// Import depuis le texte : remplace TOUT le planning.
  /// [rawText] est le texte tel que tu l'as tapé : il est conservé tel quel.
  Future<void> importPlanning(Planning planning, String rawText) async {
    // Les alarmes des blocs « identiques » suivent leur nouvel identifiant.
    ref.read(alarmsProvider.notifier).carryOver(state, planning);
    await _apply(planning);
    await ref.read(importTextProvider.notifier).setText(rawText);
  }

  /// Ajout ou modification d'un bloc depuis l'interface.
  Future<void> upsertBlock(Block block) async {
    final updated = state.withBlock(block);
    await _apply(updated);
    await ref.read(importTextProvider.notifier).regenerateFrom(updated);
  }

  Future<void> deleteBlock(String id) async {
    final updated = state.withoutBlock(id);
    await _apply(updated);
    await ref.read(importTextProvider.notifier).regenerateFrom(updated);
  }
}

final planningProvider = NotifierProvider<PlanningNotifier, Planning>(
  PlanningNotifier.new,
);

/// Le texte de l'écran Import : un brouillon sauvegardé dans le téléphone.
class ImportTextNotifier extends Notifier<String> {
  static const _key = 'import_text';

  @override
  String build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_key);
    if (saved != null) return saved;

    // Première fois (ou mise à jour de l'app) : le texte reflète le planning actuel.
    final planning = ref.read(planningProvider);
    return planning.blocks.isEmpty
        ? ''
        : const PlanningExporter().export(planning);
  }

  Future<void> setText(String text) async {
    state = text;
    await ref.read(sharedPreferencesProvider).setString(_key, text);
  }

  /// Après une modification depuis l'interface : le texte redevient
  /// le reflet exact du planning.
  Future<void> regenerateFrom(Planning planning) {
    return setText(const PlanningExporter().export(planning));
  }
}

final importTextProvider = NotifierProvider<ImportTextNotifier, String>(
  ImportTextNotifier.new,
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

  /// Après un import : une alarme est conservée si le nouveau planning contient
  /// un bloc identique (même nom, même début, mêmes jours) à l'ancien.
  /// Elle est alors rattachée au nouvel identifiant du bloc.
  void carryOver(Planning from, Planning to) {
    String signature(Block b) =>
        '${b.name}|${b.startMin}|${(b.days.toList()..sort()).join()}';

    final oldIdBySignature = {for (final b in from.blocks) signature(b): b.id};
    final migrated = <String, AlarmSetting>{};

    for (final block in to.blocks) {
      final oldId = oldIdBySignature[signature(block)];
      final setting = oldId == null ? null : state[oldId];
      if (setting != null) {
        migrated[block.id] = AlarmSetting(
          blockId: block.id,
          enabled: setting.enabled,
          offsetMin: setting.offsetMin,
        );
      }
    }
    state = migrated;
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
