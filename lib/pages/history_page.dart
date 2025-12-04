import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../storage/database_helper.dart';
import '../models/transaction.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/daily_expense_chart.dart';
import '../providers/theme_provider.dart';
import '../services/widget_service.dart';
import 'add_transaction_page.dart';

class HistoryPage extends StatefulWidget {
  final String monthId;

  const HistoryPage({Key? key, required this.monthId}) : super(key: key);

  @override
  HistoryPageState createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  List<Transaction> _transactions = [];
  Map<String, double> _dailyTotals = {};
  bool _showChart = false;
  bool _isCompactView = false;

  // only for expenses
  void _calculateDailyTotals() {
    final Map<String, double> totals = {};

    for (var t in _transactions) {
      // Only include EXPENSE transactions
      if (t.type != 'expense') continue;

      final date = DateFormat('yyyy-MM-dd').format(t.date);

      if (!totals.containsKey(date)) {
        totals[date] = 0;
      }

      totals[date] = totals[date]! + t.amount;
    }

    setState(() => _dailyTotals = totals);
  }

  @override
  void initState() {
    super.initState();
    _loadTransactions();

    // Show chart after route animation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _showChart = true);
        }
      });
    });
  }

  void _loadTransactions() {
    setState(() {
      _transactions = DatabaseHelper.getTransactionsForMonth(widget.monthId);
      _calculateDailyTotals();
    });
  }

  void _showOptionsMenu() {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final cardColor = theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = theme.isDarkMode ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.delete_sweep, color: theme.danger),
                title: Text(
                  'Clear All Transactions',
                  style: TextStyle(
                    color: theme.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Delete all transactions for this month',
                  style: TextStyle(
                    color:
                        theme.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmClearAllData();
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.file_download_outlined, color: Colors.grey[400]),
                title: Text(
                  'Export Data',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                subtitle: Text(
                  'Coming soon',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                enabled: false,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClearAllData() {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final cardColor = theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = theme.isDarkMode ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.danger, size: 28),
            const SizedBox(width: 12),
            Text('Clear All Data?', style: TextStyle(color: textColor)),
          ],
        ),
        content: Text(
          'This will permanently delete all ${_transactions.length} transaction${_transactions.length != 1 ? 's' : ''} for this month. This action cannot be undone.',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData();
            },
            child: Text(
              'Delete All',
              style: TextStyle(
                color: theme.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      // Get all transactions for this month
      final transactions =
          DatabaseHelper.getTransactionsForMonth(widget.monthId);

      // Delete each transaction (this also handles file attachments)
      for (var transaction in transactions) {
        DatabaseHelper.deleteTransaction(transaction.id);
      }

      // Recalculate month to update totals
      DatabaseHelper.recalculateMonth(widget.monthId);

      // Refresh widget
      await WidgetService.refreshWidget();

      if (mounted) {
        // Reload transactions
        _loadTransactions();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All transactions deleted for this month'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete transactions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final textColor = theme.isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor =
        theme.isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(
          'Transaction History',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: textColor),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: _transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Wrap chart in AnimatedOpacity
                AnimatedOpacity(
                  opacity: _showChart ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: DailyExpenseChart(data: _dailyTotals),
                ),

                const SizedBox(height: 32),

                // Sub-header with toggle button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All Transactions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_transactions.length} transaction${_transactions.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 13,
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isCompactView = !_isCompactView;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _isCompactView
                                  ? theme.primary.withOpacity(0.15)
                                  : (theme.isDarkMode
                                      ? Colors.grey[800]!.withOpacity(0.5)
                                      : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isCompactView
                                    ? theme.primary.withOpacity(0.3)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isCompactView
                                      ? Icons.view_agenda_outlined
                                      : Icons.view_compact_alt_outlined,
                                  size: 18,
                                  color: _isCompactView
                                      ? theme.primary
                                      : subtitleColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isCompactView ? 'Compact' : 'Default',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _isCompactView
                                        ? theme.primary
                                        : subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // List of transactions
                ..._transactions.map((transaction) {
                  return TransactionTile(
                    transaction: transaction,
                    isCompact: _isCompactView,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddTransactionPage(
                              existingTransaction: transaction),
                        ),
                      ).then((_) => _loadTransactions());
                    },
                  );
                }),
              ],
            ),
    );
  }
}
