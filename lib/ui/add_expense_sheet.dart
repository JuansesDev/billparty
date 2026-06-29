import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../domain/models/plan.dart';
import '../domain/services/split.dart';
import 'money.dart';

/// Bottom sheet to add an expense, split equally among the chosen people.
class AddExpenseSheet extends ConsumerStatefulWidget {
  final Plan plan;

  const AddExpenseSheet({super.key, required this.plan});

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  String? _payerId;
  late Set<String> _participantIds;

  @override
  void initState() {
    super.initState();
    final people = widget.plan.people;
    _payerId = people.isNotEmpty ? people.first.id : null;
    _participantIds = people.map((p) => p.id).toSet(); // everyone by default
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final amount = parseMoney(_amountController.text);
    return _descController.text.trim().isNotEmpty &&
        amount != null &&
        amount > 0 &&
        _payerId != null &&
        _participantIds.isNotEmpty;
  }

  void _submit() {
    final amount = parseMoney(_amountController.text);
    if (!_isValid || amount == null) return;

    ref
        .read(plansProvider.notifier)
        .addExpense(
          widget.plan.id,
          description: _descController.text.trim(),
          amount: amount,
          payerId: _payerId!,
          strategy: EqualSplit(_participantIds.toList()),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final people = widget.plan.people;

    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New expense',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Dinner at the beach',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            _label(theme, 'Paid by'),
            Wrap(
              spacing: 8,
              children: people
                  .map(
                    (p) => ChoiceChip(
                      label: Text(p.name),
                      selected: _payerId == p.id,
                      onSelected: (_) => setState(() => _payerId = p.id),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            _label(theme, 'Split equally between'),
            Wrap(
              spacing: 8,
              children: people
                  .map(
                    (p) => FilterChip(
                      label: Text(p.name),
                      selected: _participantIds.contains(p.id),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _participantIds.add(p.id);
                        } else {
                          _participantIds.remove(p.id);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isValid ? _submit : null,
                child: const Text('Add expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
