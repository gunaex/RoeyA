import 'package:flutter/material.dart';
import 'package:roeyp/core/constants/app_constants.dart';
import 'package:roeyp/features/accounts/screens/accounts_screen.dart';
import 'package:roeyp/features/auth/screens/confirm_pin_screen.dart';
import 'package:roeyp/features/auth/screens/create_pin_screen.dart';
import 'package:roeyp/features/auth/screens/pin_lock_screen.dart';
import 'package:roeyp/features/auth/screens/recovery_email_screen.dart';
import 'package:roeyp/features/auth/screens/welcome_screen.dart';
import 'package:roeyp/features/auth/screens/forgot_pin_screen.dart';
import 'package:roeyp/features/consent/screens/consent_screen.dart';
import 'package:roeyp/features/dashboard/screens/dashboard_screen.dart';
import 'package:roeyp/features/map/screens/transaction_map_screen.dart';
import 'package:roeyp/features/settings/screens/settings_screen.dart';
import 'package:roeyp/features/transactions/screens/browse_slips_screen.dart';
import 'package:roeyp/features/transactions/screens/bulk_import_ocr_screen.dart';
import 'package:roeyp/features/transactions/screens/manual_entry_screen.dart';
import 'package:roeyp/features/transactions/screens/qr_scanner_screen.dart';
import 'package:roeyp/features/transactions/screens/slip_ocr_screen.dart';
import 'package:roeyp/features/transactions/screens/transaction_detail_screen.dart';
import 'package:roeyp/features/transactions/screens/transaction_mode_screen.dart';
import 'package:roeyp/features/dashboard/screens/reports_screen.dart';
import 'package:roeyp/features/budgets/screens/budgets_screen.dart';
import 'package:roeyp/features/transactions/screens/search_transactions_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.routeWelcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      
      case AppConstants.routeConsent:
        return MaterialPageRoute(builder: (_) => const ConsentScreen());
      
      case AppConstants.routeCreatePin:
        return MaterialPageRoute(builder: (_) => const CreatePinScreen());
      
      case AppConstants.routeConfirmPin:
        final pin = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ConfirmPinScreen(originalPin: pin),
        );
      
      case AppConstants.routeRecoveryEmail:
        return MaterialPageRoute(builder: (_) => const RecoveryEmailScreen());
      
      case AppConstants.routePinLock:
        return MaterialPageRoute(builder: (_) => const PinLockScreen());
      
      case AppConstants.routeHome:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      
      case AppConstants.routeTransactionMode:
        return MaterialPageRoute(builder: (_) => const TransactionModeScreen());
      
      case AppConstants.routeManualEntry:
        final args = settings.arguments;
        String? txId;
        if (args is String) {
          txId = args;
        }
        return MaterialPageRoute(builder: (_) => ManualEntryScreen(transactionId: txId));
      
      case AppConstants.routeAccounts:
        return MaterialPageRoute(builder: (_) => const AccountsScreen());
      
      case AppConstants.routeSettings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      
      case AppConstants.routeTransactionMap:
        return MaterialPageRoute(builder: (_) => const TransactionMapScreen());
      
      case AppConstants.routeBrowseSlips:
        return MaterialPageRoute(builder: (_) => const BrowseSlipsScreen());
      
      case AppConstants.routeScanSlip:
        return MaterialPageRoute(builder: (_) => const SlipOcrScreen());
      
      case AppConstants.routeBulkImportOcr:
        return MaterialPageRoute(builder: (_) => const BulkImportOcrScreen());
      
      case AppConstants.routeForgotPin:
        return MaterialPageRoute(builder: (_) => const ForgotPinScreen());

      case AppConstants.routeReports:
        return MaterialPageRoute(builder: (_) => const ReportsScreen());
      
      case AppConstants.routeQrScanner:
        return MaterialPageRoute(builder: (_) => const QrScannerScreen());
      
      case AppConstants.routeTransactionDetail:
        final id = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(transactionId: id),
        );
      
      case AppConstants.routeBudgets:
        return MaterialPageRoute(builder: (_) => const BudgetsScreen());
      
      case AppConstants.routeSearchTransactions:
        return MaterialPageRoute(builder: (_) => const SearchTransactionsScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}

