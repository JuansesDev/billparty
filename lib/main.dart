import 'package:flutter/material.dart';

// Entry point of every Dart program.
void main() {
  runApp(const BillPartyApp());
}

// Root widget of the application. It never changes by itself, so it is
// a StatelessWidget. It only configures the app shell (theme, title, home).
class BillPartyApp extends StatelessWidget {
  const BillPartyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BillParty',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// A blank screen we will build the app on top of.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BillParty'),
      ),
      body: const Center(
        child: Text('Blank screen — ready to build.'),
      ),
    );
  }
}
