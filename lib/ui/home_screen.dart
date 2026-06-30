import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/plan_summary.dart';
import '../application/providers.dart';
import '../domain/models/plan.dart';
import 'brand.dart';
import 'new_plan_dialog.dart';
import 'plan_card.dart';
import 'plan_detail_screen.dart';
import 'theme_mode_provider.dart';
import 'widgets/brand_mark.dart';
import 'widgets/pill_button.dart';
import 'widgets/segmented_tabs.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _newPlan(BuildContext context) =>
      showDialog(context: context, builder: (_) => const NewPlanDialog());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);
    final hasPlans = (plansAsync.value ?? const <Plan>[]).isNotEmpty;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SegmentedTabs(labels: ['Active', 'Settled']),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: plansAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (plans) {
                    final settled = plans
                        .where(
                          (p) => PlanSummary.of(p).status == PlanStatus.settled,
                        )
                        .toList();
                    final active = plans
                        .where(
                          (p) => PlanSummary.of(p).status != PlanStatus.settled,
                        )
                        .toList();

                    return TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _PlanList(
                          plans: active,
                          label: 'Active',
                          onCreate: () => _newPlan(context),
                        ),
                        _PlanList(plans: settled, label: 'Settled'),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: hasPlans
            ? PillButton(
                label: 'New plan',
                icon: Icons.add,
                onPressed: () => _newPlan(context),
              )
            : null,
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          const BrandMark(size: 42),
          const SizedBox(width: 12),
          Text(
            'BillParty',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          _CircleButton(
            icon: switch (mode) {
              ThemeMode.light => Icons.light_mode_outlined,
              ThemeMode.dark => Icons.dark_mode_outlined,
              ThemeMode.system => Icons.brightness_auto_outlined,
            },
            onTap: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Brand.isDark(context);
    return Material(
      color: isDark ? Brand.darkSurface : Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 22,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _PlanList extends ConsumerWidget {
  final List<Plan> plans;
  final String label;
  final VoidCallback? onCreate;

  const _PlanList({required this.plans, required this.label, this.onCreate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (plans.isEmpty) {
      return onCreate != null
          ? _ActiveEmpty(onCreate: onCreate!)
          : const _SettledEmpty();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 6),
          child: Text(
            '${plans.length} ${label.toUpperCase()}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
            itemCount: plans.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final plan = plans[i];
              return Dismissible(
                key: ValueKey(plan.id),
                background: const _SwipeDelete(alignment: Alignment.centerLeft),
                secondaryBackground: const _SwipeDelete(
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
          ),
        ),
      ],
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete plan?'),
        content: Text('"$name" and all its data will be removed.'),
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

class _SwipeDelete extends StatelessWidget {
  final Alignment alignment;

  const _SwipeDelete({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
    );
  }
}

class _ActiveEmpty extends StatelessWidget {
  final VoidCallback onCreate;

  const _ActiveEmpty({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _ReceiptBadge(),
            const SizedBox(height: 28),
            Text(
              'No active plans yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Create a plan to start splitting expenses with your group.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            PillButton(
              label: 'Create your first plan',
              icon: Icons.add,
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettledEmpty extends StatelessWidget {
  const _SettledEmpty();

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
              Icons.check_circle_outline_rounded,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 14),
            Text(
              'Nothing settled yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Plans where everyone is even show up here.',
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

class _ReceiptBadge extends StatelessWidget {
  const _ReceiptBadge();

  @override
  Widget build(BuildContext context) {
    final isDark = Brand.isDark(context);
    return SizedBox(
      width: 124,
      height: 124,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 120,
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? Brand.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: Theme.of(context).colorScheme.onSurface,
              size: 54,
            ),
          ),
          Positioned(
            right: -2,
            bottom: 8,
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 3,
                ),
              ),
              child: Text(
                r'$',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
