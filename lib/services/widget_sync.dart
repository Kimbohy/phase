import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../core/models/planning.dart';

/// Envoie le planning au widget Android et lui demande de se redessiner.
class WidgetSync {
  const WidgetSync._();

  static const _androidName = 'PlanningWidgetProvider';
  static const _key = 'planning_json';

  static Future<void> push(Planning planning) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        _key,
        jsonEncode(planning.toJson()),
      );
      await HomeWidget.updateWidget(androidName: _androidName);
    } on Object catch (e) {
      // Ne jamais faire planter l'app à cause du widget.
      debugPrint('Synchronisation du widget impossible : $e');
    }
  }
}
