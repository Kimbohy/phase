import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/block.dart';
import '../../core/models/pomodoro.dart';
import '../../core/utils/time_utils.dart';
import '../../providers.dart';

/// Crée un bloc (block == null) ou modifie un bloc existant.
class BlockEditorScreen extends ConsumerStatefulWidget {
  const BlockEditorScreen({super.key, this.block, this.initialDay});

  final Block? block;
  final int? initialDay; // jour présélectionné pour un nouveau bloc

  @override
  ConsumerState<BlockEditorScreen> createState() => _BlockEditorScreenState();
}

class _BlockEditorScreenState extends ConsumerState<BlockEditorScreen> {
  late final TextEditingController _name;
  late final TextEditingController _focus;
  late final TextEditingController _break;
  late Set<int> _days;
  late int _start;
  late int _end;
  late bool _pomodoro;
  String? _error;

  @override
  void initState() {
    super.initState();
    final b = widget.block;
    _name = TextEditingController(text: b?.name ?? '');
    _focus = TextEditingController(text: '${b?.pomodoro?.focusMin ?? 25}');
    _break = TextEditingController(text: '${b?.pomodoro?.breakMin ?? 5}');

    final days = {...?b?.days};
    if (days.isEmpty && widget.initialDay != null) days.add(widget.initialDay!);
    _days = days;

    _start = b?.startMin ?? 9 * 60;
    _end = b?.endMin ?? 10 * 60;
    _pomodoro = b?.pomodoro != null;
  }

  @override
  void dispose() {
    _name.dispose();
    _focus.dispose();
    _break.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    setState(() {
      final minutes = picked.hour * 60 + picked.minute;
      if (isStart) {
        _start = minutes;
      } else {
        _end = minutes;
      }
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final focus = int.tryParse(_focus.text.trim()) ?? 0;
    final pause = int.tryParse(_break.text.trim()) ?? 0;

    String? error;
    if (name.isEmpty || name.length > 40) {
      error = 'Le nom doit faire entre 1 et 40 caractères.';
    } else if (_days.isEmpty) {
      error = 'Choisis au moins un jour.';
    } else if (_start == _end) {
      error = 'Le début et la fin doivent être différents.';
    } else if (_pomodoro && (focus <= 0 || pause <= 0)) {
      error = 'Focus et pause doivent être supérieurs à 0.';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    final pomodoro = _pomodoro
        ? Pomodoro(focusMin: focus, breakMin: pause)
        : null;
    final existing = widget.block;
    final block = existing == null
        ? Block(
            id: DateTime.now().microsecondsSinceEpoch.toRadixString(16),
            days: _days,
            startMin: _start,
            endMin: _end,
            name: name,
            pomodoro: pomodoro,
          )
        : existing.copyWith(
            name: name,
            days: _days,
            startMin: _start,
            endMin: _end,
            pomodoro: pomodoro,
            clearPomodoro: pomodoro == null,
          );

    await ref.read(planningProvider.notifier).upsertBlock(block);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.block;
    if (existing == null) return;
    await ref.read(planningProvider.notifier).deleteBlock(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.block == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Nouveau bloc' : 'Modifier le bloc'),
        actions: [
          if (!isNew)
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'Nom',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (var day = 1; day <= 7; day++)
                FilterChip(
                  label: Text(dayShortName(day)),
                  selected: _days.contains(day),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _days.add(day);
                    } else {
                      _days.remove(day);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickTime(isStart: true),
                  child: Text('Début ${formatMinutes(_start)}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickTime(isStart: false),
                  child: Text('Fin ${formatMinutes(_end)}'),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Découper en pomodoro'),
            value: _pomodoro,
            onChanged: (value) => setState(() => _pomodoro = value),
          ),
          if (_pomodoro)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _focus,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Focus (min)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _break,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pause (min)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Enregistrer')),
        ],
      ),
    );
  }
}
