import 'package:flutter/material.dart';
import '../models/tag.dart';
import '../providers/theme_provider.dart';
import 'transaction_form_widgets.dart';

/// Generic Card Container Widget
class FormCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color cardColor;
  final Color textColor;
  final ThemeProvider theme;

  const FormCard({
    super.key,
    required this.title,
    required this.child,
    required this.cardColor,
    required this.textColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: theme.isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Transaction Details Card (Type + Category)
class TransactionDetailsCard extends StatelessWidget {
  final String type;
  final String? selectedTagId;
  final List<Tag> availableTags;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ThemeProvider theme;
  final Color cardColor;
  final Color textColor;
  final Color? fillColor;

  const TransactionDetailsCard({
    super.key,
    required this.type,
    required this.selectedTagId,
    required this.availableTags,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.theme,
    required this.cardColor,
    required this.textColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'Transaction Details',
      cardColor: cardColor,
      textColor: textColor,
      theme: theme,
      child: Column(
        children: [
          const SizedBox(height: 20),
          TransactionTypeDropdown(
            value: type,
            onChanged: onTypeChanged,
            theme: theme,
            fillColor: fillColor,
            textColor: textColor,
          ),
          const SizedBox(height: 16),
          CategoryDropdown(
            value: selectedTagId,
            tags: availableTags,
            onChanged: onCategoryChanged,
            theme: theme,
            fillColor: fillColor,
            textColor: textColor,
          ),
        ],
      ),
    );
  }
}

/// Amount Card
class AmountCard extends StatelessWidget {
  final TextEditingController controller;
  final String currencySymbol;
  final ThemeProvider theme;
  final Color cardColor;
  final Color textColor;

  const AmountCard({
    super.key,
    required this.controller,
    required this.currencySymbol,
    required this.theme,
    required this.cardColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'Amount',
      cardColor: cardColor,
      textColor: textColor,
      theme: theme,
      child: Column(
        children: [
          const SizedBox(height: 16),
          AmountInputField(
            controller: controller,
            currencySymbol: currencySymbol,
            theme: theme,
            textColor: textColor,
          ),
        ],
      ),
    );
  }
}

/// Payment Method Card
class PaymentMethodCard extends StatelessWidget {
  final String type;
  final String paymentMethod;
  final ValueChanged<String> onMethodChanged;
  final ThemeProvider theme;
  final Color cardColor;
  final Color textColor;
  final Color? fillColor;

  const PaymentMethodCard({
    super.key,
    required this.type,
    required this.paymentMethod,
    required this.onMethodChanged,
    required this.theme,
    required this.cardColor,
    required this.textColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: type == 'income' ? 'Receive As' : 'Payment Method',
      cardColor: cardColor,
      textColor: textColor,
      theme: theme,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PaymentMethodButton(
                  label: type == 'income' ? 'Bank Deposit' : 'Bank',
                  icon: Icons.account_balance_outlined,
                  method: 'bank',
                  selectedMethod: paymentMethod,
                  onTap: onMethodChanged,
                  theme: theme,
                  fillColor: fillColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PaymentMethodButton(
                  label: type == 'income' ? 'Cash Received' : 'Cash',
                  icon: Icons.wallet,
                  method: 'cash',
                  selectedMethod: paymentMethod,
                  onTap: onMethodChanged,
                  theme: theme,
                  fillColor: fillColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Details Card (Date, Attachment, Description)
class DetailsCard extends StatelessWidget {
  final DateTime selectedDate;
  final String? attachmentPath;
  final TextEditingController descriptionController;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onPickAttachment;
  final VoidCallback onViewAttachment;
  final VoidCallback onRemoveAttachment;
  final ThemeProvider theme;
  final Color cardColor;
  final Color textColor;
  final Color? fillColor;
  final Color? subtitleColor;

  const DetailsCard({
    super.key,
    required this.selectedDate,
    required this.attachmentPath,
    required this.descriptionController,
    required this.onDateChanged,
    required this.onPickAttachment,
    required this.onViewAttachment,
    required this.onRemoveAttachment,
    required this.theme,
    required this.cardColor,
    required this.textColor,
    required this.fillColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'Details',
      cardColor: cardColor,
      textColor: textColor,
      theme: theme,
      child: Column(
        children: [
          const SizedBox(height: 12),
          DatePickerField(
            selectedDate: selectedDate,
            onDateSelected: onDateChanged,
            theme: theme,
            fillColor: fillColor,
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),
          const SizedBox(height: 12),
          if (attachmentPath == null)
            AttachmentPlaceholder(
              onTap: onPickAttachment,
              theme: theme,
              fillColor: fillColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            )
          else
            AttachmentPreview(
              attachmentPath: attachmentPath!,
              onView: onViewAttachment,
              onRemove: onRemoveAttachment,
              theme: theme,
              fillColor: fillColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
          const SizedBox(height: 12),
          DescriptionField(
            controller: descriptionController,
            theme: theme,
            fillColor: fillColor,
            textColor: textColor,
          ),
        ],
      ),
    );
  }
}
