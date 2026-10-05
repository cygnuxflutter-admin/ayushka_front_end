import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../data/models/medical_item_model.dart';
import '../medical_stock_controller.dart';
import 'add_edit_medicine_dialog.dart';
import 'dispose_stock_dialog.dart';
import 'view_batches_dialog.dart';

/// Comprehensive executive modal dialog for viewing Medicine Details.
/// Mirrors the Herd & Cattle module's executive details dialog pattern (openCowDetailsDialog)
/// with header banner, KPI ribbon micro-cards, section cards, details grid, and action bar.
class MedicineDetailsDialog extends StatefulWidget {
  final MedicalItemModel item;

  const MedicineDetailsDialog({super.key, required this.item});

  static Future<void> show(BuildContext context, {required MedicalItemModel item}) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => MedicineDetailsDialog(item: item),
    );
  }

  @override
  State<MedicineDetailsDialog> createState() => _MedicineDetailsDialogState();
}

class _MedicineDetailsDialogState extends State<MedicineDetailsDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<MedicalStockController>()) {
        Get.find<MedicalStockController>().fetchBatchesForItem(widget.item.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MedicalStockController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Obx(() {
      final liveItem = controller.items.firstWhereOrNull((i) => i.id == widget.item.id) ?? widget.item;
      final sortedBatches = controller.getBatchesForItem(liveItem.id);

      double totalAssetValue = 0.0;
      for (final b in sortedBatches) {
        totalAssetValue += b.availableQuantity * (b.unitPrice > 0 ? b.unitPrice : b.mrp);
      }

      return Dialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth < 600 ? 14 : 24,
          vertical: screenHeight < 700 ? 16 : 28,
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 780,
            maxHeight: screenHeight * 0.90,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -------------------------------------------------------------
              // 1. EXECUTIVE HEADER BANNER (Herd & Cattle pattern)
              // -------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.surfaceDark,
                            AppColors.cardDark,
                          ]
                        : [
                            AppColors.primary.withValues(alpha: 0.08),
                            AppColors.primaryLight.withValues(alpha: 0.03),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medicine Icon Avatar Ring
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: liveItem.categoryEnum.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: liveItem.categoryEnum.color.withValues(alpha: 0.45),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: liveItem.categoryEnum.color.withValues(alpha: 0.14),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          liveItem.categoryEnum.icon,
                          color: liveItem.categoryEnum.color,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Title, SKU Badges & Metadata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Text(
                                liveItem.itemName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              // Copy SKU Code Button
                              if (liveItem.itemCode.isNotEmpty)
                                Tooltip(
                                  message: 'Copy SKU Code',
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: liveItem.itemCode));
                                      CustomSnackbar.showInfo(
                                        title: 'Copied',
                                        message: 'SKU Code ${liveItem.itemCode} copied to clipboard',
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            liveItem.itemCode,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.copy_rounded,
                                            size: 11,
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                              // Category Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: liveItem.categoryEnum.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: liveItem.categoryEnum.color.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      liveItem.categoryEnum.icon,
                                      size: 12,
                                      color: liveItem.categoryEnum.color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      liveItem.categoryEnum.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: liveItem.categoryEnum.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Stock Status Pill (Herd & Cattle status badge style)
                              _buildStockStatusPill(liveItem, isDark),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Subtitle: Manufacturer & Unit Info
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              if (liveItem.manufacturer.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(PhosphorIconsRegular.buildings, size: 13, color: AppColors.textSecondaryLight),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Brand / Mfr: ${liveItem.manufacturer}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                const Text(
                                  'Generic formulation',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                                ),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: AppColors.textMutedLight,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                'Unit: ${liveItem.unitEnum.label}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Modern Close Button
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark.withValues(alpha: 0.8)
                              : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              // -------------------------------------------------------------
              // 2. SCROLLABLE DETAILS BODY
              // -------------------------------------------------------------
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 580;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // A. KPI Micro-Cards Ribbon
                          _buildKpiRibbon(context, isDark, liveItem, totalAssetValue, isWide, sortedBatches),
                          const SizedBox(height: 20),

                          // B. Specifications & Formulation Card
                          _buildSectionCard(
                            context: context,
                            isDark: isDark,
                            title: 'PHARMACEUTICAL SPECIFICATIONS & DATA',
                            icon: PhosphorIconsRegular.pill,
                            child: _buildDetailsGrid(
                              isWide: isWide,
                              isDark: isDark,
                              items: [
                                _DetailGridItem(
                                  icon: PhosphorIconsRegular.pill,
                                  label: 'Medicine Name',
                                  value: liveItem.itemName,
                                ),
                                _DetailGridItem(
                                  icon: PhosphorIconsRegular.barcode,
                                  label: 'Item Code / SKU',
                                  value: liveItem.itemCode.isNotEmpty ? liveItem.itemCode : 'Auto-generated',
                                ),
                                _DetailGridItem(
                                  icon: PhosphorIconsRegular.tag,
                                  label: 'Category / Form',
                                  value: liveItem.categoryEnum.label,
                                ),
                                _DetailGridItem(
                                  icon: PhosphorIconsRegular.scales,
                                  label: 'Packaging Unit',
                                  value: liveItem.unitEnum.label,
                                ),
                                _DetailGridItem(
                                  icon: PhosphorIconsRegular.buildings,
                                  label: 'Manufacturer',
                                  value: liveItem.manufacturer.isNotEmpty ? liveItem.manufacturer : 'Unspecified',
                                ),
                                _DetailGridItem(
                                  icon: PhosphorIconsRegular.warningCircle,
                                  label: 'Min Stock Alert Threshold',
                                  value: '${liveItem.minStockAlert.toStringAsFixed(0)} ${liveItem.unit}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // C. Clinical Notes & Usage (if present)
                          if (liveItem.description.trim().isNotEmpty) ...[
                            _buildSectionCard(
                              context: context,
                              isDark: isDark,
                              title: 'CLINICAL NOTES & DOSAGE INSTRUCTIONS',
                              icon: PhosphorIconsRegular.notepad,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                  ),
                                ),
                                child: Text(
                                  liveItem.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],

                          // D. Active Batches Breakdown Card
                          _buildSectionCard(
                            context: context,
                            isDark: isDark,
                            title: 'ACTIVE INVENTORY BATCHES (${sortedBatches.length})',
                            icon: PhosphorIconsRegular.stack,
                            child: sortedBatches.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(PhosphorIconsRegular.package, size: 36, color: Colors.grey.shade400),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'No stock batches recorded yet.',
                                            style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                                          ),
                                          const SizedBox(height: 10),
                                          CustomButton(
                                            text: 'Record Inward Stock',
                                            icon: PhosphorIconsRegular.plus,
                                            height: 36,
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              controller.inwardSelectedItem.value = liveItem;
                                              controller.switchTab(2);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: sortedBatches.map((batch) {
                                      final isExp = batch.isExpired;
                                      final isCrit = batch.isExpiringSoon;
                                      final isWarn = batch.isExpiringWarning;

                                      Color pillBg = const Color(0xFFE8F5E9);
                                      Color pillText = const Color(0xFF2E7D32);
                                      String pillLabel = 'SAFE';

                                      if (isExp) {
                                        pillBg = const Color(0xFFFFEBEE);
                                        pillText = const Color(0xFFC62828);
                                        pillLabel = 'EXPIRED';
                                      } else if (isCrit) {
                                        pillBg = const Color(0xFFFFF3E0);
                                        pillText = const Color(0xFFE65100);
                                        pillLabel = '< 30 DAYS';
                                      } else if (isWarn) {
                                        pillBg = const Color(0xFFFFFDE7);
                                        pillText = const Color(0xFFF57F17);
                                        pillLabel = '30-60 DAYS';
                                      } else if (batch.availableQuantity == 0) {
                                        pillBg = Colors.grey.shade100;
                                        pillText = Colors.grey.shade600;
                                        pillLabel = 'EMPTY';
                                      }

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isExp
                                              ? const Color(0xFFFFF5F5)
                                              : (isDark ? AppColors.surfaceDark : Colors.white),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isExp
                                                ? Colors.red.shade200
                                                : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Batch Tag
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                batch.batchNumber,
                                                style: const TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),

                                            // Expiry status
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: pillBg,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                pillLabel,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: pillText,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Expiry Date
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Exp: ${dateFormat.format(batch.expiryDate)}',
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                  ),
                                                  Text(
                                                    batch.daysRemainingLabel,
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      color: isExp ? AppColors.error : AppColors.textSecondaryLight,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Stock quantity
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${batch.availableQuantity.toStringAsFixed(0)} ${liveItem.unit}',
                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                ),
                                                if (batch.unitPrice > 0)
                                                  Text(
                                                    '@ ₹${batch.unitPrice.toStringAsFixed(2)}',
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                                                  ),
                                              ],
                                            ),

                                            // Quick disposal icon if expired with quantity
                                            if (batch.isExpired && batch.availableQuantity > 0) ...[
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.error),
                                                tooltip: 'Dispose Expired Stock',
                                                onPressed: () {
                                                  DisposeStockDialog.show(context, batch: batch);
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // -------------------------------------------------------------
              // 3. BOTTOM ACTION BAR & SYSTEM ID STRIP (Herd & Cattle pattern)
              // -------------------------------------------------------------
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.6) : AppColors.backgroundLight,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // System Mongo ID strip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Tooltip(
                          message: 'Click to copy System ID (${liveItem.id})',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: liveItem.id));
                              CustomSnackbar.showInfo(
                                title: 'Copied',
                                message: 'Medicine ID copied to clipboard',
                              );
                            },
                            child: Row(
                              children: [
                                const Icon(PhosphorIconsRegular.hash, size: 12, color: AppColors.textMutedLight),
                                const SizedBox(width: 4),
                                Text(
                                  'ID: ${liveItem.id}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontFamily: 'monospace',
                                    color: AppColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (liveItem.gaushalaName != null && liveItem.gaushalaName!.isNotEmpty)
                          Text(
                            'Unit: ${liveItem.gaushalaName}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CustomButton(
                          text: 'Inward Stock',
                          icon: PhosphorIconsRegular.arrowDownLeft,
                          variant: ButtonVariant.outlined,
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          onPressed: () {
                            Navigator.of(context).pop();
                            controller.inwardSelectedItem.value = liveItem;
                            controller.switchTab(2);
                          },
                        ),
                        const SizedBox(width: 8),
                        CustomButton(
                          text: 'Batches',
                          icon: PhosphorIconsRegular.stack,
                          variant: ButtonVariant.outlined,
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          onPressed: () {
                            Navigator.of(context).pop();
                            ViewBatchesDialog.show(context, item: liveItem);
                          },
                        ),
                        const SizedBox(width: 8),
                        CustomButton(
                          text: 'Close',
                          variant: ButtonVariant.outlined,
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        CustomButton(
                          text: 'Edit Medicine',
                          icon: PhosphorIconsRegular.pencilSimple,
                          variant: ButtonVariant.primary,
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          onPressed: () {
                            Navigator.of(context).pop();
                            AddEditMedicineDialog.show(context, existingItem: liveItem);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStockStatusPill(MedicalItemModel item, bool isDark) {
    final String pillText;
    final Color pillBg;
    final Color pillTextColor;
    final IconData icon;

    if (item.isOutOfStock) {
      pillText = 'Out of Stock';
      pillBg = const Color(0xFFFFEBEE);
      pillTextColor = const Color(0xFFC62828);
      icon = PhosphorIconsRegular.warningOctagon;
    } else if (item.isLowStock) {
      pillText = 'Low Stock';
      pillBg = const Color(0xFFFFF3E0);
      pillTextColor = const Color(0xFFE65100);
      icon = PhosphorIconsRegular.warning;
    } else {
      pillText = 'In Stock';
      pillBg = const Color(0xFFE8F5E9);
      pillTextColor = const Color(0xFF2E7D32);
      icon = PhosphorIconsRegular.checkCircle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pillTextColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: pillTextColor),
          const SizedBox(width: 4),
          Text(
            pillText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: pillTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRibbon(
    BuildContext context,
    bool isDark,
    MedicalItemModel item,
    double totalAssetValue,
    bool isWide,
    List<MedicalBatchModel> sortedBatches,
  ) {
    final stockColor = item.isOutOfStock
        ? const Color(0xFFC62828)
        : (item.isLowStock ? const Color(0xFFE65100) : const Color(0xFF2E7D32));

    final computedStock = sortedBatches.isNotEmpty
        ? sortedBatches.fold<double>(0.0, (s, b) => s + b.availableQuantity)
        : item.totalStock;

    final currentStockCard = _buildKpiCard(
      isDark: isDark,
      icon: PhosphorIconsRegular.scales,
      color: stockColor,
      label: 'CURRENT STOCK',
      value: '${computedStock.toStringAsFixed(0)} ${item.unit}',
      subtitle: item.isOutOfStock ? 'Stock depleted' : (item.isLowStock ? 'Below threshold' : 'Adequate stock'),
    );

    final alertCard = _buildKpiCard(
      isDark: isDark,
      icon: PhosphorIconsRegular.warningCircle,
      color: const Color(0xFFE65100),
      label: 'ALERT THRESHOLD',
      value: '${item.minStockAlert.toStringAsFixed(0)} ${item.unit}',
      subtitle: 'Reorder trigger level',
    );

    final activeBatchesCount = sortedBatches.where((b) => b.availableQuantity > 0 && !b.isExpired).length;
    final batchesCard = _buildKpiCard(
      isDark: isDark,
      icon: PhosphorIconsRegular.stack,
      color: AppColors.primary,
      label: 'ACTIVE BATCHES',
      value: '${activeBatchesCount > 0 ? activeBatchesCount : item.activeBatchesCount} Active',
      subtitle: '${sortedBatches.length} total recorded',
    );

    final valueCard = _buildKpiCard(
      isDark: isDark,
      icon: PhosphorIconsRegular.currencyInr,
      color: const Color(0xFF6366F1),
      label: 'TOTAL ASSET VALUE',
      value: '₹${totalAssetValue.toStringAsFixed(0)}',
      subtitle: 'Inventory valuation',
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(child: currentStockCard),
          const SizedBox(width: 10),
          Expanded(child: alertCard),
          const SizedBox(width: 10),
          Expanded(child: batchesCard),
          const SizedBox(width: 10),
          Expanded(child: valueCard),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: currentStockCard),
              const SizedBox(width: 10),
              Expanded(child: alertCard),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: batchesCard),
              const SizedBox(width: 10),
              Expanded(child: valueCard),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildKpiCard({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icon, color: color, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMutedLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 15, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid({
    required bool isWide,
    required List<_DetailGridItem> items,
    required bool isDark,
  }) {
    return Wrap(
      spacing: 16,
      runSpacing: 14,
      children: items.map((item) {
        final itemWidth = isWide ? (780 - 44 - 32 - 16) / 2 : double.infinity;
        return SizedBox(
          width: itemWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.icon,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DetailGridItem {
  final IconData icon;
  final String label;
  final String value;

  const _DetailGridItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
