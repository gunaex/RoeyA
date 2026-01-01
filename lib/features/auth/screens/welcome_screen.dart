import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 60,
                  color: AppColors.textInverse,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // App Name
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'AI-First Personal Finance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Features
              Text(
                'Offline-First • Privacy-First • Minimal',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textHint,
                    ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Features List
              _buildFeatureItem(
                context,
                Icons.lock_outline,
                'Your data stays on your device',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                context,
                Icons.cloud_off_outlined,
                'Works offline, sync is optional',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                context,
                Icons.smart_toy_outlined,
                'AI-assisted (optional)',
              ),
              
              const SizedBox(height: 48),
              
              // Get Started Button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: l10n.getStarted,
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppConstants.routeConsent,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

