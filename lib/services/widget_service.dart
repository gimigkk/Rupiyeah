// FILE: widget_service.dart
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/database_helper.dart';
import '../utils/format_currency.dart';

/// Service for managing home screen widget updates and interactions
class WidgetService {
  static const MethodChannel _platform =
      MethodChannel('com.example.personal_budgeting_app/widget');

  /// Callback function to open add transaction modal
  static Function()? onAddTransactionRequested;

  /// Update widget with current financial data
  /// Optional parameters allow forcing specific theme values without reading from database
  Future<void> updateWidget({String? forceThemeId, bool? forceDarkMode}) async {
    try {
      print('🔄 Widget Update Started');
      final prefs = await SharedPreferences.getInstance();

      // Get current month data
      final currentMonth = DatabaseHelper.getCurrentMonth();

      // Get all transactions for this month
      final allTransactions =
          DatabaseHelper.getTransactionsForMonth(currentMonth.id);

      // Filter today's transactions
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final todayTransactions = allTransactions.where((t) {
        return t.date.isAtSameMomentAs(startOfDay) ||
            t.date.isAfter(startOfDay);
      }).toList();

      // Calculate spent today
      final spentToday = todayTransactions
          .where((t) => t.type == 'expense')
          .fold<double>(0, (sum, t) => sum + t.amount);

      // Calculate daily budget
      final dailyBudget = currentMonth.isAutoDailyBudget
          ? _calculateAutoDailyBudget(currentMonth)
          : currentMonth.manualDailyBudget;

      final remainingBudget = dailyBudget - spentToday;

      // Calculate spending progress
      final progress = dailyBudget > 0
          ? ((spentToday / dailyBudget) * 100).clamp(0, 100).toInt()
          : 0;

      // Get theme settings - use forced values if provided, otherwise read from database
      final themeId = forceThemeId ?? DatabaseHelper.getThemeId();
      final isDarkMode = forceDarkMode ?? DatabaseHelper.getDarkMode();

      print('🎨 Theme Update: themeId=$themeId, isDarkMode=$isDarkMode');

      // Get theme colors
      final themeColors = _getThemeColors(themeId, isDarkMode);

      // Save theme info to SharedPreferences
      await prefs.setString('theme_id', themeId);
      await prefs.setBool('dark_mode', isDarkMode);

      // Save theme colors as integers
      await prefs.setInt('color_primary', themeColors['primary']!);
      await prefs.setInt('color_background', themeColors['background']!);
      await prefs.setInt('color_card', themeColors['card']!);
      await prefs.setInt('color_text_primary', themeColors['textPrimary']!);
      await prefs.setInt('color_text_secondary', themeColors['textSecondary']!);
      await prefs.setInt('color_danger', themeColors['danger']!);
      await prefs.setInt('color_warning', themeColors['warning']!);

      // Save budget data
      await prefs.setString(
          'remaining_budget', formatCurrency(remainingBudget));
      await prefs.setString('spent_today', formatCurrency(spentToday));
      await prefs.setString('progress', progress.toString());

      // Save recent transactions (max 3)
      final recent = todayTransactions.take(3).toList();

      for (int i = 0; i < 3; i++) {
        final slot = i + 1;

        if (i >= recent.length) {
          await prefs.setString('transaction${slot}_visible', 'false');
          continue;
        }

        final t = recent[i];
        final tag = DatabaseHelper.getTag(t.tagId);
        final name =
            tag?.name ?? (t.description.isNotEmpty ? t.description : 'Unknown');

        await prefs.setString('transaction${slot}_visible', 'true');
        await prefs.setString('transaction${slot}_name', name);
        await prefs.setString(
            'transaction${slot}_amount', formatCurrency(t.amount));
        await prefs.setString('transaction${slot}_type', t.type);
      }

      // CRITICAL: Ensure all data is committed to disk
      final commitSuccess = await prefs.commit();
      print('💾 SharedPreferences committed: $commitSuccess');

      // Add timestamp to force widget refresh
      await prefs.setInt('last_update', DateTime.now().millisecondsSinceEpoch);
      await prefs.commit();

      // Add small delay to ensure Android reads the updated preferences
      await Future.delayed(const Duration(milliseconds: 150));

      // Trigger widget update after data is committed
      await _triggerWidgetUpdate();
      print('✅ Widget Update Complete');
    } catch (e) {
      print('❌ Widget Update Error: $e');
      // Silently fail - widget updates are non-critical
      // In production, you might want to log to a crash reporting service
    }
  }

  /// Calculate automatic daily budget based on remaining days
  static double _calculateAutoDailyBudget(currentMonth) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = daysInMonth - now.day + 1;

    if (daysRemaining <= 0) return 0;

    return currentMonth.getRemainingCredit() / daysRemaining;
  }

  /// Get theme color values based on theme ID and dark mode setting
  static Map<String, int> _getThemeColors(String themeId, bool isDarkMode) {
    Map<String, int> colors;

    switch (themeId) {
      case 'purple':
        colors = {
          'primary': 0xFF6C63FF,
          'background': 0xFFF5F7FA,
          'card': 0xFFFFFFFF,
          'textPrimary': 0xFF212121,
          'textSecondary': 0xFF757575,
          'danger': 0xFFFF5252,
          'warning': 0xFFFF9066,
        };
        break;
      case 'ocean':
        colors = {
          'primary': 0xFF0891B2,
          'background': 0xFFF0F9FF,
          'card': 0xFFFFFFFF,
          'textPrimary': 0xFF212121,
          'textSecondary': 0xFF757575,
          'danger': 0xFFEF4444,
          'warning': 0xFFF59E0B,
        };
        break;
      case 'sunset':
        colors = {
          'primary': 0xFFEA580C,
          'background': 0xFFFFF7ED,
          'card': 0xFFFFFFFF,
          'textPrimary': 0xFF212121,
          'textSecondary': 0xFF757575,
          'danger': 0xFFDC2626,
          'warning': 0xFFFBBF24,
        };
        break;
      case 'forest':
        colors = {
          'primary': 0xFF059669,
          'background': 0xFFF0FDF4,
          'card': 0xFFFFFFFF,
          'textPrimary': 0xFF212121,
          'textSecondary': 0xFF757575,
          'danger': 0xFFF87171,
          'warning': 0xFFFBBF24,
        };
        break;
      case 'rose':
        colors = {
          'primary': 0xFFE11D48,
          'background': 0xFFFFF1F2,
          'card': 0xFFFFFFFF,
          'textPrimary': 0xFF212121,
          'textSecondary': 0xFF757575,
          'danger': 0xFFDC2626,
          'warning': 0xFFF59E0B,
        };
        break;
      case 'midnight':
        colors = {
          'primary': 0xFF1E3A8A,
          'background': 0xFFEFF6FF,
          'card': 0xFFFFFFFF,
          'textPrimary': 0xFF212121,
          'textSecondary': 0xFF757575,
          'danger': 0xFFEF4444,
          'warning': 0xFFF59E0B,
        };
        break;
      default:
        colors = {
          'primary': 0xFF6C63FF,
          'background': 0xFFF5F7FA,
          'card': 0xFFFFFFFF,
          'textPrimary': 0xFF212121,
          'textSecondary': 0xFF757575,
          'danger': 0xFFFF5252,
          'warning': 0xFFFF9066,
        };
    }

    // Apply dark mode overrides
    if (isDarkMode) {
      colors['background'] = 0xFF121212;
      colors['card'] = 0xFF1E1E1E;
      colors['textPrimary'] = 0xFFFFFFFF;
      colors['textSecondary'] = 0xFFB0B0B0;
    }

    return colors;
  }

  /// Trigger widget update via platform channel with fallback
  Future<void> _triggerWidgetUpdate() async {
    bool success = false;

    // Try platform channel first
    try {
      final result = await _platform.invokeMethod('updateWidget');
      print('📱 Platform channel update successful: $result');
      success = true;
    } catch (e) {
      print('⚠️ Platform channel failed: $e');
    }

    // If standard update fails, try force refresh
    if (!success) {
      try {
        final result = await _platform.invokeMethod('forceWidgetRefresh');
        print('📱 Force refresh successful: $result');
        success = true;
      } catch (e2) {
        print('⚠️ Force refresh failed: $e2');
      }
    }

    // Last resort: Try HomeWidget plugin
    if (!success) {
      try {
        await HomeWidget.updateWidget(
          name: 'BudgetWidgetProvider',
          androidName: 'BudgetWidgetProvider',
        );
        print('📱 HomeWidget plugin update successful');
      } catch (e3) {
        print('⚠️ All widget update methods failed');
      }
    }
  }

  /// Convenience method to refresh widget from anywhere in the app
  static Future<void> refreshWidget() => WidgetService().updateWidget();

  /// Setup interactivity for widget clicks
  static Future<void> setupInteractivity() async {
    // Set up method channel handler for widget clicks
    _platform.setMethodCallHandler((call) async {
      if (call.method == 'openAddTransaction') {
        // Call the callback if it's been set
        onAddTransactionRequested?.call();
      }
    });

    // Also listen to HomeWidget clicks as fallback
    HomeWidget.widgetClicked.listen((uri) {
      // Handle widget clicks if needed in the future
      // Currently using method channel as primary method
    });
  }
}
