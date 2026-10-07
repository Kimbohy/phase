import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/models/alarm_setting.dart';
import '../core/models/block.dart';
import '../core/models/planning.dart';
import '../core/utils/hash_utils.dart';

/// Planifie les alarmes hebdomadaires des blocs.
class AlarmService {
  AlarmService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  static const _channelId = 'block_alarms';

  Future<void> init() async {
    tz_data.initializeTimeZones();
    // Fuseau horaire du téléphone (ex. "Indian/Antananarivo").
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      ),
    );
  }

  /// Demande la permission de notifier + celle des alarmes exactes.
  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final notifications =
        await android?.requestNotificationsPermission() ?? false;
    final exact = await android?.requestExactAlarmsPermission() ?? false;
    return notifications && exact;
  }

  /// Annule tout puis recrée les alarmes activées. Simple et fiable.
  Future<void> rescheduleAll(
    Planning planning,
    Map<String, AlarmSetting> alarms,
  ) async {
    try {
      await _plugin.cancelAll();
      for (final block in planning.blocks) {
        final alarm = alarms[block.id];
        if (alarm == null || !alarm.enabled) continue;
        for (final day in block.days) {
          await _scheduleWeekly(block, alarm, day);
        }
      }
    } on Object catch (e) {
      debugPrint('Planification des alarmes impossible : $e');
    }
  }

  Future<void> _scheduleWeekly(Block block, AlarmSetting alarm, int day) async {
    // Heure de l'alarme = début du bloc - décalage. Peut passer à la veille.
    var minuteOfDay = block.startMin - alarm.offsetMin;
    var weekday = day;
    if (minuteOfDay < 0) {
      minuteOfDay += 1440;
      weekday =
          (day + 5) % 7 + 1; // jour précédent (1 = lundi ... 7 = dimanche)
    }

    await _plugin.zonedSchedule(
      id: _notificationId(block.id, day),
      title: block.name,
      body: alarm.offsetMin == 0
          ? "C'est l'heure"
          : 'Dans ${alarm.offsetMin} min',
      scheduledDate: _nextWeekly(weekday, minuteOfDay),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Alarmes des blocs',
          channelDescription: "Rappels avant ou au début d'un bloc",
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Se répète chaque semaine, le même jour à la même heure.
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Prochaine date (dans le futur) tombant sur ce jour de semaine à cette heure.
  tz.TZDateTime _nextWeekly(int weekday, int minuteOfDay) {
    final now = tz.TZDateTime.now(tz.local);
    for (var i = 0; i <= 7; i++) {
      final candidate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + i,
        minuteOfDay ~/ 60,
        minuteOfDay % 60,
      );
      if (candidate.weekday == weekday && candidate.isAfter(now)) {
        return candidate;
      }
    }
    // Ne devrait jamais arriver ; par sécurité, dans une semaine.
    return now.add(const Duration(days: 7));
  }

  /// Identifiant stable et unique par (bloc, jour).
  int _notificationId(String blockId, int day) {
    return (stableHash(blockId) % 100000000) * 10 + day;
  }
}
