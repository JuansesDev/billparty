import 'package:flutter_test/flutter_test.dart';
import 'package:billparty/application/plan_summary.dart';
import 'package:billparty/domain/models/plan.dart';
import 'package:billparty/domain/models/expense.dart';
import 'package:billparty/domain/models/payment.dart';

void main() {
  group('PlanSummary', () {
    test('an empty plan is "empty" with total 0', () {
      final summary = PlanSummary.of(
        const Plan(id: 'p', name: 'X', createdAt: 0),
      );
      expect(summary.status, PlanStatus.empty);
      expect(summary.total, 0);
    });

    test('a plan with an unsettled expense is "pending"', () {
      final plan = Plan(
        id: 'p',
        name: 'X',
        createdAt: 0,
        expenses: const [
          Expense(amount: 100, payerId: 'a', shares: {'a': 50, 'b': 50}),
        ],
      );
      final summary = PlanSummary.of(plan);
      expect(summary.total, 100);
      expect(summary.status, PlanStatus.pending);
    });

    test('a plan whose debt is fully paid back is "settled"', () {
      final plan = Plan(
        id: 'p',
        name: 'X',
        createdAt: 0,
        expenses: const [
          Expense(amount: 100, payerId: 'a', shares: {'a': 50, 'b': 50}),
        ],
        payments: const [Payment(fromId: 'b', toId: 'a', amount: 50)],
      );
      expect(PlanSummary.of(plan).status, PlanStatus.settled);
    });
  });
}
