import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/service_icons.dart';
import '../../../data/models/transaction.dart' as model;
import 'dart:math' as math;

enum VisualizationStyle { grid, swarm, bubbles }

class SubscriptionVisualizationWidget extends StatefulWidget {
  final List<model.Transaction> subscriptions;
  final double monthlyTotal;
  final double yearlyProjection;

  const SubscriptionVisualizationWidget({
    super.key,
    required this.subscriptions,
    required this.monthlyTotal,
    required this.yearlyProjection,
  });

  @override
  State<SubscriptionVisualizationWidget> createState() =>
      _SubscriptionVisualizationWidgetState();
}

class _SubscriptionVisualizationWidgetState
    extends State<SubscriptionVisualizationWidget> {
  VisualizationStyle _currentStyle = VisualizationStyle.grid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Style Selector
        _buildStyleSelector(),
        const SizedBox(height: 16),

        // Visualization
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildVisualization(),
        ),

        const SizedBox(height: 16),

        // Summary Panel
        _buildSummaryPanel(l10n),
      ],
    );
  }

  Widget _buildStyleSelector() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStyleButton(
            icon: Icons.grid_view,
            label: l10n.grid,
            style: VisualizationStyle.grid,
          ),
          _buildStyleButton(
            icon: Icons.scatter_plot,
            label: l10n.swarm,
            style: VisualizationStyle.swarm,
          ),
          _buildStyleButton(
            icon: Icons.bubble_chart,
            label: l10n.bubbles,
            style: VisualizationStyle.bubbles,
          ),
        ],
      ),
    );
  }

  Widget _buildStyleButton({
    required IconData icon,
    required String label,
    required VisualizationStyle style,
  }) {
    final isSelected = _currentStyle == style;
    return InkWell(
      onTap: () => setState(() => _currentStyle = style),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualization() {
    if (widget.subscriptions.isEmpty) {
      return _buildEmptyState();
    }

    switch (_currentStyle) {
      case VisualizationStyle.grid:
        return _buildGridView();
      case VisualizationStyle.swarm:
        return _buildSwarmView();
      case VisualizationStyle.bubbles:
        return _buildBubblesView();
    }
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.subscriptions_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              l10n.subscriptions,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.markTransactionsDesc,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Grid View (Bento Style - Staggered)
  Widget _buildGridView() {
    final sortedSubs = List<model.Transaction>.from(widget.subscriptions)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    
    final topSub = sortedSubs.isNotEmpty ? sortedSubs[0] : null;
    final mediumSubs = sortedSubs.length > 1 ? sortedSubs.sublist(1, math.min(3, sortedSubs.length)) : <model.Transaction>[];
    final smallSubs = sortedSubs.length > 3 ? sortedSubs.sublist(3, math.min(6, sortedSubs.length)) : <model.Transaction>[];

    return Column(
      key: const ValueKey('grid'),
      children: [
        if (topSub != null)
          SizedBox(
            height: 180, // Increased from 160
            width: double.infinity,
            child: _buildGridCard(widget.subscriptions.indexOf(topSub), topSub, isLarge: true),
          ),
        if (mediumSubs.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: mediumSubs.map((sub) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: sub == mediumSubs.last ? 0 : 12),
                child: SizedBox(
                   height: 160, // Increased from 140
                   child: _buildGridCard(widget.subscriptions.indexOf(sub), sub),
                ),
              ),
            )).toList(),
          ),
        ],
        if (smallSubs.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: smallSubs.map((sub) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: sub == smallSubs.last ? 0 : 12),
                child: SizedBox(
                  height: 140, // Increased from 120
                  child: _buildGridCard(widget.subscriptions.indexOf(sub), sub, isCompact: true),
                ),
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildGridCard(int index, model.Transaction sub, {bool isLarge = false, bool isCompact = false}) {
    final yearlyAmount = _getYearlyAmount(sub);
    final percentage = (sub.amount / widget.monthlyTotal * 100).round();
    final icon = ServiceIcons.getIcon(sub.description ?? '');

    return Card(
      elevation: 0,
      color: _getSubscriptionColor(index),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(isCompact ? 6 : 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(icon, style: TextStyle(fontSize: isLarge ? 28 : (isCompact ? 16 : 20))),
                ),
                if (percentage > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$percentage%',
                      style: TextStyle(
                          fontSize: isCompact ? 10 : 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      sub.description ?? 'Subscription',
                      style: TextStyle(
                          fontSize: isLarge ? 18 : (isCompact ? 12 : 14), fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      CurrencyFormatter.format(sub.amount, sub.currencyCode),
                      style: TextStyle(
                          fontSize: isLarge ? 24 : (isCompact ? 14 : 18), fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (!isCompact)
                    Text(
                      '~${CurrencyFormatter.format(yearlyAmount / 1000, sub.currencyCode)}k/yr',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Swarm View (Elegant & Minimalist)
  Widget _buildSwarmView() {
    return Container(
      key: const ValueKey('swarm'),
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: CustomPaint(
        painter: SwarmPainter(
          subscriptions: widget.subscriptions,
          monthlyTotal: widget.monthlyTotal,
        ),
        child: Container(),
      ),
    );
  }

  // Bubbles View (Playful & Visual)
  Widget _buildBubblesView() {
    return Container(
      key: const ValueKey('bubbles'),
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: widget.subscriptions
            .asMap()
            .entries
            .map((entry) => _buildBubble(entry.key, entry.value))
            .toList(),
      ),
    );
  }

  Widget _buildBubble(int index, model.Transaction sub) {
    final size = (sub.amount / widget.monthlyTotal * 150).clamp(60.0, 140.0);
    final random = math.Random(index);
    final left = random.nextDouble() * 200;
    final top = random.nextDouble() * 250;
    final icon = ServiceIcons.getIcon(sub.description ?? '');

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getSubscriptionColor(index).withOpacity(0.8),
          boxShadow: [
            BoxShadow(
              color: _getSubscriptionColor(index).withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FittedBox(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(sub.amount, sub.currencyCode),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryPanel(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.monthlyTotal.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary, letterSpacing: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(widget.monthlyTotal, 'THB'),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.yearlyProjection.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary, letterSpacing: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(widget.yearlyProjection, 'THB'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSubscriptionColor(int index) {
    final colors = [
      const Color(0xFFE8D5F2),
      const Color(0xFFD5E8F7),
      const Color(0xFFFBE5D6),
      const Color(0xFFE0F4F1),
      const Color(0xFFFCE4EC),
      const Color(0xFFE8F5E9),
      const Color(0xFFFFF9C4),
      const Color(0xFFE1F5FE),
    ];
    return colors[index % colors.length];
  }

  double _getYearlyAmount(model.Transaction sub) {
    if (sub.frequency == 'monthly') return sub.amount * 12;
    if (sub.frequency == 'yearly') return sub.amount;
    if (sub.frequency == 'weekly') return sub.amount * 52;
    return sub.amount * 12;
  }
}

// Swarm Painter for elegant visualization
class SwarmPainter extends CustomPainter {
  final List<model.Transaction> subscriptions;
  final double monthlyTotal;

  SwarmPainter({required this.subscriptions, required this.monthlyTotal});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42);

    for (var i = 0; i < subscriptions.length; i++) {
      final sub = subscriptions[i];
      final radius = (sub.amount / monthlyTotal * 30).clamp(8.0, 40.0);
      final x = (i / subscriptions.length) * size.width + random.nextDouble() * 50;
      final y = size.height / 2 + (random.nextDouble() - 0.5) * 200;

      paint.color = _getColor(i).withOpacity(0.7);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  Color _getColor(int index) {
    final colors = [
      const Color(0xFFE8D5F2),
      const Color(0xFFD5E8F7),
      const Color(0xFFFBE5D6),
      const Color(0xFFE0F4F1),
    ];
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
