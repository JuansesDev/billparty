import 'package:sqflite/sqflite.dart';

import '../../domain/models/plan.dart';
import '../../domain/models/person.dart';

/// Reads and writes plans (with their people) to SQLite.
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

  /// Turns a `plan` row + its related rows into a domain [Plan].
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

    return Plan(
      id: planId,
      name: row['name'] as String,
      createdAt: row['created_at'] as int,
      people: people,
      // expenses & payments are loaded in the next repository step.
    );
  }
}
