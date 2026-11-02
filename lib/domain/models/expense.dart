class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.note,
    required this.date,
  });

  final int id;
  final double amount;
  final int categoryId;
  final String note;
  final DateTime date;

  factory Expense.fromMap(Map<String, Object?> map) => Expense(
        id: map['id'] as int,
        amount: (map['amount'] as num).toDouble(),
        categoryId: map['category_id'] as int,
        note: map['note'] as String,
        date: DateTime.parse(map['expense_date'] as String),
      );

  Map<String, Object?> toMap() => {
        'amount': amount,
        'category_id': categoryId,
        'note': note,
        'expense_date': date.toIso8601String().substring(0, 10),
      };
}
