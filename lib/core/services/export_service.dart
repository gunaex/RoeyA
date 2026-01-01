import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/models/transaction.dart' as model;
import 'package:intl/intl.dart';

class ExportService {
  static final ExportService instance = ExportService._init();
  ExportService._init();

  final TransactionRepository _txRepo = TransactionRepository();

  /// Export transactions to CSV
  Future<File?> exportTransactionsCsv({
    int? year,
    int? month,
    String? accountId,
  }) async {
    try {
      // Get transactions
      List<model.Transaction> transactions;
      
      if (year != null && month != null) {
        // Get transactions for specific month
        final startDate = DateTime(year, month, 1);
        final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
        transactions = await _txRepo.searchTransactions(
          from: startDate,
          to: endDate,
          accountId: accountId,
        );
      } else {
        // Get all transactions
        transactions = await _txRepo.getAllTransactions();
        if (accountId != null) {
          transactions = transactions.where((t) => t.accountId == accountId).toList();
        }
      }

      // Build CSV content
      final csvLines = <String>[];
      
      // Header
      csvLines.add('Date,Type,Category,Description,Amount,Currency,Account ID,Note');
      
      // Data rows
      final dateFormat = DateFormat('yyyy-MM-dd');
      for (var tx in transactions) {
        final date = dateFormat.format(tx.transactionDate);
        final type = tx.type;
        final category = tx.category ?? '';
        final description = _escapeCsvField(tx.description ?? '');
        final amount = tx.amount.toStringAsFixed(2);
        final currency = tx.currencyCode;
        final accountId = tx.accountId;
        final note = _escapeCsvField(tx.note ?? '');
        
        csvLines.add('$date,$type,$category,$description,$amount,$currency,$accountId,$note');
      }

      final csvContent = csvLines.join('\n');
      final csvBytes = utf8.encode(csvContent);

      // Save file
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final suffix = year != null && month != null
          ? '_${year}_${month.toString().padLeft(2, '0')}'
          : '';
      final fileName = 'roeya_transactions$suffix.csv';

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Transactions',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return null;

      final file = File(result);
      await file.writeAsBytes(csvBytes);

      return file;
    } catch (e) {
      print('CSV export error: $e');
      return null;
    }
  }

  String _escapeCsvField(String field) {
    // Escape quotes and wrap in quotes if contains comma, quote, or newline
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}

