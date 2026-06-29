class Payment {
  final String? id; // null for a suggested transfer; set once persisted
  final String fromId; // debtor who paid back
  final String toId; // creditor who received
  final int amount;
  final int? createdAt; // epoch ms (set once persisted)

  const Payment({
    required this.fromId,
    required this.toId,
    required this.amount,
    this.id,
    this.createdAt,
  });
}
