import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers.dart';

import 'dart:async';

import 'core/storage/planning_repository.dart';
import 'services/widget_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  unawaited(WidgetSync.push(PlanningRepository(prefs).load()));

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const PhaseApp(),
    ),
  );
}
