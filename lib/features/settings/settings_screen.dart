import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/parser/planning_exporter.dart';
import '../../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Autoriser les alarmes'),
            subtitle: const Text('Notifications + alarmes exactes'),
            onTap: () async {
              final ok = await ref
                  .read(alarmServiceProvider)
                  .requestPermissions();
              if (!context.mounted) return;
              _message(
                context,
                ok ? 'Permissions accordées.' : 'Permissions manquantes.',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.battery_saver),
            title: const Text("Désactiver l'optimisation batterie"),
            subtitle: const Text(
              'Indispensable sur certains téléphones (Xiaomi, Tecno, Infinix, Samsung...)',
            ),
            onTap: () => Permission.ignoreBatteryOptimizations.request(),
          ),
          ListTile(
            leading: const Icon(Icons.widgets),
            title: const Text("Ajouter le widget à l'écran d'accueil"),
            onTap: () async {
              final supported =
                  await HomeWidget.isRequestPinWidgetSupported() ?? false;
              if (!context.mounted) return;
              if (supported) {
                await HomeWidget.requestPinWidget(
                  androidName: 'PlanningWidgetProvider',
                );
              } else {
                _message(
                  context,
                  'Appui long sur l\'écran d\'accueil → Widgets → Phase.',
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Copier mon planning en texte'),
            subtitle: const Text(
              'Pour le sauvegarder ou le modifier avec un LLM',
            ),
            onTap: () async {
              final text = const PlanningExporter().export(
                ref.read(planningProvider),
              );
              await Clipboard.setData(ClipboardData(text: text));
              if (!context.mounted) return;
              _message(context, 'Planning copié.');
            },
          ),
        ],
      ),
    );
  }
}
