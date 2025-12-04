import 'dart:io';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row;
import 'package:syncfusion_officechart/officechart.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../models/tag.dart';
import '../models/month_data.dart';
import '../storage/database_helper.dart';
import 'package:permission_handler/permission_handler.dart';

class ExportService {
  /// Export current month's data to Excel with charts and statistics
  static Future<void> exportToExcel(String monthId) async {
    // Create a new Excel document
    final Workbook workbook = Workbook();

    // Get month data and transactions
    final monthData = DatabaseHelper.getMonth(monthId);
    if (monthData == null) {
      throw Exception('Month not found');
    }

    final transactions = DatabaseHelper.getTransactionsForMonth(monthId);
    final allTags = DatabaseHelper.getAllTags();

    // Create a map for quick tag lookup
    final tagMap = {for (var tag in allTags) tag.id: tag};

    // Remove default sheets and create our custom sheets
    workbook.worksheets.clear();

    // 1. Create Statistics Sheet (with charts)
    final statsSheet = workbook.worksheets.addWithName('Statistics');
    _createStatisticsSheet(statsSheet, monthData, transactions, tagMap);

    // 2. Create All Transactions Sheet
    final allTransSheet = workbook.worksheets.addWithName('All Transactions');
    _createAllTransactionsSheet(allTransSheet, transactions, tagMap);

    // 3. Create Income Only Sheet
    final incomeSheet = workbook.worksheets.addWithName('Income');
    _createFilteredTransactionsSheet(incomeSheet, 'Income',
        transactions.where((t) => t.type == 'income').toList(), tagMap);

    // 4. Create Expense Only Sheet
    final expenseSheet = workbook.worksheets.addWithName('Expenses');
    _createFilteredTransactionsSheet(expenseSheet, 'Expenses',
        transactions.where((t) => t.type == 'expense').toList(), tagMap);

    // 5. Create Withdrawal Only Sheet
    final withdrawalSheet = workbook.worksheets.addWithName('Withdrawals');
    _createFilteredTransactionsSheet(withdrawalSheet, 'Withdrawals',
        transactions.where((t) => t.type == 'withdrawal').toList(), tagMap);

    // Save and share the file
    await _saveAndShareExcel(workbook, monthData.getMonthName());
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

  /// Create statistics summary sheet with charts
  static void _createStatisticsSheet(Worksheet sheet, MonthData monthData,
      List<Transaction> transactions, Map<String, Tag> tagMap) {
    final currencySymbol = DatabaseHelper.getCurrencySymbol();
    final expenseTransactions =
        transactions.where((t) => t.type == 'expense').toList();

    // ---------------------------------------------------------
    // SECTION A: MAIN TITLE
    // ---------------------------------------------------------
    sheet.getRangeByName('A1:F1').merge();
    final titleRange = sheet.getRangeByName('A1');
    titleRange.setText('${monthData.getMonthName()} - Financial Report');
    titleRange.cellStyle.bold = true;
    titleRange.cellStyle.fontSize = 18;
    titleRange.cellStyle.hAlign = HAlignType.center;
    titleRange.cellStyle.vAlign = VAlignType.center;
    titleRange.cellStyle.backColor = '#4472C4';
    titleRange.cellStyle.fontColor = '#FFFFFF';
    sheet.getRangeByName('A1').rowHeight = 30;

    int row = 3;

    // ---------------------------------------------------------
    // SECTION B: OVERALL SUMMARY
    // ---------------------------------------------------------
    _addSectionHeader(sheet, row, 'Financial Overview');
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

    row += 2; // Spacer

    // ---------------------------------------------------------
    // SECTION C: ANALYSIS
    // ---------------------------------------------------------
    _addSectionHeader(sheet, row, 'Spending Analysis');
    row++;

    final daysWithExpenses = expenseTransactions
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet()
        .length;

    final avgDailySpending = daysWithExpenses > 0
        ? (monthData.totalExpenses / daysWithExpenses).toDouble()
        : 0.0;

    _addStatRow(
        sheet, row, 'Avg Daily Spending:', avgDailySpending, currencySymbol);
    row++;
    _addStatRow(
        sheet, row, 'Active Spending Days:', daysWithExpenses.toDouble(), '',
        isInteger: true);

    row += 2; // Spacer

    // ---------------------------------------------------------
    // SECTION D: DATA FOR CHARTS
    // ---------------------------------------------------------
    final int chartDataStartRow = row;

    // -- Daily Expenses Data (For Line Chart) --
    _addSectionHeader(sheet, row, 'Daily Expenses Breakdown');
    row++;

    // Headers
    sheet.getRangeByIndex(row, 1).setText('Date');
    sheet.getRangeByIndex(row, 2).setText('Amount');
    sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 2).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 1).cellStyle.borders.all.lineStyle =
        LineStyle.thin;
    sheet.getRangeByIndex(row, 2).cellStyle.borders.all.lineStyle =
        LineStyle.thin;
    row++;

    final int dailyDataStartRow = row;

    // Group by day
    final dailyExpenses = <DateTime, double>{};
    for (var t in expenseTransactions) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      dailyExpenses[day] = (dailyExpenses[day] ?? 0) + t.amount;
    }
    final sortedDays = dailyExpenses.keys.toList()..sort();

    for (var day in sortedDays) {
      sheet.getRangeByIndex(row, 1).setText(_formatDate(day));
      sheet.getRangeByIndex(row, 2).setNumber(dailyExpenses[day]!);
      row++;
    }

    final int dailyDataEndRow = row - 1;

    row += 2; // Spacer

    // -- Tag Distribution Data (For Pie Chart) --
    final int tagDataStartRow = row;
    _addSectionHeader(sheet, row, 'Expenses by Tag');
    row++;

    // Headers
    sheet.getRangeByIndex(row, 1).setText('Category');
    sheet.getRangeByIndex(row, 2).setText('Amount');
    sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 2).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 1).cellStyle.borders.all.lineStyle =
        LineStyle.thin;
    sheet.getRangeByIndex(row, 2).cellStyle.borders.all.lineStyle =
        LineStyle.thin;
    row++;

    final int pieDataStartRow = row;

    // Group by tag
    final tagTotals = <String, double>{};
    for (var t in expenseTransactions) {
      tagTotals[t.tagId] = (tagTotals[t.tagId] ?? 0) + t.amount;
    }
    final sortedTags = tagTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedTags) {
      final tag = tagMap[entry.key];
      sheet.getRangeByIndex(row, 1).setText(tag?.name ?? 'Unknown');
      sheet.getRangeByIndex(row, 2).setNumber(entry.value);
      row++;
    }

    final int pieDataEndRow = row - 1;

    // Create BOTH charts together in a single ChartCollection
    final ChartCollection charts = ChartCollection(sheet);

    // Add Line Chart for Daily Expenses
    if (sortedDays.isNotEmpty) {
      final Chart dailyChart = charts.add();
      dailyChart.chartType = ExcelChartType.line;
      dailyChart.dataRange =
          sheet.getRangeByName('A$dailyDataStartRow:B$dailyDataEndRow');
      dailyChart.isSeriesInRows = false;
      dailyChart.hasLegend = true;
      dailyChart.chartTitle = 'Daily Expenses Trend';
      dailyChart.chartTitleArea.bold = true;
      dailyChart.chartTitleArea.size = 12;

      // Position chart
      dailyChart.topRow = chartDataStartRow;
      dailyChart.leftColumn = 4;
      dailyChart.bottomRow = chartDataStartRow + 20;
      dailyChart.rightColumn = 10;

      // Style the primary category axis
      dailyChart.primaryCategoryAxis.title = 'Date';
      dailyChart.primaryValueAxis.title = 'Amount ($currencySymbol)';
      dailyChart.primaryValueAxis.hasMajorGridLines = true;
    }

    // Add Pie Chart for Tag Distribution
    if (sortedTags.isNotEmpty) {
      final Chart pieChart = charts.add();
      pieChart.chartType = ExcelChartType.pie;
      pieChart.dataRange =
          sheet.getRangeByName('A$pieDataStartRow:B$pieDataEndRow');
      pieChart.isSeriesInRows = false;
      pieChart.hasLegend = true;
      pieChart.chartTitle = 'Expenses by Category';
      pieChart.chartTitleArea.bold = true;
      pieChart.chartTitleArea.size = 12;

      // Position chart below the line chart
      pieChart.topRow = tagDataStartRow;
      pieChart.leftColumn = 4;
      pieChart.bottomRow = tagDataStartRow + 20;
      pieChart.rightColumn = 10;

      // Show data labels with category names
      final ChartSerie serie = pieChart.series[0];
      serie.dataLabels.isValue = true;
      serie.dataLabels.isCategoryName = true;
    }

    // Assign the ChartCollection with all charts to the worksheet
    sheet.charts = charts;

    // Auto-fit columns
    sheet.autoFitColumn(1);
    sheet.autoFitColumn(2);
  }

  /// Create all transactions sheet
  static void _createAllTransactionsSheet(Worksheet sheet,
      List<Transaction> transactions, Map<String, Tag> tagMap) {
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
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#D3D3D3';
      cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
    }

    // Data rows
    int row = 2;
    for (var transaction in transactions) {
      final tag = tagMap[transaction.tagId];

      sheet.getRangeByIndex(row, 1).setText(_formatDate(transaction.date));
      sheet.getRangeByIndex(row, 2).setText(_capitalizeFirst(transaction.type));
      sheet.getRangeByIndex(row, 3).setText(tag?.name ?? 'Unknown');
      sheet.getRangeByIndex(row, 4).setText(transaction.description);
      sheet.getRangeByIndex(row, 5).setNumber(transaction.amount);
      sheet.getRangeByIndex(row, 6).setText(transaction.paymentMethod ?? 'N/A');

      row++;
    }

    // Auto-fit columns
    for (int i = 1; i <= headers.length; i++) {
      sheet.autoFitColumn(i);
    }
  }

  /// Create filtered transactions sheet (Income/Expense/Withdrawal)
  static void _createFilteredTransactionsSheet(
      Worksheet sheet,
      String sheetName,
      List<Transaction> transactions,
      Map<String, Tag> tagMap) {
    // Headers
    final headers = ['Date', 'Tag', 'Description', 'Amount', 'Payment Method'];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#D3D3D3';
      cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
    }

    // Data rows
    int row = 2;
    double total = 0;

    for (var transaction in transactions) {
      final tag = tagMap[transaction.tagId];

      sheet.getRangeByIndex(row, 1).setText(_formatDate(transaction.date));
      sheet.getRangeByIndex(row, 2).setText(tag?.name ?? 'Unknown');
      sheet.getRangeByIndex(row, 3).setText(transaction.description);
      sheet.getRangeByIndex(row, 4).setNumber(transaction.amount);
      sheet.getRangeByIndex(row, 5).setText(transaction.paymentMethod ?? 'N/A');

      total += transaction.amount;
      row++;
    }

    // Add total row
    row++;
    final totalLabelCell = sheet.getRangeByIndex(row, 3);
    totalLabelCell.setText('TOTAL:');
    totalLabelCell.cellStyle.bold = true;

    final totalValueCell = sheet.getRangeByIndex(row, 4);
    totalValueCell.setNumber(total);
    totalValueCell.cellStyle.bold = true;

    // Auto-fit columns
    for (int i = 1; i <= headers.length; i++) {
      sheet.autoFitColumn(i);
    }
  }

  // Helper methods

  static void _addSectionHeader(Worksheet sheet, int row, String title) {
    final cell = sheet.getRangeByIndex(row, 1);
    cell.setText(title);
    cell.cellStyle.bold = true;
    cell.cellStyle.fontSize = 12;
    cell.cellStyle.fontColor = '#4472C4';
  }

  static void _addStatRow(
      Worksheet sheet, int row, String label, double value, String currency,
      {bool isInteger = false}) {
    sheet.getRangeByIndex(row, 1).setText(label);

    final formattedValue =
        isInteger ? value.toInt().toString() : _formatNumber(value);

    sheet.getRangeByIndex(row, 2).setText('$currency $formattedValue'.trim());
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

  static Future<void> _saveAndShareExcel(
      Workbook workbook, String monthName) async {
    final fileName = 'Budget_${monthName.replaceAll(' ', '_')}.xlsx';
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final savedPath = await _saveToDownloads(bytes, fileName);

    if (savedPath != null) {
      await Share.shareXFiles(
        [XFile(savedPath)],
        subject: 'Budget Report - $monthName',
        text: 'Here is your budget report for $monthName',
      );
    } else {
      final directory = await getTemporaryDirectory();
      final tempPath = '${directory.path}/$fileName';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(tempPath)]);
    }
  }

  static Future<void> _saveAndShareCSV(String csv, String monthName) async {
    final fileName = 'Budget_${monthName.replaceAll(' ', '_')}.csv';
    final bytes = csv.codeUnits;

    final savedPath = await _saveToDownloads(bytes, fileName);

    if (savedPath != null) {
      await Share.shareXFiles(
        [XFile(savedPath)],
        subject: 'Budget Report - $monthName',
        text: 'Here is your budget report for $monthName',
      );
    } else {
      final directory = await getTemporaryDirectory();
      final tempPath = '${directory.path}/$fileName';
      final tempFile = File(tempPath);
      await tempFile.writeAsString(csv);
      await Share.shareXFiles([XFile(tempPath)]);
    }
  }

  static Future<String?> _saveToDownloads(
      List<int> bytes, String fileName) async {
    try {
      Directory? dir;

      if (Platform.isAndroid) {
        // ANDROID LOGIC: Try standard Download path first
        if (await _requestPermission()) {
          dir = Directory('/storage/emulated/0/Download');

          // Fallback if the standard path doesn't exist (unlikely)
          if (!await dir.exists()) {
            dir = (await getExternalStorageDirectory())!;
          }
        }
      } else if (Platform.isIOS) {
        // iOS LOGIC: Save to ApplicationDocuments
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        // Implement unique filename logic to prevent overwrite errors
        String baseName = fileName.substring(0, fileName.lastIndexOf('.'));
        String extension = fileName.substring(fileName.lastIndexOf('.'));

        String uniquePath = '${dir.path}/$fileName';
        int counter = 1;

        // Check if the file exists and append a number until a unique path is found
        while (await File(uniquePath).exists()) {
          uniquePath = '${dir.path}/$baseName($counter)$extension';
          counter++;
        }

        final file = File(uniquePath);
        await file.writeAsBytes(bytes);
        return uniquePath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        if (result == PermissionStatus.granted) return true;
      } else {
        return true;
      }
      return true;
    }
    return true;
  }
}
