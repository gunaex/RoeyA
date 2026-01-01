import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/account_repository.dart';

class CsvService {
  static final CsvService instance = CsvService._init();
  CsvService._init();

  Future<void> exportToCsv() async {
    final txRepo = TransactionRepository();
    final accRepo = AccountRepository();

    final transactions = await txRepo.getAllTransactions();
    final accounts = await accRepo.getAllAccounts();

    final StringBuffer csvBuffer = StringBuffer();

    // 1. Export Transactions
    csvBuffer.writeln('--- TRANSACTIONS ---');
    csvBuffer.writeln('Date,Type,Amount,Currency,Category,Description,Account,Note');

    for (final tx in transactions) {
      final account = accounts.firstWhere((a) => a.id == tx.accountId, orElse: () => accounts.first);
      
      final date = DateFormat('yyyy-MM-dd HH:mm').format(tx.transactionDate);
      final amount = tx.amount.toStringAsFixed(2);
      
      // Escape commas in strings
      final category = _escape(tx.category ?? '');
      final description = _escape(tx.description ?? '');
      final accountName = _escape(account.name);
      final note = _escape(tx.note ?? '');

      csvBuffer.writeln('$date,${tx.type},$amount,${tx.currencyCode},$category,$description,$accountName,$note');
    }

    csvBuffer.writeln();
    
    // 2. Export Accounts
    csvBuffer.writeln('--- ACCOUNTS ---');
    csvBuffer.writeln('Name,Category,Balance,Currency,Description');

    for (final acc in accounts) {
      final balance = acc.balance.toStringAsFixed(2);
      final name = _escape(acc.name);
      final category = _escape(acc.category);
      final description = _escape(acc.description ?? '');

      csvBuffer.writeln('$name,$category,$balance,${acc.currencyCode},$description');
    }

    // Save to file
    final directory = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/roeya_export_$timestamp.csv');
    
    await file.writeAsString(csvBuffer.toString());

    // Share file
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'RoeyA Financial Export - $timestamp',
    );
  }

  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
