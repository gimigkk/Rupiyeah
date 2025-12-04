// Save this as: lib/widgets/month_selector.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/month_data.dart';
import '../providers/theme_provider.dart';

class MonthPickerDialog extends StatefulWidget {
  final List<MonthData> availableMonths;
  final String selectedMonthId;

  const MonthPickerDialog({
    Key? key,
    required this.availableMonths,
    required this.selectedMonthId,
  }) : super(key: key);

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late int _currentYear;
  int _yearChangeDirection = 0;

  final _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  @override
  void initState() {
    super.initState();
    // Start with the selected month's year or current year
    if (widget.selectedMonthId.isNotEmpty) {
      _currentYear = int.parse(widget.selectedMonthId.split('-')[0]);
    } else {
      _currentYear = DateTime.now().year;
    }
  }

  Set<int> _getMonthsWithData() {
    return widget.availableMonths
        .where((m) => m.id.startsWith('$_currentYear-'))
        .map((m) => int.parse(m.id.split('-')[1]))
        .toSet();
  }

  bool _isSelectedMonth(int month) {
    final monthId = '$_currentYear-${month.toString().padLeft(2, '0')}';
    return monthId == widget.selectedMonthId;
  }

  void _changeYear(int delta) {
    setState(() {
      _yearChangeDirection = delta;
      _currentYear += delta;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final monthsWithData = _getMonthsWithData();

    // Dark mode colors
    final dialogBg = theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = theme.isDarkMode ? Colors.white : Colors.black87;
    final borderColor =
        theme.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final disabledTextColor =
        theme.isDarkMode ? Colors.grey[600] : Colors.grey[600];

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Year selector with direction-aware animation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: theme.primary),
                  onPressed: () => _changeYear(-1),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final offsetAnimation = Tween<Offset>(
                      begin: Offset(_yearChangeDirection > 0 ? 0.3 : -0.3, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ));

                    return SlideTransition(
                      position: offsetAnimation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  child: Text(
                    '$_currentYear',
                    key: ValueKey<int>(_currentYear),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: theme.primary),
                  onPressed: () => _changeYear(1),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Month grid with direction-aware animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: Offset(_yearChangeDirection > 0 ? 0.2 : -0.2, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ));

                return SlideTransition(
                  position: offsetAnimation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: GridView.builder(
                key: ValueKey<int>(_currentYear),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final hasData = monthsWithData.contains(month);
                  final isSelected = _isSelectedMonth(month);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final monthId =
                            '$_currentYear-${month.toString().padLeft(2, '0')}';
                        Navigator.pop(context, monthId);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? theme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasData
                                ? (isSelected
                                    ? theme.primary
                                    : theme.primary.withOpacity(0.5))
                                : borderColor,
                            width: isSelected ? 2 : (hasData ? 2 : 1),
                          ),
                        ),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected || hasData
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : (hasData
                                      ? theme.primary
                                      : disabledTextColor),
                            ),
                            child: Text(_monthNames[index]),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                    'Has Data', theme.primary.withOpacity(0.5), true,
                    textColor: textColor),
                const SizedBox(width: 16),
                _buildLegendItem('Selected', theme.primary, false,
                    filled: true, textColor: textColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool bordered,
      {bool filled = false, required Color textColor}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            border: bordered ? Border.all(color: color, width: 2) : null,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textColor.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
