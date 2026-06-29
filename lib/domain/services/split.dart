Map<String, int> splitEqually(int amount, List<String> participantIds) {
  final n = participantIds.length;
  if (n == 0) {
    throw ArgumentError('Need at least one participant');
  }
  final base = amount ~/ n;
  final remainder = amount - base * n;

  final shares = <String, int>{};
  for (var i = 0; i < n; i++) {
    final id = participantIds[i];
    shares[id] = base + (i < remainder ? 1 : 0);
  }
  return shares;
}

Map<String, int> splitExact(int amount, Map<String, int> exactAmounts) {
  final total = exactAmounts.values.fold(0, (sum, v) => sum + v);
  if (total != amount) {
    throw ArgumentError('Exact amounts sum to $total, expected $amount');
  }
  return Map.of(exactAmounts);
}

Map<String, int> splitByShares(int amount, Map<String, int> shareWeights) {
  final totalShares = shareWeights.values.fold(0, (sum, v) => sum + v);
  if (totalShares <= 0) {
    throw ArgumentError('Total shares must be greater than zero');
  }
  final result = <String, int>{};
  final remainders = <String, int>{};
  var allocated = 0;

  shareWeights.forEach((id, weight) {
    final numerator = amount * weight;
    result[id] = numerator ~/ totalShares;
    remainders[id] = numerator % totalShares;
    allocated += result[id]!;
  });

  final leftover = amount - allocated;
  final ranked = shareWeights.keys.toList()
    ..sort((a, b) => remainders[b]!.compareTo(remainders[a]!));
  for (var i = 0; i < leftover; i++) {
    result[ranked[i]] = result[ranked[i]]! + 1;
  }
  return result;
}

/// How an expense should be divided. One case per split mode.
sealed class SplitStrategy {
  const SplitStrategy();

  /// A stable label stored alongside the expense (so it can be re-edited later).
  String get type => switch (this) {
    EqualSplit() => 'equal',
    ExactSplit() => 'exact',
    SharesSplit() => 'shares',
  };
}

class EqualSplit extends SplitStrategy {
  final List<String> participantIds;
  const EqualSplit(this.participantIds);
}

class ExactSplit extends SplitStrategy {
  final Map<String, int> amounts;
  const ExactSplit(this.amounts);
}

class SharesSplit extends SplitStrategy {
  final Map<String, int> weights;
  const SharesSplit(this.weights);
}

/// Single entry point: turns a [SplitStrategy] into each person's share.
/// Adding a new mode = one more case here + its class — nothing else changes.
Map<String, int> split(int amount, SplitStrategy strategy) {
  return switch (strategy) {
    EqualSplit(:final participantIds) => splitEqually(amount, participantIds),
    ExactSplit(:final amounts) => splitExact(amount, amounts),
    SharesSplit(:final weights) => splitByShares(amount, weights),
  };
}
