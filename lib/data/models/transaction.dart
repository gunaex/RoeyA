import 'dart:convert';
import 'photo_attachment.dart';

class Transaction {
  final String id;
  final String accountId;
  final String type; // income, expense, transfer
  final double amount;
  final String currencyCode;
  final double? convertedAmount; // In base currency
  final String? convertedCurrencyCode;
  final double? exchangeRate;
  final String? category;
  final String? description;
  final String? note;
  final String? imageUri; // Legacy support
  final List<PhotoAttachment>? photos; // Up to 5 photos
  final DateTime transactionDate;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? deletedAt;
  
  final bool isSubscription;
  final String? frequency; // weekly, monthly, yearly
  final String? subscriptionId;
  
  Transaction({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.currencyCode,
    this.convertedAmount,
    this.convertedCurrencyCode,
    this.exchangeRate,
    this.category,
    this.description,
    this.note,
    this.imageUri,
    this.photos,
    required this.transactionDate,
    this.isDeleted = false,
    required this.createdAt,
    this.deletedAt,
    this.isSubscription = false,
    this.frequency,
    this.subscriptionId,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'type': type,
      'amount': amount,
      'currency_code': currencyCode,
      'converted_amount': convertedAmount,
      'converted_currency_code': convertedCurrencyCode,
      'exchange_rate': exchangeRate,
      'category': category,
      'description': description,
      'note': note,
      'image_uri': imageUri,
      'photos_json': photos != null
          ? jsonEncode(photos!.map((p) => p.toMap()).toList())
          : null,
      'transaction_date': transactionDate.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'is_subscription': isSubscription ? 1 : 0,
      'frequency': frequency,
      'subscription_id': subscriptionId,
    };
  }
  
  factory Transaction.fromMap(Map<String, dynamic> map) {
    List<PhotoAttachment>? photos;
    if (map['photos_json'] != null) {
      final photosData = jsonDecode(map['photos_json'] as String) as List;
      photos = photosData
          .map((p) => PhotoAttachment.fromMap(p as Map<String, dynamic>))
          .toList();
    }
    
    return Transaction(
      id: map['id'] as String,
      accountId: map['account_id'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      currencyCode: map['currency_code'] as String,
      convertedAmount: (map['converted_amount'] as num?)?.toDouble(),
      convertedCurrencyCode: map['converted_currency_code'] as String?,
      exchangeRate: (map['exchange_rate'] as num?)?.toDouble(),
      category: map['category'] as String?,
      description: map['description'] as String?,
      note: map['note'] as String?,
      imageUri: map['image_uri'] as String?,
      photos: photos,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      isDeleted: (map['is_deleted'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      isSubscription: (map['is_subscription'] as int?) == 1,
      frequency: map['frequency'] as String?,
      subscriptionId: map['subscription_id'] as String?,
    );
  }
  
  Transaction copyWith({
    String? id,
    String? accountId,
    String? type,
    double? amount,
    String? currencyCode,
    double? convertedAmount,
    String? convertedCurrencyCode,
    double? exchangeRate,
    String? category,
    String? description,
    String? note,
    String? imageUri,
    List<PhotoAttachment>? photos,
    DateTime? transactionDate,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? deletedAt,
    bool? isSubscription,
    String? frequency,
    String? subscriptionId,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      convertedAmount: convertedAmount ?? this.convertedAmount,
      convertedCurrencyCode: convertedCurrencyCode ?? this.convertedCurrencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      category: category ?? this.category,
      description: description ?? this.description,
      note: note ?? this.note,
      imageUri: imageUri ?? this.imageUri,
      photos: photos ?? this.photos,
      transactionDate: transactionDate ?? this.transactionDate,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isSubscription: isSubscription ?? this.isSubscription,
      frequency: frequency ?? this.frequency,
      subscriptionId: subscriptionId ?? this.subscriptionId,
    );
  }
}

