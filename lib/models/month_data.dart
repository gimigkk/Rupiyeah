import 'package:hive/hive.dart';

part 'month_data.g.dart';

@HiveType(typeId: 2)
class MonthData {
  @HiveField(0)
  String id; // Format: 'YYYY-MM'

  @HiveField(1)
  double walletCash;

  @HiveField(2)
  double bankBalance;

  @HiveField(3)
  double totalIncome;

  @HiveField(4)
  double totalExpenses;

  @HiveField(5)
  bool isAutoDailyBudget;

  @HiveField(6)
  double manualDailyBudget;

  @HiveField(7)
  List<String> transactionIds;

  MonthData({
    required this.id,
    this.walletCash = 0,
    this.bankBalance = 0,
    this.totalIncome = 0,
    this.totalExpenses = 0,
    this.isAutoDailyBudget = true,
    this.manualDailyBudget = 0,
    this.transactionIds = const [],
  });

  // Calculate remaining credit
  double getRemainingCredit() {
    return totalIncome - totalExpenses;
  }

  // Calculate daily budget (base amount, not decremented)
  double getDailyBudget() {
    if (!isAutoDailyBudget) {
      return manualDailyBudget;
    }

    // Auto mode: remaining credit ÷ days left in month
    final now = DateTime.now();
    final year = int.parse(id.split('-')[0]);
    final month = int.parse(id.split('-')[1]);

    // Check if this is the current month
    if (year != now.year || month != now.month) {
      return 0;
    }

    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final daysLeft = lastDayOfMonth - now.day + 1;

    if (daysLeft <= 0) return 0;

    final remaining = getRemainingCredit();
    if (remaining <= 0) return 0;

    return remaining / daysLeft;
  }

  // Calculate today's expenses (requires transactions to be passed in)
  double getTodayExpenses(List<dynamic> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    double todayTotal = 0;
    for (var transaction in transactions) {
      final transactionDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      if (transactionDate == today && transaction.type == 'expense') {
        todayTotal += transaction.amount;
      }
    }

    return todayTotal;
  }

  // Calculate remaining daily budget (daily budget - today's expenses)
  double getRemainingDailyBudget(List<dynamic> transactions) {
    final dailyBudget = getDailyBudget();
    final todayExpenses = getTodayExpenses(transactions);
    final remaining = dailyBudget - todayExpenses;

    // Return 0 if negative (overspent)
    return remaining > 0 ? remaining : 0;
  }

  // Check if user has overspent today
  bool isOverspentToday(List<dynamic> transactions) {
    final dailyBudget = getDailyBudget();
    final todayExpenses = getTodayExpenses(transactions);
    return todayExpenses > dailyBudget;
  }

  // Get month name
  String getMonthName() {
    final parts = id.split('-');
    final year = parts[0];
    final month = int.parse(parts[1]);

    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return '${monthNames[month - 1]} $year';
  }
}
