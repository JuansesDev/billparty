import '../domain/models/plan.dart';
import '../domain/services/balances.dart';
import '../domain/services/settle.dart';
import 'money.dart';

/// Builds the plain-text summary the organizer shares with the group:
/// the total, and the minimum set of payments to settle up.
String buildShareText(Plan plan) {
  final names = {for (final p in plan.people) p.id: p.name};
  final balances = computeBalances(plan.expenses, plan.payments);
  final transfers = simplifyDebts(balances);
  final total = plan.expenses.fold(0, (sum, e) => sum + e.amount);

  final out = StringBuffer()
    ..writeln('💸 ${plan.name}')
    ..writeln('Total: ${formatMoney(total)} · ${plan.people.length} people')
    ..writeln();

  if (transfers.isEmpty) {
    out.writeln('✅ All settled — nobody owes anybody.');
  } else {
    out.writeln('To settle up:');
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
