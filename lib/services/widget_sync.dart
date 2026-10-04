import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../core/models/planning.dart';

/// Envoie le planning aux widgets Android et leur demande de se redessiner.
class WidgetSync {
  const WidgetSync._();

  static const _bigWidget = 'PlanningWidgetProvider';
  static const _smallWidget = 'PlanningWidgetSmallProvider';
  static const _key = 'planning_json';

  static Future<void> push(Planning planning) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        _key,
        jsonEncode(planning.toJson()),
      );
      // Une demande par type de widget : Android ne réveille un provider
      // que s'il a au moins un widget posé.
      await HomeWidget.updateWidget(androidName: _bigWidget);
      await HomeWidget.updateWidget(androidName: _smallWidget);
    } on Object catch (e) {
      // Ne jamais faire planter l'app à cause du widget.
      debugPrint('Synchronisation du widget impossible : $e');
    }
  }
}
