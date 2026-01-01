import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../shared/widgets/empty_state.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountRepository _accountRepo = AccountRepository();
  
  String _selectedCategory = AppConstants.categoryAssets;
  List<Account> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() { _isLoading = true; });
    try {
      final accounts = await _accountRepo.getAccountsByCategory(_selectedCategory);
      setState(() { _accounts = accounts; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accounts)),
      body: Column(
        children: [
          _buildCategoryTabs(context),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _accounts.isEmpty
                    ? EmptyState(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'No Accounts',
                        message: 'Add your first account to get started',
                        actionLabel: l10n.addAccount,
                        onAction: _showAddAccountDialog,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAccounts,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _accounts.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) => _buildAccountCard(_accounts[index]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Row(
          children: AppConstants.accountCategories.map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(_getCategoryLabel(l10n, category)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() { _selectedCategory = category; });
                    _loadAccounts();
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAccountCard(Account account) {
    return Card(
      child: InkWell(
        onTap: () => _showEditAccountDialog(account),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildCategoryIcon(account.category),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name, style: Theme.of(context).textTheme.titleLarge),
                    if (account.description != null) Text(account.description!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(account.balance, account.currencyCode),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(account.currencyCode, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(String category) {
    final color = _getCategoryColor(category);
    final icon = _getCategoryIconData(category);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color),
    );
  }

  void _showAddAccountDialog() async {
    final result = await _showAccountForm();
    if (result == true) _loadAccounts();
  }

  void _showEditAccountDialog(Account account) async {
    final result = await _showAccountForm(account: account);
    if (result == true) _loadAccounts();
  }

  Future<bool?> _showAccountForm({Account? account}) {
    final nameController = TextEditingController(text: account?.name);
    final descController = TextEditingController(text: account?.description);
    String category = account?.category ?? _selectedCategory;
    String currency = account?.currencyCode ?? 'THB';
    final l10n = AppLocalizations.of(context)!;
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(account == null ? l10n.addAccount : l10n.editAccount),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: l10n.accountName)),
              const SizedBox(height: 12),
              TextField(controller: descController, decoration: InputDecoration(labelText: l10n.description)),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setState) => DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(labelText: l10n.category),
                  items: AppConstants.accountCategories.map((c) => DropdownMenuItem(
                    value: c, 
                    child: Text(_getCategoryLabel(l10n, c))
                  )).toList(),
                  onChanged: (val) => setState(() => category = val!),
                ),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setState) => DropdownButtonFormField<String>(
                  value: currency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: AppConstants.supportedCurrencies.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c),
                  )).toList(),
                  onChanged: (val) => setState(() => currency = val!),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (account != null)
            TextButton(
              onPressed: () async {
                await _accountRepo.softDeleteAccount(account.id);
                if (context.mounted) Navigator.pop(context, true);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              
              final newAccount = Account(
                id: account?.id ?? const Uuid().v4(),
                name: nameController.text,
                category: category,
                description: descController.text,
                icon: account?.icon ?? 'wallet',
                currencyCode: currency,
                balance: account?.balance ?? 0.0,
                createdAt: account?.createdAt ?? DateTime.now(),
              );
              
              if (account == null) {
                await _accountRepo.insertAccount(newAccount);
              } else {
                await _accountRepo.updateAccount(newAccount);
              }
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Helpers (Extracted from RoeyP)
  String _getCategoryLabel(AppLocalizations l10n, String category) {
    if (category == AppConstants.categoryAssets) return l10n.assets;
    if (category == AppConstants.categoryLiabilities) return l10n.liabilities;
    if (category == AppConstants.categoryEquity) return l10n.equity;
    if (category == AppConstants.categoryRevenue || category == AppConstants.categoryIncome) return l10n.revenue;
    if (category == AppConstants.categoryExpense) return l10n.expense;
    return category;
  }

  Color _getCategoryColor(String category) {
    if (category == AppConstants.categoryAssets) return AppColors.assets;
    if (category == AppConstants.categoryLiabilities) return AppColors.liabilities;
    if (category == AppConstants.categoryEquity) return AppColors.equity;
    if (category == AppConstants.categoryRevenue || category == AppConstants.categoryIncome) return AppColors.success;
    if (category == AppConstants.categoryExpense) return AppColors.error;
    return AppColors.primary;
  }

  IconData _getCategoryIconData(String category) {
    if (category == AppConstants.categoryAssets) return Icons.account_balance_wallet_outlined;
    if (category == AppConstants.categoryLiabilities) return Icons.credit_card_outlined;
    if (category == AppConstants.categoryEquity) return Icons.pie_chart_outline;
    if (category == AppConstants.categoryRevenue || category == AppConstants.categoryIncome) return Icons.trending_up;
    if (category == AppConstants.categoryExpense) return Icons.trending_down;
    return Icons.account_balance_wallet;
  }
}
