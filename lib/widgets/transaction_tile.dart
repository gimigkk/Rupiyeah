import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../storage/database_helper.dart';
import '../providers/theme_provider.dart';
import '../utils/format_currency.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final bool isCompact;

  const TransactionTile({
    Key? key,
    required this.transaction,
    this.onTap,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final tag = DatabaseHelper.getTag(transaction.tagId);
    final cardColor = theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = theme.isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor =
        theme.isDarkMode ? Colors.grey[400] : Colors.grey[600];

    Color typeColor;
    String prefix;

    switch (transaction.type) {
      case 'income':
      case 'surplus':
        typeColor = theme.success;
        prefix = '+';
        break;
      case 'expense':
        typeColor = theme.danger;
        prefix = '-';
        break;
      case 'withdrawal':
        typeColor = theme.primary;
        prefix = '';
        break;
      default:
        typeColor = Colors.grey;
        prefix = '';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(bottom: isCompact ? 6 : 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        border: Border.all(
          color: theme.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: theme.isDarkMode || isCompact
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: isCompact
              ? _buildCompactView(
                  theme,
                  tag,
                  typeColor,
                  prefix,
                  textColor,
                  subtitleColor,
                )
              : _buildExpandedView(
                  theme,
                  tag,
                  typeColor,
                  prefix,
                  textColor,
                  subtitleColor,
                ),
        ),
      ),
    );
  }

  Widget _buildExpandedView(
    ThemeProvider theme,
    tag,
    Color typeColor,
    String prefix,
    Color textColor,
    Color? subtitleColor,
  ) {
    return Row(
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            tag?.getIconData() ?? Icons.circle,
            color: typeColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),

        // Transaction details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    tag?.name ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (transaction.attachmentPath != null) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.attach_file,
                      size: 14,
                      color: theme.primary,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: subtitleColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(transaction.date),
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitleColor,
                    ),
                  ),
                  if (transaction.paymentMethod != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            transaction.paymentMethod == 'bank'
                                ? Icons.account_balance
                                : Icons.wallet,
                            size: 10,
                            color: subtitleColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            transaction.paymentMethod == 'bank'
                                ? 'Bank'
                                : 'Cash',
                            style: TextStyle(
                              fontSize: 10,
                              color: subtitleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (transaction.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // Amount
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$prefix${formatCurrency(transaction.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: typeColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactView(
    ThemeProvider theme,
    tag,
    Color typeColor,
    String prefix,
    Color textColor,
    Color? subtitleColor,
  ) {
    return Row(
      children: [
        // Smaller icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            tag?.getIconData() ?? Icons.circle,
            color: typeColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),

        // Transaction details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    tag?.name ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (transaction.attachmentPath != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.attach_file,
                      size: 12,
                      color: theme.primary,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    DateFormat('MMM dd').format(transaction.date),
                    style: TextStyle(
                      fontSize: 11,
                      color: subtitleColor,
                    ),
                  ),
                  if (transaction.paymentMethod != null) ...[
                    const SizedBox(width: 6),
                    Icon(
                      transaction.paymentMethod == 'bank'
                          ? Icons.account_balance
                          : Icons.wallet,
                      size: 10,
                      color: subtitleColor,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Amount
        Text(
          '$prefix${formatCurrency(transaction.amount)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: typeColor,
          ),
        ),
      ],
    );
  }
}
