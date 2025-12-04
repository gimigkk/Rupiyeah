import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'storage/database_helper.dart';
import 'services/widget_service.dart';
import 'pages/home_page.dart';
import 'pages/add_transaction_page.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive database
  await DatabaseHelper.init();

  // Setup widget interactivity
  await WidgetService.setupInteractivity();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const BudgetApp(),
    ),
  );
}

class BudgetApp extends StatefulWidget {
  const BudgetApp({Key? key}) : super(key: key);

  @override
  State<BudgetApp> createState() => _BudgetAppState();
}

class _BudgetAppState extends State<BudgetApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<HomePageState> homePageKey = GlobalKey<HomePageState>();
  static const platform =
      MethodChannel('com.example.personal_budgeting_app/widget');

  bool _isPickingFile = false;
  bool _isPendingWidgetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupWidgetDeepLink();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Don't close modals if picking file - file picker needs the modal to stay open
      if (_isPickingFile) {
        return;
      }

      // Close modals only for widget-triggered opens
      if (_isPendingWidgetOpen) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      // Reset file picking state
      _isPickingFile = false;

      // If we have a pending widget open request, handle it now
      if (_isPendingWidgetOpen) {
        _isPendingWidgetOpen = false;

        final context = navigatorKey.currentContext;
        if (context != null && mounted) {
          // Ensure everything is closed
          Navigator.of(context).popUntil((route) => route.isFirst);

          // Small delay to ensure app is fully resumed
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted && navigatorKey.currentContext != null) {
              _showAddTransactionModal(navigatorKey.currentContext!);
            }
          });
        }
      }
    }
  }

  void _setupWidgetDeepLink() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'openAddTransaction') {
        final context = navigatorKey.currentContext;

        if (context != null && mounted) {
          final appState = WidgetsBinding.instance.lifecycleState;

          // Check if we're in the foreground
          if (appState == AppLifecycleState.resumed) {
            // App is already in foreground - close any modals
            Navigator.of(context).popUntil((route) => route.isFirst);

            // Brief delay for smooth transition
            await Future.delayed(const Duration(milliseconds: 150));

            if (mounted && navigatorKey.currentContext != null) {
              _showAddTransactionModal(navigatorKey.currentContext!);
            }
          } else {
            // App is in background - mark as pending
            _isPendingWidgetOpen = true;
          }
        }
      }
    });
  }

  void _showAddTransactionModal(BuildContext context) {
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
            _isPendingWidgetOpen = false;
            homePageKey.currentState?.loadData();
          },
          onFilePicking: (bool isPicking) {
            _isPickingFile = isPicking;
          },
        ),
      ),
    ).then((_) {
      _isPendingWidgetOpen = false;
      _isPickingFile = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Budget App',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme
              .toThemeData(isDarkMode: themeProvider.isDarkMode),
          home: HomePage(key: homePageKey),
        );
      },
    );
  }
}
