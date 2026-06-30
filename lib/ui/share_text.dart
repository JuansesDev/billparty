import '../domain/models/plan.dart';
import '../domain/services/balances.dart';
import '../domain/services/settle.dart';
import 'money.dart';

/// Builds the plain-text summary the organizer shares with the group: an
/// itemized breakdown — expenses, per-person balances, and how to settle up —
/// so everyone can see exactly what they owe and why.
String buildShareText(Plan plan) {
  final names = {for (final p in plan.people) p.id: p.name};
  final balances = computeBalances(plan.expenses, plan.payments);
  final transfers = simplifyDebts(balances);
  final total = plan.expenses.fold(0, (sum, e) => sum + e.amount);

  final out = StringBuffer()
    ..writeln('💸 ${plan.name}')
    ..writeln('${plan.people.length} people · ${formatMoney(total)} total');

  if (plan.expenses.isNotEmpty) {
    out
      ..writeln()
      ..writeln('EXPENSES');
    for (final e in plan.expenses) {
      final who = names[e.payerId] ?? '?';
      final desc = e.description.isEmpty ? 'Expense' : e.description;
      out.writeln('• $desc — ${formatMoney(e.amount)} ($who paid)');
    }
  }

  out
    ..writeln()
    ..writeln('BALANCES');
  for (final p in plan.people) {
    final net = balances[p.id] ?? 0;
    final tag = net > 0
        ? 'is owed'
        : net < 0
        ? 'owes'
        : 'even';
    final amount = net > 0 ? '+${formatMoney(net)}' : formatMoney(net);
    out.writeln('• ${p.name}: $amount ($tag)');
  }

  out
    ..writeln()
    ..writeln('SETTLE UP');
  if (transfers.isEmpty) {
    out.writeln('✅ All settled — nobody owes anybody.');
  } else {
    for (final t in transfers) {
      out.writeln(
        '• ${names[t.fromId] ?? '?'} → ${names[t.toId] ?? '?'}: '
        '${formatMoney(t.amount)}',
      );
    }
  }

  out
    ..writeln()
    ..write('— shared from BillParty');

  return out.toString();
}
