import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import 'money.dart';
import 'widgets/pill_button.dart';

/// Records a payment from one person to another. Pre-fills the suggested
/// amount, but you can enter less for a partial payment — the remaining debt
/// stays and re-appears in the settle list.
class RecordPaymentDialog extends ConsumerStatefulWidget {
  final String planId;
  final String fromId;
  final String toId;
  final String fromName;
  final String toName;
  final int suggested;
  final String? expenseId;

  const RecordPaymentDialog({
    super.key,
    required this.planId,
    required this.fromId,
    required this.toId,
    required this.fromName,
    required this.toName,
    required this.suggested,
    this.expenseId,
  });

  @override
  ConsumerState<RecordPaymentDialog> createState() =>
      _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<RecordPaymentDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.suggested.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Valid only when it's positive and no more than what's owed.
  int? get _amount {
    final value = parseMoney(_controller.text);
    if (value == null || value <= 0 || value > widget.suggested) return null;
    return value;
  }

  void _submit() {
    final amount = _amount;
    if (amount == null) return;
    ref
        .read(plansProvider.notifier)
        .markSettled(
          widget.planId,
          widget.fromId,
          widget.toId,
          amount,
          expenseId: widget.expenseId,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Record payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.fromName} → ${widget.toName}',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '\$ ',
              helperText:
                  'Up to ${formatMoney(widget.suggested)} · less for a partial payment',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        PillButton(
          label: 'Cancel',
          variant: PillVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        PillButton(
          label: 'Record',
          onPressed: _amount != null ? _submit : null,
        ),
      ],
    );
  }
}
