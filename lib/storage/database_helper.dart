import 'package:hive_flutter/hive_flutter.dart';
import '../models/month_data.dart';
import '../models/transaction.dart';
import '../models/tag.dart';
import '../storage/file_helper.dart';
import '../services/widget_service.dart';

class DatabaseHelper {
  static const String monthBoxName = 'months';
  static const String transactionBoxName = 'transactions';
  static const String tagBoxName = 'tags';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(MonthDataAdapter());
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(TagAdapter());

    // Open boxes
    await Hive.openBox<MonthData>(monthBoxName);
    await Hive.openBox<Transaction>(transactionBoxName);
    await Hive.openBox<Tag>(tagBoxName);
    await Hive.openBox('settings');

    // Add default tags if empty
    final tagBox = Hive.box<Tag>(tagBoxName);
    if (tagBox.isEmpty) {
      _addDefaultTags();
    }

    // Ensure "Other" tags exist for each type
    _ensureDefaultOtherTags();
  }

  static void _addDefaultTags() {
    final tagBox = Hive.box<Tag>(tagBoxName);
    final defaultTags = [
      // Income tags
      Tag(
          id: '1',
          name: 'Salary',
          icon: 'money',
          color: 0xFF4CAF50,
          type: 'income'),
      Tag(
          id: '2',
          name: 'Bonus',
          icon: 'gift',
          color: 0xFF8BC34A,
          type: 'income'),
      Tag(
          id: 'other_income',
          name: 'Other',
          icon: 'circle',
          color: 0xFF9E9E9E,
          type: 'income'),
      // Expense tags
      Tag(
          id: '3',
          name: 'Food',
          icon: 'food',
          color: 0xFFFF9800,
          type: 'expense'),
      Tag(
          id: '4',
          name: 'Transport',
          icon: 'car',
          color: 0xFF2196F3,
          type: 'expense'),
      Tag(
          id: '5',
          name: 'Shopping',
          icon: 'shopping',
          color: 0xFFE91E63,
          type: 'expense'),
      Tag(
          id: '6',
          name: 'University',
          icon: 'education',
          color: 0xFF9C27B0,
          type: 'expense'),
      Tag(
          id: '7',
          name: 'Gasoline',
          icon: 'car',
          color: 0xFF795548,
          type: 'expense'),
      Tag(
          id: '8',
          name: 'Entertainment',
          icon: 'entertainment',
          color: 0xFFFF5722,
          type: 'expense'),
      Tag(
          id: 'other_expense',
          name: 'Other',
          icon: 'circle',
          color: 0xFF9E9E9E,
          type: 'expense'),
      // Withdrawal tags
      Tag(
          id: '9',
          name: 'ATM',
          icon: 'atm',
          color: 0xFF607D8B,
          type: 'withdrawal'),
      Tag(
          id: '10',
          name: 'Teller',
          icon: 'atm',
          color: 0xFF455A64,
          type: 'withdrawal'),
      Tag(
          id: 'other_withdrawal',
          name: 'Other',
          icon: 'circle',
          color: 0xFF9E9E9E,
          type: 'withdrawal'),
    ];

    for (var tag in defaultTags) {
      tagBox.put(tag.id, tag);
    }
  }

  static void debugPrintAllData() {
    print('=== DEBUG: All Database Data ===');

    // Print all months
    final monthBox = Hive.box<MonthData>(monthBoxName);
    print('Months (${monthBox.length}):');
    for (var month in monthBox.values) {
      print(
          '  ${month.id}: Income=${month.totalIncome}, Expenses=${month.totalExpenses}, Transactions=${month.transactionIds.length}');
    }

    // Print all transactions
    final transactionBox = Hive.box<Transaction>(transactionBoxName);
    print('\nTransactions (${transactionBox.length}):');
    for (var transaction in transactionBox.values) {
      print(
          '  ${transaction.id}: ${transaction.type} ${transaction.amount} on ${transaction.date}');
    }

    print('=== END DEBUG ===\n');
  }

  // Ensure "Other" tags exist for each type
  static void _ensureDefaultOtherTags() {
    final tagBox = Hive.box<Tag>(tagBoxName);
    final types = ['income', 'expense', 'withdrawal'];

    for (var type in types) {
      final hasOther = tagBox.values
          .any((t) => t.name.toLowerCase() == 'other' && t.type == type);

      if (!hasOther) {
        final otherTag = Tag(
          id: 'other_$type',
          name: 'Other',
          icon: 'circle',
          color: 0xFF9E9E9E,
          type: type,
        );
        tagBox.put(otherTag.id, otherTag);
      }
    }
  }

  // Get or create current month (independent, no balance transfer)
  static MonthData getCurrentMonth() {
    final now = DateTime.now();
    final monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final monthBox = Hive.box<MonthData>(monthBoxName);

    if (!monthBox.containsKey(monthId)) {
      // Create new month starting from 0
      final newMonth = MonthData(
        id: monthId,
        walletCash: 0,
        bankBalance: 0,
        transactionIds: [],
      );
      monthBox.put(monthId, newMonth);
    }

    return monthBox.get(monthId)!;
  }

  static MonthData? _getPreviousMonth() {
    final now = DateTime.now();
    final previousDate = DateTime(now.year, now.month - 1);
    final previousMonthId =
        '${previousDate.year}-${previousDate.month.toString().padLeft(2, '0')}';
    return Hive.box<MonthData>(monthBoxName).get(previousMonthId);
  }

  // Get month by ID
  static MonthData? getMonth(String monthId) {
    return Hive.box<MonthData>(monthBoxName).get(monthId);
  }

  // Get all months sorted by date (newest first)
  static List<MonthData> getAllMonths() {
    final monthBox = Hive.box<MonthData>(monthBoxName);
    final months = monthBox.values.toList();
    months.sort((a, b) => b.id.compareTo(a.id));
    return months;
  }

  // Add transaction and recalculate month
  static void addTransaction(Transaction transaction, {String? monthId}) {
    final transactionBox = Hive.box<Transaction>(transactionBoxName);
    final monthBox = Hive.box<MonthData>(monthBoxName);

    // Save transaction
    transactionBox.put(transaction.id, transaction);

    // Determine which month this belongs to
    final targetMonthId = monthId ??
        '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';

    MonthData? month = monthBox.get(targetMonthId);

    // Create month if it doesn't exist
    if (month == null) {
      month = MonthData(
        id: targetMonthId,
        walletCash: 0,
        bankBalance: 0,
        transactionIds: [],
      );
    }

    // Add transaction ID if not already present
    if (!month.transactionIds.contains(transaction.id)) {
      month.transactionIds.add(transaction.id);
    }

    // Save the month first
    monthBox.put(month.id, month);

    // Recalculate ONLY this specific month
    recalculateMonth(targetMonthId);

    WidgetService.refreshWidget();
  }

  // Update existing transaction
  static void updateTransaction(
      Transaction oldTransaction, Transaction newTransaction) {
    final transactionBox = Hive.box<Transaction>(transactionBoxName);
    final monthBox = Hive.box<MonthData>(monthBoxName);

    // CRITICAL: Ensure the new transaction keeps the same ID
    if (oldTransaction.id != newTransaction.id) {
      // If IDs are different, we need to use the old ID
      newTransaction = Transaction(
        id: oldTransaction.id,
        amount: newTransaction.amount,
        tagId: newTransaction.tagId,
        description: newTransaction.description,
        date: newTransaction.date,
        type: newTransaction.type,
        paymentMethod: newTransaction.paymentMethod,
        attachmentPath: newTransaction.attachmentPath,
      );
    }

    // Use the transaction dates to determine which months are involved
    final oldMonthId =
        '${oldTransaction.date.year}-${oldTransaction.date.month.toString().padLeft(2, '0')}';
    final newMonthId =
        '${newTransaction.date.year}-${newTransaction.date.month.toString().padLeft(2, '0')}';

    // If moving to a different month, handle the transfer
    if (oldMonthId != newMonthId) {
      // Remove from old month
      final oldMonth = monthBox.get(oldMonthId);
      if (oldMonth != null) {
        oldMonth.transactionIds.remove(oldTransaction.id);
        monthBox.put(oldMonth.id, oldMonth);
      }

      // Add to new month
      MonthData? newMonth = monthBox.get(newMonthId);
      if (newMonth == null) {
        newMonth = MonthData(
          id: newMonthId,
          walletCash: 0,
          bankBalance: 0,
          transactionIds: [],
        );
      }

      if (!newMonth.transactionIds.contains(newTransaction.id)) {
        newMonth.transactionIds.add(newTransaction.id);
      }
      monthBox.put(newMonth.id, newMonth);
    }

    // Update the transaction in the database
    transactionBox.put(newTransaction.id, newTransaction);

    // Recalculate ONLY the affected months (no cascading needed)
    //recalculateMonth(oldMonthId);
    //if (oldMonthId != newMonthId) {
    //  recalculateMonth(newMonthId);
    //}

    // Force notify listeners for both transaction and month boxes
    //transactionBox.flush();
    //monthBox.flush();

    WidgetService.refreshWidget();
  }

  // Recalculate a single month from its transactions (independent calculation)
  static void recalculateMonth(String monthId) {
    final monthBox = Hive.box<MonthData>(monthBoxName);
    final transactionBox = Hive.box<Transaction>(transactionBoxName);

    final month = monthBox.get(monthId);
    if (month == null) return;

    // Start from 0 - each month is independent
    double walletCash = 0;
    double bankBalance = 0;
    double totalIncome = 0;
    double totalExpenses = 0;

    // Clean up and recalculate from all valid transactions
    final validTransactionIds = <String>[];

    for (var transactionId in month.transactionIds) {
      final transaction = transactionBox.get(transactionId);

      if (transaction != null) {
        validTransactionIds.add(transactionId);

        // Apply transaction effects
        if (transaction.type == 'income') {
          totalIncome += transaction.amount;
          if (transaction.paymentMethod == 'cash') {
            walletCash += transaction.amount;
          } else {
            bankBalance += transaction.amount;
          }
        } else if (transaction.type == 'expense') {
          totalExpenses += transaction.amount;
          if (transaction.paymentMethod == 'cash') {
            walletCash -= transaction.amount;
          } else {
            bankBalance -= transaction.amount;
          }
        } else if (transaction.type == 'withdrawal') {
          bankBalance -= transaction.amount;
          walletCash += transaction.amount;
        }
      }
    }

    // CRITICAL: Delete and re-insert to force Hive notifications
    monthBox.delete(monthId);

    final updatedMonth = MonthData(
      id: month.id,
      walletCash: walletCash,
      bankBalance: bankBalance,
      transactionIds: validTransactionIds,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      isAutoDailyBudget: month.isAutoDailyBudget,
      manualDailyBudget: month.manualDailyBudget,
    );

    monthBox.put(updatedMonth.id, updatedMonth);
  }

  // Recalculate all months (for database repair or initial sync)
  static void recalculateAllMonths() {
    final monthBox = Hive.box<MonthData>(monthBoxName);

    // Each month is independent, so order doesn't matter
    for (var month in monthBox.values) {
      recalculateMonth(month.id);
    }
  }

  // Delete transaction
  static void deleteTransaction(String transactionId) async {
    final transactionBox = Hive.box<Transaction>(transactionBoxName);
    final monthBox = Hive.box<MonthData>(monthBoxName);
    final transaction = transactionBox.get(transactionId);

    if (transaction != null) {
      // Delete attachment file if exists
      if (transaction.attachmentPath != null) {
        await FileHelper.deleteFile(transaction.attachmentPath);
      }

      // Find which month this transaction belongs to
      final transactionDate = transaction.date;
      final monthId =
          '${transactionDate.year}-${transactionDate.month.toString().padLeft(2, '0')}';

      // Remove from month's transaction list
      final month = monthBox.get(monthId);
      if (month != null) {
        month.transactionIds.remove(transactionId);
        monthBox.put(month.id, month);
      }

      // Delete the transaction itself
      transactionBox.delete(transactionId);

      // Recalculate ONLY this specific month
      recalculateMonth(monthId);
    }

    WidgetService.refreshWidget();
  }

  // Get all transactions for current month
  static List<Transaction> getTransactionsForMonth(String monthId) {
    final month = Hive.box<MonthData>(monthBoxName).get(monthId);
    if (month == null) return [];

    final transactionBox = Hive.box<Transaction>(transactionBoxName);
    return month.transactionIds
        .map((id) => transactionBox.get(id))
        .where((t) => t != null)
        .cast<Transaction>()
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Get all tags
  static List<Tag> getAllTags() {
    return Hive.box<Tag>(tagBoxName).values.toList();
  }

  // Get tags by type
  static List<Tag> getTagsByType(String type) {
    return Hive.box<Tag>(tagBoxName)
        .values
        .where((tag) => tag.type == type)
        .toList();
  }

  // Get tag by ID
  static Tag? getTag(String tagId) {
    return Hive.box<Tag>(tagBoxName).get(tagId);
  }

  // Add new tag
  static void addTag(Tag tag) {
    Hive.box<Tag>(tagBoxName).put(tag.id, tag);
  }

  // Update an existing tag
  static void updateTag(Tag tag) {
    final tagBox = Hive.box<Tag>(tagBoxName);

    // Prevent editing "Other" tags
    final existingTag = tagBox.get(tag.id);
    if (existingTag != null && existingTag.name.toLowerCase() == 'other') {
      return; // Don't allow editing "Other" tags
    }

    tagBox.put(tag.id, tag);
  }

  // Delete a tag and reassign transactions to "Other"
  static void deleteTag(String tagId) {
    final tagBox = Hive.box<Tag>(tagBoxName);
    final transactionBox = Hive.box<Transaction>(transactionBoxName);
    final monthBox = Hive.box<MonthData>(monthBoxName);

    final tagToDelete = tagBox.get(tagId);
    if (tagToDelete == null) return;

    // Prevent deleting "Other" tags
    if (tagToDelete.name.toLowerCase() == 'other') {
      return;
    }

    // Find the "Other" tag for the same type
    final otherTag = tagBox.values.firstWhere(
      (t) => t.name.toLowerCase() == 'other' && t.type == tagToDelete.type,
      orElse: () => tagBox.values.first, // Fallback
    );

    // Reassign all transactions using this tag to "Other"
    for (var month in monthBox.values) {
      bool monthUpdated = false;

      for (var transactionId in month.transactionIds) {
        final transaction = transactionBox.get(transactionId);
        if (transaction != null && transaction.tagId == tagId) {
          transaction.tagId = otherTag.id;
          transactionBox.put(transactionId, transaction);
          monthUpdated = true;
        }
      }

      if (monthUpdated) {
        monthBox.put(month.id, month);
      }
    }

    // Remove the tag
    tagBox.delete(tagId);
  }

  // Check if a tag is the default "Other" tag
  static bool isOtherTag(String tagId) {
    final tag = getTag(tagId);
    return tag != null && tag.name.toLowerCase() == 'other';
  }

  // Update daily budget settings
  static void updateDailyBudgetSettings(bool isAuto, double manualAmount) {
    final month = getCurrentMonth();
    month.isAutoDailyBudget = isAuto;
    month.manualDailyBudget = manualAmount;
    Hive.box<MonthData>(monthBoxName).put(month.id, month);

    WidgetService.refreshWidget();
  }

  // Get currency symbol (default to Rupiah)
  static String getCurrencySymbol() {
    final box = Hive.box('settings');
    return box.get('currencySymbol', defaultValue: 'Rp');
  }

  // Get currency code
  static String getCurrencyCode() {
    final box = Hive.box('settings');
    return box.get('currencyCode', defaultValue: 'IDR');
  }

  // Set currency
  static Future<void> setCurrency(String symbol, String code) async {
    final box = Hive.box('settings');
    await box.put('currencySymbol', symbol);
    await box.put('currencyCode', code);
  }

  // Theme preference storage
  static String getThemeId() {
    final box = Hive.box('settings');
    return box.get('theme_id', defaultValue: 'purple');
  }

  static void saveThemeId(String themeId) {
    final box = Hive.box('settings');
    box.put('theme_id', themeId);
  }

  static void saveDarkMode(bool isDark) {
    final box = Hive.box('settings');
    box.put('dark_mode', isDark);
  }

  static bool getDarkMode() {
    final box = Hive.box('settings');
    return box.get('dark_mode', defaultValue: false);
  }
}
