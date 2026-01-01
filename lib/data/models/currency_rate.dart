class CurrencyRate {
  final String id;
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime updatedAt;
  
  CurrencyRate({
    required this.id,
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.updatedAt,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from_currency': fromCurrency,
      'to_currency': toCurrency,
      'rate': rate,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  factory CurrencyRate.fromMap(Map<String, dynamic> map) {
    return CurrencyRate(
      id: map['id'] as String,
      fromCurrency: map['from_currency'] as String,
      toCurrency: map['to_currency'] as String,
      rate: (map['rate'] as num).toDouble(),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

