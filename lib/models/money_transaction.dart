enum MoneyTransactionType { income, expense }

class MoneyTransaction {
  final String id;
  final DateTime date;
  final MoneyTransactionType type;
  final String category;
  final String description;
  final double amount;
  final String notes;
  final String? linkedFuelEntryId;

  const MoneyTransaction({
    required this.id,
    required this.date,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    this.notes = '',
    this.linkedFuelEntryId,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'date': date.toIso8601String(),
    'type': type.name,
    'category': category,
    'description': description,
    'amount': amount,
    'notes': notes,
    'linkedFuelEntryId': linkedFuelEntryId,
  };

  factory MoneyTransaction.fromJson(Map<String, dynamic> json) => MoneyTransaction(
    id: (json['id'] ?? '').toString(),
    date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
    type: (json['type'] ?? 'expense') == 'income' ? MoneyTransactionType.income : MoneyTransactionType.expense,
    category: (json['category'] ?? 'Other').toString(),
    description: (json['description'] ?? '').toString(),
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    notes: (json['notes'] ?? '').toString(),
    linkedFuelEntryId: json['linkedFuelEntryId']?.toString(),
  );
}

const List<String> expenseCategories = <String>[
  'Groceries', 'Rent / Mortgage', 'Bills & Utilities', 'Fuel', 'Car & Maintenance',
  'Public Transport', 'Insurance', 'Health / Medicine', 'Education', 'Eating Out',
  'Shopping', 'Entertainment', 'Subscriptions', 'Other',
];

const List<String> incomeCategories = <String>['Salary', 'Business / Side Income', 'Other Income'];
