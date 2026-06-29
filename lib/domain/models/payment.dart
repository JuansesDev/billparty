class Payment {
  final String fromId;
  final String toId;
  final int amount;

  const Payment ({
    required this.fromId,
    required this.toId,
    required this.amount,
});
}