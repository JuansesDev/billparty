import '../domain/models/plan.dart';
import '../domain/services/balances.dart';

enum PlanStatus { empty, pending, settled }

/// A small view-model the UI uses: the plan's total spend, how much is still
/// unsettled, and its status — derived from the (already tested) domain.
class PlanSummary {
  final int total;
  final int outstanding;
  final PlanStatus status;

  const PlanSummary(this.total, this.outstanding, this.status);

  factory PlanSummary.of(Plan plan) {
    final total = plan.expenses.fold(0, (sum, e) => sum + e.amount);

    if (plan.expenses.isEmpty) {
      return PlanSummary(total, 0, PlanStatus.empty);
    }

    final balances = computeBalances(plan.expenses, plan.payments);
    final outstanding = balances.values
        .where((v) => v > 0)
        .fold(0, (sum, v) => sum + v);

    return PlanSummary(
      total,
      outstanding,
      isSettled(balances) ? PlanStatus.settled : PlanStatus.pending,
    );
  }
}
