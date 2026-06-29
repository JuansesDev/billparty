import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../application/providers.dart';
import '../domain/models/plan.dart';
import '../domain/services/balances.dart';
import '../domain/services/settle.dart';
import 'add_expense_sheet.dart';
import 'manage_people_sheet.dart';
import 'money.dart';
import 'share_text.dart';

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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => AddExpenseSheet(plan: plan),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Expense'),
        ),
      ),
    );
  }
}

Map<String, String> _namesById(Plan plan) => {
  for (final p in plan.people) p.id: p.name,
};

// ── Expenses ────────────────────────────────────────────────────────────────

class _ExpensesTab extends StatelessWidget {
  final Plan plan;

  const _ExpensesTab({required this.plan});

  @override
  Widget build(BuildContext context) {
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
        return Card(
          child: ListTile(
            title: Text(e.description),
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
        );
      },
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

        final (color, caption) = net > 0
            ? (const Color(0xFF2E9E6B), 'is owed')
            : net < 0
            ? (const Color(0xFFD0454C), 'owes')
            : (Theme.of(context).colorScheme.outline, 'settled');

        return Card(
          child: ListTile(
            title: Text(person.name),
            subtitle: Text(caption),
            trailing: Text(
              formatMoney(net),
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

class _SettleTab extends ConsumerWidget {
  final Plan plan;

  const _SettleTab({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = computeBalances(plan.expenses, plan.payments);
    final transfers = simplifyDebts(balances);

    if (transfers.isEmpty) {
      return const _TabEmpty(
        icon: Icons.check_circle_outline,
        text: 'All settled.\nNobody owes anybody.',
      );
    }
    final names = _namesById(plan);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: transfers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final t = transfers[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${names[t.fromId] ?? '?'} → ${names[t.toId] ?? '?'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(formatMoney(t.amount)),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => ref
                      .read(plansProvider.notifier)
                      .markSettled(plan.id, t.fromId, t.toId, t.amount),
                  child: const Text('Mark paid'),
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
