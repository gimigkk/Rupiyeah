import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/tag.dart';
import '../providers/theme_provider.dart';
import '../storage/file_helper.dart';
import '../utils/currency_input_formatter.dart';

/// Transaction Type Dropdown Widget
class TransactionTypeDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final ThemeProvider theme;
  final Color? fillColor;
  final Color textColor;

  const TransactionTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    required this.theme,
    required this.fillColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: theme.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: "Type",
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: const [
        DropdownMenuItem(value: "income", child: Text("Income")),
        DropdownMenuItem(value: "expense", child: Text("Expense")),
        DropdownMenuItem(value: "withdrawal", child: Text("Withdrawal")),
      ],
      onChanged: onChanged,
    );
  }
}

/// Category Dropdown Widget
class CategoryDropdown extends StatelessWidget {
  final String? value;
  final List<Tag> tags;
  final ValueChanged<String?> onChanged;
  final ThemeProvider theme;
  final Color? fillColor;
  final Color textColor;

  const CategoryDropdown({
    super.key,
    required this.value,
    required this.tags,
    required this.onChanged,
    required this.theme,
    required this.fillColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: theme.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: "Category",
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: tags.map((tag) {
        return DropdownMenuItem(
          value: tag.id,
          child: Row(
            children: [
              Icon(tag.getIconData(), color: Color(tag.color), size: 18),
              const SizedBox(width: 10),
              Text(tag.name),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

/// Amount Input Field Widget
class AmountInputField extends StatelessWidget {
  final TextEditingController controller;
  final String currencySymbol;
  final ThemeProvider theme;
  final Color textColor;

  const AmountInputField({
    super.key,
    required this.controller,
    required this.currencySymbol,
    required this.theme,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      decoration: InputDecoration(
        prefixText: '$currencySymbol ',
        prefixStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: theme.primary,
        ),
        hintText: '0',
        hintStyle: TextStyle(
          fontSize: 24,
          color: theme.isDarkMode ? Colors.grey[700] : Colors.grey[300],
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        CurrencyInputFormatter(),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }

        final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

        if (digitsOnly.isEmpty || int.tryParse(digitsOnly) == null) {
          return 'Please enter a valid number';
        }

        if (int.parse(digitsOnly) <= 0) {
          return 'Amount must be greater than 0';
        }

        return null;
      },
    );
  }
}

/// Payment Method Button Widget
class PaymentMethodButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String method;
  final String selectedMethod;
  final ValueChanged<String> onTap;
  final ThemeProvider theme;
  final Color? fillColor;

  const PaymentMethodButton({
    super.key,
    required this.label,
    required this.icon,
    required this.method,
    required this.selectedMethod,
    required this.onTap,
    required this.theme,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedMethod == method;

    return InkWell(
      onTap: () => onTap(method),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary.withOpacity(0.1) : fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? theme.primary : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? theme.primary : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Date Picker Widget
class DatePickerField extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final ThemeProvider theme;
  final Color? fillColor;
  final Color textColor;
  final Color? subtitleColor;

  const DatePickerField({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.theme,
    required this.fillColor,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: theme.primary,
                  onPrimary: Colors.white,
                  onSurface: theme.isDarkMode ? Colors.white : Colors.black,
                  surface:
                      theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                ),
                dialogBackgroundColor:
                    theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today,
                color: theme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM dd, yyyy').format(selectedDate),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 20, color: subtitleColor),
          ],
        ),
      ),
    );
  }
}

/// Attachment Placeholder Widget
class AttachmentPlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  final ThemeProvider theme;
  final Color? fillColor;
  final Color textColor;
  final Color? subtitleColor;

  const AttachmentPlaceholder({
    super.key,
    required this.onTap,
    required this.theme,
    required this.fillColor,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.attach_file,
                color: theme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attachment',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'None',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 20, color: subtitleColor),
          ],
        ),
      ),
    );
  }
}

/// Attachment Preview Widget
class AttachmentPreview extends StatelessWidget {
  final String attachmentPath;
  final VoidCallback onView;
  final VoidCallback onRemove;
  final ThemeProvider theme;
  final Color? fillColor;
  final Color textColor;
  final Color? subtitleColor;

  const AttachmentPreview({
    super.key,
    required this.attachmentPath,
    required this.onView,
    required this.onRemove,
    required this.theme,
    required this.fillColor,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = FileHelper.getFileName(attachmentPath);
    final isImage = FileHelper.isImage(attachmentPath);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (isImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(attachmentPath),
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isImage ? Icons.image : Icons.description,
                  color: theme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    FutureBuilder<String>(
                      future: FileHelper.getFileSize(attachmentPath),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'Loading...',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.visibility, color: theme.primary),
                onPressed: onView,
                tooltip: 'View',
              ),
              IconButton(
                icon: Icon(Icons.close, color: theme.danger),
                onPressed: onRemove,
                tooltip: 'Remove',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Description Field Widget
class DescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final ThemeProvider theme;
  final Color? fillColor;
  final Color textColor;

  const DescriptionField({
    super.key,
    required this.controller,
    required this.theme,
    required this.fillColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: 'Add description (optional)',
        hintStyle: TextStyle(
          color: theme.isDarkMode ? Colors.grey[700] : Colors.grey[400],
        ),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      maxLines: 3,
    );
  }
}
