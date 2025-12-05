# Rupiyeah 💰

A fully offline personal budgeting app built with Flutter. Track your expenses, manage your budget, and visualize your spending - all without internet connection.

## ✨ Features

- **100% Offline** - All data stored locally using Hive database
- **Smart Daily Budgeting** - Automatic or manual daily budget calculation
- **Transaction Management** - Add, edit, and categorize with custom tags
- **Document Attachments** - Attach receipts to transactions
- **Multiple Payment Methods** - Track wallet and bank separately
- **Export Reports** - PDF with charts or CSV format
- **Home Screen Widgets** - Quick budget view and transaction shortcut
- **6 Themes** - Purple, Ocean, Sunset, Forest, Rose, Midnight (with dark mode)
- **Multi-Platform** - Android, iOS, Web, Windows, macOS, Linux

## 🚀 Getting Started

### Installation

```bash
git clone https://github.com/gimigkk/Rupiyeah.git
cd Rupiyeah
flutter pub get
flutter pub run build_runner build
flutter run
```

### Build for Release

```bash
flutter build apk --release          # Android
flutter build appbundle --release    # Android App Bundle
flutter build ios --release          # iOS
flutter build web --release          # Web
flutter build windows --release      # Windows
flutter build macos --release        # macOS
flutter build linux --release        # Linux
```

## 📂 Project Structure

```
lib/
├── main.dart                      # App entry point
├── models/                        # Data models (Hive)
│   ├── month_data.dart
│   ├── tag.dart
│   └── transaction.dart
├── pages/                         # Screens
│   ├── add_transaction_page.dart
│   ├── history_page.dart
│   ├── home_page.dart
│   └── settings_page.dart
├── providers/                     # State management
│   └── theme_provider.dart
├── services/                      # Business logic
│   ├── export_service.dart         # PDF/CSV export
│   └── widget_service.dart         # Widget updates
├── storage/                       # Data persistence
│   ├── database_helper.dart
│   └── file_helper.dart
├── utils/                         # Utilities
│   ├── currency_input_formatter.dart
│   └── format_currency.dart
└── widgets/                       # UI components
    ├── animated_number.dart
    ├── balance_card.dart
    ├── daily_expense_chart.dart
    ├── month_selector.dart
    ├── tag_dialog.dart
    ├── transaction_form_card.dart
    ├── transaction_form_widgets.dart
    └── transaction_tile.dart
```

## 📊 Export

- **PDF** - Includes statistics, charts, and transaction tables
- **CSV** - Simple spreadsheet format for external analysis

## 🛠️ Key Dependencies

- **hive** & **hive_flutter** - Local database
- **provider** - State management
- **fl_chart** - Charts and graphs
- **syncfusion_flutter_pdf** - PDF generation
- **home_widget** - Home screen widgets
- **file_picker** - Document attachments
- **share_plus** - File sharing

## 🔒 Privacy

- No internet required
- No data collection
- No third-party services
- All data stays on your device

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🐛 Issues

Found a bug? [Open an issue](https://github.com/gimigkk/Rupiyeah/issues/new)

---

**Version**: 4.0.0+4 | Made with ❤️ using Flutter
