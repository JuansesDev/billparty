class Expense {
  final String id;
  final String description;
  final int amount; // whole pesos
  final String payerId; // who paid
  final Map<String, int>
  shares; // personId -> how much they owe for THIS expense
  final String splitType; // 'equal' | 'exact' | 'shares' (for re-editing later)
  final int createdAt; // epoch ms

  const Expense({
    required this.amount,
    required this.payerId,
    required this.shares,
    this.id = '',
    this.description = '',
    this.splitType = 'equal',
    this.createdAt = 0,
  });
}
