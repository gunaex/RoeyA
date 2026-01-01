class Account {
  final String id;
  final String name;
  final String category; // assets, liabilities, equity, income, expense
  final String? description;
  final String? icon;
  final String currencyCode;
  final double balance;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? deletedAt;
  
  Account({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.icon,
    required this.currencyCode,
    this.balance = 0.0,
    this.isDeleted = false,
    required this.createdAt,
    this.deletedAt,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'icon': icon,
      'currency_code': currencyCode,
      'balance': balance,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
  
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      description: map['description'] as String?,
      icon: map['icon'] as String?,
      currencyCode: map['currency_code'] as String,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      isDeleted: (map['is_deleted'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
    );
  }
  
  Account copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? icon,
    String? currencyCode,
    double? balance,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      currencyCode: currencyCode ?? this.currencyCode,
      balance: balance ?? this.balance,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

