import '../domain/models/plan.dart';
import '../domain/services/balances.dart';

enum PlanStatus { empty, pending, settled }

/// A small view-model the UI uses: the plan's total spend and its status,
/// derived from the (already tested) domain — not stored anywhere.
class PlanSummary {
  final int total;
  final PlanStatus status;

  const PlanSummary(this.total, this.status);

  factory PlanSummary.of(Plan plan) {
    final total = plan.expenses.fold(0, (sum, e) => sum + e.amount);

    if (plan.expenses.isEmpty) {
      return PlanSummary(total, PlanStatus.empty);
    }

    final balances = computeBalances(plan.expenses, plan.payments);
    return PlanSummary(
      total,
      isSettled(balances) ? PlanStatus.settled : PlanStatus.pending,
    );
  }
}
