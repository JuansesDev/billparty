import 'package:billparty/domain/models/expense.dart';
import 'package:billparty/domain/models/payment.dart';

/// What one participant still owes the payer for a single expense.
class ExpenseDebt {
  final String personId;
  final int owed; // their share of the expense
  final int paid; // paid so far, tagged to this expense

  const ExpenseDebt(this.personId, this.owed, this.paid);

  int get remaining => owed - paid;
  bool get isSettled => remaining <= 0;
}

/// For an [expense], how much each participant (other than the payer) still owes
/// the payer — using only the payments tagged to this expense.
List<ExpenseDebt> expenseDebts(Expense expense, List<Payment> payments) {
  return expense.shares.entries.where((s) => s.key != expense.payerId).map((s) {
    final paid = payments
        .where(
          (p) =>
              p.expenseId == expense.id &&
              p.fromId == s.key &&
              p.toId == expense.payerId,
        )
        .fold(0, (sum, p) => sum + p.amount);
    return ExpenseDebt(s.key, s.value, paid);
  }).toList();
}

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
