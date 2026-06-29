import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/home_screen.dart';
import 'ui/theme.dart';
import 'ui/theme_mode_provider.dart';

void main() {
  // ProviderScope stores the state of every Riverpod provider for the whole app.
  runApp(const ProviderScope(child: BillPartyApp()));
}

class BillPartyApp extends ConsumerWidget {
  const BillPartyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'BillParty',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ref.watch(themeModeProvider),
      home: const HomeScreen(),
    );
  }
}
