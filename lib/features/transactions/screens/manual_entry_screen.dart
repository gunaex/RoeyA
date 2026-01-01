import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/decimal_text_input_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/account.dart';
import '../../../data/models/photo_attachment.dart';
import '../../../data/models/transaction.dart' as model;
import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/template_repository.dart';
import '../../../data/models/transaction_template.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/photo_attachment_widget.dart';

class ManualEntryScreen extends StatefulWidget {
  final String? transactionId;

  const ManualEntryScreen({super.key, this.transactionId});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  
  final AccountRepository _accountRepo = AccountRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();
  final TemplateRepository _templateRepo = TemplateRepository();
  
  String _type = 'expense';
  String _currency = 'THB';
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String? _selectedAccountId;
  List<Account> _accounts = [];
  
  bool _isLoading = false;
  bool _isLoadingAccounts = true;
  List<PhotoAttachment> _photos = [];
  bool _hasInitialized = false;

  List<String> get _categoryOptions {
    return _type == 'income' 
        ? AppConstants.incomeCategories 
        : AppConstants.expenseCategories;
  }

  String _getLocalizedCategory(String category, AppLocalizations l10n) {
    return l10n.getCategoryName(category);
  }

  @override
  void initState() {
    super.initState();
    _loadAccounts().then((_) {
      if (widget.transactionId != null) {
        _loadTransaction();
      }
    });
  }

  Future<void> _loadTransaction() async {
    setState(() => _isLoading = true);
    try {
      final tx = await _transactionRepo.getTransactionById(widget.transactionId!);
      if (tx != null) {
        setState(() {
          _type = tx.type;
          _selectedAccountId = tx.accountId;
          _amountController.text = tx.amount.toStringAsFixed(2);
          _descriptionController.text = tx.description ?? '';
          _noteController.text = tx.note ?? '';
          _selectedDate = tx.transactionDate;
          _photos = tx.photos ?? [];
          _currency = tx.currencyCode;
          _selectedCategory = tx.category;
        });
      }
    } catch (e) {
      print('Error loading transaction: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _accountRepo.getAllAccounts();
      setState(() {
        _accounts = accounts;
        if (accounts.isNotEmpty && _selectedAccountId == null) {
          // Choose default if not already set (e.g. by _loadTransaction)
          final defaultAcc = accounts.firstWhere(
            (a) => a.id == 'default',
            orElse: () => accounts.first,
          );
          _selectedAccountId = defaultAcc.id;
        }
        _isLoadingAccounts = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAccounts = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_hasInitialized) {
      _hasInitialized = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        if (args['photos'] != null && args['photos'] is List<PhotoAttachment>) {
          setState(() {
            _photos = args['photos'] as List<PhotoAttachment>;
            if (args['date'] != null && args['date'] is DateTime) {
              _selectedDate = args['date'] as DateTime;
            }
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manualEntry),
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark_outline),
            tooltip: l10n.useTemplate,
            onPressed: _showTemplateSelector,
          ),
        ],
      ),
      body: _isLoadingAccounts 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type Selector
                        Text(l10n.transactionType, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        SegmentedButton<String>(
                          segments: [
                            ButtonSegment(value: 'income', label: Text(l10n.income), icon: const Icon(Icons.add_circle_outline)),
                            ButtonSegment(value: 'expense', label: Text(l10n.expense), icon: const Icon(Icons.remove_circle_outline)),
                          ],
                          selected: {_type},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() { 
                              _type = newSelection.first;
                              // Reset category when type changes
                              _selectedCategory = null;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 24),

                        // Category Selector
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: l10n.category,
                            prefixIcon: const Icon(Icons.category_outlined),
                          ),
                          items: _categoryOptions.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(_getLocalizedCategory(cat, l10n)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() { _selectedCategory = value; });
                          },
                          validator: (value) => value == null ? l10n.selectCategory : null,
                        ),

                        const SizedBox(height: 16),

                        // Account Selector
                        DropdownButtonFormField<String>(
                          value: _selectedAccountId,
                          decoration: InputDecoration(
                            labelText: l10n.account,
                            prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                          ),
                          items: _accounts.map((acc) {
                            return DropdownMenuItem(
                              value: acc.id,
                              child: Text(acc.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() { _selectedAccountId = value; });
                          },
                          validator: (value) => value == null ? l10n.selectAccount : null,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Amount
                        AppTextField(
                          controller: _amountController,
                          label: l10n.amount,
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: const Icon(Icons.attach_money),
                          validator: Validators.validateAmount,
                          inputFormatters: [DecimalTextInputFormatter(decimalPlaces: 2)],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Description
                        AppTextField(
                          controller: _descriptionController,
                          label: l10n.description,
                          hint: '',
                          prefixIcon: const Icon(Icons.description_outlined),
                          validator: (value) => Validators.validateRequired(value, l10n.description),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Date
                        InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.date,
                              prefixIcon: const Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Note
                        AppTextField(
                          controller: _noteController,
                          label: l10n.note,
                          hint: '',
                          prefixIcon: const Icon(Icons.note_outlined),
                          maxLines: 2,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Photo Attachments
                        PhotoAttachmentWidget(
                          photos: _photos,
                          onPhotosChanged: (photos) {
                            setState(() { _photos = photos; });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Save Button Bar
                _buildActionBar(l10n),
              ],
            ),
          ),
    );
  }

  Widget _buildActionBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(child: AppButton(text: l10n.cancel, isOutlined: true, onPressed: () => Navigator.pop(context))),
          const SizedBox(width: 12),
          Expanded(child: AppButton(text: l10n.save, isLoading: _isLoading, onPressed: _handleSave)),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() { _selectedDate = picked; });
    }
  }

  Future<void> _showTemplateSelector() async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      final templates = await _templateRepo.getTemplatesByType(_type);
      
      if (templates.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noTemplates)),
          );
        }
        return;
      }
      
      if (mounted) {
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.selectTemplate,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      return ListTile(
                        leading: Icon(Icons.bookmark),
                        title: Text(template.name),
                        subtitle: Text(
                          '${l10n.getCategoryName(template.category ?? '')} • ${template.amount.toStringAsFixed(2)} ${template.currencyCode}',
                        ),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          _loadTemplate(template);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      print('Error loading templates: $e');
    }
  }

  void _loadTemplate(TransactionTemplate template) {
    setState(() {
      _type = template.type;
      _selectedCategory = template.category;
      _selectedAccountId = template.accountId;
      _amountController.text = template.amount.toStringAsFixed(2);
      _noteController.text = template.note ?? '';
      _currency = template.currencyCode;
    });
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) return;

    // Show save options dialog for new transactions
    if (widget.transactionId == null) {
      final saveOption = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.save),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.save),
                title: Text(l10n.save),
                subtitle: Text('Save transaction only'),
                onTap: () => Navigator.pop(context, 'save'),
              ),
              ListTile(
                leading: Icon(Icons.bookmark),
                title: Text(l10n.saveAsTemplate),
                subtitle: Text('Save transaction and create template'),
                onTap: () => Navigator.pop(context, 'save_template'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );

      if (saveOption == null) return;
      
      if (saveOption == 'save_template') {
        await _saveAsTemplate(l10n);
      }
    }

    setState(() { _isLoading = true; });

    try {
      double amount = double.parse(_amountController.text);
      amount = double.parse(amount.toStringAsFixed(2));
      
      final transaction = model.Transaction(
        id: widget.transactionId ?? const Uuid().v4(),
        accountId: _selectedAccountId!,
        type: _type,
        amount: amount,
        currencyCode: _currency,
        category: _selectedCategory,
        description: _descriptionController.text,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        photos: _photos.isNotEmpty ? _photos : null,
        transactionDate: _selectedDate,
        createdAt: DateTime.now(),
      );

      if (widget.transactionId != null) {
        await _transactionRepo.updateTransaction(transaction);
      } else {
        await _transactionRepo.insertTransaction(transaction);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.transactionId != null 
                ? '✅ ${l10n.editedSuccessfully}' 
                : '✅ ${l10n.savedSuccessfully}: ${amount.toStringAsFixed(2)} ฿'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _saveAsTemplate(AppLocalizations l10n) async {
    final nameController = TextEditingController(
      text: _descriptionController.text.isNotEmpty 
          ? _descriptionController.text 
          : '${_type == 'income' ? l10n.income : l10n.expense} Template',
    );
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.saveAsTemplate),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: l10n.templateName,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    
    if (result == true && nameController.text.isNotEmpty) {
      try {
        final amount = double.tryParse(_amountController.text) ?? 0.0;
        final template = TransactionTemplate(
          id: const Uuid().v4(),
          name: nameController.text,
          type: _type,
          category: _selectedCategory,
          accountId: _selectedAccountId,
          amount: amount,
          currencyCode: _currency,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
          createdAt: DateTime.now(),
        );
        
        await _templateRepo.insertTemplate(template);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.templateSaved),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        print('Error saving template: $e');
      }
    }
  }
}
