import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:billparty/infrastructure/db/app_database.dart';
import 'package:billparty/infrastructure/db/plan_repository.dart';
import 'package:billparty/domain/models/plan.dart';
import 'package:billparty/domain/models/person.dart';
import 'package:billparty/domain/models/expense.dart';
import 'package:billparty/domain/models/payment.dart';
import 'package:billparty/domain/services/balances.dart';

void main() {
  // Run SQLite on the host (no emulator) via FFI.
  setUpAll(() {
    sqfliteFfiInit();
  });

  late Database db;
  late PlanRepository repo;

  // A fresh in-memory database for every test → full isolation.
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(':memory:');
    await db.execute('PRAGMA foreign_keys = ON');
    await createBillPartySchema(db);
    repo = PlanRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('PlanRepository', () {
    test('creates and reads back a plan with its people', () async {
      final plan = Plan(
        id: 'p1',
        name: 'Trip to Cartagena',
        createdAt: 1000,
        people: const [
          Person(id: 'a', name: 'Ana'),
          Person(id: 'b', name: 'Beto'),
        ],
      );

      await repo.createPlan(plan);
      final loaded = await repo.getPlan('p1');

      expect(loaded, isNotNull);
      expect(loaded!.name, 'Trip to Cartagena');
      expect(loaded.createdAt, 1000);
      expect(loaded.people.map((p) => p.name).toList(), ['Ana', 'Beto']);
    });

    test('getPlan returns null for an unknown id', () async {
      expect(await repo.getPlan('nope'), isNull);
    });

    test('lists plans, newest first', () async {
      await repo.createPlan(Plan(id: 'old', name: 'Old', createdAt: 1));
      await repo.createPlan(Plan(id: 'new', name: 'New', createdAt: 2));

      final names = (await repo.getPlans()).map((p) => p.name).toList();
      expect(names, ['New', 'Old']);
    });

    test('deleting a plan cascades to its people', () async {
      await repo.createPlan(
        Plan(
          id: 'p1',
          name: 'X',
          createdAt: 1,
          people: const [Person(id: 'a', name: 'Ana')],
        ),
      );

      await repo.deletePlan('p1');

      expect(await repo.getPlan('p1'), isNull);
      expect(await db.query('person'), isEmpty); // cascade worked
    });
  });

  group('PlanRepository expenses & payments', () {
    // A plan with two people, reused by the tests below.
    Future<void> seedPlan() => repo.createPlan(
      Plan(
        id: 'p1',
        name: 'Dinner',
        createdAt: 1,
        people: const [
          Person(id: 'a', name: 'Ana'),
          Person(id: 'b', name: 'Beto'),
        ],
      ),
    );

    test('stores an expense with its shares and loads it back', () async {
      await seedPlan();
      await repo.addExpense(
        'p1',
        const Expense(
          id: 'e1',
          description: 'Pizza',
          amount: 100,
          payerId: 'a',
          shares: {'a': 50, 'b': 50},
          createdAt: 10,
        ),
      );

      final plan = await repo.getPlan('p1');
      expect(plan!.expenses.length, 1);
      expect(plan.expenses.first.description, 'Pizza');
      expect(plan.expenses.first.payerId, 'a');
      expect(plan.expenses.first.shares, {'a': 50, 'b': 50});
    });

    test('stores a payment and loads it back', () async {
      await seedPlan();
      await repo.addPayment(
        'p1',
        const Payment(
          id: 'pay1',
          fromId: 'b',
          toId: 'a',
          amount: 50,
          createdAt: 20,
        ),
      );

      final plan = await repo.getPlan('p1');
      expect(plan!.payments.length, 1);
      expect(plan.payments.first.fromId, 'b');
      expect(plan.payments.first.amount, 50);
    });

    test('balances computed from a reloaded plan match the math', () async {
      await seedPlan();
      await repo.addExpense(
        'p1',
        const Expense(
          id: 'e1',
          description: 'Pizza',
          amount: 100,
          payerId: 'a',
          shares: {'a': 50, 'b': 50},
          createdAt: 10,
        ),
      );
      await repo.addPayment(
        'p1',
        const Payment(
          id: 'pay1',
          fromId: 'b',
          toId: 'a',
          amount: 20,
          createdAt: 20,
        ),
      );

      final plan = await repo.getPlan('p1');
      final net = computeBalances(plan!.expenses, plan.payments);

      // Ana paid 100, owes 50 → +50; minus 20 Beto already paid back → +30.
      // Beto owes 50, paid 20 back → -30.
      expect(net, {'a': 30, 'b': -30});
    });
  });
}
