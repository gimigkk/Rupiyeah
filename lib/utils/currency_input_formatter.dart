import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Custom formatter for currency input with thousand separators
/// Note: This is specifically for TextInputFormatter during user input,
/// different from the display formatter in utils/format_currency.dart
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue();
    }

    // Format with thousand separators (Indonesian format: ###.###.###)
    final formatter = NumberFormat('#,###', 'id_ID');
    final formatted = formatter.format(int.parse(digitsOnly));

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
