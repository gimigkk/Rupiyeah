# Rupiyeah

A **fully offline personal budgeting app** built with Flutter.  
Designed for privacy, portability, and simplicity — no cloud sync, no external dependencies.

---

## ✨ Key Highlights
- **[Offline first](guide://action?prefill=Tell%20me%20more%20about%3A%20Offline%20first)**: All data stored locally, no internet required.  
- **[Multi‑platform support](guide://action?prefill=Tell%20me%20more%20about%3A%20Multi%E2%80%91platform%20support)**: Runs on Android, iOS, Web, Windows, macOS, and Linux.  
- **[Budget tracking](guide://action?prefill=Tell%20me%20more%20about%3A%20Budget%20tracking)**: Monitor remaining budget, daily spending, and progress with visual indicators.  
- **[Transaction management](guide://action?prefill=Tell%20me%20more%20about%3A%20Transaction%20management)**: Add, edit, and categorize expenses with multiple slots visible in widgets.  
- **[Excel export](guide://action?prefill=Tell%20me%20more%20about%3A%20Excel%20export)**: Generate `.xlsx` reports for sharing or backup.  
- **[Widgets](guide://action?prefill=Tell%20me%20more%20about%3A%20Widgets)**: Homescreen widgets show budget progress and recent transactions.  

---

## 📂 Project Structure
```
lib/
├── main.dart                # Entry point of the Flutter app
│
├── models/                  # Data models
│   ├── budget.dart          # Budget model (amounts, limits, progress)
│   ├── transaction.dart     # Transaction model (date, category, amount)
│   └── category.dart        # Expense categories
│
├── services/                # Business logic & helpers
│   ├── database_service.dart # Local storage (SQLite / Hive)
│   ├── excel_export.dart     # Export transactions to Excel
│   └── widget_service.dart   # Handles widget updates
│
├── ui/                      # User interface
│   ├── screens/
│   │   ├── home_screen.dart # Dashboard with budget overview
│   │   ├── add_expense.dart # Form to add new transactions
│   │   ├── reports_screen.dart # Charts & summaries
│   │   └── settings_screen.dart # App settings
│   │
│   ├── widgets/
│   │   ├── budget_card.dart # Card showing budget progress
│   │   ├── transaction_list.dart # List of recent transactions
│   │   └── progress_bar.dart # Custom progress bar widget
│   │
│   └── theme/
│       └── app_theme.dart   # Colors, typography, styles
│
├── utils/                   # Utility functions
│   ├── date_utils.dart      # Date formatting helpers
│   ├── number_utils.dart    # Currency formatting
│   └── constants.dart       # Static values (strings, keys)
│
└── providers/               # State management
    ├── budget_provider.dart # Handles budget state
    └── transaction_provider.dart # Handles transaction state
```

### 📂 Structure Highlights
- **`models/`**: Defines the core data structures (budget, transaction, category).  
- **`services/`**: Encapsulates logic for persistence, exports, and widget updates.  
- **`ui/`**: Contains screens, reusable widgets, and theming.  
- **`utils/`**: Helper functions for formatting and constants.  
- **`providers/`**: State management layer.  

---

## 🚀 Getting Started

### Prerequisites
- Install [Flutter SDK](guide://action?prefill=Tell%20me%20more%20about%3A%20Flutter%20SDK) (latest stable channel).  
- Ensure platform toolchains are set up (Android Studio/Xcode for mobile, CMake for desktop).  

### Installation
```bash
git clone https://github.com/gimigkk/Rupiyeah.git
cd Rupiyeah
flutter pub get
flutter run
```

---

## 📱 Usage
- Launch the app and **set your budget**.  
- Record **daily transactions** with categories.  
- View **progress bars and summaries** in the app or via widgets.  
- Export data to **Excel** for external analysis.  

---

## 🤝 Contributing
Contributions are welcome!  
1. Fork the repo  
2. Create a feature branch  
   ```bash
   git checkout -b feature/new-feature
   ```
3. Commit changes  
   ```bash
   git commit -m "Add new feature"
   ```
4. Push and open a Pull Request  

---

## 📜 License
Licensed under the **MIT License** — free to use, modify, and distribute.

---
