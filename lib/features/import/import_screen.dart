import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/parser/parse_result.dart';
import '../../core/parser/planning_parser.dart';
import '../../core/prompt/llm_prompt.dart';
import '../../providers.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  late final TextEditingController _controller;
  ParseResult? _result;

  @override
  void initState() {
    super.initState();
    // Le champ démarre avec le texte sauvegardé.
    _controller = TextEditingController(text: ref.read(importTextProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _copyPrompt() async {
    await Clipboard.setData(const ClipboardData(text: llmPrompt));
    if (!mounted) return;
    _showMessage('Prompt copié. Colle-le dans un LLM.');
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (!mounted || text == null) return;

    _controller.text = text;
    await ref.read(importTextProvider.notifier).setText(text);
    if (!mounted) return;
    _analyze();
  }

  /// Remet dans le champ le texte qui correspond au planning actuel.
  Future<void> _reload() async {
    await ref
        .read(importTextProvider.notifier)
        .regenerateFrom(ref.read(planningProvider));
    // Le champ se met à jour tout seul (voir ref.listen dans build).
  }

  void _analyze() {
    setState(() => _result = const PlanningParser().parse(_controller.text));
  }

  Future<bool> _confirmReplace(int oldCount, int newCount, bool hasErrors) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remplacer le planning ?'),
        content: Text(
          'Importer ce texte supprime les $oldCount blocs actuels et les '
          'remplace par les $newCount blocs du texte.\n\n'
          '${hasErrors ? 'Attention : des lignes en erreur seront ignorées.\n\n' : ''}'
          'Les alarmes des blocs identiques sont conservées, les autres sont supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remplacer'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _apply() async {
    // On relit TOUJOURS le texte actuel (pas une ancienne analyse).
    final result = const PlanningParser().parse(_controller.text);
    setState(() => _result = result);

    final newCount = result.planning.blocks.length;
    if (newCount == 0) {
      _showMessage('Aucun bloc valide à importer.');
      return;
    }

    // Rien à perdre si le planning actuel est vide : pas de confirmation.
    final current = ref.read(planningProvider);
    if (current.blocks.isNotEmpty) {
      final ok = await _confirmReplace(current.blocks.length, newCount, result.hasErrors);
      if (!ok || !mounted) return;
    }

    await ref
        .read(planningProvider.notifier)
        .importPlanning(result.planning, _controller.text);
    if (!mounted) return;
    _showMessage('Planning remplacé : $newCount blocs.');
  }

  @override
  Widget build(BuildContext context) {
    // Quand le texte change ailleurs (modification depuis l'interface, « Recharger »),
    // on met le champ à jour et on efface l'ancienne analyse.
    ref.listen<String>(importTextProvider, (previous, next) {
      if (_controller.text != next) {
        setState(() {
          _controller.text = next;
          _result = null;
        });
      }
    });

    final text = ref.watch(importTextProvider);
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('Importer un planning')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: _copyPrompt,
                icon: const Icon(Icons.copy),
                label: const Text('Copier le prompt'),
              ),
              FilledButton.tonalIcon(
                onPressed: _paste,
                icon: const Icon(Icons.paste),
                label: const Text('Coller'),
              ),
              OutlinedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Recharger le planning actuel'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: 8,
            maxLines: 16,
            style: const TextStyle(fontFamily: 'monospace'),
            // Sauvegarde du brouillon à chaque modification.
            onChanged: (value) =>
                unawaited(ref.read(importTextProvider.notifier).setText(value)),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '[Lun-Ven]\n07:00-07:45 | Réveil\n...',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(onPressed: _analyze, child: const Text('Analyser')),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: text.trim().isEmpty ? null : _apply,
                child: const Text('Importer'),
              ),
            ],
          ),
          if (result != null) ...[
            const SizedBox(height: 16),
            Text('${result.planning.blocks.length} blocs reconnus'),
            if (result.issues.isEmpty)
              const Text('Aucun problème détecté.')
            else
              for (final issue in result.issues)
                ListTile(
                  dense: true,
                  leading: Icon(
                    issue.level == IssueLevel.error
                        ? Icons.error_outline
                        : Icons.warning_amber,
                    color: issue.level == IssueLevel.error ? Colors.red : Colors.orange,
                  ),
                  title: Text(issue.toString()),
                ),
          ],
        ],
      ),
    );
  }
}