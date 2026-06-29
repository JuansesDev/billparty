import 'package:flutter_test/flutter_test.dart';
import 'package:billparty/domain/services/split.dart';

void main() {
  group('splitEqually', () {
    test('divides evenly when it can', () {
      final shares = splitEqually(300, ['a', 'b', 'c']);
      expect(shares, {'a':100, 'b':100, 'c':100});
    });
    test('hands the remainder to the first participants', () {
      final shares = splitEqually(100, ['a', 'b', 'c']);
      expect(shares, {'a':34, 'b':33, 'c':33});
    });
    test('shares always sum back to the amount (the invariant)', () {
      final shares = splitEqually(100, ['a', 'b', 'c']);
      final total = shares.values.fold(0, (sum, s) => sum + s);
      expect(total, 100);
    });
  });

  group('splitExact', () {
    test('returns the assigned amounts when they sum to the total', () {
      expect(splitExact(100, {'a': 70, 'b': 30}), {'a': 70, 'b': 30});
    });
    test('throws when the amounts do not add up', () {
      expect(() => splitExact(100, {'a': 70, 'b': 40}), throwsArgumentError);
    });
  });

  group('splitByShares', () {
    test('splits proportionally', () {
      expect(splitByShares(90, {'a': 2, 'b': 1}), {'a': 60, 'b': 30});
    });
    test('remainder distributed so shares sum exactly (the invariant)', () {
      final shares = splitByShares(100, {'a': 1, 'b': 1, 'c': 1});
      final total = shares.values.fold(0, (s, v) => s + v);
      expect(total, 100); // 34 + 33 + 33
    });
  });
}