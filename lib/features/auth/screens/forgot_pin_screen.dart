import 'package:flutter/material.dart';
import 'package:roeyp/core/constants/app_constants.dart';
import 'package:roeyp/core/localization/app_localizations.dart';
import 'package:roeyp/core/services/secure_storage_service.dart';
import 'package:roeyp/core/theme/app_colors.dart';
import 'package:roeyp/core/utils/validators.dart';
import 'package:roeyp/shared/widgets/app_button.dart';
import 'package:roeyp/shared/widgets/app_text_field.dart';

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.forgotPin),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  
                  // Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.help_outline,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    l10n.forgotPin,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  Text(
                    'Enter your recovery email to reset your PIN',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Email Field
                  AppTextField(
                    controller: _emailController,
                    label: l10n.recoveryEmail,
                    hint: 'Enter your recovery email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: Validators.validateEmail,
                  ),
                  
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  
                  const SizedBox(height: 48),
                  
                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Verify Email',
                      isLoading: _isLoading,
                      onPressed: _handleVerify,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final savedEmail = await SecureStorageService.instance.getRecoveryEmail();
      final inputEmail = _emailController.text.trim();

      if (savedEmail != null && savedEmail.toLowerCase() == inputEmail.toLowerCase()) {
        // Match! Proceed to reset PIN
        if (mounted) {
          // In a real app, we might send a code. 
          // For this offline MVP, we allow resetting if the email matches.
          Navigator.pushReplacementNamed(
            context,
            AppConstants.routeCreatePin,
          );
        }
      } else {
        setState(() {
          _error = 'Email does not match our records';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
