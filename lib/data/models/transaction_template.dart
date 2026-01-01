class TransactionTemplate {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final String? category;
  final String? accountId;
  final double amount;
  final String currencyCode;
  final String? note;
  final DateTime createdAt;

  TransactionTemplate({
    required this.id,
    required this.name,
    required this.type,
    this.category,
    this.accountId,
    required this.amount,
    required this.currencyCode,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'category': category,
      'account_id': accountId,
      'amount': amount,
      'currency_code': currencyCode,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionTemplate.fromMap(Map<String, dynamic> map) {
    return TransactionTemplate(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      category: map['category'] as String?,
      accountId: map['account_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      currencyCode: map['currency_code'] as String,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  TransactionTemplate copyWith({
    String? id,
    String? name,
    String? type,
    String? category,
    String? accountId,
    double? amount,
    String? currencyCode,
    String? note,
    DateTime? createdAt,
  }) {
    return TransactionTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

