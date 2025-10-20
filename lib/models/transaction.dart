class TransactionModel {
  final String id;
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final bool isIncome;

  TransactionModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.isIncome,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'description': description,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'isIncome': isIncome,
  };

  static TransactionModel fromMap(Map<String, dynamic> map) => TransactionModel(
    id: map['id'],
    description: map['description'],
    amount: map['amount'],
    category: map['category'],
    date: DateTime.parse(map['date']),
    isIncome: map['isIncome'],
  );
}
