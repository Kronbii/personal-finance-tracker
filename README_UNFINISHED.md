# Unfinished Features & Continuation Guide

This document lists features that are partially implemented or need additional work, along with prompts to continue development.

## Implemented Features (100% Complete)

✅ **Priority 1: App Foundation**
- Flutter project structure with clean architecture
- Premium dark/light theme system
- Desktop sidebar navigation
- Riverpod state management setup

✅ **Priority 2: Database Layer**
- All Drift tables (wallets, categories, transactions, subscriptions, debts, savings_goals, savings_contributions, settings)
- Complete DAOs with CRUD and analytics queries
- Default category seeding

✅ **Priority 3: Main Screens (UI Complete)**
- Dashboard screen with stats, charts, wallet cards
- Transactions screen with filters, search, grouped list
- Insights screen with all 5 tabs (Spending, Income, Savings, Subscriptions, Debts)
- Bulk Entry screen with grid form
- Settings screen with sections

✅ **Priority 4: Supabase Sync (Architecture)**
- SyncService with push/pull logic
- Timestamp-based conflict resolution
- Table conversion helpers

✅ **Priority 5: Linux Packaging**
- AppImage build script

---

## Features Needing Completion

### 1. Add/Edit Wallet Modal

**Status**: Settings screen has placeholder for wallet management

**Files to create/modify**:
- `lib/presentation/screens/settings/widgets/add_wallet_modal.dart`

**Continuation prompt**:
```
Create a premium Add/Edit Wallet modal for the Settings screen. The modal should:
1. Have fields for: name, initial balance, currency (dropdown), gradient color selection
2. Follow the same Apple-style design as AddTransactionModal
3. Support both create and edit modes
4. Integrate with WalletsDao for database operations
5. Include validation and error handling
```

### 2. Category Management Screen

**Status**: Settings screen has placeholder navigation

**Files to create/modify**:
- `lib/presentation/screens/settings/widgets/manage_categories_modal.dart`
- `lib/presentation/screens/settings/widgets/add_category_modal.dart`

**Continuation prompt**:
```
Create a category management UI for the Settings screen. Include:
1. A modal showing all categories (expense/income tabs)
2. Drag-to-reorder functionality
3. Add/Edit category modal with: name, icon picker, color picker
4. Delete with confirmation (check for transaction usage first)
5. Follow Apple-style design patterns from existing code
```

### 3. CSV Import/Export

**Status**: Settings screen has placeholder buttons

**Files to create/modify**:
- `lib/data/services/csv_service.dart`
- Update `settings_screen.dart` to use the service

**Continuation prompt**:
```
Implement CSV import/export functionality:
1. Create CsvService in lib/data/services/
2. Export: Generate CSV from transactions with columns: date, type, amount, category, wallet, note
3. Import: Parse CSV, validate data, create transactions (show preview before import)
4. Use file_picker package for file selection
5. Show progress and results summary
```

### 4. Currency Conversion

**Status**: Settings has placeholder, database has conversion_rate field

**Files to modify**:
- `lib/presentation/screens/settings/widgets/currency_picker.dart`
- Update dashboard/insights to support multiple currencies

**Continuation prompt**:
```
Implement currency support:
1. Create a currency picker modal with common currencies
2. Store default currency in settings
3. Add manual conversion rate input (for display purposes)
4. Update amount formatting throughout the app to respect selected currency
5. Optionally fetch real-time rates from a free API
```

### 5. Supabase Integration (UI)

**Status**: SyncService exists, needs UI connection

**Files to modify**:
- `lib/presentation/screens/settings/widgets/supabase_config_modal.dart`
- Connect sync button to actual SyncService
- Add sync status indicators

**Continuation prompt**:
```
Connect Supabase sync to the UI:
1. Create configuration modal for entering Supabase URL and anon key
2. Store credentials securely in settings
3. Initialize Supabase client on app start if configured
4. Connect "Sync Now" buttons to SyncService.syncNow()
5. Show sync progress, results, and error handling
6. Add last sync timestamp display
```

### 6. Transaction Details Modal

**Status**: Transaction list items are tappable but modal not implemented

**Files to create**:
- `lib/presentation/screens/transactions/widgets/transaction_details_modal.dart`

**Continuation prompt**:
```
Create a transaction details modal that shows:
1. Full transaction information with formatted display
2. Edit button that opens AddTransactionModal in edit mode
3. Delete button with confirmation
4. Duplicate transaction option
5. Attachment preview if available
6. Follow the premium modal design from other modals
```

### 7. Add Subscription/Debt Modals

**Status**: Insights screen shows lists but no add functionality

**Files to create**:
- `lib/presentation/screens/insights/widgets/add_subscription_modal.dart`
- `lib/presentation/screens/insights/widgets/add_debt_modal.dart`

**Continuation prompt**:
```
Create modals for adding subscriptions and debts:

Subscription modal fields:
- Name, amount, frequency, wallet, category
- Start date, next billing date
- Auto-create transaction toggle
- Reminder days before billing

Debt modal fields:
- Person name, original amount, type (owed/lent)
- Due date, interest rate (optional)
- Associated wallet, description, contact info

Both should follow the existing modal design patterns.
```

### 8. Keyboard Shortcuts

**Status**: Not implemented

**Files to modify**:
- `lib/app/shell/app_shell.dart`
- Add shortcuts to each screen

**Continuation prompt**:
```
Implement keyboard shortcuts for desktop:
1. Add CallbackShortcuts wrapper in AppShell
2. Navigation: Ctrl+1-5 for screen switching
3. Actions: Ctrl+N for new transaction, Ctrl+F for search
4. Modal: Escape to close, Enter to submit
5. Add shortcut hints to tooltips
```

### 9. Data Visualization Improvements

**Status**: Basic charts implemented

**Files to modify**:
- `lib/presentation/widgets/line_chart_widget.dart`
- `lib/presentation/widgets/category_pie_chart.dart`

**Continuation prompt**:
```
Enhance chart visualizations:
1. Add date range selector for trends (1M, 3M, 6M, 1Y, All)
2. Add comparison view (this month vs last month)
3. Improve touch interactions with detailed tooltips
4. Add bar chart option for category comparison
5. Implement budget vs actual visualization
```

### 10. Notifications/Reminders

**Status**: Not implemented

**Files to create**:
- `lib/data/services/notification_service.dart`

**Continuation prompt**:
```
Implement notification system for:
1. Subscription billing reminders (X days before)
2. Debt due date reminders
3. Savings goal milestones
4. Use linux_notification or similar package
5. Store notification preferences in settings
```

---

## Testing

No unit or widget tests have been written. To add tests:

```
Create comprehensive tests for:
1. Unit tests for all DAOs (test CRUD operations, analytics queries)
2. Unit tests for SyncService
3. Widget tests for key UI components
4. Integration tests for critical user flows
Use flutter_test and mockito for mocking
```

---

## Performance Optimizations

Consider implementing:
- Pagination for large transaction lists
- Query optimization with database indexes
- Image/attachment caching
- State caching for expensive computations

---

## Quick Start for Continuation

1. Pick a feature from above
2. Copy the continuation prompt
3. Add context: "I'm continuing development of the Personal Finance Tracker Flutter app. Here's the current state: [paste relevant existing files]"
4. Run the prompt to generate the implementation
5. Test thoroughly before moving to next feature

