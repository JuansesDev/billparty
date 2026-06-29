class Expense {
  final int amount;
  final String payerId;
  final Map<String, int> shares;

  const Expense({
    required this.amount,
    required this.payerId,
    required this.shares,
});
}