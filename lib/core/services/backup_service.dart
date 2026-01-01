import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/database/database_helper.dart';

class BackupService {
  BackupService._();
  static final instance = BackupService._();

  final AccountRepository _accountRepo = AccountRepository();
  final TransactionRepository _txRepo = TransactionRepository();
  final BudgetRepository _budgetRepo = BudgetRepository();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // PBKDF2 parameters
  static const int _pbkdf2Iterations = 100000;
  static const int _saltLength = 16;
  static const int _ivLength = 16;
  static const int _keyLength = 32; // 256 bits

  /// Export backup with PIN encryption
  Future<File> exportBackup({required String pin}) async {
    // 1. Read all data
    final accounts = await _accountRepo.getAllAccounts();
    final transactions = await _txRepo.getAllTransactions();
    final budgets = await _budgetRepo.getAllBudgets();

    // 2. Build JSON payload
    final payload = {
      'version': AppConstants.appVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'data': {
        'accounts': accounts.map((a) => a.toMap()).toList(),
        'transactions': transactions.map((t) => t.toMap()).toList(),
        'budgets': budgets.map((b) => b.toMap()).toList(),
      },
    };

    final jsonString = jsonEncode(payload);

    // 3. Generate salt and IV
    final random = Random.secure();
    final saltBytes = List<int>.generate(_saltLength, (_) => random.nextInt(256));
    final ivBytes = List<int>.generate(_ivLength, (_) => random.nextInt(256));
    final salt = crypto.SecretKey(saltBytes);
    final iv = crypto.SecretKey(ivBytes);

    // 4. Derive key from PIN using PBKDF2
    final pinBytes = utf8.encode(pin);
    final pbkdf2 = crypto.Pbkdf2(
      macAlgorithm: crypto.Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: _keyLength * 8,
    );

    final saltBytesList = await salt.extractBytes();
    final secretKey = await pbkdf2.deriveKey(
      secretKey: crypto.SecretKey(pinBytes),
      nonce: saltBytesList,
    );

    // 5. Encrypt JSON using AES-GCM
    final algorithm = crypto.AesGcm.with256bits();
    final ivBytesList = await iv.extractBytes();
    final secretBox = await algorithm.encrypt(
      utf8.encode(jsonString),
      secretKey: secretKey,
      nonce: ivBytesList,
    );

    // 6. Build encrypted payload: salt + iv + ciphertext + mac
    final encryptedData = {
      'salt': base64Encode(saltBytesList),
      'iv': base64Encode(ivBytesList),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };

    final encryptedJson = jsonEncode(encryptedData);

    // 7. Write to .roeya file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final fileName = 'roeya_backup_$timestamp.bak';
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(encryptedJson);

    return file;
  }

  /// Import backup with PIN decryption
  Future<void> importBackup({
    required String pin,
    required File backupFile,
  }) async {
    // 1. Read file
    final encryptedJson = await backupFile.readAsString();
    final encryptedData = jsonDecode(encryptedJson) as Map<String, dynamic>;

    // 2. Extract salt, IV, ciphertext, and MAC
    final saltBytes = base64Decode(encryptedData['salt'] as String);
    final ivBytes = base64Decode(encryptedData['iv'] as String);
    final ciphertextBytes = base64Decode(encryptedData['ciphertext'] as String);
    final macBytes = base64Decode(encryptedData['mac'] as String);

    // 3. Derive key from PIN
    final pinBytes = utf8.encode(pin);
    final pbkdf2 = crypto.Pbkdf2(
      macAlgorithm: crypto.Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: _keyLength * 8,
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: crypto.SecretKey(pinBytes),
      nonce: saltBytes,
    );

    // 4. Decrypt
    final algorithm = crypto.AesGcm.with256bits();
    final secretBox = crypto.SecretBox(
      ciphertextBytes,
      mac: crypto.Mac(macBytes),
      nonce: ivBytes,
    );

    try {
      final decryptedBytes = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      final jsonString = utf8.decode(decryptedBytes);
      final payload = jsonDecode(jsonString) as Map<String, dynamic>;

      // 5. Validate version
      final version = payload['version'] as String?;
      if (version == null) {
        throw Exception('Invalid backup file: missing version');
      }

      // 6. Extract data
      final data = payload['data'] as Map<String, dynamic>;
      final accountsData = data['accounts'] as List<dynamic>;
      final transactionsData = data['transactions'] as List<dynamic>;
      final budgetsData = data['budgets'] as List<dynamic>? ?? [];

      // 7. Import into database (inside transaction)
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        // Clear existing data
        await txn.delete('transactions');
        await txn.delete('budgets');
        await txn.delete('accounts');

        // Import accounts
        for (final accountMap in accountsData) {
          await txn.insert('accounts', accountMap as Map<String, dynamic>);
        }

        // Import transactions
        for (final txMap in transactionsData) {
          await txn.insert('transactions', txMap as Map<String, dynamic>);
        }

        // Import budgets
        for (final budgetMap in budgetsData) {
          await txn.insert('budgets', budgetMap as Map<String, dynamic>);
        }
      });

      // 8. Recalculate account balances
      await _recalculateBalances();
    } catch (e, stackTrace) {
      debugPrint('Import backup error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (e.toString().contains('authentication') || e.toString().contains('mac') || e.toString().contains('SecretBox')) {
        throw Exception('Wrong PIN or corrupted file');
      }
      throw Exception('Failed to decrypt backup: $e');
    }
  }

  /// Recalculate account balances from transactions
  Future<void> _recalculateBalances() async {
    final accounts = await _accountRepo.getAllAccounts();
    final transactions = await _txRepo.getAllTransactions();

    // Reset all balances
    for (final account in accounts) {
      await _accountRepo.updateAccount(
        account.copyWith(balance: 0.0),
      );
    }

    // Recalculate from transactions
    for (final tx in transactions) {
      final account = await _accountRepo.getAccountById(tx.accountId);
      if (account != null) {
        final delta = tx.type == 'income' ? tx.amount : -tx.amount;
        final newBalance = account.balance + delta;
        await _accountRepo.updateAccount(
          account.copyWith(balance: newBalance),
        );
      }
    }
  }
}
