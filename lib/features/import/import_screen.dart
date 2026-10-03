import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/parser/parse_result.dart';
import '../../core/parser/planning_parser.dart';
import '../../core/prompt/llm_prompt.dart';
import '../../providers.dart';

/// StatefulWidget : on garde le texte saisi et le résultat de l'analyse.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final _controller = TextEditingController();
  ParseResult? _result;

  @override
  void dispose() {
    _controller.dispose(); // toujours libérer les controllers
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _copyPrompt() async {
    await Clipboard.setData(const ClipboardData(text: llmPrompt));
    if (!mounted) return; // l'écran a pu être fermé pendant l'await
    _showMessage('Prompt copié. Colle-le dans un LLM.');
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    if (!mounted || data?.text == null) return;
    setState(() => _controller.text = data!.text!);
    _analyze();
  }

  void _analyze() {
    setState(() => _result = const PlanningParser().parse(_controller.text));
  }

  Future<void> _apply() async {
    final result = _result;
    if (result == null) return;
    await ref.read(planningProvider.notifier).setPlanning(result.planning);
    if (!mounted) return;
    _showMessage('Planning importé (${result.planning.blocks.length} blocs).');
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final blockCount = result?.planning.blocks.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Importer un planning')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
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
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: 8,
            maxLines: 16,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '[Lun-Ven]\n07:00-07:45 | Réveil\n...',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: _analyze,
                child: const Text('Analyser'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: blockCount > 0
                    ? _apply
                    : null, // null = bouton grisé
                child: Text(
                  result?.hasErrors ?? false
                      ? 'Importer quand même ($blockCount blocs)'
                      : 'Importer ($blockCount blocs)',
                ),
              ),
            ],
          ),
          if (result != null) ...[
            const SizedBox(height: 16),
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
                    color: issue.level == IssueLevel.error
                        ? Colors.red
                        : Colors.orange,
                  ),
                  title: Text(issue.toString()),
                ),
          ],
        ],
      ),
    );
  }
}
