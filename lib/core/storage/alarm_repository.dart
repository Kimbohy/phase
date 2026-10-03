import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm_setting.dart';

class AlarmRepository {
  AlarmRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'alarms_json';

  /// blockId -> réglage
  Map<String, AlarmSetting> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return {
        for (final item in list)
          (item as Map<String, dynamic>)['id'] as String: AlarmSetting.fromJson(
            item,
          ),
      };
    } on Object catch (e) {
      debugPrint('Alarmes illisibles : $e');
      return {};
    }
  }

  Future<void> save(Map<String, AlarmSetting> alarms) {
    return _prefs.setString(
      _key,
      jsonEncode(alarms.values.map((a) => a.toJson()).toList()),
    );
  }
}
