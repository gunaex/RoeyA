import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction.dart' as model;
import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/transaction_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AccountRepository _accountRepo = AccountRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();
  
  double _netWorth = 0.0;
  Map<String, double> _categorySummary = {};
  List<model.Transaction> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final netWorth = await _accountRepo.getNetWorth();
      final summary = await _accountRepo.getCategorySummary();
      final recent = await _transactionRepo.getRecentTransactions(limit: 5);
      
      setState(() {
        _netWorth = netWorth;
        _categorySummary = summary;
        _recentTransactions = recent;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final connectivity = Provider.of<ConnectivityService>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmationDialog(context, l10n);
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appName),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: l10n.search,
              onPressed: () {
                Navigator.pushNamed(context, AppConstants.routeSearchTransactions);
              },
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart_outlined),
              tooltip: l10n.reports,
              onPressed: () {
                Navigator.pushNamed(context, AppConstants.routeReports);
              },
            ),
            // Online/Offline Indicator (icon only)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(
                connectivity.isOnline
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                size: 20,
                color: connectivity.isOnline
                    ? AppColors.success
                    : AppColors.textHint,
              ),
            ),
            
            // Settings
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.pushNamed(context, AppConstants.routeSettings);
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Net Worth Card
                      _buildNetWorthCard(context, l10n),
                      
                      const SizedBox(height: 24),
                      
                      // Category Summary
                      _buildSectionHeader(context, l10n.accounts, l10n.viewAll, () {
                        Navigator.pushNamed(context, AppConstants.routeAccounts);
                      }),
                      const SizedBox(height: 12),
                      _buildCategorySummaryGrid(context, l10n),
                      
                      const SizedBox(height: 24),
                      
                      // Recent Transactions
                      _buildSectionHeader(context, l10n.recentTransactions, l10n.viewAll, () {
                        // TODO: Navigate to transactions list
                      }),
                      const SizedBox(height: 12),
                      _buildRecentTransactionsList(context, l10n),
                      
                      const SizedBox(height: 80), // Bottom padding
                    ],
                  ),
                ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.pushNamed(context, AppConstants.routeTransactionMode);
            if (result == true) {
              _loadData();
            }
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.addTransaction),
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context, AppLocalizations l10n) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.appName),
            content: Text(l10n.exitConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.no),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.yes),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildSectionHeader(BuildContext context, String title, String actionLabel, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ],
    );
  }

  Widget _buildNetWorthCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      color: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.netWorth,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(_netWorth, 'THB'),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${l10n.assets} - ${l10n.liabilities}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySummaryGrid(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        _buildCategoryItem(
          context,
          l10n.assets,
          _categorySummary[AppConstants.categoryAssets] ?? 0.0,
          Icons.account_balance_wallet_outlined,
          AppColors.assets,
        ),
        const SizedBox(height: 8),
        _buildCategoryItem(
          context,
          l10n.equity,
          _categorySummary[AppConstants.categoryEquity] ?? 0.0,
          Icons.pie_chart_outline,
          AppColors.equity,
        ),
        const SizedBox(height: 8),
        _buildCategoryItem(
          context,
          l10n.revenue,
          _categorySummary[AppConstants.categoryRevenue] ?? 0.0,
          Icons.trending_up,
          AppColors.success,
        ),
        const SizedBox(height: 8),
        _buildCategoryItem(
          context,
          l10n.expense,
          _categorySummary[AppConstants.categoryExpense] ?? 0.0,
          Icons.trending_down,
          AppColors.error,
        ),
        const SizedBox(height: 8),
        _buildCategoryItem(
          context,
          l10n.liabilities,
          _categorySummary[AppConstants.categoryLiabilities] ?? 0.0,
          Icons.credit_card_outlined,
          AppColors.liabilities,
        ),
      ],
    );
  }

  Widget _buildCategoryItem(BuildContext context, String title, double amount, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    CurrencyFormatter.format(amount, 'THB'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            context,
            l10n.scanSlip,
            Icons.qr_code_scanner,
            AppColors.primary,
            () => Navigator.pushNamed(context, AppConstants.routeScanSlip),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionButton(
            context,
            l10n.manualEntry,
            Icons.edit_note,
            AppColors.secondary,
            () => Navigator.pushNamed(context, AppConstants.routeManualEntry),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionButton(
            context,
            l10n.mapView,
            Icons.map_outlined,
            AppColors.primary,
            () => Navigator.pushNamed(context, AppConstants.routeTransactionMap),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsList(BuildContext context, AppLocalizations l10n) {
    if (_recentTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Text(l10n.noDataAvailable, style: TextStyle(color: AppColors.textHint)),
        ),
      );
    }

    return Column(
      children: _recentTransactions.map((tx) => _buildTransactionItem(context, tx)).toList(),
    );
  }

  Widget _buildTransactionItem(BuildContext context, model.Transaction tx) {
    final bool isIncome = tx.type == 'income';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isIncome ? AppColors.success : AppColors.error).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isIncome ? Icons.add : Icons.remove,
          color: isIncome ? AppColors.success : AppColors.error,
          size: 20,
        ),
      ),
      title: Text(tx.description ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${tx.transactionDate.day}/${tx.transactionDate.month}/${tx.transactionDate.year}'),
      trailing: Text(
        '${isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amount, tx.currencyCode)}',
        style: TextStyle(
          color: isIncome ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () async {
        final result = await Navigator.pushNamed(
          context,
          AppConstants.routeTransactionDetail,
          arguments: tx.id,
        );
        if (result == true) {
          _loadData();
        }
      },
    );
  }
}
