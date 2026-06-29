import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:billparty/infrastructure/db/app_database.dart';
import 'package:billparty/infrastructure/db/plan_repository.dart';
import 'package:billparty/application/plan_service.dart';
import 'package:billparty/domain/services/split.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late Database db;
  late PlanService service;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(':memory:');
    await db.execute('PRAGMA foreign_keys = ON');
    await createBillPartySchema(db);

    var counter = 0;
    service = PlanService(
      PlanRepository(db),
      newId: () => 'id${counter++}', // deterministic ids
      now: () => 42, // frozen clock
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('PlanService', () {
    test('createPlan persists the plan with generated ids', () async {
      final plan = await service.createPlan('Trip', ['Ana', 'Beto']);

      expect(plan.people.length, 2);
      expect(plan.people.every((p) => p.id.isNotEmpty), true);
      expect(plan.createdAt, 42);

      final loaded = await PlanRepository(db).getPlan(plan.id);
      expect(loaded!.people.map((p) => p.name).toList(), ['Ana', 'Beto']);
    });

    test(
      'addExpense computes shares via the strategy and stores them',
      () async {
        final plan = await service.createPlan('Dinner', ['Ana', 'Beto']);
        final ana = plan.people[0].id;
        final beto = plan.people[1].id;

        await service.addExpense(
          plan.id,
          description: 'Pizza',
          amount: 100,
          payerId: ana,
          strategy: EqualSplit([ana, beto]),
        );

        final loaded = await PlanRepository(db).getPlan(plan.id);
        expect(loaded!.expenses.length, 1);
        expect(loaded.expenses.first.shares, {ana: 50, beto: 50});
        expect(loaded.expenses.first.splitType, 'equal');
      },
    );

    test('markSettled records a payment', () async {
      final plan = await service.createPlan('Dinner', ['Ana', 'Beto']);
      final ana = plan.people[0].id;
      final beto = plan.people[1].id;

      await service.markSettled(plan.id, beto, ana, 50);

      final loaded = await PlanRepository(db).getPlan(plan.id);
      expect(loaded!.payments.length, 1);
      expect(loaded.payments.first.fromId, beto);
      expect(loaded.payments.first.amount, 50);
    });
  });
}
