import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roeyp/core/constants/app_constants.dart';
import 'package:roeyp/core/localization/app_localizations.dart';
import 'package:roeyp/core/utils/currency_formatter.dart';
import 'package:roeyp/data/models/transaction.dart';
import 'package:roeyp/data/repositories/transaction_repository.dart';

class SearchTransactionsScreen extends StatefulWidget {
  const SearchTransactionsScreen({super.key});

  @override
  State<SearchTransactionsScreen> createState() => _SearchTransactionsScreenState();
}

class _SearchTransactionsScreenState extends State<SearchTransactionsScreen> {
  final _txRepo = TransactionRepository();
  final _searchController = TextEditingController();
  
  List<Transaction> _results = [];
  bool _isLoading = false;
  bool _showFilters = false;
  
  // Filters
  String? _selectedCategory;
  String? _selectedAccountId;
  DateTime? _fromDate;
  DateTime? _toDate;
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    
    try {
      final minAmount = _minAmountController.text.isEmpty
          ? null
          : double.tryParse(_minAmountController.text);
      final maxAmount = _maxAmountController.text.isEmpty
          ? null
          : double.tryParse(_maxAmountController.text);
      
      final results = await _txRepo.searchTransactions(
        query: _searchController.text.isEmpty ? null : _searchController.text,
        category: _selectedCategory,
        accountId: _selectedAccountId,
        from: _fromDate,
        to: _toDate,
        minAmount: minAmount,
        maxAmount: maxAmount,
        type: _selectedType,
      );
      
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedAccountId = null;
      _fromDate = null;
      _toDate = null;
      _minAmountController.clear();
      _maxAmountController.clear();
      _selectedType = null;
    });
    _performSearch();
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_fromDate ?? DateTime.now()) : (_toDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchTransactions),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // Filters panel
          if (_showFilters)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.filters, style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: _clearFilters,
                        child: Text(l10n.clearFilters),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  
                  // Type filter
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: l10n.transactionType,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    value: _selectedType,
                    items: [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: 'income', child: Text(l10n.income)),
                      DropdownMenuItem(value: 'expense', child: Text(l10n.expense)),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedType = value);
                      _performSearch();
                    },
                  ),
                  SizedBox(height: 8),
                  
                  // Category filter
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: l10n.category,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    value: _selectedCategory,
                    items: [
                      DropdownMenuItem(value: null, child: Text('All')),
                      ...AppConstants.expenseCategories.map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(l10n.getCategoryName(cat)),
                      )),
                      ...AppConstants.incomeCategories.map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(l10n.getCategoryName(cat)),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCategory = value);
                      _performSearch();
                    },
                  ),
                  SizedBox(height: 8),
                  
                  // Date range
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.fromDate,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: Text(_fromDate == null
                                ? 'Select'
                                : DateFormat('yyyy-MM-dd').format(_fromDate!)),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.toDate,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: Text(_toDate == null
                                ? 'Select'
                                : DateFormat('yyyy-MM-dd').format(_toDate!)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  
                  // Amount range
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minAmountController,
                          decoration: InputDecoration(
                            labelText: l10n.minAmount,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => _performSearch(),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _maxAmountController,
                          decoration: InputDecoration(
                            labelText: l10n.maxAmount,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => _performSearch(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          // Results
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(l10n.noResults),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final tx = _results[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: tx.type == 'income' ? Colors.green : Colors.red,
                              child: Icon(
                                tx.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(tx.description ?? 'No description'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (tx.category != null)
                                  Text(l10n.getCategoryName(tx.category!)),
                                Text(DateFormat('yyyy-MM-dd').format(tx.transactionDate)),
                              ],
                            ),
                            trailing: Text(
                              CurrencyFormatter.format(tx.amount, tx.currencyCode),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: tx.type == 'income' ? Colors.green : Colors.red,
                              ),
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppConstants.routeTransactionDetail,
                                arguments: tx.id,
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

