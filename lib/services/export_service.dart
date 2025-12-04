import 'dart:io';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../models/tag.dart';
import '../models/month_data.dart';
import '../storage/database_helper.dart';

class ExportService {
  /// Export current month's data to Excel with charts and statistics
  static Future<void> exportToExcel(String monthId) async {
    final excel = Excel.createExcel();

    // Get month data and transactions
    final monthData = DatabaseHelper.getMonth(monthId);
    if (monthData == null) {
      throw Exception('Month not found');
    }

    final transactions = DatabaseHelper.getTransactionsForMonth(monthId);
    final allTags = DatabaseHelper.getAllTags();

    // Create a map for quick tag lookup
    final tagMap = {for (var tag in allTags) tag.id: tag};

    // Remove default sheets
    excel.delete('Sheet1');

    // 1. Create Statistics Sheet
    _createStatisticsSheet(excel, monthData, transactions, tagMap);

    // 2. Create All Transactions Sheet
    _createAllTransactionsSheet(excel, transactions, tagMap);

    // 3. Create Income Only Sheet
    _createFilteredTransactionsSheet(excel, 'Income',
        transactions.where((t) => t.type == 'income').toList(), tagMap);

    // 4. Create Expense Only Sheet
    _createFilteredTransactionsSheet(excel, 'Expenses',
        transactions.where((t) => t.type == 'expense').toList(), tagMap);

    // 5. Create Withdrawal Only Sheet
    _createFilteredTransactionsSheet(excel, 'Withdrawals',
        transactions.where((t) => t.type == 'withdrawal').toList(), tagMap);

    // 6. Create Daily Expenses Chart Data
    _createDailyExpensesSheet(excel, transactions);

    // 7. Create Tag Distribution Sheet
    _createTagDistributionSheet(excel, transactions, tagMap);

    // Save and share the file
    await _saveAndShareExcel(excel, monthData.getMonthName());
  }

  /// Export current month's data to CSV (simple format)
  static Future<void> exportToCSV(String monthId) async {
    final monthData = DatabaseHelper.getMonth(monthId);
    if (monthData == null) {
      throw Exception('Month not found');
    }

    final transactions = DatabaseHelper.getTransactionsForMonth(monthId);
    final allTags = DatabaseHelper.getAllTags();
    final tagMap = {for (var tag in allTags) tag.id: tag};

    // Create CSV data
    List<List<dynamic>> rows = [
      ['Date', 'Type', 'Tag', 'Description', 'Amount', 'Payment Method']
    ];

    for (var transaction in transactions) {
      final tag = tagMap[transaction.tagId];
      rows.add([
        _formatDate(transaction.date),
        transaction.type,
        tag?.name ?? 'Unknown',
        transaction.description,
        transaction.amount,
        transaction.paymentMethod ?? 'N/A',
      ]);
    }

    // Convert to CSV string
    String csv = const ListToCsvConverter().convert(rows);

    // Save and share
    await _saveAndShareCSV(csv, monthData.getMonthName());
  }

  /// Create statistics summary sheet
  static void _createStatisticsSheet(Excel excel, MonthData monthData,
      List<Transaction> transactions, Map<String, Tag> tagMap) {
    final sheet = excel['Statistics'];

    final currencySymbol = DatabaseHelper.getCurrencySymbol();

    // Title
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('D1'));
    var titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value =
        TextCellValue('${monthData.getMonthName()} - Financial Summary');
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: HorizontalAlign.Center,
    );

    int row = 3;

    // Overall Summary
    _addSectionHeader(sheet, row, 'Overall Summary');
    row++;
    _addStatRow(
        sheet, row, 'Total Income:', monthData.totalIncome, currencySymbol);
    row++;
    _addStatRow(
        sheet, row, 'Total Expenses:', monthData.totalExpenses, currencySymbol);
    row++;
    _addStatRow(sheet, row, 'Net Savings:', monthData.getRemainingCredit(),
        currencySymbol);
    row++;
    _addStatRow(
        sheet, row, 'Wallet Cash:', monthData.walletCash, currencySymbol);
    row++;
    _addStatRow(
        sheet, row, 'Bank Balance:', monthData.bankBalance, currencySymbol);
    row++;

    row++;

    // Daily Statistics
    _addSectionHeader(sheet, row, 'Daily Statistics');
    row++;
    final expenseTransactions =
        transactions.where((t) => t.type == 'expense').toList();
    final daysWithExpenses = expenseTransactions
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet()
        .length
        .toInt();

    final avgDailySpending = daysWithExpenses > 0
        ? (monthData.totalExpenses / daysWithExpenses).toDouble()
        : 0.0;

    _addStatRow(sheet, row, 'Average Daily Spending:', avgDailySpending,
        currencySymbol);
    row++;
    _addStatRow(
        sheet, row, 'Days with Expenses:', daysWithExpenses.toDouble(), '',
        isInteger: true);
    row++;

    // Find highest expense day
    if (expenseTransactions.isNotEmpty) {
      final dailyExpenses = <DateTime, double>{};
      for (var t in expenseTransactions) {
        final day = DateTime(t.date.year, t.date.month, t.date.day);
        dailyExpenses[day] = (dailyExpenses[day] ?? 0) + t.amount;
      }

      final highestDay =
          dailyExpenses.entries.reduce((a, b) => a.value > b.value ? a : b);
      _addStatRow(
          sheet, row, 'Highest Expense Day:', highestDay.value, currencySymbol);
      row++;
      _addTextRow(sheet, row, '  Date:', _formatDate(highestDay.key));
      row++;
    }

    row++;

    // Top Expenses
    _addSectionHeader(sheet, row, 'Top 5 Expenses');
    row++;
    final sortedExpenses = expenseTransactions
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final top5 = sortedExpenses.take(5);

    for (var transaction in top5) {
      final tag = tagMap[transaction.tagId];
      _addTextRow(
          sheet,
          row,
          '${tag?.name ?? "Unknown"} - ${transaction.description}',
          '$currencySymbol ${_formatNumber(transaction.amount)}');
      row++;
    }

    row++;

    // Most Used Tags
    _addSectionHeader(sheet, row, 'Most Used Tags (Expenses)');
    row++;
    final tagUsage = <String, int>{};
    for (var t in expenseTransactions) {
      tagUsage[t.tagId] = (tagUsage[t.tagId] ?? 0) + 1;
    }

    final sortedTags = tagUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedTags.take(5)) {
      final tag = tagMap[entry.key];
      _addTextRow(sheet, row, '${tag?.name ?? "Unknown"}:',
          '${entry.value} transactions');
      row++;
    }

    // Auto-fit columns
    _autoFitColumns(sheet, 4);
  }

  /// Create all transactions sheet
  static void _createAllTransactionsSheet(
      Excel excel, List<Transaction> transactions, Map<String, Tag> tagMap) {
    final sheet = excel['All Transactions'];

    // Headers
    final headers = [
      'Date',
      'Type',
      'Tag',
      'Description',
      'Amount',
      'Payment Method'
    ];
    for (int i = 0; i < headers.length; i++) {
      var cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'),
      );
    }

    // Data rows
    int row = 1;
    for (var transaction in transactions) {
      final tag = tagMap[transaction.tagId];

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(_formatDate(transaction.date));
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(_capitalizeFirst(transaction.type));
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(tag?.name ?? 'Unknown');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue(transaction.description);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = DoubleCellValue(transaction.amount);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = TextCellValue(transaction.paymentMethod ?? 'N/A');

      row++;
    }

    _autoFitColumns(sheet, headers.length);
  }

  /// Create filtered transactions sheet (Income/Expense/Withdrawal)
  static void _createFilteredTransactionsSheet(Excel excel, String sheetName,
      List<Transaction> transactions, Map<String, Tag> tagMap) {
    final sheet = excel[sheetName];

    // Headers
    final headers = ['Date', 'Tag', 'Description', 'Amount', 'Payment Method'];
    for (int i = 0; i < headers.length; i++) {
      var cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'),
      );
    }

    // Data rows
    int row = 1;
    double total = 0;

    for (var transaction in transactions) {
      final tag = tagMap[transaction.tagId];

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(_formatDate(transaction.date));
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(tag?.name ?? 'Unknown');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(transaction.description);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = DoubleCellValue(transaction.amount);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = TextCellValue(transaction.paymentMethod ?? 'N/A');

      total += transaction.amount;
      row++;
    }

    // Add total row
    row++;
    var totalLabelCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
    totalLabelCell.value = TextCellValue('TOTAL:');
    totalLabelCell.cellStyle = CellStyle(bold: true);

    var totalValueCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
    totalValueCell.value = DoubleCellValue(total);
    totalValueCell.cellStyle = CellStyle(bold: true);

    _autoFitColumns(sheet, headers.length);
  }

  /// Create daily expenses sheet for charting
  static void _createDailyExpensesSheet(
      Excel excel, List<Transaction> transactions) {
    final sheet = excel['Daily Expenses'];

    final expenses = transactions.where((t) => t.type == 'expense').toList();

    // Group by day
    final dailyExpenses = <DateTime, double>{};
    for (var transaction in expenses) {
      final day = DateTime(
          transaction.date.year, transaction.date.month, transaction.date.day);
      dailyExpenses[day] = (dailyExpenses[day] ?? 0) + transaction.amount;
    }

    // Sort by date
    final sortedDays = dailyExpenses.keys.toList()..sort();

    // Headers
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Date');
    sheet.cell(CellIndex.indexByString('B1')).value =
        TextCellValue('Total Expenses');

    var headerStyle = CellStyle(
        bold: true, backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'));
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByString('B1')).cellStyle = headerStyle;

    // Data
    int row = 1;
    for (var day in sortedDays) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(_formatDate(day));
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = DoubleCellValue(dailyExpenses[day]!);
      row++;
    }

    _autoFitColumns(sheet, 2);
  }

  /// Create tag distribution sheet for pie chart
  static void _createTagDistributionSheet(
      Excel excel, List<Transaction> transactions, Map<String, Tag> tagMap) {
    final sheet = excel['Tag Distribution'];

    final expenses = transactions.where((t) => t.type == 'expense').toList();

    // Group by tag
    final tagTotals = <String, double>{};
    for (var transaction in expenses) {
      tagTotals[transaction.tagId] =
          (tagTotals[transaction.tagId] ?? 0) + transaction.amount;
    }

    // Sort by amount
    final sortedTags = tagTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Headers
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Tag');
    sheet.cell(CellIndex.indexByString('B1')).value =
        TextCellValue('Total Amount');
    sheet.cell(CellIndex.indexByString('C1')).value =
        TextCellValue('Percentage');

    var headerStyle = CellStyle(
        bold: true, backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'));
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByString('B1')).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByString('C1')).cellStyle = headerStyle;

    // Calculate total for percentages
    final total = tagTotals.values.fold(0.0, (sum, amount) => sum + amount);

    // Data
    int row = 1;
    for (var entry in sortedTags) {
      final tag = tagMap[entry.key];
      final percentage =
          total > 0 ? (entry.value / total * 100).toDouble() : 0.0;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(tag?.name ?? 'Unknown');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = DoubleCellValue(entry.value);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue('${percentage.toStringAsFixed(1)}%');
      row++;
    }

    _autoFitColumns(sheet, 3);
  }

  // Helper methods

  static void _addSectionHeader(Sheet sheet, int row, String title) {
    var cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue(title);
    cell.cellStyle = CellStyle(
      bold: true,
      fontSize: 12,
      backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
  }

  static void _addStatRow(
      Sheet sheet, int row, String label, double value, String currency,
      {bool isInteger = false}) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue(label);

    final formattedValue =
        isInteger ? value.toInt().toString() : _formatNumber(value);

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
        .value = TextCellValue('$currency $formattedValue'.trim());
  }

  static void _addTextRow(Sheet sheet, int row, String label, String value) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue(label);
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
        .value = TextCellValue(value);
  }

  static void _autoFitColumns(Sheet sheet, int columnCount) {
    for (int i = 0; i < columnCount; i++) {
      sheet.setColumnWidth(i, 20);
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static String _formatNumber(double number) {
    return number.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static Future<void> _saveAndShareExcel(Excel excel, String monthName) async {
    // Encode to bytes
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to encode Excel file');
    }

    // Get temporary directory
    final directory = await getTemporaryDirectory();
    final fileName = 'Budget_${monthName.replaceAll(' ', '_')}.xlsx';
    final filePath = '${directory.path}/$fileName';

    // Write file
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    // Share file
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'Budget Report - $monthName',
      text: 'Here is your budget report for $monthName',
    );
  }

  static Future<void> _saveAndShareCSV(String csv, String monthName) async {
    // Get temporary directory
    final directory = await getTemporaryDirectory();
    final fileName = 'Budget_${monthName.replaceAll(' ', '_')}.csv';
    final filePath = '${directory.path}/$fileName';

    // Write file
    final file = File(filePath);
    await file.writeAsString(csv);

    // Share file
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'Budget Report - $monthName',
      text: 'Here is your budget report for $monthName',
    );
  }
}
