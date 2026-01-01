import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/services/ai_financial_advisor_service.dart';
import '../../../data/models/transaction.dart' as model;
import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/widgets/photo_attachment_widget.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final AccountRepository _accountRepo = AccountRepository();
  final AiFinancialAdvisorService _aiAdvisor = AiFinancialAdvisorService.instance;
  
  model.Transaction? _transaction;
  String? _accountName;
  bool _isLoading = true;
  String? _aiInsight;
  bool _isLoadingAi = false;

  @override
  void initState() {
    super.initState();
    _aiAdvisor.initialize();
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    try {
      final tx = await _transactionRepo.getTransactionById(widget.transactionId);
      if (tx != null) {
        final account = await _accountRepo.getAccountById(tx.accountId);
        if (mounted) {
          setState(() {
            _transaction = tx;
            _accountName = account?.name ?? 'Unknown Account';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_transaction == null) return const Scaffold(body: Center(child: Text('Transaction not found')));

    final isIncome = _transaction!.type == 'income';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recentTransactions),
        actions: [
          if (_aiAdvisor.isConfigured)
            IconButton(
              icon: Icon(_isLoadingAi ? Icons.hourglass_empty : Icons.auto_awesome_outlined),
              tooltip: 'Ask AI',
              onPressed: _isLoadingAi ? null : _generateAiInsight,
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context, 
                AppConstants.routeManualEntry,
                arguments: _transaction!.id,
              );
              if (result == true) {
                _loadTransaction(); // Refresh data
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Amount Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: (isIncome ? AppColors.success : AppColors.error).withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}${CurrencyFormatter.format(_transaction!.amount, _transaction!.currencyCode)}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: isIncome ? AppColors.success : AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _transaction!.description ?? '',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // AI Insight Card
            if (_aiInsight != null) ...[
              _buildAiInsightCard(l10n),
              const SizedBox(height: 24),
            ],
            
            // Details List
            _buildDetailRow(Icons.account_balance_wallet_outlined, l10n.accounts, _accountName ?? ''),
            _buildDetailRow(Icons.calendar_today_outlined, l10n.date, '${_transaction!.transactionDate.day}/${_transaction!.transactionDate.month}/${_transaction!.transactionDate.year}'),
            _buildDetailRow(Icons.category_outlined, l10n.category, _transaction!.category ?? 'No Category'),
            if (_transaction!.note != null) _buildDetailRow(Icons.note_outlined, l10n.note, _transaction!.note!),
            
            // Location Detail
            ...((_transaction!.photos ?? []).any((p) => p.location != null) ? [
              _buildDetailRow(
                Icons.location_on_outlined, 
                l10n.location, 
                _transaction!.photos!.firstWhere((p) => p.location != null).location!.fullLocationName
              ),
            ] : []),
            
            const SizedBox(height: 32),
            
            // Photos
            if (_transaction!.photos != null && _transaction!.photos!.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(height: 12),
              PhotoAttachmentWidget(
                photos: _transaction!.photos!,
                readOnly: true,
                onPhotosChanged: (_) {},
              ),
              
              const SizedBox(height: 32),
              
              // Map View
              if ((_transaction!.photos ?? []).any((p) => p.location != null)) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.transactionLocation, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          _transaction!.photos!.firstWhere((p) => p.location != null).location!.latitude,
                          _transaction!.photos!.firstWhere((p) => p.location != null).location!.longitude,
                        ),
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.roeya',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                _transaction!.photos!.firstWhere((p) => p.location != null).location!.latitude,
                                _transaction!.photos!.firstWhere((p) => p.location != null).location!.longitude,
                              ),
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on, color: AppColors.error, size: 40),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAiInsight() async {
    if (_transaction == null || !_aiAdvisor.isConfigured) return;
    
    setState(() {
      _isLoadingAi = true;
      _aiInsight = null;
    });
    
    try {
      final locale = Localizations.localeOf(context);
      final language = locale.languageCode;
      
      final insight = await _aiAdvisor.generateTransactionInsight(
        description: _transaction!.description ?? 'No description',
        amount: _transaction!.amount,
        category: _transaction!.category,
        accountName: _accountName,
        date: _transaction!.transactionDate,
        type: _transaction!.type,
        language: language,
      );
      
      if (mounted) {
        setState(() {
          _aiInsight = insight;
          _isLoadingAi = false;
        });
      }
    } catch (e) {
      print('Error generating AI insight: $e');
      if (mounted) {
        setState(() {
          _isLoadingAi = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate AI insight')),
        );
      }
    }
  }

  Widget _buildAiInsightCard(AppLocalizations l10n) {
    return Card(
      elevation: 2,
      color: AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'AI Insight',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() => _aiInsight = null);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _aiInsight ?? '',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('This will restore the amount to your account balance.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _transactionRepo.softDeleteTransaction(_transaction!.id);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Return to list with refresh signal
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
