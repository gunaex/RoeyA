import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction.dart' as model;

class RenewalReminderWidget extends StatelessWidget {
  final List<model.Transaction> subscriptions;

  const RenewalReminderWidget({super.key, required this.subscriptions});

  List<Map<String, dynamic>> _getUpcomingRenewals() {
    final now = DateTime.now();
    final upcoming = <Map<String, dynamic>>[];

    for (var sub in subscriptions) {
      DateTime? nextBilling;
      
      // Calculate next billing date based on frequency
      if (sub.frequency == 'monthly') {
        nextBilling = DateTime(now.year, now.month + 1, sub.transactionDate.day);
      } else if (sub.frequency == 'yearly') {
        nextBilling = DateTime(now.year + 1, sub.transactionDate.month, sub.transactionDate.day);
      } else if (sub.frequency == 'weekly') {
        nextBilling = now.add(const Duration(days: 7));
      }

      if (nextBilling != null) {
        final daysUntil = nextBilling.difference(now).inDays;
        if (daysUntil >= 0) {
          upcoming.add({
            'subscription': sub,
            'daysUntil': daysUntil,
            'nextBilling': nextBilling,
          });
        }
      }
    }

    upcoming.sort((a, b) => (a['daysUntil'] as int).compareTo(b['daysUntil'] as int));
    return upcoming.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final upcoming = _getUpcomingRenewals();

    if (upcoming.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: AppColors.warning.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  l10n.upcomingRenewals,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...upcoming.map((item) => _buildRenewalItem(context, item, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildRenewalItem(
      BuildContext context, Map<String, dynamic> item, AppLocalizations l10n) {
    final sub = item['subscription'] as model.Transaction;
    final daysUntil = item['daysUntil'] as int;

    String daysText;
    if (daysUntil == 0) {
      daysText = l10n.today;
    } else if (daysUntil == 1) {
      daysText = l10n.tomorrow;
    } else {
      daysText = l10n.inDays.replaceAll('{days}', daysUntil.toString());
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: daysUntil <= 2 ? AppColors.error : AppColors.warning,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.description ?? 'Subscription',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${CurrencyFormatter.format(sub.amount, sub.currencyCode)} • $daysText',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.calendar_today,
            size: 16,
            color: AppColors.textHint,
          ),
        ],
      ),
    );
  }
}
