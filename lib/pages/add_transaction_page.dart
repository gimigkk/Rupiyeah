import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../storage/database_helper.dart';
import '../models/transaction.dart';
import '../models/tag.dart';
import '../models/month_data.dart';
import '../providers/theme_provider.dart';
import '../services/widget_service.dart';
import '../storage/file_helper.dart';
import '../widgets/transaction_form_cards.dart';
import 'package:vibration/vibration.dart';
//import '../utils/currency_input_formatter.dart';

class AddTransactionPage extends StatefulWidget {
  final Transaction? existingTransaction;
  final String? monthId;
  final VoidCallback? onSaved;
  final Function(bool isPicking)? onFilePicking;

  const AddTransactionPage({
    super.key,
    this.existingTransaction,
    this.monthId,
    this.onSaved,
    this.onFilePicking,
  });

  @override
  AddTransactionPageState createState() => AddTransactionPageState();
}

class AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'expense';
  String _paymentMethod = 'bank';
  String? _selectedTagId;
  DateTime _selectedDate = DateTime.now();
  List<Tag> _availableTags = [];
  bool _isReady = false;
  String? _attachmentPath;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Initialize form with existing transaction data or defaults
  void _initializeForm() {
    if (widget.existingTransaction != null) {
      final transaction = widget.existingTransaction!;

      // Format amount with thousand separators
      final formatter = NumberFormat('#,###', 'id_ID');
      _amountController.text = formatter.format(transaction.amount.toInt());

      _descriptionController.text = transaction.description;
      _type = transaction.type;
      _paymentMethod = transaction.paymentMethod ?? 'bank';
      _selectedTagId = transaction.tagId;
      _selectedDate = transaction.date;
      _attachmentPath = transaction.attachmentPath;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTags();
      setState(() => _isReady = true);
    });
  }

  /// Load available tags based on transaction type
  void _loadTags() {
    setState(() {
      _availableTags = DatabaseHelper.getTagsByType(_type);

      if (_availableTags.isNotEmpty) {
        final isValidSelection =
            _availableTags.any((tag) => tag.id == _selectedTagId);
        if (!isValidSelection) {
          _selectedTagId = _availableTags.first.id;
        }
      } else {
        _selectedTagId = null;
      }
    });
  }

  String get currencySymbol => DatabaseHelper.getCurrencySymbol();

  /// Pick attachment file (image or document)
  Future<void> _pickAttachment() async {
    widget.onFilePicking?.call(true);

    try {
      final path = await FileHelper.pickFile();

      if (mounted && path != null) {
        setState(() {
          _attachmentPath = path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    } finally {
      widget.onFilePicking?.call(false);
    }
  }

  /// Remove attachment from transaction
  void _removeAttachment() {
    setState(() {
      _attachmentPath = null;
    });
  }

  /// View/Open attachment file
  Future<void> _viewAttachment() async {
    if (_attachmentPath != null) {
      try {
        await FileHelper.openFile(_attachmentPath!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open file: $e')),
          );
        }
      }
    }
  }

  /// Save or update transaction
  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTagId == null || _availableTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    try {
      // Parse amount by removing all non-digit characters
      final amountText =
          _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
      final amount = double.parse(amountText);

      final transaction = Transaction(
        id: widget.existingTransaction?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        tagId: _selectedTagId!,
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        type: _type,
        paymentMethod: _type == 'withdrawal' ? null : _paymentMethod,
        attachmentPath: _attachmentPath,
      );

      if (widget.existingTransaction != null) {
        await _updateExistingTransaction(transaction);
      } else {
        await _addNewTransaction(transaction);
      }

      // Add vibration here - short 50ms pulse
      Vibration.vibrate(duration: 50);

      // Refresh widget
      await WidgetService.refreshWidget();

      // Navigate back or call callback
      if (mounted) {
        if (widget.onSaved != null) {
          widget.onSaved!();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save transaction: $e')),
        );
      }
    }
  }

  /// Update existing transaction
  Future<void> _updateExistingTransaction(Transaction transaction) async {
    // Delete old attachment if it was changed
    if (widget.existingTransaction!.attachmentPath != null &&
        _attachmentPath != widget.existingTransaction!.attachmentPath) {
      await FileHelper.deleteFile(widget.existingTransaction!.attachmentPath);
    }

    DatabaseHelper.updateTransaction(
      widget.existingTransaction!,
      transaction,
    );

    // Recalculate the month page being viewed
    if (widget.monthId != null) {
      DatabaseHelper.recalculateMonth(widget.monthId!);
      await Hive.box<MonthData>(DatabaseHelper.monthBoxName).flush();
    }

    // Also recalculate the actual months affected by the transaction
    final oldMonthId =
        '${widget.existingTransaction!.date.year}-${widget.existingTransaction!.date.month.toString().padLeft(2, '0')}';
    final newMonthId =
        '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';

    DatabaseHelper.recalculateMonth(oldMonthId);
    if (oldMonthId != newMonthId) {
      DatabaseHelper.recalculateMonth(newMonthId);
    }
    await Hive.box<MonthData>(DatabaseHelper.monthBoxName).flush();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction updated successfully')),
      );
    }
  }

  /// Add new transaction
  Future<void> _addNewTransaction(Transaction transaction) async {
    DatabaseHelper.addTransaction(transaction, monthId: widget.monthId);

    // Recalculate the month where transaction was added
    final targetMonthId = widget.monthId ??
        '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';

    DatabaseHelper.recalculateMonth(targetMonthId);
    await Hive.box<MonthData>(DatabaseHelper.monthBoxName).flush();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction added successfully')),
      );
    }
  }

  /// Delete transaction with confirmation
  Future<void> _deleteTransaction() async {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final cardColor = theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = theme.isDarkMode ? Colors.white : Colors.black87;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Transaction', style: TextStyle(color: textColor)),
        content: Text(
          'Are you sure you want to delete this transaction?',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: theme.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Delete attachment file if exists
        if (widget.existingTransaction!.attachmentPath != null) {
          await FileHelper.deleteFile(
              widget.existingTransaction!.attachmentPath);
        }

        // Recalculate the month before deleting
        final monthId =
            '${widget.existingTransaction!.date.year}-${widget.existingTransaction!.date.month.toString().padLeft(2, '0')}';

        DatabaseHelper.deleteTransaction(widget.existingTransaction!.id);

        // Recalculate after deletion
        DatabaseHelper.recalculateMonth(monthId);
        await Hive.box<MonthData>(DatabaseHelper.monthBoxName).flush();

        await WidgetService.refreshWidget();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted')),
          );

          if (widget.onSaved != null) {
            widget.onSaved!();
          } else {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete transaction: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final cardColor = theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = theme.isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor =
        theme.isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final fillColor =
        theme.isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[50];

    return Scaffold(
      backgroundColor: theme.background,
      appBar: _buildAppBar(theme, textColor),
      body: !_isReady
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        TransactionDetailsCard(
                          type: _type,
                          selectedTagId: _selectedTagId,
                          availableTags: _availableTags,
                          onTypeChanged: (value) {
                            setState(() {
                              _type = value!;
                              _loadTags();
                            });
                          },
                          onCategoryChanged: (value) {
                            setState(() => _selectedTagId = value);
                          },
                          theme: theme,
                          cardColor: cardColor,
                          textColor: textColor,
                          fillColor: fillColor,
                        ),
                        const SizedBox(height: 16),
                        AmountCard(
                          controller: _amountController,
                          currencySymbol: currencySymbol,
                          theme: theme,
                          cardColor: cardColor,
                          textColor: textColor,
                        ),
                        const SizedBox(height: 16),
                        if (_type == 'expense' || _type == 'income')
                          PaymentMethodCard(
                            type: _type,
                            paymentMethod: _paymentMethod,
                            onMethodChanged: (method) {
                              setState(() => _paymentMethod = method);
                            },
                            theme: theme,
                            cardColor: cardColor,
                            textColor: textColor,
                            fillColor: fillColor,
                          ),
                        if (_type == 'expense' || _type == 'income')
                          const SizedBox(height: 16),
                        DetailsCard(
                          selectedDate: _selectedDate,
                          attachmentPath: _attachmentPath,
                          descriptionController: _descriptionController,
                          onDateChanged: (date) {
                            setState(() => _selectedDate = date);
                          },
                          onPickAttachment: _pickAttachment,
                          onViewAttachment: _viewAttachment,
                          onRemoveAttachment: _removeAttachment,
                          theme: theme,
                          cardColor: cardColor,
                          textColor: textColor,
                          fillColor: fillColor,
                          subtitleColor: subtitleColor,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _buildSaveButton(theme),
              ],
            ),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar(ThemeProvider theme, Color textColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.existingTransaction == null
            ? 'Add Transaction'
            : 'Edit Transaction',
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (widget.existingTransaction != null)
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.danger),
            onPressed: _deleteTransaction,
          ),
      ],
    );
  }

  /// Build save/update button at bottom
  Widget _buildSaveButton(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              widget.existingTransaction == null
                  ? 'Save Transaction'
                  : 'Update Transaction',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
