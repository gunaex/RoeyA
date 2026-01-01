import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, String currencyCode) {
    final formatter = NumberFormat.currency(
      symbol: getCurrencySymbol(currencyCode),
      decimalDigits: getDecimalDigits(currencyCode),
    );
    return formatter.format(amount);
  }
  
  static String formatCompact(double amount, String currencyCode) {
    final symbol = getCurrencySymbol(currencyCode);
    if (amount.abs() >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount, currencyCode);
  }
  
  static String getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'THB':
        return '฿';
      case 'USD':
        return '\$';
      case 'JPY':
        return '¥';
      case 'CNY':
        return '¥';
      case 'KRW':
        return '₩';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'SGD':
        return 'S\$';
      default:
        return currencyCode;
    }
  }
  
  static int getDecimalDigits(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'JPY':
      case 'KRW':
        return 0; // No decimal places for these currencies
      default:
        return 2;
    }
  }
  
  static String getCurrencyName(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'THB':
        return 'Thai Baht';
      case 'USD':
        return 'US Dollar';
      case 'JPY':
        return 'Japanese Yen';
      case 'CNY':
        return 'Chinese Yuan';
      case 'KRW':
        return 'Korean Won';
      case 'EUR':
        return 'Euro';
      case 'GBP':
        return 'British Pound';
      case 'SGD':
        return 'Singapore Dollar';
      default:
        return currencyCode;
    }
  }
}

