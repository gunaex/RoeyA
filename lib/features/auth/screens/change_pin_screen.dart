import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/pin_numpad.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final SecureStorageService _storage = SecureStorageService.instance;
  
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  String? _errorMessage;
  int _step = 1; // 1 = current PIN, 2 = new PIN, 3 = confirm PIN

  void _onNumberTap(String number) {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
    
    String activePin = _step == 1 ? _currentPin : (_step == 2 ? _newPin : _confirmPin);
    
    if (activePin.length < AppConstants.pinLength) {
      setState(() {
        if (_step == 1) {
          _currentPin += number;
        } else if (_step == 2) {
          _newPin += number;
        } else {
          _confirmPin += number;
        }
      });
      
      activePin = _step == 1 ? _currentPin : (_step == 2 ? _newPin : _confirmPin);
      
      if (activePin.length == AppConstants.pinLength) {
        _handlePinComplete(activePin);
      }
    }
  }

  void _onBackspace() {
    setState(() {
      if (_step == 1 && _currentPin.isNotEmpty) {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      } else if (_step == 2 && _newPin.isNotEmpty) {
        _newPin = _newPin.substring(0, _newPin.length - 1);
      } else if (_step == 3 && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      }
      _errorMessage = null;
    });
  }

  Future<void> _handlePinComplete(String pin) async {
    if (_step == 1) {
      // Verify current PIN
      final isValid = await _storage.verifyPin(pin);
      if (!isValid) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.incorrectPin;
          _currentPin = '';
        });
        return;
      }
      // Move to step 2
      setState(() {
        _step = 2;
        _currentPin = pin;
      });
    } else if (_step == 2) {
      // Move to step 3
      setState(() {
        _step = 3;
        _newPin = pin;
      });
    } else {
      // Confirm new PIN
      if (pin != _newPin) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.pinMismatch;
          _confirmPin = '';
        });
        return;
      }
      // Save new PIN
      await _storage.savePin(pin);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pinChangedSuccessfully),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  String _getActivePin() {
    return _step == 1 ? _currentPin : (_step == 2 ? _newPin : _confirmPin);
  }

  String _getTitle() {
    final l10n = AppLocalizations.of(context)!;
    if (_step == 1) return l10n.enterCurrentPin;
    if (_step == 2) return l10n.createNewPin;
    return l10n.confirmNewPin;
  }

  String _getSubtitle() {
    final l10n = AppLocalizations.of(context)!;
    if (_step == 1) return l10n.enterCurrentPinToContinue;
    if (_step == 2) return l10n.createNewPinDescription;
    return l10n.confirmNewPinDescription;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activePin = _getActivePin();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.changePin),
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
                  size: 64,
                  color: AppColors.primary,
                ),
                
                const SizedBox(height: 24),
                
                // Title
                Text(
                  _getTitle(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  _getSubtitle(),
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
                    (index) => _buildPinDot(index, activePin),
                  ),
                ),
                
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinDot(int index, String pin) {
    final isFilled = index < pin.length;
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
}

