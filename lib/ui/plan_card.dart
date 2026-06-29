import 'package:flutter/material.dart';

import '../application/plan_summary.dart';
import '../domain/models/plan.dart';
import 'money.dart';

class PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback? onTap;

  const PlanCard({super.key, required this.plan, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = PlanSummary.of(plan);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${plan.people.length} people · ${formatMoney(summary.total)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusChip(status: summary.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final PlanStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PlanStatus.settled => ('Settled', const Color(0xFF2E9E6B)),
      PlanStatus.pending => ('Pending', const Color(0xFFD08700)),
      PlanStatus.empty => ('Empty', Theme.of(context).colorScheme.outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
