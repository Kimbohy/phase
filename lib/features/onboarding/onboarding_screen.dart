import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/add_widget_sheet.dart';

import 'package:permission_handler/permission_handler.dart';

import '../../providers.dart';

/// 4 étapes au premier lancement : bienvenue, alarmes, batterie, widget.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == 3) {
      widget.onDone();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  const _Step(
                    icon: Icons.schedule,
                    title: 'Bienvenue dans Phase',
                    text:
                        'Ton emploi du temps en un coup d\'œil : le bloc en cours, '
                        'le temps restant, ce qui vient ensuite.',
                  ),
                  _Step(
                    icon: Icons.notifications_active,
                    title: 'Alarmes',
                    text:
                        'Pour être prévenu au début d\'un bloc, autorise les '
                        'notifications et les alarmes exactes.',
                    actionLabel: 'Autoriser',
                    onAction: () =>
                        ref.read(alarmServiceProvider).requestPermissions(),
                  ),
                  _Step(
                    icon: Icons.battery_saver,
                    title: 'Batterie',
                    text:
                        'Certains téléphones arrêtent les apps en arrière-plan. '
                        "Désactive l'optimisation batterie pour que le widget et les "
                        'alarmes restent fiables.',
                    actionLabel: 'Ouvrir le réglage',
                    onAction: () =>
                        Permission.ignoreBatteryOptimizations.request(),
                  ),
                  _Step(
                    icon: Icons.widgets,
                    title: 'Le widget',
                    text:
                        'Ajoute un widget Phase à ton écran d\'accueil : '
                        'standard (4x2) ou compact (4x1).',
                    actionLabel: 'Ajouter un widget',
                    onAction: () => showAddWidgetSheet(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_page == 3 ? 'Terminer' : 'Suivant'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.title,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            title,
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(text, style: textTheme.bodyLarge, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 24),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
