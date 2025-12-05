import 'dart:io';
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../models/tag.dart';
import '../models/month_data.dart';
import '../storage/database_helper.dart';

class ExportService {
  /// Export current month's data to PDF with statistics and charts
  static Future<String> exportToPDF(String monthId) async {
    // Get month data and transactions
    final monthData = DatabaseHelper.getMonth(monthId);
    if (monthData == null) {
      throw Exception('Month not found');
    }

    final transactions = DatabaseHelper.getTransactionsForMonth(monthId);
    final allTags = DatabaseHelper.getAllTags();

    // Create a map for quick tag lookup
    final tagMap = {for (var tag in allTags) tag.id: tag};

    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    // Set document properties
    document.pageSettings.size = PdfPageSize.a4;
    document.pageSettings.margins.all = 40;

    // Create pages
    _createStatisticsPage(document, monthData, transactions, tagMap);
    _createTransactionsPage(
        document, 'All Transactions', transactions, tagMap, monthData);
    _createTransactionsPage(
        document,
        'Income',
        transactions.where((t) => t.type == 'income').toList(),
        tagMap,
        monthData);
    _createTransactionsPage(
        document,
        'Expenses',
        transactions.where((t) => t.type == 'expense').toList(),
        tagMap,
        monthData);
    _createTransactionsPage(
        document,
        'Withdrawals',
        transactions.where((t) => t.type == 'withdrawal').toList(),
        tagMap,
        monthData);

    // Save and share the PDF
    return await _saveAndSharePDF(document, monthData.getMonthName());
  }

  /// Export current month's data to CSV (simple format)
  static Future<String> exportToCSV(String monthId) async {
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
    return await _saveAndShareCSV(csv, monthData.getMonthName());
  }

  /// Create statistics summary page with charts
  static void _createStatisticsPage(PdfDocument document, MonthData monthData,
      List<Transaction> transactions, Map<String, Tag> tagMap) {
    PdfPage page = document.pages.add();
    PdfGraphics graphics = page.graphics;
    final currencySymbol = DatabaseHelper.getCurrencySymbol();

    double yPosition = 0;
    final pageWidth = page.getClientSize().width;

    // Title
    final titleFont =
        PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold);
    final titleBrush = PdfSolidBrush(PdfColor(68, 114, 196));
    final title = '${monthData.getMonthName()} - Financial Report';
    final titleSize = titleFont.measureString(title);
    graphics.drawString(
      title,
      titleFont,
      brush: titleBrush,
      bounds: Rect.fromLTWH((pageWidth - titleSize.width) / 2, yPosition,
          titleSize.width, titleSize.height),
    );
    yPosition += 40;

    // Calculate data for pie chart first
    final expenseTransactions =
        transactions.where((t) => t.type == 'expense').toList();
    final tagTotals = <String, double>{};
    for (var t in expenseTransactions) {
      tagTotals[t.tagId] = (tagTotals[t.tagId] ?? 0) + t.amount;
    }
    final sortedTags = tagTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Left side: Financial Overview and Analysis
    final leftColumnWidth = pageWidth * 0.5;
    double leftYPosition = yPosition;

    // Financial Overview Section
    leftYPosition = _drawSectionHeaderAt(
        graphics, 'Financial Overview', leftYPosition, 0, leftColumnWidth);
    leftYPosition += 10;

    leftYPosition = _drawStatLineAt(graphics, 'Total Income:',
        monthData.totalIncome, currencySymbol, leftYPosition, 0);
    leftYPosition = _drawStatLineAt(graphics, 'Total Expenses:',
        monthData.totalExpenses, currencySymbol, leftYPosition, 0);
    leftYPosition = _drawStatLineAt(graphics, 'Net Savings:',
        monthData.getRemainingCredit(), currencySymbol, leftYPosition, 0);
    leftYPosition = _drawStatLineAt(graphics, 'Wallet Cash:',
        monthData.walletCash, currencySymbol, leftYPosition, 0);
    leftYPosition = _drawStatLineAt(graphics, 'Bank Balance:',
        monthData.bankBalance, currencySymbol, leftYPosition, 0);
    leftYPosition += 20;

    // Spending Analysis Section
    final daysWithExpenses = expenseTransactions
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet()
        .length;

    final avgDailySpending = daysWithExpenses > 0
        ? (monthData.totalExpenses / daysWithExpenses).toDouble()
        : 0.0;

    leftYPosition = _drawSectionHeaderAt(
        graphics, 'Spending Analysis', leftYPosition, 0, leftColumnWidth);
    leftYPosition += 10;
    leftYPosition = _drawStatLineAt(graphics, 'Avg Daily Spending:',
        avgDailySpending, currencySymbol, leftYPosition, 0);
    leftYPosition = _drawStatLineAt(graphics, 'Active Spending Days:',
        daysWithExpenses.toDouble(), '', leftYPosition, 0,
        isInteger: true);

    // Right side: Pie Chart
    if (sortedTags.isNotEmpty && monthData.totalExpenses > 0) {
      final chartSize = 140.0;
      final rightMargin = 20.0;
      final chartStartX = pageWidth - chartSize - rightMargin;
      final chartCenterX = chartStartX + chartSize / 2;
      final chartCenterY = yPosition + chartSize / 2 + 30;

      // Draw pie chart title
      graphics.drawString(
        'Expenses by Category',
        PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(68, 114, 196)),
        bounds: Rect.fromLTWH(chartStartX, yPosition, chartSize, 20),
      );

      double startAngle = 0;
      int colorIndex = 0;
      final colors = [
        PdfColor(68, 114, 196), // Blue
        PdfColor(237, 125, 49), // Orange
        PdfColor(165, 165, 165), // Gray
        PdfColor(255, 192, 0), // Yellow
        PdfColor(91, 155, 213), // Light Blue
        PdfColor(112, 173, 71), // Green
        PdfColor(158, 72, 14), // Brown
        PdfColor(99, 99, 99), // Dark Gray
      ];

      // Draw pie slices
      for (var i = 0; i < sortedTags.length; i++) {
        final entry = sortedTags[i];
        final percentage = entry.value / monthData.totalExpenses;
        final sweepAngle = 360 * percentage;

        graphics.drawPie(
          Rect.fromLTWH(
            chartStartX, // <-- Changed from chartCenterX - chartSize / 2
            chartCenterY - chartSize / 2,
            chartSize,
            chartSize,
          ),
          startAngle,
          sweepAngle,
          pen: PdfPen(colors[colorIndex % colors.length]),
          brush: PdfSolidBrush(colors[colorIndex % colors.length]),
        );

        startAngle += sweepAngle;
        colorIndex++;
      }

      // Draw compact legend next to pie chart
      double legendY = chartCenterY + chartSize / 2 + 15;
      colorIndex = 0;

      for (var entry in sortedTags.take(10)) {
        // Show top 5 in legend
        final tag = tagMap[entry.key];
        final tagName = tag?.name ?? 'Unknown';
        final percentage = (entry.value / monthData.totalExpenses * 100);

        // Draw color box
        graphics.drawRectangle(
          bounds: Rect.fromLTWH(chartStartX, legendY, 10, 10),
          brush: PdfSolidBrush(colors[colorIndex % colors.length]),
        );

        // Draw legend text (compact)
        final legendText = '$tagName (${percentage.toStringAsFixed(1)}%)';
        graphics.drawString(
          legendText,
          PdfStandardFont(PdfFontFamily.helvetica, 8),
          bounds: Rect.fromLTWH(chartStartX + 15, legendY, chartSize - 15, 12),
        );

        legendY += 14;
        colorIndex++;
      }
    }

    // Continue with the rest below both columns
    yPosition =
        leftYPosition > (yPosition + 280) ? leftYPosition : (yPosition + 280);
    yPosition += 20;

    // Daily Spending Line Chart
    final dailyExpenses = <DateTime, double>{};
    for (var t in expenseTransactions) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      dailyExpenses[day] = (dailyExpenses[day] ?? 0) + t.amount;
    }
    final sortedDays = dailyExpenses.keys.toList()..sort();

    if (sortedDays.isNotEmpty) {
      if (yPosition > page.getClientSize().height - 250) {
        final newPage = document.pages.add();
        page = newPage;
        graphics = newPage.graphics;
        yPosition = 0;
      }

      yPosition = _drawSectionHeader(
          graphics, 'Daily Expenses Trend', yPosition, pageWidth);
      yPosition += 10;

      // Chart dimensions
      final chartHeight = 150.0;
      final chartWidth = pageWidth - 80;
      final chartX = 60.0;
      final chartY = yPosition;

      // Find max value for scaling
      final maxExpense = dailyExpenses.values.reduce((a, b) => a > b ? a : b);
      final minExpense = 0.0;

      // Draw axes
      graphics.drawLine(
        PdfPen(PdfColor(100, 100, 100), width: 1.5),
        Offset(chartX, chartY),
        Offset(chartX, chartY + chartHeight),
      );
      graphics.drawLine(
        PdfPen(PdfColor(100, 100, 100), width: 1.5),
        Offset(chartX, chartY + chartHeight),
        Offset(chartX + chartWidth, chartY + chartHeight),
      );

      // Draw grid lines and Y-axis labels
      final numberOfGridLines = 5;
      for (int i = 0; i <= numberOfGridLines; i++) {
        final y = chartY + (chartHeight / numberOfGridLines * i);
        final value = maxExpense - (maxExpense / numberOfGridLines * i);

        // Grid line
        graphics.drawLine(
          PdfPen(PdfColor(220, 220, 220), width: 0.5),
          Offset(chartX, y),
          Offset(chartX + chartWidth, y),
        );

        // Y-axis label (right-aligned)
        final labelText = _formatNumber(value);
        final labelWidth = 50.0;
        graphics.drawString(
          labelText,
          PdfStandardFont(PdfFontFamily.helvetica, 8),
          bounds: Rect.fromLTWH(chartX - labelWidth - 5, y - 5, labelWidth, 10),
          format: PdfStringFormat(alignment: PdfTextAlignment.right),
        );
      }

      // Plot data points and lines
      final pointsToShow = sortedDays.length > 15
          ? sortedDays.sublist(sortedDays.length - 15)
          : sortedDays;

      for (int i = 0; i < pointsToShow.length; i++) {
        final day = pointsToShow[i];
        final expense = dailyExpenses[day]!;

        final x = chartX + (chartWidth / (pointsToShow.length - 1)) * i;
        final y = chartY +
            chartHeight -
            ((expense - minExpense) / (maxExpense - minExpense) * chartHeight);

        // Draw point
        graphics.drawEllipse(
          Rect.fromLTWH(x - 3, y - 3, 6, 6),
          brush: PdfSolidBrush(PdfColor(68, 114, 196)),
          pen: PdfPen(PdfColor(255, 255, 255), width: 1),
        );

        // Draw line to next point
        if (i < pointsToShow.length - 1) {
          final nextDay = pointsToShow[i + 1];
          final nextExpense = dailyExpenses[nextDay]!;
          final nextX =
              chartX + (chartWidth / (pointsToShow.length - 1)) * (i + 1);
          final nextY = chartY +
              chartHeight -
              ((nextExpense - minExpense) /
                  (maxExpense - minExpense) *
                  chartHeight);

          graphics.drawLine(
            PdfPen(PdfColor(68, 114, 196), width: 2.5),
            Offset(x, y),
            Offset(nextX, nextY),
          );
        }

        // Draw X-axis label (every few days to avoid crowding)
        if (pointsToShow.length <= 7 ||
            i % ((pointsToShow.length / 7).ceil()) == 0 ||
            i == pointsToShow.length - 1) {
          final dateLabel = '${day.day}/${day.month}';
          graphics.drawString(
            dateLabel,
            PdfStandardFont(PdfFontFamily.helvetica, 8),
            bounds: Rect.fromLTWH(x - 20, chartY + chartHeight + 5, 40, 12),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
        }
      }

      yPosition = chartY + chartHeight + 25;
    }

    // Add page number
    _addPageNumber(graphics, page, 1, document.pages.count);
  }

  /// Create transactions page
  static void _createTransactionsPage(
      PdfDocument document,
      String title,
      List<Transaction> transactions,
      Map<String, Tag> tagMap,
      MonthData monthData) {
    if (transactions.isEmpty) return;

    PdfPage page = document.pages.add();
    PdfGraphics graphics = page.graphics;
    final pageWidth = page.getClientSize().width;
    final pageHeight = page.getClientSize().height;
    double yPosition = 0;

    // Title
    final titleFont =
        PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final titleBrush = PdfSolidBrush(PdfColor(68, 114, 196));
    graphics.drawString(title, titleFont,
        brush: titleBrush, bounds: Rect.fromLTWH(0, yPosition, pageWidth, 25));
    yPosition += 35;

    // Table headers
    final headerFont =
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
    final headerBrush = PdfSolidBrush(PdfColor(211, 211, 211));
    final textBrush = PdfSolidBrush(PdfColor(0, 0, 0));

    final headers = ['Date', 'Type', 'Tag', 'Description', 'Amount', 'Payment'];
    final columnWidths = [65.0, 65.0, 70.0, 130.0, 80.0, 60.0];
    double xPosition = 0;

    // Draw header background
    graphics.drawRectangle(
      bounds: Rect.fromLTWH(0, yPosition, pageWidth, 20),
      brush: headerBrush,
    );

    // Draw header text
    for (int i = 0; i < headers.length; i++) {
      graphics.drawString(
        headers[i],
        headerFont,
        bounds:
            Rect.fromLTWH(xPosition + 5, yPosition + 5, columnWidths[i], 15),
        brush: textBrush,
      );
      xPosition += columnWidths[i];
    }
    yPosition += 25;

    // Table data
    final dataFont = PdfStandardFont(PdfFontFamily.helvetica, 9);
    int pageNumber = document.pages.indexOf(page) + 1;

    for (var transaction in transactions) {
      if (yPosition > pageHeight - 80) {
        _addPageNumber(graphics, page, pageNumber, document.pages.count + 1);
        final newPage = document.pages.add();
        page = newPage;
        graphics = newPage.graphics;
        yPosition = 0;
        pageNumber++;

        // Redraw headers on new page
        xPosition = 0;
        graphics.drawRectangle(
          bounds: Rect.fromLTWH(0, yPosition, pageWidth, 20),
          brush: headerBrush,
        );
        for (int i = 0; i < headers.length; i++) {
          graphics.drawString(
            headers[i],
            headerFont,
            bounds: Rect.fromLTWH(
                xPosition + 5, yPosition + 5, columnWidths[i], 15),
            brush: textBrush,
          );
          xPosition += columnWidths[i];
        }
        yPosition += 25;
      }

      final tag = tagMap[transaction.tagId];
      xPosition = 0;

      final currencySymbol = DatabaseHelper.getCurrencySymbol();

      // Format amount with sign (only expenses get negative sign)
      String amountStr;
      if (transaction.type == 'expense') {
        amountStr = '-$currencySymbol ${_formatNumber(transaction.amount)}';
      } else {
        amountStr = '$currencySymbol ${_formatNumber(transaction.amount)}';
      }

      // Capitalize first letter of type
      final typeStr =
          transaction.type[0].toUpperCase() + transaction.type.substring(1);

      final rowData = [
        _formatDate(transaction.date),
        typeStr,
        tag?.name ?? 'Unknown',
        transaction.description.length > 20
            ? '${transaction.description.substring(0, 17)}...'
            : transaction.description,
        amountStr,
        transaction.paymentMethod ?? 'N/A',
      ];

      // Draw alternating row background
      if (transactions.indexOf(transaction) % 2 == 0) {
        graphics.drawRectangle(
          bounds: Rect.fromLTWH(0, yPosition, pageWidth, 18),
          brush: PdfSolidBrush(PdfColor(245, 245, 245)),
        );
      }

      for (int i = 0; i < rowData.length; i++) {
        graphics.drawString(
          rowData[i],
          dataFont,
          bounds: Rect.fromLTWH(
              xPosition + 5, yPosition + 3, columnWidths[i] - 10, 15),
          brush: textBrush,
        );
        xPosition += columnWidths[i];
      }

      yPosition += 18;
    }

    // Only show Net Savings for "All Transactions" page
    if (title == 'All Transactions') {
      // Draw total row
      yPosition += 10;

      // Draw total background
      graphics.drawRectangle(
        bounds: Rect.fromLTWH(0, yPosition, pageWidth, 20),
        brush: PdfSolidBrush(PdfColor(230, 230, 230)),
      );

      final totalFont = PdfStandardFont(PdfFontFamily.helvetica, 11,
          style: PdfFontStyle.bold);
      final currencySymbol = DatabaseHelper.getCurrencySymbol();

      final netSavings = monthData.getRemainingCredit();
      String netSavingsStr;
      if (netSavings >= 0) {
        netSavingsStr = '$currencySymbol ${_formatNumber(netSavings)}';
      } else {
        netSavingsStr = '-$currencySymbol ${_formatNumber(netSavings.abs())}';
      }

      graphics.drawString(
        'NET SAVINGS:',
        totalFont,
        bounds: Rect.fromLTWH(columnWidths[0] + columnWidths[1] + 10,
            yPosition + 3, columnWidths[2] + columnWidths[3], 15),
        brush: textBrush,
      );
      graphics.drawString(
        netSavingsStr,
        totalFont,
        bounds: Rect.fromLTWH(
            columnWidths[0] +
                columnWidths[1] +
                columnWidths[2] +
                columnWidths[3] +
                10,
            yPosition + 3,
            columnWidths[4],
            15),
        brush: textBrush,
      );
    }

    _addPageNumber(graphics, page, pageNumber, document.pages.count);
  }

  // Helper methods

  static double _drawSectionHeader(
      PdfGraphics graphics, String title, double yPosition, double pageWidth) {
    final headerFont =
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);
    final headerBrush = PdfSolidBrush(PdfColor(68, 114, 196));
    graphics.drawString(
      title,
      headerFont,
      brush: headerBrush,
      bounds: Rect.fromLTWH(0, yPosition, pageWidth, 20),
    );
    return yPosition + 25;
  }

  static double _drawSectionHeaderAt(PdfGraphics graphics, String title,
      double yPosition, double xPosition, double width) {
    final headerFont =
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);
    final headerBrush = PdfSolidBrush(PdfColor(68, 114, 196));
    graphics.drawString(
      title,
      headerFont,
      brush: headerBrush,
      bounds: Rect.fromLTWH(xPosition, yPosition, width, 20),
    );
    return yPosition + 25;
  }

  static double _drawStatLine(PdfGraphics graphics, String label, double value,
      String currency, double yPosition,
      {bool isInteger = false}) {
    final labelFont = PdfStandardFont(PdfFontFamily.helvetica, 11);
    final valueFont =
        PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold);

    graphics.drawString(
      label,
      labelFont,
      bounds: Rect.fromLTWH(0, yPosition, 200, 15),
    );

    final formattedValue =
        isInteger ? value.toInt().toString() : _formatNumber(value);
    final valueText =
        currency.isEmpty ? formattedValue : '$currency $formattedValue';

    graphics.drawString(
      valueText,
      valueFont,
      bounds: Rect.fromLTWH(200, yPosition, 200, 15),
    );

    return yPosition + 18;
  }

  static double _drawStatLineAt(PdfGraphics graphics, String label,
      double value, String currency, double yPosition, double xPosition,
      {bool isInteger = false}) {
    final labelFont = PdfStandardFont(PdfFontFamily.helvetica, 11);
    final valueFont =
        PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold);

    graphics.drawString(
      label,
      labelFont,
      bounds: Rect.fromLTWH(xPosition, yPosition, 150, 15),
    );

    final formattedValue =
        isInteger ? value.toInt().toString() : _formatNumber(value);
    final valueText =
        currency.isEmpty ? formattedValue : '$currency $formattedValue';

    graphics.drawString(
      valueText,
      valueFont,
      bounds: Rect.fromLTWH(xPosition + 150, yPosition, 150, 15),
    );

    return yPosition + 18;
  }

  static void _addPageNumber(
      PdfGraphics graphics, PdfPage page, int currentPage, int totalPages) {
    final pageSize = page.getClientSize();
    final pageNumberText = 'Page $currentPage of $totalPages';
    final font = PdfStandardFont(PdfFontFamily.helvetica, 9);
    final textSize = font.measureString(pageNumberText);

    graphics.drawString(
      pageNumberText,
      font,
      bounds: Rect.fromLTWH(
        (pageSize.width - textSize.width) / 2,
        pageSize.height + 20,
        textSize.width,
        textSize.height,
      ),
    );
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

  static Future<String> _saveAndSharePDF(
      PdfDocument document, String monthName) async {
    print('📄 Starting PDF save process...');
    final fileName = 'Budget_${monthName.replaceAll(' ', '_')}.pdf';
    print('📄 File name: $fileName');

    final List<int> bytes = document.saveSync();
    print('📄 PDF bytes generated: ${bytes.length} bytes');
    document.dispose();

    print('📄 About to call _saveToDownloads...');
    final savedPath = await _saveToDownloads(bytes, fileName);
    print('📄 Saved path returned: $savedPath');

    if (savedPath != null) {
      print('📄 File saved successfully to: $savedPath');
      await Share.shareXFiles(
        [XFile(savedPath)],
        subject: 'Budget Report - $monthName',
        text: 'Here is your budget report for $monthName',
      );
      print('📄 Share dialog opened');
      return savedPath;
    } else {
      print('⚠️ Failed to save to Downloads, using temp directory');
      final directory = await getTemporaryDirectory();
      final tempPath = '${directory.path}/$fileName';
      print('📄 Temp path: $tempPath');
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(tempPath)]);
      print('📄 Share dialog opened from temp');
      return tempPath;
    }
  }

  static Future<String> _saveAndShareCSV(String csv, String monthName) async {
    final fileName = 'Budget_${monthName.replaceAll(' ', '_')}.csv';
    final bytes = csv.codeUnits;

    final savedPath = await _saveToDownloads(bytes, fileName);

    if (savedPath != null) {
      await Share.shareXFiles(
        [XFile(savedPath)],
        subject: 'Budget Report - $monthName',
        text: 'Here is your budget report for $monthName',
      );
      return savedPath;
    } else {
      final directory = await getTemporaryDirectory();
      final tempPath = '${directory.path}/$fileName';
      final tempFile = File(tempPath);
      await tempFile.writeAsString(csv);
      await Share.shareXFiles([XFile(tempPath)]);
      return tempPath;
    }
  }

  static Future<String?> _saveToDownloads(
      List<int> bytes, String fileName) async {
    try {
      print('💾 [START] Attempting to save to Downloads...');
      print(
          '💾 Platform: ${Platform.isAndroid ? "Android" : Platform.isIOS ? "iOS" : "Other"}');
      print('💾 File size to save: ${bytes.length} bytes');

      Directory? dir;

      if (Platform.isAndroid) {
        print('💾 Android detected - attempting direct write to Downloads');

        // Try primary Downloads path
        dir = Directory('/storage/emulated/0/Download');
        print('💾 Checking directory: ${dir.path}');
        bool exists = await dir.exists();
        print('💾 Directory exists: $exists');

        if (!exists) {
          print('⚠️ Download directory does not exist, trying alternative');
          // Try alternative Downloads path
          dir = Directory('/storage/emulated/0/Downloads');
          print('💾 Checking alternative: ${dir.path}');
          exists = await dir.exists();
          print('💾 Alternative exists: $exists');

          if (!exists) {
            print('⚠️ Alternative also does not exist, using external storage');
            dir = await getExternalStorageDirectory();
            print('💾 External storage directory: ${dir?.path}');
            if (dir != null) {
              exists = await dir.exists();
              print('💾 External storage exists: $exists');
            }
          }
        }
      } else if (Platform.isIOS) {
        print('💾 iOS detected, using ApplicationDocuments');
        dir = await getApplicationDocumentsDirectory();
        print('💾 Directory: ${dir.path}');
      }

      if (dir != null) {
        print('💾 [WRITE] Using directory: ${dir.path}');
        String baseName = fileName.substring(0, fileName.lastIndexOf('.'));
        String extension = fileName.substring(fileName.lastIndexOf('.'));

        String uniquePath = '${dir.path}/$fileName';
        int counter = 1;

        print('💾 Checking for existing files at: $uniquePath');
        while (await File(uniquePath).exists()) {
          uniquePath = '${dir.path}/$baseName($counter)$extension';
          counter++;
          print('💾 File exists, trying: $uniquePath');
        }

        print('💾 [WRITE] Final path: $uniquePath');
        print('💾 [WRITE] Attempting to write ${bytes.length} bytes...');
        final file = File(uniquePath);
        await file.writeAsBytes(bytes, flush: true);

        final fileExists = await file.exists();
        final fileSize = fileExists ? await file.length() : 0;

        print('✅ [SUCCESS] File written: $fileExists');
        print('✅ [SUCCESS] File size on disk: $fileSize bytes');
        print('✅ [SUCCESS] Final saved path: $uniquePath');

        return uniquePath;
      }
      print('❌ [FAIL] Directory is null - cannot save');
      return null;
    } catch (e, stackTrace) {
      print('❌ [ERROR] Exception in _saveToDownloads: $e');
      print('❌ [ERROR] Stack trace: $stackTrace');
      return null;
    }
  }
}
