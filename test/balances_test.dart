import 'package:flutter_test/flutter_test.dart';
import 'package:billparty/domain/models/expense.dart';
import 'package:billparty/domain/models/payment.dart';
import 'package:billparty/domain/services/balances.dart';

void main() {
  group('computeBalances', () {
    test('one expense split equally', () {
      final expenses = [
        Expense(amount: 90, payerId: 'ana', shares: {'ana': 30, 'beto': 30, 'caro': 30}),
      ];
      final net = computeBalances(expenses, []);
      // Ana: +90 paid − 30 her share = +60 ; Beto −30 ; Caro −30
      expect(net, {'ana': 60, 'beto': -30, 'caro': -30});
    });

    test('a registered payment reduces the debt', () {
      final expenses = [
        Expense(amount: 90, payerId: 'ana', shares: {'ana': 30, 'beto': 30, 'caro': 30}),
      ];
      final payments = [
        Payment(fromId: 'beto', toId: 'ana', amount: 30), // Beto pays Ana back
      ];
      final net = computeBalances(expenses, payments);
      expect(net, {'ana': 30, 'beto': 0, 'caro': -30});
    });

    test('all balances always sum to zero (money is conserved)', () {
      final expenses = [
        Expense(amount: 100, payerId: 'a', shares: {'a': 34, 'b': 33, 'c': 33}),
      ];
      final net = computeBalances(expenses, []);
      final sum = net.values.fold(0, (s, v) => s + v);
      expect(sum, 0); // ← the deep invariant: the system is always balanced
    });
  });

  group('isSettled', () {
    test('true when everyone is at zero', () {
      expect(isSettled({'a': 0, 'b': 0}), true);
    });
    test('true for an empty plan (no debts)', () {
      expect(isSettled({}), true);
    });
    test('false when someone still owes', () {
      expect(isSettled({'a': 60, 'b': -60}), false);
    });
  });
}