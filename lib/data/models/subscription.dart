import 'package:uuid/uuid.dart';

class Subscription {
  final String id;
  final String name;
  final double amount;
  final String currencyCode;
  final String frequency; // 'monthly' or 'yearly'
  final String? category;
  final String? icon;
  final int colorValue;
  final DateTime nextBillingDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    String? id,
    required this.name,
    required this.amount,
    required this.currencyCode,
    required this.frequency,
    this.category,
    this.icon,
    required this.colorValue,
    required this.nextBillingDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'currency_code': currencyCode,
      'frequency': frequency,
      'category': category,
      'icon': icon,
      'color_value': colorValue,
      'next_billing_date': nextBillingDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      currencyCode: map['currency_code'],
      frequency: map['frequency'],
      category: map['category'],
      icon: map['icon'],
      colorValue: map['color_value'],
      nextBillingDate: DateTime.parse(map['next_billing_date']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Subscription copyWith({
    String? name,
    double? amount,
    String? currencyCode,
    String? frequency,
    String? category,
    String? icon,
    int? colorValue,
    DateTime? nextBillingDate,
  }) {
    return Subscription(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      frequency: frequency ?? this.frequency,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
