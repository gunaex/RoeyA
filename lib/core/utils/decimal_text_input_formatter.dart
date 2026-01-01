import 'package:flutter/services.dart';

class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalPlaces;

  DecimalTextInputFormatter({this.decimalPlaces = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow empty value
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Only allow digits and decimal point
    if (!RegExp(r'^[\d.]*$').hasMatch(newValue.text)) {
      return oldValue;
    }

    // Don't allow more than one decimal point
    if (newValue.text.split('.').length > 2) {
      return oldValue;
    }

    // Check decimal places
    if (newValue.text.contains('.')) {
      final parts = newValue.text.split('.');
      if (parts[1].length > decimalPlaces) {
        return oldValue;
      }
    }

    return newValue;
  }
}

