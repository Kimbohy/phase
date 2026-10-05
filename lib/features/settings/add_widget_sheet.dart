import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

/// Ouvre une feuille qui propose les widgets disponibles.
/// Utilisée par les réglages ET par l'onboarding : un seul endroit à maintenir.
Future<void> showAddWidgetSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Choisir un widget',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.widgets),
            title: const Text('Widget standard'),
            subtitle: const Text('4x2 : phase, jauge, temps restant, suite'),
            onTap: () => _pin(
              rootContext: context,
              sheetContext: sheetContext,
              androidName: 'PlanningWidgetProvider',
              pickerName: 'Phase',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.view_stream),
            title: const Text('Widget compact'),
            subtitle: const Text('4x1 : moitié de hauteur'),
            onTap: () => _pin(
              rootContext: context,
              sheetContext: sheetContext,
              androidName: 'PlanningWidgetSmallProvider',
              pickerName: 'Phase compact',
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _pin({
  required BuildContext rootContext,
  required BuildContext sheetContext,
  required String androidName,
  required String pickerName,
}) async {
  // On récupère le messager AVANT l'await : on n'utilise pas un context après une pause.
  final messenger = ScaffoldMessenger.of(rootContext);
  Navigator.of(sheetContext).pop();

  final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
  if (supported) {
    await HomeWidget.requestPinWidget(androidName: androidName);
  } else {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          "Appui long sur l'écran d'accueil → Widgets → $pickerName.",
        ),
      ),
    );
  }
}
