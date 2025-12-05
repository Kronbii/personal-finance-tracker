<div align="center">
  <img src="assets/icon/app_icon.png" alt="REE Logo" width="128" height="128">
  
  # REE - Personal Finance Tracker
  
  **A beautiful, desktop-first personal finance application with Apple-inspired design**
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
  [![Platform](https://img.shields.io/badge/Platform-Linux-FCC624?logo=linux&logoColor=black)](https://www.linux.org)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
</div>

---

## ✨ Features

### 💰 Financial Management
- **Multi-Wallet Support** - Track multiple accounts (cash, bank, crypto, etc.)
- **Transaction Tracking** - Log income, expenses, and transfers with categories
- **Subscription Management** - Track recurring payments and billing cycles
- **Debt Tracking** - Monitor money you owe and money owed to you
- **Savings Goals** - Set and track progress toward financial goals

### 📊 Insights & Analytics
- **Dashboard Overview** - At-a-glance view of your financial health
- **Category Breakdown** - Beautiful pie charts showing spending by category
- **Monthly Insights** - Deep dive into any month's finances
- **Yearly Trends** - Track patterns across the year
- **Spending Analysis** - Understand where your money goes

### �� Premium User Experience
- **Apple-Inspired Design** - Clean, elegant UI with attention to detail
- **Dark & Light Themes** - Easy on the eyes, day or night
- **Smooth Animations** - Polished interactions throughout
- **Desktop Optimized** - Built specifically for keyboard and mouse

### 🛠️ Power Features
- **Bulk Entry Mode** - Add multiple transactions at once
- **CSV Import/Export** - Backup and migrate your data easily
- **Custom Categories** - Create and organize your own categories
- **Multi-Currency** - Display amounts in your preferred currency

---

## 📸 Screenshots & Demo

### 🎬 Video Demo

<div align="center">
  
[![REE Demo Video](https://img.shields.io/badge/▶️_Watch_Demo-YouTube-red?style=for-the-badge&logo=youtube)](YOUR_YOUTUBE_LINK_HERE)

<!-- Or embed directly if using a gif: -->
<!-- ![Demo](assets/screenshots/demo.gif) -->

</div>

### Screenshots

<div align="center">
<table>
  <tr>
    <td align="center"><b>Dashboard</b></td>
    <td align="center"><b>Transactions</b></td>
  </tr>
  <tr>
    <td><img src="assets/screenshots/dashboard.png" alt="Dashboard" width="400"></td>
    <td><img src="assets/screenshots/transactions.png" alt="Transactions" width="400"></td>
  </tr>
  <tr>
    <td align="center"><b>Insights</b></td>
    <td align="center"><b>Monthly Insights</b></td>
  </tr>
  <tr>
    <td><img src="assets/screenshots/insights.png" alt="Insights" width="400"></td>
    <td><img src="assets/screenshots/monthly-insights.png" alt="Monthly Insights" width="400"></td>
  </tr>
  <tr>
    <td align="center"><b>Bulk Entry</b></td>
    <td align="center"><b>Settings</b></td>
  </tr>
  <tr>
    <td><img src="assets/screenshots/bulk-entry.png" alt="Bulk Entry" width="400"></td>
    <td><img src="assets/screenshots/settings.png" alt="Settings" width="400"></td>
  </tr>
</table>
</div>

<details>
<summary><b>🌙 Dark Mode Screenshots</b></summary>
<br>
<div align="center">
<table>
  <tr>
    <td><img src="assets/screenshots/dashboard-dark.png" alt="Dashboard Dark" width="400"></td>
    <td><img src="assets/screenshots/transactions-dark.png" alt="Transactions Dark" width="400"></td>
  </tr>
</table>
</div>
</details>

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** 3.10 or higher
- **Linux** with desktop support enabled
- **Git** for cloning the repository

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Kronbii/personal-finance-tracker.git
   cd personal-finance-tracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate database code** (if needed)
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the application**
   ```bash
   flutter run -d linux
   ```

### Building AppImage

#### Safe Update (Recommended for Production)

To safely update an existing installation while preserving your database:

```bash
bash scripts/safe_update_appimage.sh
```

This script will:
- ✅ Backup your production database automatically
- ✅ Backup the existing AppImage
- ✅ Build and install the new AppImage
- ✅ Verify database integrity
- ✅ Keep the last 5 backups for rollback

#### Manual Build

To build the AppImage manually (for development):

```bash
bash scripts/build_appimage.sh
```

The AppImage will be built to `build/REE-1.0.0-x86_64.AppImage`.

#### Restoring Database

If you need to restore your database from a backup:

```bash
bash scripts/restore_database.sh
```

This will list all available backups and let you choose which one to restore.

---

## 🏗️ Architecture

```
lib/
├── app/
│   ├── router/         # GoRouter navigation
│   ├── shell/          # Desktop shell with sidebar
│   └── theme/          # Premium theming system
├── data/
│   ├── drift/          # SQLite database layer
│   │   ├── daos/       # Data Access Objects
│   │   └── tables/     # Table definitions
│   ├── providers/      # Riverpod providers
│   └── services/       # Business logic services
└── presentation/
    ├── screens/        # App screens
    │   ├── dashboard/
    │   ├── transactions/
    │   ├── insights/
    │   ├── monthly_insights/
    │   ├── bulk_entry/
    │   └── settings/
    └── widgets/        # Reusable UI components
```

### Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.x |
| Language | Dart 3.x |
| State Management | Riverpod |
| Local Database | Drift (SQLite) |
| Navigation | GoRouter |
| Charts | FL Chart |
| Icons | Lucide Icons |

---

## 💾 Data Storage

### Development Mode
When running with `flutter run`, a test database is used at:
```
.test_data/ree_test.db  (inside the project)
```

### Production Mode
The AppImage and release builds use:
```
~/.local/share/ree/ree.db
```

This separation ensures your real financial data is never affected during development.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Design inspired by Apple's iOS/macOS apps
- Built with Flutter's excellent desktop support
- Icons by [Lucide](https://lucide.dev/)

---

<div align="center">
  <sub>Built with ❤️ using Flutter</sub>
</div>
