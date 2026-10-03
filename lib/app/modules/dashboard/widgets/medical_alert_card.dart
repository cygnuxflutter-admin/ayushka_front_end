import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/dashboard_alerts_model.dart';
import '../../../routes/app_routes.dart';

/// Interactive card presenting either a Low Medical Stock or Expiring Medicine Batch with Quick Inward action.
class MedicalAlertCard extends StatefulWidget {
  final MedicalLowStockAlertItem? lowStockItem;
  final MedicalExpiringAlertItem? expiringItem;
  final VoidCallback onQuickInward;

  const MedicalAlertCard({
    super.key,
    this.lowStockItem,
    this.expiringItem,
    required this.onQuickInward,
  }) : assert(lowStockItem != null || expiringItem != null, 'Either lowStockItem or expiringItem must be provided');

  @override
  State<MedicalAlertCard> createState() => _MedicalAlertCardState();
}

class _MedicalAlertCardState extends State<MedicalAlertCard> {
  bool _isHovered = false;

  bool get _isLowStock => widget.lowStockItem != null;
  String get _itemName => widget.lowStockItem?.itemName ?? widget.expiringItem!.itemName;
  String get _category => widget.lowStockItem?.category ?? widget.expiringItem?.category ?? 'PHARMACY';
  MedicalLowStockAlertItem? get lowStockItem => widget.lowStockItem;
  MedicalExpiringAlertItem? get expiringItem => widget.expiringItem;
  VoidCallback get onQuickInward => widget.onQuickInward;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isExpired = expiringItem != null && expiringItem!.isExpired;
    final accentColor = _isLowStock
        ? AppColors.error
        : (isExpired ? AppColors.error : AppColors.warning);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: _isHovered
            ? Matrix4.translationValues(0.0, -3.0, 0.0)
            : Matrix4.identity(),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? accentColor.withValues(alpha: 0.5)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: _isHovered ? 1.4 : 1.0,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // High-Visibility Medical Alert Attention Banner
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accentColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIconsRegular.warningCircle, size: 12, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  _isLowStock
                      ? '⚠️ LOW INVENTORY SHORTFALL • REORDER REQUIRED'
                      : '⚠️ BATCH EXPIRING WITHIN 30 DAYS • FIRST-EXPIRE DISPENSE',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Header Row: Category Badge + Status Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsRegular.pill, size: 13, color: AppColors.info),
                    const SizedBox(width: 5),
                    Text(
                      _category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _isLowStock
                      ? 'LOW STOCK'
                      : (isExpired ? 'EXPIRED' : 'EXPIRING SOON'),
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Item Name
          Text(
            _itemName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

          // Condition Details
          if (_isLowStock) ...[
            Text(
              'Current stock: ${lowStockItem!.totalStock.toStringAsFixed(1)} ${lowStockItem!.unit} '
              '(Alert threshold: ≤ ${lowStockItem!.minStockAlert.toStringAsFixed(1)} ${lowStockItem!.unit})',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
          ] else ...[
            Wrap(
              spacing: 14,
              children: [
                Text(
                  'Batch: ${expiringItem!.batchNumber}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
                if (expiringItem!.expiryDate != null)
                  Text(
                    'Expiry: ${DateFormat('dd MMM yyyy').format(expiringItem!.expiryDate!)} (${expiringItem!.daysRemaining}d left)',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.medicalStock),
                child: const Text('Manage Stock', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              CustomButton(
                text: 'Quick Inward',
                icon: PhosphorIconsRegular.arrowDownLeft,
                height: 36,
                width: 140,
                onPressed: onQuickInward,
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
