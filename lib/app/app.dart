import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:roeyp/core/constants/app_constants.dart';
import 'package:roeyp/core/localization/app_localizations.dart';
import 'package:roeyp/core/localization/locale_provider.dart';
import 'package:roeyp/core/services/connectivity_service.dart';
import 'package:roeyp/core/services/secure_storage_service.dart';
import 'package:roeyp/core/theme/app_theme.dart';
import 'package:roeyp/data/repositories/account_repository.dart';
import 'package:roeyp/app/routes.dart';

class RoeyPApp extends StatefulWidget {
  const RoeyPApp({super.key});

  @override
  State<RoeyPApp> createState() => _RoeyPAppState();
}

class _RoeyPAppState extends State<RoeyPApp> {
  String? _initialRoute;
  bool _isInitializing = true;
  static const MethodChannel _shortcutChannel = MethodChannel('com.example/shortcut');

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize critical services
      await SecureStorageService.instance.init();
      await ConnectivityService.instance.init();
      
      // Initialize default accounts (non-blocking)
      final accountRepo = AccountRepository();
      await accountRepo.createDefaultAccountsIfNeeded();
      
      // Determine initial route
      final isFirstLaunch = await SecureStorageService.instance.isFirstLaunch();
      _initialRoute = await _getDefaultRoute(isFirstLaunch);
    } catch (e) {
      debugPrint('App init error: $e');
      _initialRoute = AppConstants.routeWelcome;
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<String> _getDefaultRoute(bool isFirstLaunch) async {
    if (isFirstLaunch) {
      return AppConstants.routeWelcome;
    } else {
      final hasConsented = await SecureStorageService.instance.hasConsented();
      final hasPin = await SecureStorageService.instance.getPin();
      final recoveryEmail = await SecureStorageService.instance.getRecoveryEmail();
      
      if (!hasConsented) {
        return AppConstants.routeConsent;
      } else if (hasPin == null) {
        return AppConstants.routeCreatePin;
      } else if (recoveryEmail == null) {
        return AppConstants.routeRecoveryEmail;
      } else {
        return AppConstants.routePinLock;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B7355),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LocaleProvider()..loadLocale(),
        ),
        ChangeNotifierProvider.value(
          value: ConnectivityService.instance,
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            
            // Theme
            theme: AppTheme.lightTheme,
            
            // Localization
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('th'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            
            // Routing
            initialRoute: _initialRoute,
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}

