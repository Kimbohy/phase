import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/planning.dart';

/// Lit et écrit le planning dans le stockage local du téléphone.
class PlanningRepository {
  PlanningRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'planning_json';

  Planning load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return Planning.empty;
    try {
      return Planning.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object catch (e) {
      debugPrint('Planning illisible, on repart de zéro : $e');
      return Planning.empty;
    }
  }

  Future<void> save(Planning planning) {
    return _prefs.setString(_key, jsonEncode(planning.toJson()));
  }
}
