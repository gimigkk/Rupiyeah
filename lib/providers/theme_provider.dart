// Create: lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import '../storage/database_helper.dart';
import 'package:flutter/services.dart';

class AppTheme {
  final String id;
  final String name;
  final Color primary;
  final Color secondary;
  final Color success;
  final Color danger;
  final Color warning;
  final Color background;

  const AppTheme({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.success,
    required this.danger,
    required this.warning,
    required this.background,
  });

  ThemeData toThemeData({required bool isDarkMode}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: background,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor:
          isDarkMode ? const Color(0xFF121212) : background,
      cardTheme: CardTheme(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : background,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDarkMode ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return null;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  static final Map<String, AppTheme> _themes = {
    'purple': const AppTheme(
      id: 'purple',
      name: 'Purple Dream',
      primary: Color(0xFF6C63FF),
      secondary: Color(0xFF5A52E0),
      success: Color(0xFF4CAF50),
      danger: Color(0xFFFF5252),
      warning: Color(0xFFFF9066),
      background: Color(0xFFF5F7FA),
    ),
    'ocean': const AppTheme(
      id: 'ocean',
      name: 'Ocean Blue',
      primary: Color(0xFF0891B2),
      secondary: Color(0xFF0E7490),
      success: Color(0xFF10B981),
      danger: Color(0xFFEF4444),
      warning: Color(0xFFF59E0B),
      background: Color(0xFFF0F9FF),
    ),
    'sunset': const AppTheme(
      id: 'sunset',
      name: 'Sunset Orange',
      primary: Color(0xFFEA580C),
      secondary: Color(0xFFC2410C),
      success: Color(0xFF22C55E),
      danger: Color(0xFFDC2626),
      warning: Color(0xFFFBBF24),
      background: Color(0xFFFFF7ED),
    ),
    'forest': const AppTheme(
      id: 'forest',
      name: 'Forest Green',
      primary: Color(0xFF059669),
      secondary: Color(0xFF047857),
      success: Color(0xFF10B981),
      danger: Color(0xFFF87171),
      warning: Color(0xFFFBBF24),
      background: Color(0xFFF0FDF4),
    ),
    'rose': const AppTheme(
      id: 'rose',
      name: 'Rose Pink',
      primary: Color(0xFFE11D48),
      secondary: Color(0xFFBE123C),
      success: Color(0xFF10B981),
      danger: Color(0xFFDC2626),
      warning: Color(0xFFF59E0B),
      background: Color(0xFFFFF1F2),
    ),
    'midnight': const AppTheme(
      id: 'midnight',
      name: 'Midnight Blue',
      primary: Color(0xFF1E3A8A),
      secondary: Color(0xFF1E40AF),
      success: Color(0xFF22C55E),
      danger: Color(0xFFEF4444),
      warning: Color(0xFFF59E0B),
      background: Color(0xFFEFF6FF),
    ),
  };

  AppTheme _currentTheme;
  bool _isDarkMode = false;

  ThemeProvider() : _currentTheme = _themes['purple']! {
    _loadTheme();
  }

  AppTheme get currentTheme => _currentTheme;
  bool get isDarkMode => _isDarkMode;
  List<AppTheme> get availableThemes => _themes.values.toList();

  void _loadTheme() {
    final themeId = DatabaseHelper.getThemeId();
    _currentTheme = _themes[themeId] ?? _themes['purple']!;
    _isDarkMode = DatabaseHelper.getDarkMode();
    notifyListeners();
  }

  void setTheme(String themeId) {
    final theme = _themes[themeId];
    if (theme != null) {
      _currentTheme = theme;
      DatabaseHelper.saveThemeId(themeId);
      notifyListeners();
    }
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    DatabaseHelper.saveDarkMode(_isDarkMode);
    notifyListeners();
  }

  // Helper methods to access colors easily
  Color get primary => _currentTheme.primary;
  Color get secondary => _currentTheme.secondary;
  Color get success => _currentTheme.success;
  Color get danger => _currentTheme.danger;
  Color get warning => _currentTheme.warning;
  Color get background =>
      _isDarkMode ? const Color(0xFF121212) : _currentTheme.background;
}

// Extension to easily access theme colors from context
extension ThemeContext on BuildContext {
  ThemeProvider get themeProvider => ThemeProvider();

  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get secondaryColor => Theme.of(this).colorScheme.secondary;
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;
}
