class Budget {
  final String id;
  final int year;
  final int month;
  final String? category; // null for overall monthly budget
  final double amount;
  final String currencyCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    required this.id,
    required this.year,
    required this.month,
    this.category,
    required this.amount,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'month': month,
      'category': category,
      'amount': amount,
      'currency_code': currencyCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      year: map['year'] as int,
      month: map['month'] as int,
      category: map['category'] as String?,
      amount: (map['amount'] as num).toDouble(),
      currencyCode: map['currency_code'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Budget copyWith({
    String? id,
    int? year,
    int? month,
    String? category,
    double? amount,
    String? currencyCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

