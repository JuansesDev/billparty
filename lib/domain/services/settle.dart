import 'package:billparty/domain/models/payment.dart';

class _Holding {
  final String id;
  int amount;
  _Holding(this.id, this.amount);
}

List<Payment> simplifyDebts(Map<String, int> balances) {
  final creditors =
      balances.entries
          .where((e) => e.value > 0) // owed money
          .map((e) => _Holding(e.key, e.value)) // keep it positive
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

  final debtors =
      balances.entries
          .where((e) => e.value < 0) // owe money
          .map((e) => _Holding(e.key, -e.value)) // flip to a positive magnitude
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

  final transfers = <Payment>[];
  var i = 0;
  var j = 0;

  while (i < creditors.length && j < debtors.length) {
    final credit = creditors[i];
    final debt = debtors[j];
    final pay = credit.amount < debt.amount ? credit.amount : debt.amount;

    transfers.add(Payment(fromId: debt.id, toId: credit.id, amount: pay));

    credit.amount -= pay;
    debt.amount -= pay;

    if (credit.amount == 0) i++;
    if (debt.amount == 0) j++;
  }
  return transfers;
}
