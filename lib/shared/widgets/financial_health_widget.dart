import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class FinancialHealthWidget extends StatelessWidget {
  final Map<String, double> categorySummary;
  final double netWorth;

  const FinancialHealthWidget({
    super.key,
    required this.categorySummary,
    required this.netWorth,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    final assets = categorySummary['assets'] ?? 0.0;
    final liabilities = categorySummary['liabilities'] ?? 0.0;
    final equity = categorySummary['equity'] ?? 0.0;
    final revenue = categorySummary['revenue'] ?? 0.0;
    final expense = categorySummary['expense'] ?? 0.0;

    return Column(
      children: [
        // Financial Health Score
        _buildHealthScore(context, l10n, assets, liabilities),
        const SizedBox(height: 16),
        
        // Category Breakdown Donut Chart
        _buildCategoryDonut(context, l10n, categorySummary),
        const SizedBox(height: 16),
        
        // Cash Flow Indicator
        _buildCashFlowIndicator(context, l10n, revenue, expense),
      ],
    );
  }

  Widget _buildHealthScore(BuildContext context, AppLocalizations l10n, 
      double assets, double liabilities) {
    final healthScore = liabilities > 0 
        ? ((assets / (assets + liabilities)) * 100).clamp(0, 100)
        : 100.0;
    
    Color scoreColor;
    String scoreLabel;
    if (healthScore >= 80) {
      scoreColor = AppColors.success;
      scoreLabel = l10n.excellent;
    } else if (healthScore >= 60) {
      scoreColor = AppColors.warning;
      scoreLabel = l10n.good;
    } else {
      scoreColor = AppColors.error;
      scoreLabel = l10n.needsAttention;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: healthScore / 100,
                    strokeWidth: 8,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(scoreColor),
                  ),
                  Text(
                    '${healthScore.toInt()}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.financialHealthScore,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scoreLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.getCategoryName('assets')}: ${CurrencyFormatter.format(assets, 'THB')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  Text(
                    '${l10n.getCategoryName('liabilities')}: ${CurrencyFormatter.format(liabilities, 'THB')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDonut(BuildContext context, AppLocalizations l10n,
      Map<String, double> summary) {
    final sections = <PieChartSectionData>[];
    final colors = {
      'assets': AppColors.assets,
      'liabilities': AppColors.liabilities,
      'equity': AppColors.equity,
      'revenue': AppColors.income,
      'expense': AppColors.expense,
    };

    summary.forEach((key, value) {
      if (value > 0) {
        sections.add(PieChartSectionData(
          value: value,
          color: colors[key] ?? AppColors.primary,
          radius: 60,
          title: '',
        ));
      }
    });

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.accountDistribution,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashFlowIndicator(BuildContext context, AppLocalizations l10n,
      double revenue, double expense) {
    final netCashFlow = revenue - expense;
    final isPositive = netCashFlow >= 0;

    return Card(
      elevation: 0,
      color: (isPositive ? AppColors.success : AppColors.error).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: (isPositive ? AppColors.success : AppColors.error).withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              size: 40,
              color: isPositive ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.netCashFlow,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(netCashFlow.abs(), 'THB'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isPositive ? AppColors.success : AppColors.error,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPositive ? l10n.surplus : l10n.deficit,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
