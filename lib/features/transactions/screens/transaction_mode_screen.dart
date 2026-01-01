import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class TransactionModeScreen extends StatelessWidget {
  const TransactionModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addTransaction),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.howToAddTransaction,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            const SizedBox(height: 16),
            
            // Scan Slip with OCR (ML Kit - NEW!)
            _buildModeCard(
              context,
              title: l10n.scanSlipOcr,
              subtitle: l10n.scanSlipOcrDesc,
              icon: Icons.document_scanner,
              color: AppColors.success,
              isEnabled: true,
              onTap: () async {
                final result = await Navigator.pushNamed(
                  context,
                  AppConstants.routeScanSlip,
                );
                print('🔙 Returned to TransactionMode. Result: $result');
                // Forward result to dashboard
                if (result == true && context.mounted) {
                  print('✅ Forwarding result=true to Dashboard');
                  Navigator.pop(context, true);
                } else {
                  print('❌ Not forwarding result (result: $result)');
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Manual Entry Option
            _buildModeCard(
              context,
              title: l10n.manualEntry,
              subtitle: l10n.manualEntryDesc,
              icon: Icons.edit_outlined,
              color: AppColors.secondary,
              isEnabled: true,
              onTap: () async {
                final result = await Navigator.pushNamed(
                  context,
                  AppConstants.routeManualEntry,
                );
                // Forward result to dashboard
                if (result == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    String? disabledMessage,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: color,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  isEnabled ? subtitle : (disabledMessage ?? subtitle),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isEnabled
                            ? AppColors.textSecondary
                            : AppColors.error,
                      ),
                  textAlign: TextAlign.center,
                ),
                
                if (!isEnabled) ...[
                  const SizedBox(height: 12),
                  const Icon(
                    Icons.lock_outline,
                    size: 20,
                    color: AppColors.error,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
