import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/storage/planning_repository.dart';
import 'core/storage/alarm_repository.dart';
import 'providers.dart';
import 'services/alarm_service.dart';
import 'services/widget_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final alarmService = AlarmService(FlutterLocalNotificationsPlugin());
  try {
    await alarmService.init();
  } on Object catch (e) {
    debugPrint('Initialisation des alarmes impossible : $e');
  }

  unawaited(
    WidgetSync.push(
      PlanningRepository(prefs).load(),
      AlarmRepository(prefs).load(),
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        alarmServiceProvider.overrideWithValue(alarmService),
      ],
      child: const PhaseApp(),
    ),
  );
}
