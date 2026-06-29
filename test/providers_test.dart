import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:billparty/infrastructure/db/app_database.dart';
import 'package:billparty/infrastructure/db/plan_repository.dart';
import 'package:billparty/application/providers.dart';

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
}
