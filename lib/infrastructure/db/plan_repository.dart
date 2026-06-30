import 'package:sqflite/sqflite.dart';

import '../../domain/models/plan.dart';
import '../../domain/models/person.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/payment.dart';

/// Reads and writes plans (with their people, expenses and payments) to SQLite.
///
/// The repository is the *only* place that knows about rows and tables — it maps
/// database rows to domain models so the domain stays free of persistence.
class PlanRepository {
  final Database _db;

  PlanRepository(this._db);

  Future<void> createPlan(Plan plan) async {
    // A transaction: either the plan AND all its people are saved, or nothing.
    await _db.transaction((txn) async {
      await txn.insert('plan', {
        'id': plan.id,
        'name': plan.name,
        'created_at': plan.createdAt,
      });
      for (final person in plan.people) {
        await txn.insert('person', {
          'id': person.id,
          'plan_id': plan.id,
          'name': person.name,
          'color_index': person.colorIndex,
        });
      }
    });
  }

  Future<void> addExpense(String planId, Expense expense) async {
    await _db.transaction((txn) async {
      await txn.insert('expense', {
        'id': expense.id,
        'plan_id': planId,
        'description': expense.description,
        'amount': expense.amount,
        'payer_id': expense.payerId,
        'split_type': expense.splitType,
        'created_at': expense.createdAt,
      });
      // One row per participant, holding their computed share.
      for (final entry in expense.shares.entries) {
        await txn.insert('expense_share', {
          'expense_id': expense.id,
          'person_id': entry.key,
          'value': entry.value,
        });
      }
    });
  }

  Future<void> addPayment(String planId, Payment payment) async {
    await _db.insert('payment', {
      'id': payment.id,
      'plan_id': planId,
      'from_id': payment.fromId,
      'to_id': payment.toId,
      'amount': payment.amount,
      'expense_id': payment.expenseId,
      'created_at': payment.createdAt,
    });
  }

  Future<void> deleteExpense(String expenseId) async {
    // expense_share rows cascade via ON DELETE CASCADE.
    await _db.delete('expense', where: 'id = ?', whereArgs: [expenseId]);
  }

  Future<void> addPerson(String planId, Person person) async {
    await _db.insert('person', {
      'id': person.id,
      'plan_id': planId,
      'name': person.name,
      'color_index': person.colorIndex,
    });
  }

  Future<void> removePerson(String personId) async {
    await _db.delete('person', where: 'id = ?', whereArgs: [personId]);
  }

  Future<List<Plan>> getPlans() async {
    final rows = await _db.query('plan', orderBy: 'created_at DESC');
    final plans = <Plan>[];
    for (final row in rows) {
      plans.add(await _hydrate(row));
    }
    return plans;
  }

  Future<Plan?> getPlan(String id) async {
    final rows = await _db.query(
      'plan',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _hydrate(rows.first);
  }

  Future<void> deletePlan(String id) async {
    // people / expenses / payments are removed automatically by ON DELETE CASCADE.
    await _db.delete('plan', where: 'id = ?', whereArgs: [id]);
  }

  /// Turns a `plan` row + all its related rows into a domain [Plan].
  Future<Plan> _hydrate(Map<String, Object?> row) async {
    final planId = row['id'] as String;

    final personRows = await _db.query(
      'person',
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
    final people = personRows
        .map(
          (p) => Person(
            id: p['id'] as String,
            name: p['name'] as String,
            colorIndex: p['color_index'] as int,
          ),
        )
        .toList();

    final expenses = await _loadExpenses(planId);

    final paymentRows = await _db.query(
      'payment',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'created_at',
    );
    final payments = paymentRows
        .map(
          (p) => Payment(
            id: p['id'] as String,
            fromId: p['from_id'] as String,
            toId: p['to_id'] as String,
            amount: p['amount'] as int,
            expenseId: p['expense_id'] as String?,
            createdAt: p['created_at'] as int,
          ),
        )
        .toList();

    return Plan(
      id: planId,
      name: row['name'] as String,
      createdAt: row['created_at'] as int,
      people: people,
      expenses: expenses,
      payments: payments,
    );
  }

  Future<List<Expense>> _loadExpenses(String planId) async {
    final expenseRows = await _db.query(
      'expense',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'created_at DESC',
    );

    final expenses = <Expense>[];
    for (final e in expenseRows) {
      final expenseId = e['id'] as String;
      final shareRows = await _db.query(
        'expense_share',
        where: 'expense_id = ?',
        whereArgs: [expenseId],
      );
      final shares = {
        for (final s in shareRows) s['person_id'] as String: s['value'] as int,
      };

      expenses.add(
        Expense(
          id: expenseId,
          description: e['description'] as String,
          amount: e['amount'] as int,
          payerId: e['payer_id'] as String,
          splitType: e['split_type'] as String,
          createdAt: e['created_at'] as int,
          shares: shares,
        ),
      );
    }
    return expenses;
  }
}
