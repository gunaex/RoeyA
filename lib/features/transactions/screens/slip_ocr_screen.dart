import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/mlkit_ocr_service.dart';
import '../../../core/services/exif_location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/thai_qr_parser.dart';
import '../../../data/models/account.dart';
import '../../../data/models/slip_data.dart';
import '../../../data/models/transaction.dart' as model;
import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/widgets/app_button.dart';

class SlipOcrScreen extends StatefulWidget {
  const SlipOcrScreen({super.key});

  @override
  State<SlipOcrScreen> createState() => _SlipOcrScreenState();
}

class _SlipOcrScreenState extends State<SlipOcrScreen> {
  final ImagePicker _picker = ImagePicker();
  final MlKitOcrService _ocrService = MlKitOcrService.instance;
  final AccountRepository _accountRepo = AccountRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();
  
  File? _imageFile;
  SlipData? _slipData;
  bool _isScanning = false;
  bool _didLoadArgs = false;
  
  String? _selectedAccountId;
  List<Account> _accounts = [];
  
  // Transaction type and category
  String _transactionType = 'expense';
  String? _selectedCategory;

  // Controllers for editing
  final _amountController = TextEditingController();
  final _feeController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _refController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadArgs) return;
    _didLoadArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      final file = File(args);
      _processImage(file);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _feeController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _refController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _accountRepo.getAllAccounts();
      if (mounted) {
        setState(() {
          _accounts = accounts;
          if (accounts.isNotEmpty) {
            final defaultAcc = accounts.firstWhere(
              (a) => a.id == 'default',
              orElse: () => accounts.first,
            );
            _selectedAccountId = defaultAcc.id;
          }
        });
      }
    } catch (e) {
      print('Error loading accounts: $e');
    }
  }

  List<String> get _categoryOptions {
    return _transactionType == 'income' 
        ? AppConstants.incomeCategories 
        : AppConstants.expenseCategories;
  }

  String _getLocalizedCategory(String category, AppLocalizations l10n) {
    return l10n.getCategoryName(category);
  }

  /// Pick image from camera
  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      await _processImage(File(image.path));
    } catch (e) {
      setState(() { _isScanning = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  /// Pick image from gallery using file_picker (preserves EXIF GPS on Android 13+)
  Future<void> _pickFromGallery() async {
    try {
      // Use file_picker instead of image_picker to preserve EXIF data
      await ExifLocationService.instance.requestMediaReadPermission();
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      
      if (result == null || result.files.isEmpty || result.files.single.path == null) return;

      await _processImage(File(result.files.single.path!));
    } catch (e) {
      setState(() { _isScanning = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  /// Process the selected image (scan OCR)
  Future<void> _processImage(File imageFile) async {
    setState(() {
      _imageFile = imageFile;
      _slipData = null;
      _isScanning = true;
    });

    final slipData = await _ocrService.scanSlip(_imageFile!);

    setState(() {
      _slipData = slipData;
      _isScanning = false;
      _populateControllers();
      // Default category for bank transfers
      _selectedCategory = 'Transfer';
    });
  }

  void _populateControllers() {
    if (_slipData == null) return;
    _amountController.text = (_slipData!.amount ?? _slipData!.amountFromQr)?.toStringAsFixed(2) ?? '';
    _feeController.text = _slipData!.fee?.toStringAsFixed(2) ?? '0.00';
    _fromController.text = _slipData!.fromAccount ?? '';
    _toController.text = _slipData!.toAccount ?? '';
    _refController.text = _slipData!.referenceNo ?? '';
    
    final now = DateTime.now();
    final thaiYear = now.year + 543;
    _dateController.text = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/$thaiYear';
    _timeController.text = _slipData!.transactionTime ?? '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveTransaction() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (_slipData == null || _selectedAccountId == null) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseEnterValidAmount), backgroundColor: AppColors.error));
      return;
    }

    try {
      DateTime transactionDate = DateTime.now();
      if (_dateController.text.isNotEmpty) {
        final parts = _dateController.text.split('/');
        if (parts.length == 3) {
          transactionDate = DateTime(
            int.parse(parts[2]) - 543, // Convert Buddhist Year to Gregorian
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }

      final transaction = model.Transaction(
        id: const Uuid().v4(),
        accountId: _selectedAccountId!,
        type: _transactionType,
        amount: amount,
        currencyCode: 'THB',
        category: _selectedCategory,
        description: '${_slipData!.bankName ?? "โอนเงิน"} - ${_toController.text}',
        note: _noteController.text.isNotEmpty 
            ? _noteController.text 
            : 'Ref: ${_refController.text}\nFrom: ${_fromController.text}\nFee: ${_feeController.text}',
        transactionDate: transactionDate,
        createdAt: DateTime.now(),
      );

      await _transactionRepo.insertTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${l10n.savedSuccessfully}: ${amount.toStringAsFixed(2)} ฿'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanTransferSlip),
      ),
      body: _imageFile == null
          ? _buildEmptyState(l10n)
          : _isScanning
              ? _buildScanningState(l10n)
              : _slipData != null
                  ? _buildResultsView(l10n)
                  : _buildErrorState(l10n),
      floatingActionButton: _imageFile != null && _slipData != null && !_isScanning
          ? FloatingActionButton.extended(
              onPressed: _saveTransaction,
              icon: const Icon(Icons.save),
              label: Text(l10n.save),
              backgroundColor: AppColors.success,
            )
          : null,
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.document_scanner, size: 80, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(l10n.scanTransferSlip, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(icon: Icons.camera_alt, label: l10n.takePhoto, onTap: _pickFromCamera),
                const SizedBox(width: 16),
                _buildActionButton(icon: Icons.photo_library, label: l10n.gallery, onTap: _pickFromGallery),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(l10n.scanning, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildResultsView(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slip Image Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_imageFile!, height: 150, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 20),
          
          // Transaction Type Selector
          Text(l10n.transactionType, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'income', label: Text(l10n.income), icon: const Icon(Icons.add_circle_outline, size: 18)),
              ButtonSegment(value: 'expense', label: Text(l10n.expense), icon: const Icon(Icons.remove_circle_outline, size: 18)),
            ],
            selected: {_transactionType},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() { 
                _transactionType = newSelection.first;
                // Reset category when type changes
                _selectedCategory = _categoryOptions.isNotEmpty ? _categoryOptions.first : null;
              });
            },
          ),
          const SizedBox(height: 16),

          // Category Selector
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: l10n.category,
              prefixIcon: const Icon(Icons.category_outlined),
              border: const OutlineInputBorder(),
            ),
            items: _categoryOptions.map((cat) => DropdownMenuItem(
              value: cat, 
              child: Text(_getLocalizedCategory(cat, l10n)),
            )).toList(),
            onChanged: (value) => setState(() { _selectedCategory = value; }),
          ),
          const SizedBox(height: 16),

          // Account Selector
          DropdownButtonFormField<String>(
            value: _selectedAccountId,
            decoration: InputDecoration(
              labelText: l10n.saveToAccount,
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              border: const OutlineInputBorder(),
            ),
            items: _accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text(acc.name))).toList(),
            onChanged: (value) => setState(() { _selectedAccountId = value; }),
          ),
          const SizedBox(height: 16),

          // Amount
          _buildEditableField(label: '${l10n.amount} (฿)', controller: _amountController, icon: Icons.payments, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          
          // Date
          _buildEditableField(label: l10n.date, controller: _dateController, icon: Icons.calendar_today),
          const SizedBox(height: 12),
          
          // To (Recipient)
          _buildEditableField(label: l10n.recipient, controller: _toController, icon: Icons.person),
          const SizedBox(height: 12),
          
          // Reference
          _buildEditableField(label: l10n.reference, controller: _refController, icon: Icons.tag),
          const SizedBox(height: 12),
          
          // Note
          _buildEditableField(label: l10n.note, controller: _noteController, icon: Icons.note, maxLines: 2),
          
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label, 
    required TextEditingController controller, 
    required IconData icon, 
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: AppColors.error),
          const SizedBox(height: 16),
          Text(l10n.cannotReadSlip, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          AppButton(text: l10n.retry, onPressed: () => setState(() { _imageFile = null; _slipData = null; })),
        ],
      ),
    );
  }
}
