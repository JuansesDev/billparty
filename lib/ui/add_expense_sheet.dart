import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../domain/models/expense.dart';
import '../domain/models/plan.dart';
import '../domain/services/split.dart';
import 'money.dart';
import 'widgets/pill_button.dart';

enum _Mode { equal, exact, shares }

/// Add or edit an expense, split equally, by exact amounts, or by shares.
class AddExpenseSheet extends ConsumerStatefulWidget {
  final Plan plan;
  final Expense? existing;

  const AddExpenseSheet({super.key, required this.plan, this.existing});

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController(); // total (equal & shares)

  _Mode _mode = _Mode.equal;
  String? _payerId;

  late Set<String> _equalParticipants; // equal mode
  late Map<String, TextEditingController> _exactCtrls; // exact mode
  late Map<String, int> _weights; // shares mode

  @override
  void initState() {
    super.initState();
    final people = widget.plan.people;
    _exactCtrls = {for (final p in people) p.id: TextEditingController()};
    _weights = {for (final p in people) p.id: 1};

    final existing = widget.existing;
    if (existing == null) {
      _payerId = people.isNotEmpty ? people.first.id : null;
      _equalParticipants = people.map((p) => p.id).toSet();
    } else {
      _descController.text = existing.description;
      _payerId = existing.payerId;
      _equalParticipants = people.map((p) => p.id).toSet();
      if (existing.splitType == 'equal') {
        _mode = _Mode.equal;
        _equalParticipants = existing.shares.keys.toSet();
        _amountController.text = existing.amount.toString();
      } else {
        // Exact (and shares, which we can't reverse) edit as exact amounts.
        _mode = _Mode.exact;
        existing.shares.forEach((id, value) {
          _exactCtrls[id]?.text = value.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    for (final c in _exactCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _exactTotal =>
      _exactCtrls.values.fold(0, (sum, c) => sum + (parseMoney(c.text) ?? 0));

  bool get _isValid {
    if (_descController.text.trim().isEmpty || _payerId == null) return false;
    switch (_mode) {
      case _Mode.equal:
        final amount = parseMoney(_amountController.text);
        return amount != null && amount > 0 && _equalParticipants.isNotEmpty;
      case _Mode.exact:
        return _exactTotal > 0;
      case _Mode.shares:
        final amount = parseMoney(_amountController.text);
        final totalWeight = _weights.values.fold(0, (s, w) => s + w);
        return amount != null && amount > 0 && totalWeight > 0;
    }
  }

  void _submit() {
    if (!_isValid) return;
    final description = _descController.text.trim();

    late final int amount;
    late final SplitStrategy strategy;

    switch (_mode) {
      case _Mode.equal:
        amount = parseMoney(_amountController.text)!;
        strategy = EqualSplit(_equalParticipants.toList());
      case _Mode.exact:
        final amounts = <String, int>{};
        for (final entry in _exactCtrls.entries) {
          final value = parseMoney(entry.value.text) ?? 0;
          if (value > 0) amounts[entry.key] = value;
        }
        amount = amounts.values.fold(0, (s, v) => s + v);
        strategy = ExactSplit(amounts);
      case _Mode.shares:
        amount = parseMoney(_amountController.text)!;
        final weights = {
          for (final e in _weights.entries)
            if (e.value > 0) e.key: e.value,
        };
        strategy = SharesSplit(weights);
    }

    final notifier = ref.read(plansProvider.notifier);
    final existing = widget.existing;
    if (existing == null) {
      notifier.addExpense(
        widget.plan.id,
        description: description,
        amount: amount,
        payerId: _payerId!,
        strategy: strategy,
      );
    } else {
      notifier.updateExpense(
        widget.plan.id,
        existing.id,
        description: description,
        amount: amount,
        payerId: _payerId!,
        strategy: strategy,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'New expense' : 'Edit expense',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<_Mode>(
                segments: const [
                  ButtonSegment(value: _Mode.equal, label: Text('Equal')),
                  ButtonSegment(value: _Mode.exact, label: Text('Exact')),
                  ButtonSegment(value: _Mode.shares, label: Text('Shares')),
                ],
                selected: {_mode},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
            ),
            const SizedBox(height: 18),
            _modeSection(theme),
            const SizedBox(height: 18),
            _label(theme, 'Paid by'),
            Wrap(
              spacing: 8,
              children: widget.plan.people
                  .map(
                    (p) => ChoiceChip(
                      label: Text(p.name),
                      selected: _payerId == p.id,
                      onSelected: (_) => setState(() => _payerId = p.id),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            PillButton(
              label: widget.existing == null ? 'Add expense' : 'Save changes',
              expand: true,
              onPressed: _isValid ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeSection(ThemeData theme) {
    switch (_mode) {
      case _Mode.equal:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _amountField(),
            const SizedBox(height: 16),
            _label(theme, 'Split equally between'),
            Wrap(
              spacing: 8,
              children: widget.plan.people
                  .map(
                    (p) => FilterChip(
                      label: Text(p.name),
                      selected: _equalParticipants.contains(p.id),
                      onSelected: (sel) => setState(() {
                        sel
                            ? _equalParticipants.add(p.id)
                            : _equalParticipants.remove(p.id);
                      }),
                    ),
                  )
                  .toList(),
            ),
          ],
        );

      case _Mode.exact:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(theme, 'How much each one ordered'),
            const SizedBox(height: 4),
            for (final p in widget.plan.people)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(p.name)),
                    SizedBox(
                      width: 130,
                      child: TextField(
                        controller: _exactCtrls[p.id],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.end,
                        decoration: const InputDecoration(
                          prefixText: '\$ ',
                          isDense: true,
                          hintText: '0',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Total: ${formatMoney(_exactTotal)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );

      case _Mode.shares:
        final amount = parseMoney(_amountController.text);
        final weights = {
          for (final e in _weights.entries)
            if (e.value > 0) e.key: e.value,
        };
        final preview = (amount != null && amount > 0 && weights.isNotEmpty)
            ? split(amount, SharesSplit(weights))
            : const <String, int>{};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _amountField(),
            const SizedBox(height: 16),
            _label(theme, 'Shares per person'),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 6),
              child: Text(
                'More shares = pays more. The total splits proportionally.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final p in widget.plan.people)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(p.name)),
                    if (preview[p.id] != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          formatMoney(preview[p.id]!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    _Stepper(
                      value: _weights[p.id]!,
                      onChanged: (v) => setState(() => _weights[p.id] = v),
                    ),
                  ],
                ),
              ),
          ],
        );
    }
  }

  Widget _amountField() => TextField(
    controller: _amountController,
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ '),
    onChanged: (_) => setState(() {}),
  );

  Widget _label(ThemeData theme, String text) => Text(
    text,
    style: theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );
}

class _Stepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _Stepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove, size: 18),
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 22,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}
