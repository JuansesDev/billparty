import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/plan.dart';
import '../domain/services/split.dart';
import '../infrastructure/db/app_database.dart';
import '../infrastructure/db/plan_repository.dart';
import 'plan_service.dart';

/// Wiring for the whole app. Each provider builds the next layer.
///
/// In tests we override [planRepositoryProvider] with an in-memory database, so
/// nothing here ever touches a real device.
final planRepositoryProvider = FutureProvider<PlanRepository>((ref) async {
  final db = await AppDatabase.instance;
  return PlanRepository(db);
});

final planServiceProvider = FutureProvider<PlanService>((ref) async {
  final repo = await ref.watch(planRepositoryProvider.future);
  return PlanService(repo);
});

/// The list of plans, as async state (loading / data / error) for the UI.
/// Mutations call the service and then reload the list.
class PlansNotifier extends AsyncNotifier<List<Plan>> {
  @override
  Future<List<Plan>> build() async {
    final repo = await ref.watch(planRepositoryProvider.future);
    return repo.getPlans();
  }

  Future<void> createPlan(String name, List<String> personNames) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(planServiceProvider.future);
      await service.createPlan(name, personNames);
      final repo = await ref.read(planRepositoryProvider.future);
      return repo.getPlans();
    });
  }

  Future<void> deletePlan(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(planRepositoryProvider.future);
      await repo.deletePlan(id);
      return repo.getPlans();
    });
  }

  // Mutations triggered from inside a plan refresh the list silently (no loading
  // flash) so the detail screen doesn't blink while you add things.
  Future<void> addExpense(
    String planId, {
    required String description,
    required int amount,
    required String payerId,
    required SplitStrategy strategy,
  }) async {
    final service = await ref.read(planServiceProvider.future);
    await service.addExpense(
      planId,
      description: description,
      amount: amount,
      payerId: payerId,
      strategy: strategy,
    );
    await _reload();
  }

  Future<void> markSettled(
    String planId,
    String fromId,
    String toId,
    int amount,
  ) async {
    final service = await ref.read(planServiceProvider.future);
    await service.markSettled(planId, fromId, toId, amount);
    await _reload();
  }

  Future<void> addPerson(String planId, String name) async {
    final service = await ref.read(planServiceProvider.future);
    await service.addPerson(planId, name);
    await _reload();
  }

  Future<void> removePerson(String planId, String personId) async {
    final service = await ref.read(planServiceProvider.future);
    await service.removePerson(personId);
    await _reload();
  }

  Future<void> _reload() async {
    final repo = await ref.read(planRepositoryProvider.future);
    state = AsyncData(await repo.getPlans());
  }
}

final plansProvider = AsyncNotifierProvider<PlansNotifier, List<Plan>>(
  PlansNotifier.new,
);
