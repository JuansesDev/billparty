import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:billparty/infrastructure/db/app_database.dart';
import 'package:billparty/infrastructure/db/plan_repository.dart';
import 'package:billparty/application/providers.dart';
import 'package:billparty/domain/services/split.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late Database db;
  late ProviderContainer container;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(':memory:');
    await db.execute('PRAGMA foreign_keys = ON');
    await createBillPartySchema(db);

    // Swap the real (device) repository for one backed by the in-memory db.
    container = ProviderContainer(
      overrides: [
        planRepositoryProvider.overrideWith((ref) async => PlanRepository(db)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('plansProvider starts empty', () async {
    final plans = await container.read(plansProvider.future);
    expect(plans, isEmpty);
  });

  test('createPlan adds a plan to the list', () async {
    await container.read(plansProvider.future); // build the notifier
    await container.read(plansProvider.notifier).createPlan('Trip', [
      'Ana',
      'Beto',
    ]);

    final plans = container.read(plansProvider).requireValue;
    expect(plans.length, 1);
    expect(plans.first.name, 'Trip');
    expect(plans.first.people.map((p) => p.name).toList(), ['Ana', 'Beto']);
  });

  test('deletePlan removes it from the list', () async {
    await container.read(plansProvider.future);
    await container.read(plansProvider.notifier).createPlan('Trip', ['Ana']);
    final created = container.read(plansProvider).requireValue.first;

    await container.read(plansProvider.notifier).deletePlan(created.id);

    expect(container.read(plansProvider).requireValue, isEmpty);
  });

  test('addExpense updates the plan in the list', () async {
    await container.read(plansProvider.future);
    final notifier = container.read(plansProvider.notifier);
    await notifier.createPlan('Trip', ['Ana', 'Beto']);

    final plan = container.read(plansProvider).requireValue.first;
    final ana = plan.people[0].id;
    final beto = plan.people[1].id;

    await notifier.addExpense(
      plan.id,
      description: 'Pizza',
      amount: 100,
      payerId: ana,
      strategy: EqualSplit([ana, beto]),
    );

    final updated = container.read(plansProvider).requireValue.first;
    expect(updated.expenses.length, 1);
    expect(updated.expenses.first.shares, {ana: 50, beto: 50});
  });

  test('addPerson and removePerson manage the plan roster', () async {
    await container.read(plansProvider.future);
    final notifier = container.read(plansProvider.notifier);
    await notifier.createPlan('Trip', ['Ana', 'Beto']);
    final plan = container.read(plansProvider).requireValue.first;

    await notifier.addPerson(plan.id, 'Caro');
    var updated = container.read(plansProvider).requireValue.first;
    expect(updated.people.length, 3);
    expect(updated.people.map((p) => p.name), contains('Caro'));

    final caro = updated.people.firstWhere((p) => p.name == 'Caro');
    await notifier.removePerson(plan.id, caro.id);
    updated = container.read(plansProvider).requireValue.first;
    expect(updated.people.length, 2);
    expect(updated.people.any((p) => p.name == 'Caro'), isFalse);
  });
}
