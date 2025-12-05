import 'dart:io';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../drift/database.dart';
import '../drift/tables/transactions_table.dart';

/// Result of CSV import operation
class CsvImportResult {
  final int totalRows;
  final int successful;
  final int failed;
  final List<String> errors;

  CsvImportResult({
    required this.totalRows,
    required this.successful,
    required this.failed,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
}

/// Preview row for CSV import
class CsvPreviewRow {
  final int rowNumber;
  final Map<String, String> data;
  final List<String> errors;
  final bool isValid;

  CsvPreviewRow({
    required this.rowNumber,
    required this.data,
    required this.errors,
    required this.isValid,
  });
}

/// Service for CSV import/export operations
class CsvService {
  final AppDatabase database;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  CsvService(this.database);

  /// Export all transactions to CSV file
  /// Returns the file path if successful, null otherwise
  Future<String?> exportTransactions() async {
    try {
      // Get all transactions
      final transactions = await database.transactionsDao.getAllTransactions();
      
      if (transactions.isEmpty) {
        throw Exception('No transactions to export');
      }

      // Get all wallets and categories for name lookup
      final wallets = await database.walletsDao.getAllWallets();
      final categories = await database.categoriesDao.getAllCategories();
      
      final walletMap = {for (var w in wallets) w.id: w.name};
      final categoryMap = {for (var c in categories) c.id: c.name};

      // Prepare CSV data
      final csvData = <List<String>>[];
      
      // Header row
      csvData.add([
        'Date',
        'Type',
        'Amount',
        'Category',
        'Wallet',
        'To Wallet',
        'Note',
      ]);

      // Data rows
      for (final transaction in transactions) {
        final categoryName = transaction.categoryId != null
            ? (categoryMap[transaction.categoryId] ?? '')
            : '';
        final walletName = walletMap[transaction.walletId] ?? '';
        final toWalletName = transaction.toWalletId != null
            ? (walletMap[transaction.toWalletId] ?? '')
            : '';

        csvData.add([
          _dateTimeFormat.format(transaction.date),
          transaction.type.name,
          transaction.amount.toStringAsFixed(2),
          categoryName,
          walletName,
          toWalletName,
          transaction.note ?? '',
        ]);
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(csvData);

      // Save to file
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Transactions',
        fileName: 'transactions_${_dateFormat.format(DateTime.now())}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) {
        return null; // User cancelled
      }

      final file = File(result);
      await file.writeAsString(csvString);

      return result;
    } catch (e) {
      throw Exception('Failed to export transactions: $e');
    }
  }

  /// Parse CSV file and return preview rows
  Future<List<CsvPreviewRow>> previewImport(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final content = await file.readAsString();
      final csvData = const CsvToListConverter().convert(content);

      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Get headers (first row)
      final headers = csvData[0]
          .map((h) => h.toString().trim().toLowerCase())
          .toList();

      // Validate headers
      final requiredHeaders = ['date', 'type', 'amount'];
      final missingHeaders = requiredHeaders
          .where((h) => !headers.contains(h))
          .toList();
      
      if (missingHeaders.isNotEmpty) {
        throw Exception(
          'Missing required columns: ${missingHeaders.join(", ")}',
        );
      }

      // Get wallets and categories for validation
      final wallets = await database.walletsDao.getAllWallets();
      final categories = await database.categoriesDao.getAllCategories();
      
      final walletNames = wallets.map((w) => w.name.toLowerCase()).toSet();
      final categoryNames = categories.map((c) => c.name.toLowerCase()).toSet();

      // Parse data rows
      final previewRows = <CsvPreviewRow>[];
      
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        final rowData = <String, String>{};
        final errors = <String>[];

        // Map row data to headers
        for (int j = 0; j < headers.length && j < row.length; j++) {
          rowData[headers[j]] = row[j].toString().trim();
        }

        // Validate row
        final dateStr = rowData['date'] ?? '';
        final typeStr = rowData['type'] ?? '';
        final amountStr = rowData['amount'] ?? '';
        final categoryStr = rowData['category'] ?? '';
        final walletStr = rowData['wallet'] ?? '';
        final toWalletStr = rowData['to wallet'] ?? '';

        // Validate date
        DateTime? date;
        try {
          // Try multiple date formats
          date = _tryParseDate(dateStr);
          if (date == null) {
            errors.add('Invalid date format: $dateStr');
          }
        } catch (e) {
          errors.add('Invalid date: $dateStr');
        }

        // Validate type
        if (!['expense', 'income', 'transfer'].contains(typeStr.toLowerCase())) {
          errors.add('Invalid type: $typeStr (must be expense, income, or transfer)');
        }

        // Validate amount
        double? amount;
        try {
          amount = double.tryParse(amountStr);
          if (amount == null || amount <= 0) {
            errors.add('Invalid amount: $amountStr (must be a positive number)');
          }
        } catch (e) {
          errors.add('Invalid amount: $amountStr');
        }

        // Validate wallet (required)
        if (walletStr.isEmpty) {
          errors.add('Wallet is required');
        } else if (!walletNames.contains(walletStr.toLowerCase())) {
          errors.add('Wallet not found: $walletStr');
        }

        // Validate category (required for expense/income, optional for transfer)
        if (typeStr.toLowerCase() != 'transfer' && categoryStr.isNotEmpty) {
          if (!categoryNames.contains(categoryStr.toLowerCase())) {
            errors.add('Category not found: $categoryStr');
          }
        }

        // Validate toWallet (required for transfer)
        if (typeStr.toLowerCase() == 'transfer') {
          if (toWalletStr.isEmpty) {
            errors.add('To Wallet is required for transfers');
          } else if (!walletNames.contains(toWalletStr.toLowerCase())) {
            errors.add('To Wallet not found: $toWalletStr');
          }
        }

        previewRows.add(CsvPreviewRow(
          rowNumber: i + 1, // 1-indexed for user display
          data: rowData,
          errors: errors,
          isValid: errors.isEmpty,
        ));
      }

      return previewRows;
    } catch (e) {
      throw Exception('Failed to preview CSV: $e');
    }
  }

  /// Import transactions from CSV file
  Future<CsvImportResult> importTransactions(String filePath) async {
    try {
      final previewRows = await previewImport(filePath);

      // Get wallets and categories for ID lookup
      final wallets = await database.walletsDao.getAllWallets();
      final categories = await database.categoriesDao.getAllCategories();
      
      final walletNameToId = {
        for (var w in wallets) w.name.toLowerCase(): w.id
      };
      final categoryNameToId = {
        for (var c in categories) c.name.toLowerCase(): c.id
      };

      int successful = 0;
      int failed = 0;
      final errors = <String>[];

      // Process valid rows
      final validRows = previewRows.where((r) => r.isValid).toList();
      
      if (validRows.isEmpty) {
        return CsvImportResult(
          totalRows: previewRows.length,
          successful: 0,
          failed: previewRows.length,
          errors: ['No valid rows to import'],
        );
      }

      // Prepare transactions for batch insert
      final transactionsToInsert = <TransactionsCompanion>[];

      for (final row in validRows) {
        try {
          final data = row.data;
          final dateStr = data['date'] ?? '';
          final typeStr = data['type'] ?? '';
          final amountStr = data['amount'] ?? '';
          final categoryStr = data['category'] ?? '';
          final walletStr = data['wallet'] ?? '';
          final toWalletStr = data['to wallet'] ?? '';
          final noteStr = data['note'] ?? '';

          // Parse values
          final date = _tryParseDate(dateStr)!;
          final type = TransactionType.values.firstWhere(
            (t) => t.name == typeStr.toLowerCase(),
            orElse: () => TransactionType.expense,
          );
          final amount = double.parse(amountStr);
          final walletId = walletNameToId[walletStr.toLowerCase()]!;
          final categoryId = categoryStr.isNotEmpty
              ? categoryNameToId[categoryStr.toLowerCase()]
              : null;
          final toWalletId = toWalletStr.isNotEmpty
              ? walletNameToId[toWalletStr.toLowerCase()]
              : null;

          // Create transaction
          transactionsToInsert.add(TransactionsCompanion.insert(
            id: const Uuid().v4(),
            date: date,
            type: type,
            amount: amount,
            walletId: Value(walletId),
            categoryId: Value(categoryId),
            toWalletId: Value(toWalletId),
            note: Value(noteStr.isNotEmpty ? noteStr : null),
            isConfirmed: const Value(true),
          ));

          successful++;
        } catch (e) {
          failed++;
          errors.add('Row ${row.rowNumber}: $e');
        }
      }

      // Batch insert transactions
      if (transactionsToInsert.isNotEmpty) {
        await database.transactionsDao.insertTransactions(transactionsToInsert);
      }

      // Count failed rows from preview
      failed += previewRows.where((r) => !r.isValid).length;
      for (final row in previewRows.where((r) => !r.isValid)) {
        errors.add('Row ${row.rowNumber}: ${row.errors.join(", ")}');
      }

      return CsvImportResult(
        totalRows: previewRows.length,
        successful: successful,
        failed: failed,
        errors: errors,
      );
    } catch (e) {
      throw Exception('Failed to import transactions: $e');
    }
  }

  /// Try to parse date from various formats
  DateTime? _tryParseDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    // Try ISO format first (yyyy-MM-dd or yyyy-MM-dd HH:mm:ss)
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    // Try common formats
    final formats = [
      DateFormat('yyyy-MM-dd'),
      DateFormat('MM/dd/yyyy'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('yyyy/MM/dd'),
      DateFormat('MM-dd-yyyy'),
      DateFormat('dd-MM-yyyy'),
    ];

    for (final format in formats) {
      try {
        return format.parse(dateStr);
      } catch (_) {}
    }

    return null;
  }
}

