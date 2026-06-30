import 'package:flutter/material.dart';

import '../application/plan_summary.dart';
import '../domain/models/plan.dart';
import 'money.dart';
import 'widgets/avatar.dart';
import 'widgets/brand_card.dart';

class PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback? onTap;

  const PlanCard({super.key, required this.plan, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = PlanSummary.of(plan);
    final count = plan.people.length;

    return BrandCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _StatusPill(summary: summary),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              AvatarCluster(names: plan.people.map((p) => p.name).toList()),
              const Spacer(),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$count ${count == 1 ? 'person' : 'people'} · ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextSpan(
                      text: formatMoney(summary.total),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final PlanSummary summary;

  const _StatusPill({required this.summary});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (Color fg, String text, bool strong) = switch (summary.status) {
      PlanStatus.pending => (
        scheme.onSurface,
        '${formatMoney(summary.outstanding)} unsettled',
        true,
      ),
      PlanStatus.settled => (scheme.onSurfaceVariant, 'Settled', false),
      PlanStatus.empty => (scheme.onSurfaceVariant, 'No expenses', false),
    };

    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: strong ? 0.10 : 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
          fontSize: 13,
          height: 1.15,
        ),
      ),
    );
  }
}
