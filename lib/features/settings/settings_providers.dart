import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

/// Réglage « périodes libres ».
/// true  : chaque période libre est une ligne, comme un bloc.
/// false : (par défaut) seul un trait visuel indique la période libre EN COURS.
class ShowFreeRowsNotifier extends Notifier<bool> {
  static const _key = 'show_free_rows';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

final showFreeRowsProvider = NotifierProvider<ShowFreeRowsNotifier, bool>(
  ShowFreeRowsNotifier.new,
);
