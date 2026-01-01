import 'package:flutter/material.dart';
import 'package:roeyp/core/constants/app_constants.dart';
import 'package:roeyp/core/localization/app_localizations.dart';
import 'package:roeyp/core/theme/app_colors.dart';
import 'package:roeyp/shared/widgets/app_button.dart';
import 'package:roeyp/shared/widgets/pin_numpad.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  String _pin = '';

  void _onNumberTap(String number) {
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createPin),
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
                  color: AppColors.primary,
                ),
                
                const SizedBox(height: 24),
                
                // Title
                Text(
                  l10n.createPin,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'Create a 4-digit PIN to secure your app',
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
                
                const SizedBox(height: 32),
                
                // Virtual Numpad
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: PinNumpad(
                    onNumberTap: _onNumberTap,
                    onBackspace: _onBackspace,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You\'ll need this PIN every time you open the app',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
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
    
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isFilled ? AppColors.primary : AppColors.border,
          width: 2,
        ),
        color: isFilled ? AppColors.primary : Colors.transparent,
      ),
      child: isFilled
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

  void _handlePinComplete(String pin) {
    Navigator.pushReplacementNamed(
      context,
      AppConstants.routeConfirmPin,
      arguments: pin,
    );
  }
}

