import 'person.dart';
import 'expense.dart';
import 'payment.dart';

class Plan {
  final String id;
  final String name;
  final int createdAt;
  final List<Person> people;
  final List<Expense> expenses;
  final List<Payment> payments;

  const Plan({
    required this.id,
    required this.name,
    required this.createdAt,
    this.people = const [],
    this.expenses = const [],
    this.payments = const [],
  });
}