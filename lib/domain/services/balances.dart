import '../models/expense.dart';
import '../models/payment.dart';

Map<String, int> computeBalances(List<Expense> expenses, List<Payment> payments) {
  final net = <String, int>{};

  void add(String id, int delta) {
    net[id] = (net[id] ?? 0) + delta;
  }
    for (final e in expenses) {
      add(e.payerId, e.amount);
      e.shares.forEach((p, share){
        add(p, -share);
      });
    }
    for (final p in payments) {
      add(p.fromId, p.amount);
      add(p.toId, -p.amount);
    }
    return net;
}

bool isSettled(Map<String, int> balances){
  return balances.values.every((net) => net == 0);
}