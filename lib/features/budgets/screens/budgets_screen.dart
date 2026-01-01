import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roeyp/core/constants/app_constants.dart';
import 'package:roeyp/core/localization/app_localizations.dart';
import 'package:roeyp/core/utils/currency_formatter.dart';
import 'package:roeyp/data/models/budget.dart';
import 'package:roeyp/data/repositories/budget_repository.dart';
import 'package:roeyp/data/repositories/transaction_repository.dart';
import 'package:uuid/uuid.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _budgetRepo = BudgetRepository();
  final _txRepo = TransactionRepository();
  
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  List<Budget> _budgets = [];
  Map<String, double> _actuals = {}; // category -> actual amount
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final budgets = await _budgetRepo.getCategoryBudgets(_year, _month);
      
      // Load actual spending for each category
      final expenseCats = await _txRepo.getCategoryBreakdown('expense', _year, _month);
      final actualsMap = <String, double>{};
      for (var cat in expenseCats) {
        final catName = cat['category']?.toString();
        final total = (cat['total'] as num?)?.toDouble() ?? 0.0;
        if (catName != null) {
          actualsMap[catName] = total;
        }
      }
      
      if (mounted) {
        setState(() {
          _budgets = budgets;
          _actuals = actualsMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading budgets: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddBudgetDialog() async {
    final l10n = AppLocalizations.of(context)!;
    
    String? selectedCategory;
    final amountController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.setBudget),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Month selector
              ListTile(
                title: Text(l10n.selectMonth),
                subtitle: Text('${_year}-${_month.toString().padLeft(2, '0')}'),
                trailing: Icon(Icons.calendar_today),
              ),
              Divider(),
              
              // Category selector
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: l10n.category,
                  border: OutlineInputBorder(),
                ),
                value: selectedCategory,
                items: [
                  ...AppConstants.expenseCategories.map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(l10n.getCategoryName(cat)),
                  )),
                ],
                onChanged: (value) => setState(() => selectedCategory = value),
              ),
              SizedBox(height: 16),
              
              // Amount input
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: l10n.budgetAmount,
                  border: OutlineInputBorder(),
                  prefixText: '฿ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              if (selectedCategory != null && amountController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    
    if (result == true && selectedCategory != null && amountController.text.isNotEmpty) {
      final amount = double.tryParse(amountController.text);
      if (amount != null && amount > 0) {
        final budget = Budget(
          id: const Uuid().v4(),
          year: _year,
          month: _month,
          category: selectedCategory,
          amount: amount,
          currencyCode: 'THB',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _budgetRepo.upsertBudget(budget);
        await _load();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.savedSuccessfully)),
          );
        }
      }
    }
  }

  Future<void> _deleteBudget(Budget budget) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteBudget),
        content: Text('${l10n.delete} ${l10n.getCategoryName(budget.category ?? '')}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    
    if (result == true) {
      await _budgetRepo.deleteBudget(budget.id);
      await _load();
    }
  }

  Widget _buildBudgetCard(Budget budget) {
    final l10n = AppLocalizations.of(context)!;
    final actual = _actuals[budget.category] ?? 0.0;
    final usage = budget.amount > 0 ? (actual / budget.amount) : 0.0;
    final isOverBudget = usage > 1.0;
    final isWarning = usage > 0.8;
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(l10n.getCategoryName(budget.category ?? '')),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${l10n.budget}: ${CurrencyFormatter.format(budget.amount, budget.currencyCode)}'),
                Text('${l10n.expense}: ${CurrencyFormatter.format(actual, budget.currencyCode)}'),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: usage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? Colors.red : (isWarning ? Colors.orange : Colors.green),
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${(usage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: isOverBudget ? Colors.red : (isWarning ? Colors.orange : Colors.green),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () => _deleteBudget(budget),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final monthName = DateFormat('MMMM yyyy').format(DateTime(_year, _month));
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.budgets),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              setState(() {
                if (_month == 1) {
                  _month = 12;
                  _year--;
                } else {
                  _month--;
                }
              });
              _load();
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: Text(monthName)),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios),
            onPressed: () {
              setState(() {
                if (_month == 12) {
                  _month = 1;
                  _year++;
                } else {
                  _month++;
                }
              });
              _load();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _budgets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(l10n.noBudgetSet),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: _showAddBudgetDialog,
                        child: Text(l10n.setBudget),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _budgets.length,
                    itemBuilder: (context, index) => _buildBudgetCard(_budgets[index]),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBudgetDialog,
        child: Icon(Icons.add),
        tooltip: l10n.setBudget,
      ),
    );
  }
}

