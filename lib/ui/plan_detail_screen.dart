import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../application/providers.dart';
import '../domain/models/plan.dart';
import '../domain/services/balances.dart';
import '../domain/services/settle.dart';
import 'brand.dart';
import 'add_expense_sheet.dart';
import 'manage_people_sheet.dart';
import 'money.dart';
import 'record_payment_dialog.dart';
import 'share_text.dart';
import 'widgets/avatar.dart';
import 'widgets/pill_button.dart';

class PlanDetailScreen extends ConsumerWidget {
  final String planId;

  const PlanDetailScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);

    return plansAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (plans) {
        final matches = plans.where((p) => p.id == planId);
        if (matches.isEmpty) {
          // The plan was deleted while we were here.
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Plan not found')),
          );
        }
        return _PlanDetailView(plan: matches.first);
      },
    );
  }
}

class _PlanDetailView extends StatelessWidget {
  final Plan plan;

  const _PlanDetailView({required this.plan});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(plan.name),
          actions: [
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.ios_share),
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: buildShareText(plan)),
              ),
            ),
            IconButton(
              tooltip: 'People',
              icon: const Icon(Icons.group_outlined),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => ManagePeopleSheet(planId: plan.id),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Balances'),
              Tab(text: 'Settle'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ExpensesTab(plan: plan),
            _BalancesTab(plan: plan),
            _SettleTab(plan: plan),
          ],
        ),
        floatingActionButton: PillButton(
          label: 'Expense',
          icon: Icons.add,
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => AddExpenseSheet(plan: plan),
          ),
        ),
      ),
    );
  }
}

Map<String, String> _namesById(Plan plan) => {
  for (final p in plan.people) p.id: p.name,
};

// ── Expenses ────────────────────────────────────────────────────────────────

class _ExpensesTab extends ConsumerWidget {
  final Plan plan;

  const _ExpensesTab({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (plan.expenses.isEmpty) {
      return const _TabEmpty(
        icon: Icons.receipt_outlined,
        text: 'No expenses yet.\nTap "Expense" to add one.',
      );
    }
    final names = _namesById(plan);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: plan.expenses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final e = plan.expenses[i];
        return Dismissible(
          key: ValueKey(e.id),
          direction: DismissDirection.endToStart,
          background: _SwipeDeleteBg(),
          confirmDismiss: (_) => _confirmDelete(context, e.description),
          onDismissed: (_) =>
              ref.read(plansProvider.notifier).deleteExpense(plan.id, e.id),
          child: Card(
            child: ListTile(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => AddExpenseSheet(plan: plan, existing: e),
              ),
              title: Text(e.description.isEmpty ? 'Expense' : e.description),
              subtitle: Text(
                'Paid by ${names[e.payerId] ?? '?'} · among ${e.shares.length}',
              ),
              trailing: Text(
                formatMoney(e.amount),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String desc) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text(
          '${desc.isEmpty ? 'This expense' : '"$desc"'} will be removed.',
        ),
        actions: [
          PillButton(
            label: 'Cancel',
            variant: PillVariant.ghost,
            onPressed: () => Navigator.pop(context, false),
          ),
          PillButton(
            label: 'Delete',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _SwipeDeleteBg extends StatelessWidget {
  const _SwipeDeleteBg();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
    );
  }
}

// ── Balances ────────────────────────────────────────────────────────────────

class _BalancesTab extends StatelessWidget {
  final Plan plan;

  const _BalancesTab({required this.plan});

  @override
  Widget build(BuildContext context) {
    final balances = computeBalances(plan.expenses, plan.payments);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: plan.people.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final person = plan.people[i];
        final net = balances[person.id] ?? 0;
        final scheme = Theme.of(context).colorScheme;

        final caption = net > 0
            ? 'is owed'
            : net < 0
            ? 'owes'
            : 'settled';
        final amountText = net > 0 ? '+${formatMoney(net)}' : formatMoney(net);
        final color = net > 0
            ? Brand.owed(context)
            : net < 0
            ? Brand.owes(context)
            : scheme.onSurfaceVariant;

        return Card(
          child: ListTile(
            leading: Avatar(name: person.name, size: 40),
            title: Text(person.name),
            subtitle: Text(caption),
            trailing: Text(
              amountText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Settle ──────────────────────────────────────────────────────────────────

class _SettleTab extends StatelessWidget {
  final Plan plan;

  const _SettleTab({required this.plan});

  @override
  Widget build(BuildContext context) {
    final names = _namesById(plan);

    // Expenses that still have someone owing their share.
    final pending = plan.expenses
        .map(
          (e) => (
            e,
            expenseDebts(
              e,
              plan.payments,
            ).where((d) => d.remaining > 0).toList(),
          ),
        )
        .where((pair) => pair.$2.isNotEmpty)
        .toList();

    if (pending.isEmpty) {
      return const _TabEmpty(
        icon: Icons.check_circle_outline,
        text: 'All settled.\nEveryone covered their share.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: pending.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final (expense, debts) = pending[i];
        final theme = Theme.of(context);
        final payerName = names[expense.payerId] ?? '?';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description.isEmpty ? 'Expense' : expense.description,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatMoney(expense.amount)} · paid by $payerName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                for (final d in debts)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${names[d.personId] ?? '?'} owes ',
                                ),
                                TextSpan(
                                  text: formatMoney(d.remaining),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        PillButton(
                          label: 'Mark paid',
                          variant: PillVariant.secondary,
                          size: PillSize.sm,
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => RecordPaymentDialog(
                              planId: plan.id,
                              fromId: d.personId,
                              toId: expense.payerId,
                              fromName: names[d.personId] ?? '?',
                              toName: payerName,
                              suggested: d.remaining,
                              expenseId: expense.id,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Shared ──────────────────────────────────────────────────────────────────

class _TabEmpty extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TabEmpty({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: scheme.outline),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
