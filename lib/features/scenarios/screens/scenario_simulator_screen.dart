import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/ai_financial_advisor_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/decimal_text_input_formatter.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class ScenarioSimulatorScreen extends StatefulWidget {
  const ScenarioSimulatorScreen({super.key});

  @override
  State<ScenarioSimulatorScreen> createState() => _ScenarioSimulatorScreenState();
}

class _ScenarioSimulatorScreenState extends State<ScenarioSimulatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _txRepo = TransactionRepository();
  final _aiAdvisor = AiFinancialAdvisorService.instance;
  
  final _incomeController = TextEditingController();
  final _expenseController = TextEditingController();
  final _targetSavingController = TextEditingController();
  final _targetAmountController = TextEditingController(); // New: Target purchase amount
  final _timeframeController = TextEditingController(); // New: Timeframe in months
  
  Map<String, double> _categoryReductions = {}; // category -> percentage
  String? _simulationResult;
  bool _isLoading = false;
  bool _isLoadingData = true;
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  String _simulationType = 'saving'; // 'saving' or 'purchase'

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _expenseController.dispose();
    _targetSavingController.dispose();
    _targetAmountController.dispose();
    _timeframeController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentData() async {
    try {
      final monthly = await _txRepo.getMonthlySummary(_year, _month);
      final income = monthly['income'] ?? 0.0;
      final expense = monthly['expense'] ?? 0.0;
      
      if (mounted) {
        setState(() {
          _incomeController.text = income > 0 ? income.toStringAsFixed(2) : '';
          _expenseController.text = expense > 0 ? expense.toStringAsFixed(2) : '';
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('Error loading current data: $e');
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _simulate() async {
    if (!_formKey.currentState!.validate() || !_aiAdvisor.isConfigured) return;
    
    setState(() {
      _isLoading = true;
      _simulationResult = null;
    });
    
    try {
      final income = double.tryParse(_incomeController.text) ?? 0.0;
      final expense = double.tryParse(_expenseController.text) ?? 0.0;
      final targetSaving = _targetSavingController.text.isNotEmpty
          ? double.tryParse(_targetSavingController.text)
          : null;
      final targetAmount = _targetAmountController.text.isNotEmpty
          ? double.tryParse(_targetAmountController.text)
          : null;
      final timeframe = _timeframeController.text.isNotEmpty
          ? int.tryParse(_timeframeController.text)
          : null;
      
      final categoryReductions = _categoryReductions.isNotEmpty
          ? _categoryReductions
          : null;
      
      final locale = Localizations.localeOf(context);
      final language = locale.languageCode;
      
      final result = await _aiAdvisor.simulateScenario(
        currentIncome: income,
        currentExpense: expense,
        targetSaving: targetSaving,
        targetPurchaseAmount: targetAmount,
        timeframeMonths: timeframe,
        categoryReductions: categoryReductions,
        language: language,
      );
      
      if (mounted) {
        setState(() {
          _simulationResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error simulating scenario: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to simulate scenario')),
        );
      }
    }
  }

  Future<void> _showCategoryReductionDialog() async {
    final l10n = AppLocalizations.of(context)!;
    String? selectedCategory;
    final percentageController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reduceCategory),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: l10n.category,
                  border: OutlineInputBorder(),
                ),
                value: selectedCategory,
                items: AppConstants.expenseCategories.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(l10n.getCategoryName(cat)),
                )).toList(),
                onChanged: (value) => setState(() => selectedCategory = value),
              ),
              SizedBox(height: 16),
              TextField(
                controller: percentageController,
                decoration: InputDecoration(
                  labelText: l10n.reductionPercentage,
                  hintText: '0-100',
                  border: OutlineInputBorder(),
                  suffixText: '%',
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
              if (selectedCategory != null && percentageController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    
    if (result == true && selectedCategory != null && percentageController.text.isNotEmpty) {
      final percentage = double.tryParse(percentageController.text);
      if (percentage != null && percentage >= 0 && percentage <= 100) {
        setState(() {
          _categoryReductions[selectedCategory!] = percentage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.scenarioSimulation)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scenarioSimulation),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Current Situation Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Situation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _incomeController,
                      label: l10n.currentIncome,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.arrow_downward, color: AppColors.success),
                      inputFormatters: [DecimalTextInputFormatter(decimalPlaces: 2)],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter income';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _expenseController,
                      label: l10n.currentExpense,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.arrow_upward, color: AppColors.error),
                      inputFormatters: [DecimalTextInputFormatter(decimalPlaces: 2)],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter expense';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Goals Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Goals',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Simulation Type Toggle
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'saving', label: Text(l10n.savingGoal), icon: const Icon(Icons.savings_outlined)),
                        ButtonSegment(value: 'purchase', label: Text(l10n.purchaseGoal), icon: const Icon(Icons.shopping_bag_outlined)),
                      ],
                      selected: {_simulationType},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _simulationType = newSelection.first;
                          if (_simulationType == 'saving') {
                            _targetAmountController.clear();
                            _timeframeController.clear();
                          } else {
                            _targetSavingController.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Conditional inputs based on simulation type
                    if (_simulationType == 'saving') ...[
                      AppTextField(
                        controller: _targetSavingController,
                        label: l10n.targetSaving,
                        hint: 'Optional - Monthly saving target',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: const Icon(Icons.savings_outlined),
                        inputFormatters: [DecimalTextInputFormatter(decimalPlaces: 2)],
                      ),
                    ] else ...[
                      AppTextField(
                        controller: _targetAmountController,
                        label: l10n.targetPurchaseAmount,
                        hint: 'e.g., 100000',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: const Icon(Icons.shopping_bag_outlined),
                        inputFormatters: [DecimalTextInputFormatter(decimalPlaces: 2)],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final amount = double.tryParse(value);
                            if (amount == null || amount <= 0) {
                              return 'Please enter a valid amount';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _timeframeController,
                        label: l10n.timeframeMonths,
                        hint: 'e.g., 6 (for 6 months)',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final months = int.tryParse(value);
                            if (months == null || months <= 0) {
                              return 'Please enter valid months (1-120)';
                            }
                            if (months > 120) {
                              return 'Maximum 120 months';
                            }
                          } else if (_targetAmountController.text.isNotEmpty) {
                            return 'Timeframe required when target amount is set';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_categoryReductions.isNotEmpty) ...[
                      Text(
                        l10n.reduceCategory,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      ..._categoryReductions.entries.map((entry) {
                        return ListTile(
                          leading: const Icon(Icons.category_outlined),
                          title: Text(l10n.getCategoryName(entry.key)),
                          subtitle: Text('Reduce by ${entry.value.toStringAsFixed(1)}%'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _categoryReductions.remove(entry.key);
                              });
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(l10n.reduceCategory),
                      onPressed: _showCategoryReductionDialog,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Simulate Button
            AppButton(
              text: l10n.simulateScenario,
              isLoading: _isLoading,
              onPressed: _aiAdvisor.isConfigured ? _simulate : null,
            ),
            
            if (!_aiAdvisor.isConfigured) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.configureAiToEnable,
                        style: TextStyle(color: Colors.orange[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Simulation Result
            if (_simulationResult != null) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                color: AppColors.primary.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 24, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            l10n.feasibility,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _simulationResult!,
                        style: const TextStyle(fontSize: 14, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

