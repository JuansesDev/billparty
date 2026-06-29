import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:billparty/infrastructure/db/app_database.dart';
import 'package:billparty/infrastructure/db/plan_repository.dart';
import 'package:billparty/domain/models/plan.dart';
import 'package:billparty/domain/models/person.dart';

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
}
