import 'package:flutter_test/flutter_test.dart';
import 'package:billparty/ui/share_text.dart';
import 'package:billparty/domain/models/plan.dart';
import 'package:billparty/domain/models/person.dart';
import 'package:billparty/domain/models/expense.dart';
import 'package:billparty/domain/models/payment.dart';

void main() {
  group('buildShareText', () {
    final people = const [
      Person(id: 'a', name: 'Ana'),
      Person(id: 'b', name: 'Beto'),
    ];

    test('itemizes expenses, balances and the settle-up', () {
      final plan = Plan(
        id: 'p',
        name: 'Trip',
        createdAt: 0,
        people: people,
        expenses: const [
          Expense(
            description: 'Hotel',
            amount: 100,
            payerId: 'a',
            shares: {'a': 50, 'b': 50},
          ),
        ],
      );
      final text = buildShareText(plan);

      expect(text, contains('EXPENSES'));
      expect(text, contains('Hotel'));
      expect(text, contains('BALANCES'));
      expect(text, contains('SETTLE UP'));
      expect(text, contains('Beto → Ana'));
      expect(text, contains(r'$50'));
    });

    test('says all settled when nobody owes', () {
      final plan = Plan(
        id: 'p',
        name: 'Dinner',
        createdAt: 0,
        people: people,
        expenses: const [
          Expense(amount: 100, payerId: 'a', shares: {'a': 50, 'b': 50}),
        ],
        payments: const [Payment(fromId: 'b', toId: 'a', amount: 50)],
      );

      expect(buildShareText(plan), contains('All settled'));
    });
  });
}
