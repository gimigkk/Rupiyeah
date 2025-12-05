import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../storage/database_helper.dart';
import '../models/month_data.dart';
import '../models/tag.dart';
import '../widgets/tag_dialog.dart';
import '../services/widget_service.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  MonthData? currentMonth;
  final _manualBudgetController = TextEditingController();
  List<Tag> _allTags = [];
  String _version = 'Loading...';
  bool _isAboutExpanded = false;
  bool _isThemeExpanded = false;
  bool _isIncomeTagsExpanded = false;
  bool _isExpenseTagsExpanded = false;
  bool _isWithdrawalTagsExpanded = false;

  String get currencySymbol => DatabaseHelper.getCurrencySymbol();

  @override
  void initState() {
    super.initState();
    // Defer loading to allow transition to start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
      _loadVersion();
    });
  }

  @override
  void dispose() {
    _manualBudgetController.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = 'v${packageInfo.version}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _version = 'v1.0.0';
        });
      }
    }
  }

  void _loadSettings() {
    if (mounted) {
      setState(() {
        currentMonth = DatabaseHelper.getCurrentMonth();
        _manualBudgetController.text =
            currentMonth!.manualDailyBudget.toStringAsFixed(0);
        _allTags = DatabaseHelper.getAllTags();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final cardColor = theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = theme.isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor =
        theme.isDarkMode ? Colors.grey[400] : Colors.grey[600];

    if (currentMonth == null) {
      return Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: Text('Settings', style: TextStyle(color: textColor)),
          backgroundColor: theme.background,
          foregroundColor: textColor,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: textColor)),
        backgroundColor: theme.background,
        foregroundColor: textColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Daily Budget Section
          Text(
            'Daily Budget Mode',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 0,
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color:
                      theme.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Automatic Daily Budget',
                        style: TextStyle(color: textColor)),
                    subtitle: Text(
                      currentMonth!.isAutoDailyBudget
                          ? 'Budget calculated based on remaining credit'
                          : 'Using manual fixed amount',
                      style: TextStyle(color: subtitleColor),
                    ),
                    value: currentMonth!.isAutoDailyBudget,
                    activeColor: theme.primary,
                    activeTrackColor: theme.primary.withOpacity(0.5),
                    inactiveThumbColor: Colors.grey[400],
                    inactiveTrackColor: Colors.grey[300],
                    onChanged: (value) {
                      setState(() {
                        currentMonth!.isAutoDailyBudget = value;
                      });
                      _saveBudgetSettings();
                    },
                  ),
                  if (!currentMonth!.isAutoDailyBudget) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _manualBudgetController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Manual Daily Budget',
                        labelStyle:
                            TextStyle(color: textColor.withOpacity(0.7)),
                        prefixText: '$currencySymbol ',
                        prefixStyle: TextStyle(
                          color: theme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.primary,
                            width: 2,
                          ),
                        ),
                        helperText: 'Fixed amount per day',
                        helperStyle: TextStyle(color: subtitleColor),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => _saveBudgetSettings(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Dark Mode Section
          Text(
            'Appearance',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 0,
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color:
                      theme.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Dark Mode', style: TextStyle(color: textColor)),
                subtitle: Text(
                  theme.isDarkMode ? 'Using dark theme' : 'Using light theme',
                  style: TextStyle(color: subtitleColor),
                ),
                value: theme.isDarkMode,
                activeColor: theme.primary,
                activeTrackColor: theme.primary.withOpacity(0.5),
                inactiveThumbColor: Colors.grey[400],
                inactiveTrackColor: Colors.grey[300],
                onChanged: (value) {
                  theme.toggleDarkMode();
                  // Pass the new dark mode value directly to avoid reading stale data
                  WidgetService().updateWidget(forceDarkMode: value);
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Theme Section
          Text(
            'Color Theme',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 16),

          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Card(
                elevation: 0,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: theme.isDarkMode
                          ? Colors.grey[800]!
                          : Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              themeProvider.currentTheme.primary,
                              themeProvider.currentTheme.secondary
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: themeProvider.currentTheme.primary
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      title: Text(themeProvider.currentTheme.name,
                          style: TextStyle(color: textColor)),
                      subtitle: Text('Current theme',
                          style: TextStyle(color: subtitleColor)),
                      trailing: IconButton(
                        icon: Icon(
                          _isThemeExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: theme.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _isThemeExpanded = !_isThemeExpanded;
                          });
                        },
                      ),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Column(
                        children: [
                          const Divider(height: 1),
                          ...themeProvider.availableThemes
                              .asMap()
                              .entries
                              .map((entry) {
                            final index = entry.key;
                            final themeItem = entry.value;
                            final isSelected =
                                themeItem.id == themeProvider.currentTheme.id;
                            final isLast = index ==
                                themeProvider.availableThemes.length - 1;

                            return Column(
                              children: [
                                InkWell(
                                  onTap: () async {
                                    // Capture provider reference before async gap
                                    final provider = themeProvider;
                                    final isDark = provider.isDarkMode;

                                    provider.setTheme(themeItem.id);
                                    // Pass the new theme ID directly to avoid reading stale data
                                    await WidgetService().updateWidget(
                                      forceThemeId: themeItem.id,
                                      forceDarkMode: isDark,
                                    );

                                    if (!mounted) return;

                                    // Use captured context-free values
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Theme changed to ${themeItem.name}'),
                                        duration: const Duration(seconds: 1),
                                        backgroundColor: themeItem.primary,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                themeItem.primary,
                                                themeItem.secondary
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: themeItem.primary
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                themeItem.name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  color: textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  _buildColorDot(
                                                      themeItem.success),
                                                  const SizedBox(width: 4),
                                                  _buildColorDot(
                                                      themeItem.danger),
                                                  const SizedBox(width: 4),
                                                  _buildColorDot(
                                                      themeItem.warning),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: themeItem.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  const Divider(
                                      height: 1, indent: 16, endIndent: 16),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                      crossFadeState: _isThemeExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Tags Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manage Tags',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _showAddTagDialog,
                style: IconButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ..._buildTagSections(theme),

          const SizedBox(height: 24),

          // About Section with Expandable Update Notes
          Card(
            elevation: 0,
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color:
                      theme.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: theme.primary),
                  title: Text('About', style: TextStyle(color: textColor)),
                  subtitle: Text('Budget App $_version',
                      style: TextStyle(color: subtitleColor)),
                  trailing: IconButton(
                    icon: Icon(
                      _isAboutExpanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isAboutExpanded = !_isAboutExpanded;
                      });
                    },
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Changes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Added CSV/Excel export with statistics\n'
                          '• Added haptic feedback when saving transactions\n'
                          '• Improved widget data responsiveness and accuracy\n'
                          '• Removed monthly surplus credit transfer feature\n'
                          '• Added clear data feature to delete all transactions\n'
                          '• Minor code refactoring for better modularity\n'
                          '• Added borders to homepage for design consistency\n'
                          '• Added homescreen number animations\n'
                          '• Project now on GitHub: github.com/gimigkk/Rupiyeah',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bug Fixes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Fixed graph colors displaying incorrectly\n'
                          '• Fixed black screen issue when deleting transactions\n'
                          '• Fixed ghost transaction data bug\n'
                          '• Fixed transactions disappearing when editing\n'
                          '• Fixed transactions now move to correct month\n'
                          '• Fixed Android status bar color in light theme\n'
                          '• Fixed homescreen widget theme synchronization\n'
                          '• Fixed homescreen data accuracy',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: _isAboutExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTagSections(ThemeProvider theme) {
    final incomeTagsList = _allTags.where((t) => t.type == 'income').toList();
    final expenseTagsList = _allTags.where((t) => t.type == 'expense').toList();
    final withdrawalTagsList =
        _allTags.where((t) => t.type == 'withdrawal').toList();

    return [
      _buildTagSection('Income Tags', incomeTagsList, theme.success, 'income'),
      const SizedBox(height: 16),
      _buildTagSection(
          'Expense Tags', expenseTagsList, theme.danger, 'expense'),
      const SizedBox(height: 16),
      _buildTagSection(
          'Withdrawal Tags', withdrawalTagsList, theme.primary, 'withdrawal'),
    ];
  }

  Widget _buildColorDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTagSection(
      String title, List<Tag> tags, Color color, String type) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final cardColor = theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = theme.isDarkMode ? Colors.white : Colors.black87;

    bool isExpanded = false;
    if (type == 'income') isExpanded = _isIncomeTagsExpanded;
    if (type == 'expense') isExpanded = _isExpenseTagsExpanded;
    if (type == 'withdrawal') isExpanded = _isWithdrawalTagsExpanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color:
                    theme.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.label_outline, color: color),
                title: Text('${tags.length} tags',
                    style: TextStyle(color: textColor)),
                trailing: IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: color,
                  ),
                  onPressed: () {
                    setState(() {
                      if (type == 'income')
                        _isIncomeTagsExpanded = !_isIncomeTagsExpanded;
                      if (type == 'expense')
                        _isExpenseTagsExpanded = !_isExpenseTagsExpanded;
                      if (type == 'withdrawal')
                        _isWithdrawalTagsExpanded = !_isWithdrawalTagsExpanded;
                    });
                  },
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const Divider(height: 1),
                    ...tags.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tag = entry.value;
                      final isOtherTag = tag.name.toLowerCase() == 'other';
                      final isLastItem = index == tags.length - 1;

                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: Icon(tag.getIconData(),
                                color: Color(tag.color)),
                            title: Text(tag.name,
                                style: TextStyle(color: textColor)),
                            trailing: isOtherTag
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'DEFAULT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            size: 18, color: Colors.grey[600]),
                                        onPressed: () =>
                                            _showEditTagDialog(tag),
                                        constraints: const BoxConstraints(
                                            minWidth: 40, minHeight: 40),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            size: 18, color: Colors.grey[600]),
                                        onPressed: () => _confirmDeleteTag(tag),
                                        constraints: const BoxConstraints(
                                            minWidth: 40, minHeight: 40),
                                      ),
                                    ],
                                  ),
                          ),
                          if (!isLastItem)
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _saveBudgetSettings() {
    final manualAmount = double.tryParse(_manualBudgetController.text) ?? 0;
    DatabaseHelper.updateDailyBudgetSettings(
      currentMonth!.isAutoDailyBudget,
      manualAmount,
    );
  }

  void _showAddTagDialog() async {
    final result = await showDialog<Tag>(
      context: context,
      builder: (context) => const TagDialog(),
    );

    if (result != null) {
      DatabaseHelper.addTag(result);
      _loadSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tag added successfully'),
          backgroundColor:
              Provider.of<ThemeProvider>(context, listen: false).success,
        ),
      );
    }
  }

  void _showEditTagDialog(Tag tag) async {
    final result = await showDialog<Tag>(
      context: context,
      builder: (context) => TagDialog(existingTag: tag),
    );

    if (result != null) {
      DatabaseHelper.updateTag(result);
      _loadSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tag updated successfully'),
          backgroundColor:
              Provider.of<ThemeProvider>(context, listen: false).primary,
        ),
      );
    }
  }

  void _confirmDeleteTag(Tag tag) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete Tag'),
          content: Text(
            'Are you sure you want to delete "${tag.name}"?\n\n'
            'All transactions using this tag will be reassigned to "Other".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                DatabaseHelper.deleteTag(tag.id);
                Navigator.pop(context);
                _loadSettings();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Tag deleted successfully'),
                    backgroundColor: theme.danger,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
