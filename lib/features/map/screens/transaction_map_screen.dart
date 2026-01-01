import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction.dart' as model;
import '../../../data/repositories/transaction_repository.dart';

class TransactionMapScreen extends StatefulWidget {
  const TransactionMapScreen({super.key});

  @override
  State<TransactionMapScreen> createState() => _TransactionMapScreenState();
}

class _TransactionMapScreenState extends State<TransactionMapScreen> {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final MapController _mapController = MapController();
  
  List<model.Transaction> _transactionsWithLocation = [];
  List<Marker> _markers = [];
  bool _isLoading = true;
  
  static const LatLng _initialCenter = LatLng(13.7563, 100.5018);

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final allTransactions = await _transactionRepo.getAllTransactions();
      final withLocation = allTransactions.where((tx) => tx.photos != null && tx.photos!.any((p) => p.location != null)).toList();
      setState(() { _transactionsWithLocation = withLocation; _isLoading = false; });
      _createMarkers();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _createMarkers() {
    final markers = <Marker>[];
    for (final tx in _transactionsWithLocation) {
      final photo = tx.photos!.firstWhere((p) => p.location != null);
      markers.add(Marker(
        width: 60, height: 60,
        point: LatLng(photo.location!.latitude, photo.location!.longitude),
        child: GestureDetector(
          onTap: () => _navigateToDetail(tx),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: tx.type == 'income' ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(photo.thumbnailPath ?? photo.path),
                width: 56, height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surface,
                  child: Icon(tx.type == 'income' ? Icons.add : Icons.remove, color: tx.type == 'income' ? AppColors.success : AppColors.error),
                ),
              ),
            ),
          ),
        ),
      ));
    }
    setState(() {
      _markers = markers;
    });
  }

  void _navigateToDetail(model.Transaction tx) async {
    final result = await Navigator.pushNamed(
      context, 
      AppConstants.routeTransactionDetail,
      arguments: tx.id,
    );
    if (result == true) {
      _loadTransactions(); // Refresh if deleted or edited
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Determine center
    LatLng center = _initialCenter;
    if (_transactionsWithLocation.isNotEmpty) {
      center = LatLng(
        _transactionsWithLocation.first.photos!.firstWhere((p) => p.location != null).location!.latitude,
        _transactionsWithLocation.first.photos!.firstWhere((p) => p.location != null).location!.longitude,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapView)),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.roeya',
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }
}
