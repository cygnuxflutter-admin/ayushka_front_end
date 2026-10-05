import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/medical_item_model.dart';
import '../medical_stock_controller.dart';
import '../widgets/medical_stock_animations.dart';
import 'dispose_stock_dialog.dart';

/// Modal dialog displaying all active and historical batches for a specific Medicine SKU
class ViewBatchesDialog extends StatefulWidget {
  final MedicalItemModel item;

  const ViewBatchesDialog({super.key, required this.item});

  static Future<void> show(BuildContext context, {required MedicalItemModel item}) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => ViewBatchesDialog(item: item),
    );
  }

  @override
  State<ViewBatchesDialog> createState() => _ViewBatchesDialogState();
}

class _ViewBatchesDialogState extends State<ViewBatchesDialog> {
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
    final dateFormat = DateFormat('dd MMM yyyy');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get live item batches from controller reactive state
    return Obx(() {
      final liveItem = controller.items.firstWhereOrNull((i) => i.id == widget.item.id) ?? widget.item;
      final sortedBatches = controller.getBatchesForItem(liveItem.id);

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 12,
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880, maxHeight: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Executive Header Banner (Herd & Cattle Style)
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
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: liveItem.categoryEnum.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: liveItem.categoryEnum.color.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          liveItem.categoryEnum.icon,
                          color: liveItem.categoryEnum.color,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  liveItem.itemName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (liveItem.itemCode.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    liveItem.itemCode,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textPrimaryDark : Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Form: ${liveItem.categoryEnum.label}  •  Unit: ${liveItem.unit}  •  Total Available: ${(sortedBatches.isNotEmpty ? sortedBatches.fold<double>(0.0, (s, b) => s + b.availableQuantity) : liveItem.totalStock).toStringAsFixed(0)} ${liveItem.unit} across ${sortedBatches.length} batches',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
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

              // Content / Batches Table
              Expanded(
                child: sortedBatches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorIconsRegular.package, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'No batches recorded for this medicine yet.',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: 14),
                            CustomButton(
                              text: 'Inward Stock Now',
                              icon: PhosphorIconsRegular.plus,
                              height: 38,
                              onPressed: () {
                                Navigator.of(context).pop();
                                controller.inwardSelectedItem.value = liveItem;
                                controller.switchTab(2); // Go to Inward entry
                              },
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          const double horizontalPadding = 40.0;
                          final double availableWidth = (constraints.maxWidth - horizontalPadding).clamp(0.0, double.infinity);
                          const double minTableWidth = 720.0;
                          final double tableWidth = availableWidth < minTableWidth ? minTableWidth : availableWidth;

                          return SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            padding: const EdgeInsets.all(20),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: tableWidth,
                                child: Table(
                                  columnWidths: const {
                                    0: FlexColumnWidth(2.0), // Batch No
                                    1: FlexColumnWidth(1.5), // Status
                                    2: FlexColumnWidth(2.0), // Available Stock
                                    3: FlexColumnWidth(1.8), // Expiry Date
                                    4: FlexColumnWidth(1.4), // Unit Price
                                    5: FixedColumnWidth(130), // Actions
                                  },
                                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                  children: [
                                    // Table Header
                                    TableRow(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF4F6F1),
                                        border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1.5)),
                                      ),
                                      children: [
                                        _tableHeader('Batch Number'),
                                        _tableHeader('Status'),
                                        _tableHeader('Available Stock'),
                                        _tableHeader('Expiry / FEFO'),
                                        _tableHeader('Unit Price'),
                                        _tableHeader('Actions', alignRight: true),
                                      ],
                                    ),

                                    // Batch Rows
                                    ...sortedBatches.map((batch) {
                                      final isExp = batch.isExpired;
                                      final isCrit = batch.isExpiringSoon;
                                      final isWarn = batch.isExpiringWarning;

                                      Color badgeBg = const Color(0xFFE8F5E9);
                                      Color badgeText = const Color(0xFF2E7D32);
                                      String badgeLabel = 'SAFE';

                                      if (isExp) {
                                        badgeBg = const Color(0xFFFFEBEE);
                                        badgeText = const Color(0xFFC62828);
                                        badgeLabel = 'EXPIRED';
                                      } else if (isCrit) {
                                        badgeBg = const Color(0xFFFFF3E0);
                                        badgeText = const Color(0xFFE65100);
                                        badgeLabel = '< 30 DAYS';
                                      } else if (isWarn) {
                                        badgeBg = const Color(0xFFFFFDE7);
                                        badgeText = const Color(0xFFF57F17);
                                        badgeLabel = '30-60 DAYS';
                                      } else if (batch.availableQuantity == 0) {
                                        badgeBg = Colors.grey.shade100;
                                        badgeText = Colors.grey.shade600;
                                        badgeLabel = 'EXHAUSTED';
                                      }

                                      final progress = batch.quantity > 0
                                          ? (batch.availableQuantity / batch.quantity).clamp(0.0, 1.0)
                                          : 0.0;

                                      return TableRow(
                                        decoration: BoxDecoration(
                                          color: isExp ? const Color(0xFFFFF9F9) : Colors.transparent,
                                          border: const Border(bottom: BorderSide(color: AppColors.dividerLight)),
                                        ),
                                        children: [
                                          // Batch No
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  PhosphorIconsRegular.tag,
                                                  size: 15,
                                                  color: isExp ? AppColors.error : AppColors.primary,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        batch.batchNumber,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                          color: isExp ? AppColors.error : AppColors.textPrimaryLight,
                                                        ),
                                                      ),
                                                      if (batch.mfgDate != null)
                                                        Text(
                                                          'Mfg: ${dateFormat.format(batch.mfgDate!)}',
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(fontSize: 10, color: AppColors.textMutedLight),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Status Badge
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: isExp
                                                  ? PulsingBadge(
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: badgeBg,
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(color: badgeText.withValues(alpha: 0.3)),
                                                        ),
                                                        child: Text(
                                                          badgeLabel,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: badgeText,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: badgeBg,
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: badgeText.withValues(alpha: 0.3)),
                                                      ),
                                                      child: Text(
                                                        badgeLabel,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: badgeText,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ),

                                          // Stock level with progress bar
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${batch.availableQuantity.toStringAsFixed(0)} / ${batch.quantity.toStringAsFixed(0)} ${liveItem.unit}',
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                ),
                                                const SizedBox(height: 4),
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: LinearProgressIndicator(
                                                    value: progress,
                                                    minHeight: 5,
                                                    backgroundColor: Colors.grey.shade200,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      isExp
                                                          ? AppColors.error
                                                          : (progress < 0.25 ? AppColors.warning : AppColors.primary),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Expiry Date & Days Left
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  dateFormat.format(batch.expiryDate),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                    color: isExp ? AppColors.error : AppColors.textPrimaryLight,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  batch.daysRemainingLabel,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: isExp ? AppColors.error : (isCrit ? AppColors.warning : Colors.grey.shade600),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Unit Price
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                            child: Text(
                                              '₹${batch.unitPrice.toStringAsFixed(2)}',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                            ),
                                          ),

                                          // Actions
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: batch.availableQuantity > 0
                                                  ? FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: CustomButton(
                                                        text: isExp ? 'Dispose' : 'Adjust',
                                                        variant: isExp ? ButtonVariant.danger : ButtonVariant.outlined,
                                                        icon: isExp ? PhosphorIconsRegular.trash : PhosphorIconsRegular.slidersHorizontal,
                                                        height: 30,
                                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                                        onPressed: () {
                                                          DisposeStockDialog.show(
                                                            context,
                                                            batch: batch,
                                                            item: liveItem,
                                                          );
                                                        },
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Depleted',
                                                      style: TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7FAF4),
                  border: Border(top: BorderSide(color: AppColors.borderLight)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'FEFO Principle: Batches expiring earliest will be automatically prioritized during dispensing.',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(width: 16),
                    CustomButton(
                      text: 'Close',
                      variant: ButtonVariant.outlined,
                      height: 38,
                      onPressed: () => Navigator.of(context).pop(),
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

  Widget _tableHeader(String text, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondaryLight,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
