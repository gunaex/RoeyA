import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/mlkit_ocr_service.dart';
import '../../../core/services/exif_location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account.dart';
import '../../../data/models/slip_data.dart';
import '../../../data/models/transaction.dart' as model;
import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/transaction_repository.dart';

class BulkImportOcrScreen extends StatefulWidget {
  const BulkImportOcrScreen({super.key});

  @override
  State<BulkImportOcrScreen> createState() => _BulkImportOcrScreenState();
}

class _BulkImportOcrScreenState extends State<BulkImportOcrScreen> {
  final MlKitOcrService _ocrService = MlKitOcrService.instance;
  final AccountRepository _accountRepo = AccountRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();
  
  List<_SlipItem> _slipItems = [];
  bool _isScanning = false;
  int _currentScanIndex = 0;
  
  String? _selectedAccountId;
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await _accountRepo.getAllAccounts();
    setState(() {
      _accounts = accounts;
      if (accounts.isNotEmpty) {
        _selectedAccountId = accounts.firstWhere((a) => a.id == 'default', orElse: () => accounts.first).id;
      }
    });
  }

  Future<void> _pickImages() async {
    try {
      // Use file_picker instead of image_picker to preserve EXIF GPS data
      await ExifLocationService.instance.requestMediaReadPermission();
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      setState(() {
        _slipItems = result.files.where((f) => f.path != null).map((file) => _SlipItem(
          imageFile: File(file.path!),
          fileName: file.name,
          status: _SlipStatus.pending,
        )).toList();
        _isScanning = true;
        _currentScanIndex = 0;
      });

      await _scanAllSlips();
    } catch (e) {
      setState(() { _isScanning = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _scanAllSlips() async {
    for (int i = 0; i < _slipItems.length; i++) {
      setState(() { _currentScanIndex = i; _slipItems[i].status = _SlipStatus.scanning; });
      try {
        final slipData = await _ocrService.scanSlip(_slipItems[i].imageFile);
        setState(() {
          _slipItems[i].slipData = slipData;
          _slipItems[i].status = slipData.isComplete && slipData.confidence >= 0.7 ? _SlipStatus.success : _SlipStatus.needsReview;
        });
      } catch (e) {
        setState(() { _slipItems[i].status = _SlipStatus.error; });
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    setState(() { _isScanning = false; });
  }

  Future<void> _importAll() async {
    if (_selectedAccountId == null) return;
    final successItems = _slipItems.where((item) => item.status == _SlipStatus.success && item.slipData != null).toList();
    if (successItems.isEmpty) return;

    try {
      int imported = 0;
      for (final item in successItems) {
        final slipData = item.slipData!;
        DateTime transactionDate = DateTime.now();
        if (slipData.transactionDate != null && slipData.transactionDate!.isNotEmpty) {
          try {
            final parts = slipData.transactionDate!.split('/');
            if (parts.length == 3) {
              transactionDate = DateTime(int.parse(parts[2]) - 543, int.parse(parts[1]), int.parse(parts[0]));
            }
          } catch (e) {}
        }

        final transaction = model.Transaction(
          id: const Uuid().v4(),
          accountId: _selectedAccountId!,
          type: 'expense',
          amount: slipData.amount ?? 0.0,
          currencyCode: 'THB',
          description: '${slipData.bankName ?? "โอนเงิน"} - ${slipData.toAccount ?? ""}',
          note: 'Ref: ${slipData.referenceNo ?? ""}\nFrom: ${slipData.fromAccount ?? ""}',
          transactionDate: transactionDate,
          createdAt: DateTime.now(),
        );

        await _transactionRepo.insertTransaction(transaction);
        imported++;
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ นำเข้าสำเร็จ $imported รายการ'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Import Slips'),
        actions: [
          if (_slipItems.isNotEmpty && !_isScanning)
            TextButton.icon(onPressed: _importAll, icon: const Icon(Icons.check), label: Text('นำเข้า (${_slipItems.where((t)=>t.status == _SlipStatus.success).length})')),
        ],
      ),
      body: _slipItems.isEmpty ? _buildEmptyState() : Column(children: [
        if (_isScanning) _buildProgressBar(),
        if (!_isScanning && _slipItems.isNotEmpty) _buildAccountSelector(),
        Expanded(child: _buildSlipList()),
      ]),
      floatingActionButton: _slipItems.isEmpty || _isScanning
          ? FloatingActionButton.extended(onPressed: _isScanning ? null : _pickImages, icon: const Icon(Icons.photo_library), label: const Text('เลือกรูป'))
          : null,
    );
  }

  Widget _buildAccountSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: DropdownButtonFormField<String>(
        value: _selectedAccountId,
        decoration: const InputDecoration(labelText: 'บันทึกลงบัญชี', prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
        items: _accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text(acc.name))).toList(),
        onChanged: (val) => setState(() => _selectedAccountId = val),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.upload_file, size: 80, color: AppColors.primary)),
      const SizedBox(height: 24),
      Text('Bulk Import', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      const Text('เลือกสลิปหลายรูปพร้อมกัน\nระบบจะอ่านข้อมูลให้อัตโนมัติ', textAlign: TextAlign.center),
    ])));
  }

  Widget _buildProgressBar() {
    final progress = _slipItems.isEmpty ? 0.0 : (_currentScanIndex + 1) / _slipItems.length;
    return LinearProgressIndicator(value: progress);
  }

  Widget _buildSlipList() {
    return ListView.builder(itemCount: _slipItems.length, itemBuilder: (context, index) {
      final item = _slipItems[index];
      return ListTile(
        leading: ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.file(item.imageFile, width: 40, height: 40, fit: BoxFit.cover)),
        title: Text('Slip ${index + 1} - ${item.status.name}'),
        subtitle: item.slipData?.amount != null ? Text(CurrencyFormatter.format(item.slipData!.amount!, 'THB')) : null,
        trailing: IconButton(
          icon: const Icon(Icons.edit_note),
          onPressed: () => _showReviewDialog(index),
        ),
      );
    });
  }

  void _showReviewDialog(int index) {
    final item = _slipItems[index];
    final amountController = TextEditingController(text: item.slipData?.amount?.toString() ?? '0');
    final dateController = TextEditingController(text: item.slipData?.transactionDate ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Slip Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
            TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date (DD/MM/YYYY)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _slipItems[index].slipData = (_slipItems[index].slipData ?? SlipData(isManualComplete: true, confidence: 1.0)).copyWith(
                  amount: double.tryParse(amountController.text),
                  transactionDate: dateController.text,
                );
                _slipItems[index].status = _SlipStatus.success;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SlipItem {
  final File imageFile;
  final String fileName;
  _SlipStatus status;
  SlipData? slipData;
  _SlipItem({required this.imageFile, required this.fileName, required this.status});
}

enum _SlipStatus { pending, scanning, success, needsReview, error }
