class Budget {
  final String category;
  final double monthlyLimit;
  const Budget({required this.category, required this.monthlyLimit});
  Map<String, dynamic> toJson() => <String, dynamic>{'category': category, 'monthlyLimit': monthlyLimit};
  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    category: (json['category'] ?? '').toString(),
    monthlyLimit: (json['monthlyLimit'] as num?)?.toDouble() ?? 0,
  );
}
