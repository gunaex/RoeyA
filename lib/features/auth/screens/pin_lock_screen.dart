import 'package:flutter/material.dart';
import 'package:roeyp/core/constants/app_constants.dart';
import 'package:roeyp/core/localization/app_localizations.dart';
import 'package:roeyp/core/services/secure_storage_service.dart';
import 'package:roeyp/core/theme/app_colors.dart';
import 'package:roeyp/shared/widgets/pin_numpad.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final SecureStorageService _storage = SecureStorageService.instance;
  
  String _pin = '';
  String? _errorMessage;
  bool _isLocked = false;
  DateTime? _lockoutEndTime;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  void _onNumberTap(String number) {
    if (_isLocked) return;
    
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
    if (_isLocked) return;
    
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _checkLockStatus() async {
    final isLocked = await _storage.isPinLocked();
    if (isLocked) {
      final endTime = await _storage.getPinLockoutEndTime();
      setState(() {
        _isLocked = true;
        _lockoutEndTime = endTime;
      });
      _startLockoutTimer();
    }
  }

  void _startLockoutTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      
      if (_lockoutEndTime != null && DateTime.now().isAfter(_lockoutEndTime!)) {
        setState(() {
          _isLocked = false;
          _lockoutEndTime = null;
        });
      } else if (_isLocked) {
        setState(() {}); // Refresh UI to update countdown
        _startLockoutTimer();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                
                // App Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isLocked ? AppColors.error : AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _isLocked ? Icons.lock_outline : Icons.lock_open_outlined,
                    size: 40,
                    color: AppColors.textInverse,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title
                Text(
                  _isLocked ? 'App Locked' : l10n.enterPin,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                if (_isLocked && _lockoutEndTime != null)
                  Text(
                    'Too many failed attempts\nTry again in ${_getRemainingTime()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    'Enter your PIN to continue',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                
                const SizedBox(height: 32),
                
                if (!_isLocked) ...[
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
                      enabled: !_isLocked,
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                if (!_isLocked)
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppConstants.routeForgotPin);
                    },
                    child: Text(l10n.forgotPin),
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

  String _getRemainingTime() {
    if (_lockoutEndTime == null) return '';
    
    final remaining = _lockoutEndTime!.difference(DateTime.now());
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handlePinComplete(String pin) async {
    final isValid = await _storage.verifyPin(pin);
    
    if (isValid) {
      await _storage.resetPinAttemptCount();
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppConstants.routeHome);
      }
    } else {
      await _storage.incrementPinAttemptCount();
      final attemptCount = await _storage.getPinAttemptCount();
      
      if (attemptCount >= AppConstants.maxPinAttempts) {
        await _storage.setLastPinAttemptTime(DateTime.now());
        await _checkLockStatus();
      }
      
      setState(() {
        _errorMessage = 'Incorrect PIN (${AppConstants.maxPinAttempts - attemptCount} attempts left)';
        _pin = '';
      });
    }
  }
}

