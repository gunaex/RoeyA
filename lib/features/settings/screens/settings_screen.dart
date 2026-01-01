import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roeyp/core/constants/app_constants.dart';
import 'package:roeyp/core/localization/app_localizations.dart';
import 'package:roeyp/core/localization/locale_provider.dart';
import 'package:roeyp/core/services/secure_storage_service.dart';
import 'package:roeyp/core/services/gemini_service.dart';
import 'package:roeyp/core/services/ai_financial_advisor_service.dart';
import 'package:roeyp/core/theme/app_colors.dart';
import 'package:roeyp/features/consent/screens/consent_screen.dart';
import '../../../shared/widgets/app_button.dart';

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
