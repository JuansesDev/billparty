import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/plan_summary.dart';
import '../application/providers.dart';
import '../domain/models/plan.dart';
import 'new_plan_dialog.dart';
import 'plan_card.dart';
import 'plan_detail_screen.dart';
import 'theme_mode_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);
    final themeMode = ref.watch(themeModeProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('BillParty'),
          actions: [
            IconButton(
              tooltip: 'Toggle theme',
              onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
              icon: Icon(switch (themeMode) {
                ThemeMode.light => Icons.light_mode_outlined,
                ThemeMode.dark => Icons.dark_mode_outlined,
                ThemeMode.system => Icons.brightness_auto_outlined,
              }),
            ),
            const SizedBox(width: 4),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Settled'),
            ],
          ),
        ),
        body: plansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (plans) {
            final settled = plans
                .where((p) => PlanSummary.of(p).status == PlanStatus.settled)
                .toList();
            final active = plans
                .where((p) => PlanSummary.of(p).status != PlanStatus.settled)
                .toList();

            return TabBarView(
              children: [
                _PlanList(
                  plans: active,
                  emptyTitle: 'No active plans',
                  emptySubtitle:
                      'Create a plan to start splitting expenses with your group.',
                ),
                _PlanList(
                  plans: settled,
                  emptyTitle: 'Nothing settled yet',
                  emptySubtitle:
                      'Plans where everyone is even will show up here.',
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const NewPlanDialog(),
          ),
          icon: const Icon(Icons.add),
          label: const Text('New plan'),
        ),
      ),
    );
  }
}

class _PlanList extends ConsumerWidget {
  final List<Plan> plans;
  final String emptyTitle;
  final String emptySubtitle;

  const _PlanList({
    required this.plans,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (plans.isEmpty) {
      return _EmptyState(title: emptyTitle, subtitle: emptySubtitle);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: plans.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final plan = plans[i];
        return Dismissible(
          key: ValueKey(plan.id),
          background: const _SwipeDeleteBackground(
            alignment: Alignment.centerLeft,
          ),
          secondaryBackground: const _SwipeDeleteBackground(
            alignment: Alignment.centerRight,
          ),
          confirmDismiss: (_) => _confirmDelete(context, plan.name),
          onDismissed: (_) =>
              ref.read(plansProvider.notifier).deletePlan(plan.id),
          child: PlanCard(
            plan: plan,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlanDetailScreen(planId: plan.id),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete plan?'),
        content: Text('"$name" and all its data will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  final Alignment alignment;

  const _SwipeDeleteBackground({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
