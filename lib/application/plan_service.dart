import 'package:uuid/uuid.dart';

import '../domain/models/plan.dart';
import '../domain/models/person.dart';
import '../domain/models/expense.dart';
import '../domain/models/payment.dart';
import '../domain/services/split.dart';
import '../infrastructure/db/plan_repository.dart';

/// The application layer: use cases that orchestrate the domain and the repo.
///
/// The two "impure" concerns — generating ids and reading the clock — are
/// injected, so every use case stays deterministic and testable.
class PlanService {
  final PlanRepository _repo;
  final String Function() _newId;
  final int Function() _now;

  PlanService(this._repo, {String Function()? newId, int Function()? now})
    : _newId = newId ?? (() => const Uuid().v4()),
      _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  /// Creates a plan with its people and saves it. Returns the new plan.
  Future<Plan> createPlan(String name, List<String> personNames) async {
    final people = personNames
        .map((n) => Person(id: _newId(), name: n))
        .toList();
    final plan = Plan(
      id: _newId(),
      name: name,
      createdAt: _now(),
      people: people,
    );
    await _repo.createPlan(plan);
    return plan;
  }

  /// Computes each person's share from the [strategy] and saves the expense.
  Future<void> addExpense(
    String planId, {
    required String description,
    required int amount,
    required String payerId,
    required SplitStrategy strategy,
  }) async {
    final shares = split(amount, strategy); // ← the domain finally runs here
    final expense = Expense(
      id: _newId(),
      description: description,
      amount: amount,
      payerId: payerId,
      shares: shares,
      splitType: strategy.type,
      createdAt: _now(),
    );
    await _repo.addExpense(planId, expense);
  }

  /// Records that [fromId] paid [toId] back, reducing the debt.
  Future<void> markSettled(
    String planId,
    String fromId,
    String toId,
    int amount,
  ) async {
    final payment = Payment(
      id: _newId(),
      fromId: fromId,
      toId: toId,
      amount: amount,
      createdAt: _now(),
    );
    await _repo.addPayment(planId, payment);
  }
}
