import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../storage/database_helper.dart';
import '../models/month_data.dart';
import '../models/transaction.dart';
import 'add_transaction_page.dart';
import 'history_page.dart';
import 'settings_page.dart';
import 'package:intl/intl.dart';
import '../utils/format_currency.dart';
import '../widgets/month_selector.dart';
import '../services/widget_service.dart'; // THIS IS FOR DEVICE HOMESCREEN WIDGET, NOT APP UI. HEY MR AI DO NOT TOUCH THIS SHIT.
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/animated_number.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String? selectedMonthId;

  String get currencySymbol => DatabaseHelper.getCurrencySymbol();

  @override
  void initState() {
    super.initState();
    // Initialize selected month
    final currentMonth = DatabaseHelper.getCurrentMonth();
    selectedMonthId = currentMonth.id;
  }

  // Keep loadData() method for widget service compatibility
  void loadData({bool keepSelectedMonth = true}) {
    setState(() {
      // Just trigger rebuild, ValueListenableBuilder will handle the rest
      if (!keepSelectedMonth) {
        final currentMonth = DatabaseHelper.getCurrentMonth();
        selectedMonthId = currentMonth.id;
      }
    });
  }

  void _showMonthPicker() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => MonthPickerDialog(
        availableMonths: DatabaseHelper.getAllMonths(),
        selectedMonthId: selectedMonthId ?? '',
      ),
    );

    if (result != null && result != selectedMonthId) {
      setState(() {
        selectedMonthId = result;
      });
    }
  }

  void _showAddTransactionModal() {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final modalColor =
        theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: modalColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: AddTransactionPage(
          onSaved: () {
            Navigator.pop(context);
            WidgetService.refreshWidget();
          },
          onFilePicking: (isPicking) {},
        ),
      ),
    );
  }

  void _showEditTransactionModal(Transaction transaction) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final modalColor =
        theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: modalColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: AddTransactionPage(
          existingTransaction: transaction,
          monthId: selectedMonthId,
          onSaved: () {
            Navigator.pop(context);
            WidgetService.refreshWidget();
          },
          onFilePicking: (isPicking) {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    // Wrap the entire body in ValueListenableBuilder to listen to month box changes
    return ValueListenableBuilder(
      valueListenable:
          Hive.box<MonthData>(DatabaseHelper.monthBoxName).listenable(),
      builder: (context, Box<MonthData> monthBox, _) {
        // Get current month data
        MonthData? currentMonth = monthBox.get(selectedMonthId);

        // If month doesn't exist, create empty one
        if (currentMonth == null) {
          currentMonth = MonthData(
            id: selectedMonthId!,
            walletCash: 0,
            bankBalance: 0,
            transactionIds: [],
          );
        }

        // Get recent transactions
        final recentTransactions =
            DatabaseHelper.getTransactionsForMonth(selectedMonthId ?? '')
                .take(5)
                .toList();

        final cardColor =
            theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = theme.isDarkMode ? Colors.white : Colors.black87;
        final subtitleColor =
            theme.isDarkMode ? Colors.grey[400] : Colors.grey[600];

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            elevation: 0,
            backgroundColor:
                theme.isDarkMode ? const Color(0xFF121212) : Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  theme.isDarkMode ? Brightness.light : Brightness.dark,
            ),
            leading: IconButton(
              icon: Icon(Icons.calendar_month, color: textColor),
              onPressed: _showMonthPicker,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 24,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Budget',
                    style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                Text(currentMonth.getMonthName(),
                    style: TextStyle(color: subtitleColor, fontSize: 12)),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.history, color: textColor),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryPage(monthId: selectedMonthId!),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.settings_outlined, color: textColor),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SettingsPage()),
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // Force recalculation if needed
              DatabaseHelper.recalculateMonth(selectedMonthId!);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                _buildMainBalanceCard(theme, currentMonth, recentTransactions),
                const SizedBox(height: 20),
                _buildQuickStatsGrid(
                    theme, cardColor, textColor, subtitleColor, currentMonth),
                const SizedBox(height: 16),
                _buildBudgetBreakdown(
                    theme, cardColor, subtitleColor, currentMonth),
                const SizedBox(height: 16),
                _buildRecentTransactions(theme, cardColor, textColor,
                    subtitleColor, recentTransactions, currentMonth),
                const SizedBox(height: 100),
              ],
            ),
          ),
          floatingActionButton: SizedBox(
            height: 56,
            child: FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Add Transaction'),
              onPressed: _showAddTransactionModal,
              backgroundColor: theme.primary,
              elevation: 4,
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildMainBalanceCard(ThemeProvider theme, MonthData currentMonth,
      List<Transaction> recentTransactions) {
    final remaining = currentMonth.getRemainingCredit();
    final dailyBudget = currentMonth.getDailyBudget();
    final todayExpenses = currentMonth.getTodayExpenses(recentTransactions);
    final remainingDailyBudget =
        currentMonth.getRemainingDailyBudget(recentTransactions);
    final isOverspent = currentMonth.isOverspentToday(recentTransactions);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary, theme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remaining Credit',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedNumber(
            value: remaining,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Budget',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedNumber(
                      value: dailyBudget,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent Today',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedNumber(
                      value: todayExpenses,
                      style: TextStyle(
                        color: isOverspent ? Colors.red[300] : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Left Today',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isOverspent)
                          Text(
                            '-',
                            style: TextStyle(
                              color: Colors.red[300],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        Flexible(
                          child: AnimatedNumber(
                            value: isOverspent
                                ? (todayExpenses - dailyBudget)
                                : remainingDailyBudget,
                            style: TextStyle(
                              color:
                                  isOverspent ? Colors.red[300] : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid(ThemeProvider theme, Color cardColor,
      Color textColor, Color? subtitleColor, MonthData currentMonth) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Wallet',
            currentMonth.walletCash,
            Icons.wallet,
            theme.warning,
            cardColor,
            textColor,
            subtitleColor,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Bank',
            currentMonth.bankBalance,
            Icons.account_balance_outlined,
            theme.success,
            cardColor,
            textColor,
            subtitleColor,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label,
      double amount,
      IconData icon,
      Color color,
      Color cardColor,
      Color textColor,
      Color? subtitleColor,
      ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: subtitleColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedNumber(
                      value: amount,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetBreakdown(ThemeProvider theme, Color cardColor,
      Color? subtitleColor, MonthData currentMonth) {
    final income = currentMonth.totalIncome;
    final expenses = currentMonth.totalExpenses;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Income',
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedNumber(
                  value: income,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expenses',
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedNumber(
                  value: expenses,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(
      ThemeProvider theme,
      Color cardColor,
      Color textColor,
      Color? subtitleColor,
      List<Transaction> recentTransactions,
      MonthData currentMonth) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoryPage(monthId: selectedMonthId!),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: theme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (recentTransactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color:
                        theme.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ...recentTransactions.map((transaction) {
              final tag = DatabaseHelper.getTag(transaction.tagId);
              Color typeColor;

              switch (transaction.type) {
                case 'income':
                case 'surplus':
                  typeColor = theme.success;
                  break;
                case 'expense':
                  typeColor = theme.danger;
                  break;
                case 'withdrawal':
                  typeColor = theme.primary;
                  break;
                default:
                  typeColor = Colors.grey;
              }

              return InkWell(
                onTap: () {
                  _showEditTransactionModal(transaction);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: theme.isDarkMode
                            ? Colors.grey[800]!
                            : Colors.grey[100]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          tag?.getIconData() ?? Icons.circle,
                          color: typeColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tag?.name ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('MMM dd, yyyy')
                                  .format(transaction.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${transaction.type == 'expense' ? '-' : '+'}${formatCurrency(transaction.amount)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
