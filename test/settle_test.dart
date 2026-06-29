import 'package:flutter_test/flutter_test.dart';
import 'package:billparty/domain/services/settle.dart';

void main() {
  group('simplifyDebts', () {
    test('a simple two-person debt', () {
      final transfers = simplifyDebts({'ana': 30, 'beto': -30});
      expect(transfers.length, 1);
      expect(transfers.first.fromId, 'beto');
      expect(transfers.first.toId, 'ana');
      expect(transfers.first.amount, 30);
    });

    test('keeps the number of transfers minimal', () {
      final transfers = simplifyDebts({'a': 60, 'b': -30, 'c': -30});
      expect(transfers.length, 2);
    });

    test(
      'after applying the transfers, everyone is settled (the invariant)',
      () {
        final balances = {'a': 60, 'b': -30, 'c': -30};
        final transfers = simplifyDebts(balances);

        final net = Map<String, int>.from(balances);
        for (final t in transfers) {
          net[t.fromId] = net[t.fromId]! + t.amount;
          net[t.toId] = net[t.toId]! - t.amount;
        }
        expect(net.values.every((v) => v == 0), true);
      },
    );
  });
}
