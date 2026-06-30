import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:billparty/application/providers.dart';
import 'package:billparty/domain/models/plan.dart';
import 'package:billparty/ui/home_screen.dart';
import 'package:billparty/ui/theme_mode_provider.dart';

/// A notifier that returns no plans immediately — no database, no real async,
/// so the loading spinner resolves at once and the test never hangs.
class _EmptyPlans extends PlansNotifier {
  @override
  Future<List<Plan>> build() async => [];
}

void main() {
  testWidgets('home shows the empty state when there are no plans', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          plansProvider.overrideWith(_EmptyPlans.new),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // The "Active" tab is shown first.
    expect(find.text('No active plans yet'), findsOneWidget);
  });
}
