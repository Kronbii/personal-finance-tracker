# Personal Finance Tracker

A premium, desktop-first personal finance application built with Flutter, featuring an Apple-inspired UI design.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Drift](https://img.shields.io/badge/Drift-SQLite-green)
![Riverpod](https://img.shields.io/badge/State-Riverpod-purple)
![License](https://img.shields.io/badge/License-MIT-yellow)

## Features

### Core Functionality
- 📊 **Dashboard** - Complete financial overview with savings, income/expenses, category breakdowns
- 💳 **Transactions** - Full transaction management with filters, search, and day-grouped lists
- 📈 **Insights** - Analytics with spending trends, category breakdowns, subscriptions, and debt tracking
- ⚡ **Bulk Entry** - Multi-row grid form for rapid transaction entry
- ⚙️ **Settings** - Theme toggle, wallet/category management, data import/export

### Technical Features
- 🗄️ **Local Database** - Drift (SQLite) with comprehensive schema
- 🔄 **Sync Ready** - Supabase sync service architecture
- 🎨 **Premium UI** - Apple-inspired design with dark/light themes
- 🖥️ **Desktop Optimized** - Collapsible sidebar, keyboard navigation
- 📦 **Linux Packaging** - AppImage build script included

## Screenshots

*Coming soon*

## Getting Started

### Prerequisites
- Flutter SDK 3.10+
- Linux desktop support enabled

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/personal-finance-tracker.git
cd personal-finance-tracker
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate Drift database code:
```bash
dart run build_runner build --delete-conflicting-outputs
```

4. Run the application:
```bash
flutter run -d linux
```

## Project Structure

```
lib/
├── app/
│   ├── theme/          # Premium theming system
│   ├── router/         # GoRouter navigation
│   └── shell/          # Desktop sidebar shell
├── data/
│   ├── drift/          # Database layer
│   │   ├── tables/     # Table definitions
│   │   ├── daos/       # Data Access Objects
│   │   └── database.dart
│   ├── sync/           # Supabase sync service
│   └── providers/      # Riverpod providers
├── domain/
│   ├── models/         # Domain models
│   └── repositories/   # Repository interfaces
└── presentation/
    ├── screens/        # App screens
    │   ├── dashboard/
    │   ├── transactions/
    │   ├── insights/
    │   ├── bulk_entry/
    │   └── settings/
    ├── widgets/        # Reusable widgets
    └── components/     # UI components
```

## Database Schema

### Tables
- **wallets** - Financial accounts with balances
- **categories** - Expense/income categories
- **transactions** - All financial transactions
- **subscriptions** - Recurring payments
- **debts** - Money owed/lent tracking
- **savings_goals** - Savings targets
- **savings_contributions** - Goal contributions
- **settings** - App configuration

## Building for Linux

### AppImage
```bash
./scripts/build_appimage.sh
```

The AppImage will be created in `build/Personal_Finance_Tracker-VERSION-x86_64.AppImage`.

### Prerequisites for AppImage
- `appimagetool` (downloaded automatically if not present)

## Supabase Sync Setup

1. Create a Supabase project
2. Create tables matching the Drift schema (see `lib/data/drift/tables/`)
3. Configure RLS policies for security
4. Add credentials in Settings

### Recommended RLS Policy (Read-Only Safe)
```sql
-- Enable RLS on all tables
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
-- Add similar for other tables

-- Allow authenticated users to read/write their own data
CREATE POLICY "Users can manage own data" ON wallets
  FOR ALL USING (auth.uid() = user_id);
```

## Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Riverpod
- **Local Database**: Drift (SQLite)
- **Remote Sync**: Supabase
- **Routing**: GoRouter
- **Charts**: FL Chart
- **Icons**: Lucide Icons
- **Fonts**: Google Fonts (Inter, Outfit, JetBrains Mono)

## Contributing

Contributions are welcome! Please read the contributing guidelines first.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Design inspired by Apple's iOS apps (Wallet, Stocks, Fitness)
- Built with Flutter's excellent desktop support
