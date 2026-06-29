import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';

class NewPlanDialog extends ConsumerStatefulWidget {
  const NewPlanDialog({super.key});

  @override
  ConsumerState<NewPlanDialog> createState() => _NewPlanDialogState();
}

class _NewPlanDialogState extends ConsumerState<NewPlanDialog> {
  final _nameController = TextEditingController();
  final _personController = TextEditingController();
  final List<String> _people = [];

  @override
  void dispose() {
    _nameController.dispose();
    _personController.dispose();
    super.dispose();
  }

  void _addPerson() {
    final name = _personController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _people.add(name);
      _personController.clear();
    });
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty && _people.length >= 2;

  void _submit() {
    if (!_isValid) return;
    ref
        .read(plansProvider.notifier)
        .createPlan(_nameController.text.trim(), _people);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('New plan'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Plan name',
                hintText: 'Trip to Cartagena',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _personController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Add person',
                hintText: 'Ana',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addPerson,
                ),
              ),
              onSubmitted: (_) => _addPerson(),
            ),
            if (_people.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _people.asMap().entries.map((entry) {
                  return InputChip(
                    label: Text(entry.value),
                    onDeleted: () =>
                        setState(() => _people.removeAt(entry.key)),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _people.length < 2
                  ? 'Add at least 2 people'
                  : '${_people.length} people',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isValid ? _submit : null,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
