import 'package:intl/intl.dart';
import '../storage/database_helper.dart';

String formatCurrency(double amount) {
  final symbol = DatabaseHelper.getCurrencySymbol();

  // Indonesian-style formatting, no decimals
  final formatted = NumberFormat('#,###', 'id_ID').format(amount);

  return '$symbol $formatted';
}
