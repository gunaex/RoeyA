import 'package:flutter/material.dart';
import 'package:roeyp/core/constants/app_constants.dart';
import 'package:roeyp/core/localization/app_localizations.dart';
import 'package:roeyp/core/services/secure_storage_service.dart';
import 'package:roeyp/core/theme/app_colors.dart';
import 'package:roeyp/shared/widgets/app_button.dart';
import 'package:roeyp/shared/widgets/pin_numpad.dart';

class ConfirmPinScreen extends StatefulWidget {
  final String originalPin;

  const ConfirmPinScreen({super.key, required this.originalPin});

  @override
  State<ConfirmPinScreen> createState() => _ConfirmPinScreenState();
}

class _ConfirmPinScreenState extends State<ConfirmPinScreen> {
  String _pin = '';
  String? _errorMessage;

  void _onNumberTap(String number) {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
    
    if (_pin.length < AppConstants.pinLength) {
      setState(() {
        _pin += number;
      });
      
      if (_pin.length == AppConstants.pinLength) {
        _handlePinComplete(_pin);
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.confirmPin),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                
                // Icon
                Icon(
                  Icons.lock_outline,
                  size: 64, // Slightly smaller icon
                  color: _errorMessage != null ? AppColors.error : AppColors.primary,
                ),
                
                const SizedBox(height: 24),
                
                // Title
                Text(
                  l10n.confirmPin,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'Enter the same PIN again',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // PIN Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    AppConstants.pinLength,
                    (index) => _buildPinDot(index),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Error Message
                SizedBox(
                  height: 24,
                  child: _errorMessage != null
                      ? Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.error,
                              ),
                        )
                      : null,
                ),
                
                const SizedBox(height: 12),
                
                // Virtual Numpad
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: PinNumpad(
                    onNumberTap: _onNumberTap,
                    onBackspace: _onBackspace,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: l10n.next,
                    onPressed: _pin.length == AppConstants.pinLength
                        ? () => _handlePinComplete(_pin)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinDot(int index) {
    final isFilled = index < _pin.length;
    final hasError = _errorMessage != null;
    
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: hasError
              ? AppColors.error
              : (isFilled ? AppColors.primary : AppColors.border),
          width: 2,
        ),
        color: hasError
            ? AppColors.error.withOpacity(0.1)
            : (isFilled ? AppColors.primary : Colors.transparent),
      ),
      child: isFilled && !hasError
          ? const Center(
              child: Icon(
                Icons.circle,
                size: 16,
                color: AppColors.textInverse,
              ),
            )
          : null,
    );
  }

  Future<void> _handlePinComplete(String pin) async {
    if (pin != widget.originalPin) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.pinMismatch;
        _pin = '';
      });
      return;
    }

    // Save PIN
    await SecureStorageService.instance.savePin(pin);

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppConstants.routeRecoveryEmail,
      );
    }
  }
}

