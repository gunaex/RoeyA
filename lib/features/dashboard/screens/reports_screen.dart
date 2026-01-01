import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/ai_financial_advisor_service.dart';
import '../../../data/repositories/transaction_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TransactionRepository _txRepo = TransactionRepository();
  final AiFinancialAdvisorService _aiAdvisor = AiFinancialAdvisorService.instance;
  
  bool _isLoading = true;
  bool _isLoadingAi = false;
  Map<String, double> _monthly = {'income': 0, 'expense': 0};
  List<Map<String, dynamic>> _incomeCats = [];
  List<Map<String, dynamic>> _expenseCats = [];
  String? _aiSuggestions;
  late int _year;
  late int _month;

  // Colors for pie chart segments
  final List<Color> _chartColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF22C55E), // Green
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFEF4444), // Red
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFF14B8A6), // Teal
    const Color(0xFFF97316), // Orange
    const Color(0xFF64748B), // Slate
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _aiAdvisor.initialize();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final monthly = await _txRepo.getMonthlySummary(_year, _month);
      final incomeCats = await _txRepo.getCategoryBreakdown('income', _year, _month);
      final expenseCats = await _txRepo.getCategoryBreakdown('expense', _year, _month);
      
      print('📊 Reports: Monthly summary for $_year-$_month: $monthly');
      print('📊 Reports: Income categories: $incomeCats');
      print('📊 Reports: Expense categories: $expenseCats');
      
      if (mounted) {
        setState(() {
          _monthly = monthly;
          _incomeCats = incomeCats;
          _expenseCats = expenseCats;
          _isLoading = false;
        });
        
        // Load AI suggestions if API is configured and there's data
        final income = monthly['income'] ?? 0;
        final expense = monthly['expense'] ?? 0;
        if (_aiAdvisor.isConfigured && (income > 0 || expense > 0)) {
          _loadAiSuggestions();
        }
      }
    } catch (e) {
      print('📊 Reports Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAiSuggestions() async {
    if (!_aiAdvisor.isConfigured) return;
    
    setState(() => _isLoadingAi = true);
    
    try {
      final income = _monthly['income'] ?? 0;
      final expense = _monthly['expense'] ?? 0;
      final net = income - expense;
      
      // Convert category lists to maps
      final incomeCatMap = <String, double>{};
      for (var cat in _incomeCats) {
        final catName = cat['category']?.toString() ?? 'Other';
        final total = (cat['total'] as num?)?.toDouble() ?? 0;
        incomeCatMap[catName] = total;
      }
      
      final expenseCatMap = <String, double>{};
      for (var cat in _expenseCats) {
        final catName = cat['category']?.toString() ?? 'Other';
        final total = (cat['total'] as num?)?.toDouble() ?? 0;
        expenseCatMap[catName] = total;
      }
      
      // Get current locale
      final locale = Localizations.localeOf(context);
      final language = locale.languageCode;
      
      final suggestions = await _aiAdvisor.generateFinancialSuggestions(
        income: income,
        expense: expense,
        netBalance: net,
        incomeCategories: incomeCatMap,
        expenseCategories: expenseCatMap,
        language: language,
      );
      
      if (mounted) {
        setState(() {
          _aiSuggestions = suggestions;
          _isLoadingAi = false;
        });
      }
    } catch (e) {
      print('🤖 AI Suggestions Error: $e');
      if (mounted) {
        setState(() {
          _aiSuggestions = null;
          _isLoadingAi = false;
        });
      }
    }
  }

  String _getLocalizedCategory(String? category, AppLocalizations l10n) {
    if (category == null) return '-';
    return l10n.getCategoryName(category);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final monthLabel = DateFormat('MMMM yyyy').format(DateTime(_year, _month, 1));
    final income = _monthly['income'] ?? 0;
    final expense = _monthly['expense'] ?? 0;
    final net = income - expense;
    final hasData = income > 0 || expense > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Month Navigation
                  _buildMonthNavigation(monthLabel),
                  const SizedBox(height: 16),
                  
                  // Summary Card
                  _buildSummaryCard(l10n, income, expense, net),
                  const SizedBox(height: 16),
                  
                  // AI Suggestions Card (if configured and has data)
                  if (hasData) ...[
                    _buildAiSuggestionsCard(l10n),
                    const SizedBox(height: 16),
                  ],
                  
                  // Income vs Expense Bar Chart
                  if (hasData) ...[
                    _buildBarChartCard(l10n, income, expense),
                    const SizedBox(height: 16),
                  ],
                  
                  // Expense Pie Chart
                  if (_expenseCats.isNotEmpty) ...[
                    _buildPieChartCard(l10n, l10n.expense, _expenseCats, AppColors.error),
                    const SizedBox(height: 16),
                  ],
                  
                  // Income Pie Chart
                  if (_incomeCats.isNotEmpty) ...[
                    _buildPieChartCard(l10n, l10n.income, _incomeCats, AppColors.success),
                    const SizedBox(height: 16),
                  ],
                  
                  // Category Breakdown Lists
                  _buildCategorySection(l10n, l10n.income, _incomeCats, AppColors.success),
                  const SizedBox(height: 16),
                  _buildCategorySection(l10n, l10n.expense, _expenseCats, AppColors.error),
                  
                  // Empty state
                  if (!hasData && _incomeCats.isEmpty && _expenseCats.isEmpty)
                    _buildEmptyState(l10n),
                ],
              ),
            ),
    );
  }

  Widget _buildAiSuggestionsCard(AppLocalizations l10n) {
    return Card(
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
                Expanded(
                  child: Text(
                    l10n.aiSuggestions,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (_aiAdvisor.isConfigured && _aiSuggestions != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _loadAiSuggestions,
                    tooltip: l10n.refreshSuggestions,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (!_aiAdvisor.isConfigured)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.configureAiToEnable,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else if (_isLoadingAi)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.generatingSuggestions,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              )
            else if (_aiSuggestions == null || _aiSuggestions!.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.failedToGenerateSuggestions,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withOpacity(0.3)),
                ),
                child: Text(
                  _aiSuggestions!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavigation(String monthLabel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                final prev = DateTime(_year, _month - 1, 1);
                setState(() {
                  _year = prev.year;
                  _month = prev.month;
                });
                _load();
              },
            ),
            Text(
              monthLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                final next = DateTime(_year, _month + 1, 1);
                if (next.isBefore(DateTime.now()) || next.month == DateTime.now().month) {
                  setState(() {
                    _year = next.year;
                    _month = next.month;
                  });
                  _load();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(AppLocalizations l10n, double income, double expense, double net) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, size: 24),
                const SizedBox(width: 8),
                Text(l10n.monthlySummary, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildSummaryItem(l10n.income, income, AppColors.success, Icons.arrow_upward)),
                Container(width: 1, height: 50, color: AppColors.border),
                Expanded(child: _buildSummaryItem(l10n.expense, expense, AppColors.error, Icons.arrow_downward)),
              ],
            ),
            const Divider(height: 32),
            _buildNetRow(l10n.netBalance, net),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '฿${NumberFormat('#,##0.00').format(value)}',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNetRow(String label, double value) {
    final color = value >= 0 ? AppColors.success : AppColors.error;
    final icon = value >= 0 ? Icons.trending_up : Icons.trending_down;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        Text(
          '฿${NumberFormat('#,##0.00').format(value)}',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChartCard(AppLocalizations l10n, double income, double expense) {
    final maxY = (income > expense ? income : expense) * 1.2;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, size: 24),
                const SizedBox(width: 8),
                Text(l10n.incomeVsExpense, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY > 0 ? maxY : 1000,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label = groupIndex == 0 ? l10n.income : l10n.expense;
                        return BarTooltipItem(
                          '$label\n฿${NumberFormat('#,##0').format(rod.toY)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final titles = [l10n.income, l10n.expense];
                          if (value.toInt() < titles.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(titles[value.toInt()], style: const TextStyle(fontSize: 12)),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox();
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: income,
                          color: AppColors.success,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: expense,
                          color: AppColors.error,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    ),
                  ],
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 0 ? maxY / 5 : 200,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard(AppLocalizations l10n, String title, List<Map<String, dynamic>> items, Color baseColor) {
    final total = items.fold<double>(0, (sum, e) => sum + ((e['total'] as num?)?.toDouble() ?? 0));
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, size: 24),
                const SizedBox(width: 8),
                Text('$title ${l10n.breakdown}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // Pie Chart
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: items.asMap().entries.map((entry) {
                          final i = entry.key;
                          final e = entry.value;
                          final value = (e['total'] as num?)?.toDouble() ?? 0;
                          final percentage = total > 0 ? (value / total * 100) : 0;
                          
                          return PieChartSectionData(
                            color: _chartColors[i % _chartColors.length],
                            value: value,
                            title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  // Legend
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: items.asMap().entries.map((entry) {
                          final i = entry.key;
                          final e = entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _chartColors[i % _chartColors.length],
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _getLocalizedCategory(e['category']?.toString(), l10n),
                                    style: const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
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

  Widget _buildCategorySection(AppLocalizations l10n, String title, List<Map<String, dynamic>> items, Color color) {
    final total = items.fold<double>(0, (sum, e) => sum + ((e['total'] as num?)?.toDouble() ?? 0));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  '฿${NumberFormat('#,##0.00').format(total)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            if (items.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    l10n.noTransactionsThisMonth,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              )
            else
              ...items.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final value = (e['total'] as num?)?.toDouble() ?? 0;
                final count = (e['count'] as num?)?.toInt() ?? 0;
                final percentage = total > 0 ? (value / total * 100) : 0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _chartColors[i % _chartColors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getLocalizedCategory(e['category']?.toString(), l10n),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '$count ${l10n.transactions}',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '฿${NumberFormat('#,##0').format(value)}',
                            style: TextStyle(color: color, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(_chartColors[i % _chartColors.length]),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.noTransactionsThisMonth,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addTransactionsToSeeReports,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
