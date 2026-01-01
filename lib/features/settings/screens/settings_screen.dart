import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roeyp/core/constants/app_constants.dart';
import 'package:roeyp/core/localization/app_localizations.dart';
import 'package:roeyp/core/localization/locale_provider.dart';
import 'package:roeyp/core/services/secure_storage_service.dart';
import 'package:roeyp/core/services/gemini_service.dart';
import 'package:roeyp/core/services/ai_financial_advisor_service.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roeyp/core/services/backup_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:roeyp/core/theme/app_colors.dart';
import 'package:roeyp/features/consent/screens/consent_screen.dart';
import 'package:roeyp/core/services/csv_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/pin_numpad.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SecureStorageService _storage = SecureStorageService.instance;
  
  String _currentLanguage = 'en';
  String _currentCurrency = 'THB';
  String? _recoveryEmail;
  bool _didInitLocale = false;
  bool _languageChanged = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitLocale) return;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _currentLanguage = localeProvider.locale.languageCode;
    _didInitLocale = true;
  }

  Future<void> _loadSettings() async {
    final currency = await _storage.getBaseCurrency();
    final email = await _storage.getRecoveryEmail();
    
    setState(() {
      _currentCurrency = currency;
      _recoveryEmail = email;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_languageChanged && mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppConstants.routeHome,
            (route) => false,
          );
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.settings),
        ),
        body: ListView(
        children: [
          // App Section
          _buildSectionHeader(context, l10n.app),
          
          _buildSettingTile(
            context,
            title: l10n.language,
            subtitle: _getLanguageName(_currentLanguage),
            icon: Icons.language,
            onTap: () => _showLanguageDialog(l10n),
          ),
          
          _buildSettingTile(
            context,
            title: l10n.currency,
            subtitle: _currentCurrency,
            icon: Icons.attach_money,
            onTap: () => _showCurrencyDialog(l10n),
          ),
          
          const Divider(),
          
          // Security Section
          _buildSectionHeader(context, l10n.security),
          
          _buildSettingTile(
            context,
            title: l10n.changePin,
            icon: Icons.lock_outline,
            onTap: () {
              Navigator.pushNamed(context, AppConstants.routeChangePin);
            },
          ),
          
          _buildSettingTile(
            context,
            title: l10n.recoveryEmail,
            subtitle: _recoveryEmail ?? l10n.notSet,
            icon: Icons.email_outlined,
            onTap: () {
              Navigator.pushNamed(context, AppConstants.routeChangeEmail);
            },
          ),
          
          const Divider(),
          
          // AI Section
          _buildSectionHeader(context, l10n.aiFeatures),
          
          _buildSettingTile(
            context,
            title: l10n.geminiApiKey,
            subtitle: l10n.configureAi,
            icon: Icons.smart_toy_outlined,
            onTap: () => _showApiKeyDialog(l10n),
          ),
          
          const Divider(),
          
          // Data Visualization Section
          _buildSectionHeader(context, l10n.dataAndReports),
          
          _buildSettingTile(
            context,
            title: l10n.budgets,
            subtitle: l10n.monthlyBudget,
            icon: Icons.account_balance_wallet_outlined,
            onTap: () {
              Navigator.pushNamed(context, AppConstants.routeBudgets);
            },
          ),

          _buildSettingTile(
            context,
            title: l10n.scenarioSimulation,
            subtitle: l10n.simulateScenario,
            icon: Icons.trending_up_outlined,
            onTap: () {
              Navigator.pushNamed(context, AppConstants.routeScenarioSimulator);
            },
          ),

          _buildSettingTile(
            context,
            title: l10n.transactionMap,
            subtitle: l10n.viewLocationsOnMap,
            icon: Icons.map_outlined,
            onTap: () {
              Navigator.pushNamed(context, AppConstants.routeTransactionMap);
            },
          ),

          _buildSettingTile(
            context,
            title: l10n.bulkImportOcr,
            subtitle: l10n.bulkImportDesc,
            icon: Icons.auto_awesome_motion,
            onTap: () {
              Navigator.pushNamed(context, AppConstants.routeBulkImportOcr);
            },
          ),
          
          const Divider(),
          
          // Backup & Restore Section
          _buildSectionHeader(context, l10n.backup),
          
          _buildSettingTile(
            context,
            title: l10n.exportBackup,
            subtitle: l10n.exportBackupDesc,
            icon: Icons.backup_outlined,
            onTap: () => _showExportBackupDialog(l10n),
          ),
          
          _buildSettingTile(
            context,
            title: l10n.importBackup,
            subtitle: l10n.importBackupDesc,
            icon: Icons.restore_outlined,
            onTap: () => _showImportBackupDialog(l10n),
          ),

          _buildSettingTile(
            context,
            title: 'Export to CSV (Excel)',
            subtitle: 'Export data for email or spreadsheet apps',
            icon: Icons.table_chart_outlined,
            onTap: () async {
              try {
                await CsvService.instance.exportToCsv();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
                );
              }
            },
          ),
          
          const Divider(),
          
          // About Section
          _buildSectionHeader(context, l10n.about),
          
          _buildSettingTile(
            context,
            title: l10n.version,
            subtitle: AppConstants.appVersion,
            icon: Icons.info_outline,
          ),
          
          _buildSettingTile(
            context,
            title: l10n.developerNote,
            subtitle: l10n.developerNoteDesc,
            icon: Icons.code_outlined,
            onTap: () => _showDeveloperNote(context, l10n),
          ),
          
          _buildSettingTile(
            context,
            title: l10n.privacyPolicy,
            icon: Icons.shield_outlined,
            onTap: () => _showPrivacyPolicy(context),
          ),
          
          _buildSettingTile(
            context,
            title: l10n.termsOfUse,
            icon: Icons.description_outlined,
            onTap: () => _showTermsOfUse(context),
          ),
          
          const SizedBox(height: 32),
          
          // Danger Zone
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppButton(
              text: l10n.clearAllData,
              color: AppColors.error,
              onPressed: () => _showClearDataDialog(l10n),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
            ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: AppColors.textHint)
          : null,
      onTap: onTap,
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'th':
        return 'ไทย (Thai)';
      default:
        return code;
    }
  }

  void _showLanguageDialog(AppLocalizations l10n) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: _currentLanguage,
              onChanged: (value) async {
                if (value != null) {
                  await localeProvider.setLocale(Locale(value));
                  setState(() {
                    _currentLanguage = value;
                    _languageChanged = true;
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    // Force refresh by restarting at home to apply locale immediately
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppConstants.routeHome,
                      (route) => false,
                    );
                  }
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('ไทย (Thai)'),
              value: 'th',
              groupValue: _currentLanguage,
              onChanged: (value) async {
                if (value != null) {
                  await localeProvider.setLocale(Locale(value));
                  setState(() {
                    _currentLanguage = value;
                    _languageChanged = true;
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppConstants.routeHome,
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectCurrency),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppConstants.supportedCurrencies.map((currency) {
              return RadioListTile<String>(
                title: Text(currency),
                value: currency,
                groupValue: _currentCurrency,
                onChanged: (value) async {
                  if (value != null) {
                    await _storage.setBaseCurrency(value);
                    setState(() {
                      _currentCurrency = value;
                    });
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showApiKeyDialog(AppLocalizations l10n) {
    final controller = TextEditingController();
    final geminiService = GeminiService.instance;
    final aiAdvisor = AiFinancialAdvisorService.instance;
    
    // Load existing API key if available
    _storage.getGeminiApiKey().then((key) {
      if (key != null && mounted) {
        controller.text = key;
      }
    });
    
    showDialog(
      context: context,
      builder: (dialogContext) => _ApiKeyDialog(
        controller: controller,
        l10n: l10n,
        onSave: () async {
          final apiKey = controller.text.trim();
          if (apiKey.isEmpty) {
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(content: Text('Please enter an API key'), backgroundColor: AppColors.error),
            );
            return;
          }

          // Validate API key
          final isValid = await geminiService.validateApiKey(apiKey);
          
          if (!isValid) {
            if (dialogContext.mounted) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text(l10n.apiKeyInvalid),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            return;
          }

          // Save API key
          await geminiService.setApiKey(apiKey);
          await aiAdvisor.setApiKey(apiKey);
          
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.apiKeyValid),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    // Reuse logic from ConsentScreen if possible, or just copy-paste here if it's simpler
    showDialog(
      context: context,
      builder: (context) => const PrivacyPolicyDialog(),
    );
  }

  void _showTermsOfUse(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TermsOfUseDialog(),
    );
  }

  void _showDeveloperNote(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.code_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(l10n.developerNote),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.developerNoteDesc,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.developerNoteMessage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearAllData),
        content: Text(l10n.clearDataWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              // TODO: Implement data clearing
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data clear feature coming soon')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: Text(l10n.deleteAll),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportBackupDialog(AppLocalizations l10n) async {
    String pin = '';
    String? errorMessage;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.exportBackup),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter a 4-digit PIN to encrypt your backup',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: errorMessage != null
                              ? AppColors.error
                              : (index < pin.length ? AppColors.primary : AppColors.border),
                          width: 2,
                        ),
                        color: index < pin.length ? AppColors.primary : Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 270),
                child: PinNumpad(
                  onNumberTap: (number) {
                    if (pin.length < 4) {
                      setState(() {
                        pin += number;
                        errorMessage = null;
                      });
                    }
                  },
                  onBackspace: () {
                    if (pin.isNotEmpty) {
                      setState(() {
                        pin = pin.substring(0, pin.length - 1);
                        errorMessage = null;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: pin.length == 4
                  ? () => Navigator.pop(context, true)
                  : null,
              child: Text(l10n.export),
            ),
          ],
        ),
      ),
    );

    if (result == true && pin.length == 4) {
      try {
        final backupFile = await BackupService.instance.exportBackup(pin: pin);
        
        if (mounted) {
          // Verify file exists and path is valid
          if (!await backupFile.exists()) {
            throw Exception('Backup file was not created successfully');
          }
          
          final filePath = backupFile.path;
          if (filePath.isEmpty) {
            throw Exception('Invalid file path');
          }
          
          // Share the file
          await Share.shareXFiles(
            [XFile(filePath)],
            text: 'RoeyA Backup File - ${backupFile.path.split('/').last}',
            subject: 'RoeyA Backup',
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.backupSuccess}\n${backupFile.path.split('/').last}'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          debugPrint('Export backup error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.backupFailed}: ${e.toString()}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  /// Try to pick a backup file using file_picker, returns null if failed or cancelled
  Future<File?> _tryPickBackupFile(AppLocalizations l10n) async {
    _pickerWasCancelled = false;
    try {
      // Try file picker - file_picker 8.x handles permissions automatically
      FilePickerResult? result;
      try {
        // Use the most basic call to avoid platform-specific argument errors
        result = await FilePicker.platform.pickFiles(
          allowMultiple: false,
          // type: FileType.any is the default
        );
      } catch (e) {
        debugPrint('FilePicker primary failed: $e');
        // Final fallback attempt
        try {
          result = await FilePicker.platform.pickFiles();
        } catch (e2) {
          debugPrint('FilePicker final fallback failed: $e2');
          return null;
        }
      }

      if (result == null || result.files.isEmpty) {
        debugPrint('FilePicker: User cancelled');
        _pickerWasCancelled = true;
        return null;
      }

      final pickedFile = result.files.first;
      
      // Log what was picked
      debugPrint('FilePicker: Selected file - name: ${pickedFile.name}, path: ${pickedFile.path}, bytes: ${pickedFile.bytes?.length ?? 0}');
      
      // Notify user of what was picked (briefly)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected: ${pickedFile.name}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // Check extension but don't hard-fail if it's missing (just warn)
      // This allows importing even if the file was renamed or lost its extension
      final fileName = pickedFile.name.toLowerCase();
      final hasValidExtension = fileName.endsWith('.bak') || fileName.endsWith('.roeya');
      
      if (!hasValidExtension) {
        debugPrint('Import: ⚠️ File extension is not .bak or .roeya, but will try to proceed: ${pickedFile.name}');
      }

      // Priority 1: Try using bytes first (most reliable on Android)
      // This bypasses many OS permission issues with file paths
      if (pickedFile.bytes != null && pickedFile.bytes!.isNotEmpty) {
        try {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/import_backup_${DateTime.now().millisecondsSinceEpoch}.bak');
          await tempFile.writeAsBytes(pickedFile.bytes!);
          debugPrint('Import: ✅ Created temp file from bytes: ${tempFile.path} (${pickedFile.bytes!.length} bytes)');
          return tempFile;
        } catch (e) {
          debugPrint('Import: ❌ Error creating temp file from bytes: $e');
        }
      }
      
      // Priority 2: Try using file path
      if (pickedFile.path != null && pickedFile.path!.isNotEmpty) {
        try {
          final file = File(pickedFile.path!);
          if (await file.exists()) {
            debugPrint('Import: ✅ Using file path: ${file.path}');
            return file;
          } else {
            // Try to read anyway - sometimes exists() fails but readAsBytes() works on some URIs
            try {
              await file.readAsBytes();
              debugPrint('Import: ✅ File readable despite exists() returning false');
              return file;
            } catch (e) {
              debugPrint('Import: ❌ Cannot read file at path: $e');
            }
          }
        } catch (e) {
          debugPrint('Import: ❌ Error accessing file path: $e');
        }
      }
      
      // If we get here, both methods failed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Could not read file content.\nName: ${pickedFile.name}\nBytes: ${pickedFile.bytes?.length ?? 0}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Import: FilePicker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picker error: $e'), backgroundColor: AppColors.error),
        );
      }
      return null;
    }
  }

  // Helper to distinguish between user-cancelled and actual error
  bool _pickerWasCancelled = false;

  /// Show dialog for manual file path input
  Future<File?> _showManualPathDialog(AppLocalizations l10n) async {
    final pathController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Backup File Path'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the full path to your .bak or .roeya backup file:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Example:\n/storage/emulated/0/Download/roeya_backup_2025-01-01.bak',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pathController,
              decoration: const InputDecoration(
                hintText: '/storage/emulated/0/Download/...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              if (pathController.text.trim().isNotEmpty) {
                Navigator.pop(context, pathController.text.trim());
              }
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    
    if (result == null || result.isEmpty) return null;
    
    final lowerResult = result.toLowerCase();
    if (!lowerResult.endsWith('.bak') && !lowerResult.endsWith('.roeya')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('File must have .bak or .roeya extension'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
    
    // Check if file exists
    final file = File(result);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('File not found. Please check the path.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
    
    return file;
  }

  /// Scan Downloads folder for .roeya backup files
  Future<List<File>> _scanDownloadsForBackups() async {
    final List<File> backupFiles = [];
    
    // Common download paths on Android
    final paths = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/sdcard/Download',
      '/sdcard/Downloads',
    ];
    
    // Add internal app directory as well
    try {
      final appDir = await getApplicationDocumentsDirectory();
      paths.add(appDir.path);
    } catch (_) {}

    for (final path in paths) {
      try {
        final dir = Directory(path);
        if (await dir.exists()) {
          debugPrint('Scanning directory: $path');
          final List<FileSystemEntity> entities = await dir.list().toList();
          for (final entity in entities) {
            if (entity is File) {
              final lowerPath = entity.path.toLowerCase();
              if (lowerPath.endsWith('.bak') || lowerPath.endsWith('.roeya')) {
                debugPrint('Found backup: ${entity.path}');
                backupFiles.add(entity);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error scanning $path: $e');
      }
    }
    
    // Sort by modification date (newest first)
    backupFiles.sort((a, b) {
      try {
        return b.lastModifiedSync().compareTo(a.lastModifiedSync());
      } catch (_) {
        return 0;
      }
    });
    
    return backupFiles;
  }

  /// Show dialog to select from found backup files
  Future<File?> _showBackupFilesDialog(AppLocalizations l10n, List<File> files) async {
    final result = await showDialog<File>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Backup File'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final name = file.path.split('/').last;
              String dateStr = '';
              try {
                final date = file.lastModifiedSync();
                dateStr = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
              } catch (_) {}
              
              return ListTile(
                leading: const Icon(Icons.backup),
                title: Text(name, style: const TextStyle(fontSize: 14)),
                subtitle: Text(dateStr, style: const TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(context, file),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    
    return result;
  }

  Future<File> _copyFileToCache(File originalFile) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final fileName = 'import_${DateTime.now().millisecondsSinceEpoch}_${originalFile.path.split('/').last}';
      final cacheFile = File('${cacheDir.path}/$fileName');
      
      // Use readAsBytes and writeAsBytes to ensure we can read it if we have general storage permission
      final bytes = await originalFile.readAsBytes();
      await cacheFile.writeAsBytes(bytes);
      
      debugPrint('File copied to cache: ${cacheFile.path}');
      return cacheFile;
    } catch (e) {
      debugPrint('Error copying file to cache: $e');
      // If copying fails, return original and hope for the best (or let import fail)
      return originalFile;
    }
  }

  Future<void> _showImportBackupDialog(AppLocalizations l10n) async {
    // Try file picker first
    File? file = await _tryPickBackupFile(l10n);
    
    if (file == null) {
      // If the user just cancelled, don't show the error methods dialog
      if (_pickerWasCancelled) return;

      // File picker failed - show fallback options immediately
      if (mounted) {
        final choice = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select Backup Method'),
            content: const Text(
              'The file picker didn\'t work. Choose another method to select your backup file:',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'scan'),
                child: const Text('📂 Scan Downloads'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'manual'),
                child: const Text('✏️ Enter Path'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        );
        
        if (choice == 'scan') {
          // Show loading while scanning
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Scanning Downloads...'),
                ],
              ),
            ),
          );
          
          // Request permission first
          if (Platform.isAndroid) {
            final status = await Permission.manageExternalStorage.request();
            if (!status.isGranted) {
              if (mounted) {
                Navigator.pop(context); // Dismiss loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Storage permission is required to scan for backups.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
              return;
            }
          }
          
          final backups = await _scanDownloadsForBackups();
          
          // Dismiss loading
          if (mounted) Navigator.pop(context);
          
          if (backups.isEmpty) {
            if (mounted) {
              final tryManual = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('No Backup Files Found'),
                  content: const Text(
                    'No .bak or .roeya backup files were found in your Downloads or Documents folders.\n\nTips:\n1. Ensure your backup file ends with .bak\n2. Move the file to your Downloads folder\n3. Or enter the file path manually below.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Enter Path Manually'),
                    ),
                  ],
                ),
              );
              if (tryManual == true) {
                file = await _showManualPathDialog(l10n);
              }
            }
          } else {
            file = await _showBackupFilesDialog(l10n, backups);
          }
        } else if (choice == 'manual') {
          file = await _showManualPathDialog(l10n);
        }
        
        if (file == null) return;
      } else {
        return;
      }
    }

    // 2. Ask for PIN
    String pin = '';
    String? errorMessage;

    final pinResult = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.importBackup),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter the 4-digit PIN used to encrypt this backup',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: errorMessage != null
                              ? AppColors.error
                              : (index < pin.length ? AppColors.primary : AppColors.border),
                          width: 2,
                        ),
                        color: index < pin.length ? AppColors.primary : Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 270),
                child: PinNumpad(
                  onNumberTap: (number) {
                    if (pin.length < 4) {
                      setState(() {
                        pin += number;
                        errorMessage = null;
                        if (pin.length == 4) {
                          // Auto-submit when PIN is complete
                          Future.delayed(const Duration(milliseconds: 200), () {
                            if (mounted) {
                              Navigator.pop(context, pin);
                            }
                          });
                        }
                      });
                    }
                  },
                  onBackspace: () {
                    if (pin.isNotEmpty) {
                      setState(() {
                        pin = pin.substring(0, pin.length - 1);
                        errorMessage = null;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: pin.length == 4
                  ? () => Navigator.pop(context, pin)
                  : null,
              child: Text(l10n.import),
            ),
          ],
        ),
      ),
    );

    if (pinResult != null && pinResult.length == 4) {
      final enteredPin = pinResult;
      // 3. Confirm import
      final confirmResult = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.confirmImport),
          content: Text(l10n.importWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(l10n.import),
            ),
          ],
        ),
      );

      if (confirmResult == true) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        try {
          // Copy to internal cache first to solve permission issues
          final cachedFile = await _copyFileToCache(file);
          await BackupService.instance.importBackup(pin: enteredPin, backupFile: cachedFile);
          
          if (mounted) {
            // Dismiss loading indicator
            Navigator.pop(context);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.importSuccess),
                backgroundColor: AppColors.success,
              ),
            );
            // Reload settings
            _loadSettings();
          }
        } catch (e) {
          if (mounted) {
            // Dismiss loading indicator
            Navigator.pop(context);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${l10n.importFailed}: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    }
  }
}

class _ApiKeyDialog extends StatefulWidget {
  final TextEditingController controller;
  final AppLocalizations l10n;
  final VoidCallback onSave;

  const _ApiKeyDialog({
    required this.controller,
    required this.l10n,
    required this.onSave,
  });

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  bool _isValidating = false;
  String? _validationStatus;
  Color? _validationColor;
  String _currentText = '';

  @override
  void initState() {
    super.initState();
    _currentText = widget.controller.text;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.controller.text != _currentText) {
      setState(() {
        _currentText = widget.controller.text;
        _validationStatus = null;
      });
    }
  }

  Future<void> _validateKey() async {
    final apiKey = widget.controller.text.trim();
    if (apiKey.isEmpty) {
      setState(() {
        _validationStatus = null;
      });
      return;
    }
    
    if (!apiKey.startsWith('AIza')) {
      setState(() {
        _isValidating = false;
        _validationStatus = 'Invalid format. API key should start with "AIza"';
        _validationColor = AppColors.error;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _validationStatus = widget.l10n.validatingApiKey;
      _validationColor = Colors.blue;
    });

    try {
      final geminiService = GeminiService.instance;
      final isValid = await geminiService.validateApiKey(apiKey);

      if (mounted) {
        setState(() {
          _isValidating = false;
          if (isValid) {
            _validationStatus = widget.l10n.apiKeyValid;
            _validationColor = AppColors.success;
          } else {
            _validationStatus = '${widget.l10n.apiKeyInvalid}\n\nPlease check:\n• API key is copied correctly\n• API key has proper permissions\n• Internet connection is active';
            _validationColor = AppColors.error;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidating = false;
          _validationStatus = '${widget.l10n.apiKeyInvalid}\n\nError: ${e.toString()}';
          _validationColor = AppColors.error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.geminiApiKey),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.l10n.enterApiKey,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.controller,
            decoration: InputDecoration(
              labelText: widget.l10n.apiKeyHint,
              hintText: 'AIza...',
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: _isValidating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      onPressed: _isValidating ? null : _validateKey,
                      tooltip: 'Validate API Key',
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _validationStatus = null;
              });
            },
          ),
          if (_validationStatus != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _validationColor?.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _validationColor ?? Colors.grey,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _validationColor == AppColors.success ? Icons.check_circle : Icons.error,
                    size: 18,
                    color: _validationColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _validationStatus!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _validationColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Model: Gemini 2.5 Flash (Stable)',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Note: Gemini 3 Pro Preview may not be available in all regions',
            style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.l10n.cancel),
        ),
        TextButton(
          onPressed: widget.onSave,
          child: Text(widget.l10n.save),
        ),
      ],
    );
  }
}
