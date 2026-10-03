import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/values/app_colors.dart';
import '../../../core/values/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dropdown_search.dart';
import '../../../core/widgets/custom_pagination.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/medical_item_model.dart';
import '../dialogs/dispose_stock_dialog.dart';
import '../medical_stock_controller.dart';
import '../widgets/medical_stock_animations.dart';

/// Screen E: Batches & Expiry Tracker
/// Dedicated expiry radar tracking shelf-life across all batches with color-coded
/// warning badges, medicine filters, and quick expired stock disposal actions.
class BatchesTrackerView extends StatelessWidget {
  const BatchesTrackerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MedicalStockController>();
    final dateFormat = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width < 600 ? 14 : 24,
        vertical: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -----------------------------------------------------------
              // TOP HEADER
              // -----------------------------------------------------------
              _buildHeader(context, controller),
              const SizedBox(height: 18),

              // -----------------------------------------------------------
              // FILTER TABS & SEARCH BAR
              // -----------------------------------------------------------
              _buildFilterBar(context, controller),
              const SizedBox(height: 18),

              // -----------------------------------------------------------
              // BATCHES DATA TABLE
              // -----------------------------------------------------------
              _buildBatchesTableCard(context, controller, dateFormat),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MedicalStockController controller) {
    return StaggeredEntrance(
      index: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 750;

          final titleRow = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(PhosphorIconsRegular.clockCountdown, color: Color(0xFFEA580C), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Batches & Expiry Tracker (FEFO Radar)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Obx(
                      () => Text(
                        'Monitoring ${controller.allBatches.length} production lots across all veterinary medicines in ${controller.activeGaushalaName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final legendPills = Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _legendIndicator('Safe (>60d)', const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
              _legendIndicator('30-60 Days', const Color(0xFFD97706), const Color(0xFFFEF9C3)),
              _legendIndicator('< 30 Days', const Color(0xFFEA580C), const Color(0xFFFFF0E6)),
              _legendIndicator('Expired', const Color(0xFFDC2626), const Color(0xFFFDE8E8)),
            ],
          );

          return Container(
            padding: EdgeInsets.all(isMobile ? 14 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      titleRow,
                      const SizedBox(height: 12),
                      legendPills,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: titleRow),
                      const SizedBox(width: 14),
                      legendPills,
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _legendIndicator(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, MedicalStockController controller) {
    return StaggeredEntrance(
      index: 1,
      child: Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Filter Tabs (All, Active, Expiring in 30 Days, Expired)
          Obx(() {
            final allCount = controller.allBatches.length;
            final activeCount = controller.allBatches.where((b) => b.availableQuantity > 0 && !b.isExpired).length;
            final expiringCount = controller.allBatches.where((b) => b.isExpiringSoon && b.availableQuantity > 0).length;
            final expiredCount = controller.allBatches.where((b) => b.isExpired).length;

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterTab(
                  label: 'All Batches',
                  value: 'ALL',
                  count: allCount,
                  activeColor: AppColors.primary,
                  controller: controller,
                ),
                _filterTab(
                  label: 'Active Batches',
                  value: 'ACTIVE',
                  count: activeCount,
                  activeColor: const Color(0xFF16A34A),
                  dotColor: const Color(0xFF16A34A),
                  inactiveBadgeBg: const Color(0xFFDCFCE7),
                  inactiveBadgeTextColor: const Color(0xFF15803D),
                  controller: controller,
                ),
                _filterTab(
                  label: 'Expiring in < 30 Days',
                  value: 'EXPIRING_30',
                  count: expiringCount,
                  activeColor: const Color(0xFFEA580C),
                  dotColor: const Color(0xFFEA580C),
                  inactiveBadgeBg: const Color(0xFFFFF0E6),
                  inactiveBadgeTextColor: const Color(0xFFC2410C),
                  controller: controller,
                ),
                _filterTab(
                  label: 'Expired Batches',
                  value: 'EXPIRED',
                  count: expiredCount,
                  activeColor: const Color(0xFFDC2626),
                  dotColor: const Color(0xFFDC2626),
                  inactiveBadgeBg: const Color(0xFFFDE8E8),
                  inactiveBadgeTextColor: const Color(0xFFB91C1C),
                  controller: controller,
                ),
              ],
            );
          }),

          const SizedBox(width: 10),

          // Search Field
          SizedBox(
            width: 290,
            child: CustomTextField(
              hint: 'Search batch no or medicine...',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 16),
              prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onChanged: (val) {
                controller.batchSearchQuery.value = val;
                controller.batchesCurrentPage.value = 1;
              },
            ),
          ),

          // Medicine Filter Dropdown
          Obx(() {
            final medicineList = controller.items.toList();
            final currentId = controller.batchMedicineFilter.value;
            String currentDisplay = 'All Medicines';
            if (currentId != null && currentId.isNotEmpty && currentId != 'all') {
              final match = medicineList.firstWhereOrNull((m) => m.id == currentId);
              if (match != null) {
                currentDisplay = match.itemName;
              }
            }

            return SizedBox(
              width: 230,
              child: CustomDropdownSearch<String>(
                hint: 'All Medicines',
                prefixIcon: PhosphorIconsRegular.pill,
                searchable: medicineList.length > 5,
                searchHint: 'Search medicine...',
                selectedItem: currentDisplay,
                items: [
                  'All Medicines',
                  ...medicineList.map((m) => m.itemName),
                ],
                itemAsString: (s) => s,
                showClearButton: false,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                onChanged: (val) {
                  if (val == null || val == 'All Medicines') {
                    controller.batchMedicineFilter.value = null;
                  } else {
                    final match = medicineList.firstWhereOrNull((m) => m.itemName == val);
                    controller.batchMedicineFilter.value = match?.id;
                  }
                  controller.batchesCurrentPage.value = 1;
                },
                customItemBuilder: (ctx, item, isDisabled, isSelected) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsRegular.pill, size: 16, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                      ],
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    ),
  );
}

Widget _filterTab({
  required String label,
  required String value,
  required int count,
  required Color activeColor,
  Color? dotColor,
  Color? inactiveBadgeBg,
  Color? inactiveBadgeTextColor,
  required MedicalStockController controller,
}) {
  final isSelected = controller.batchExpiryFilter.value == value;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        controller.batchExpiryFilter.value = value;
        controller.batchesCurrentPage.value = 1;
      },
      borderRadius: BorderRadius.circular(10),
      hoverColor: activeColor.withValues(alpha: 0.06),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.borderLight,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.22),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedScale(
              scale: isSelected ? 1.06 : 1.0,
              duration: const Duration(milliseconds: 160),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (inactiveBadgeBg ?? const Color(0xFFEDF2E8)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (inactiveBadgeTextColor ?? AppColors.textSecondaryLight),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildBatchesTableCard(BuildContext context, MedicalStockController controller, DateFormat dateFormat) {
  return StaggeredEntrance(
    index: 2,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() {
            final list = controller.filteredBatches;

            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(PhosphorIconsRegular.package, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text(
                        'No batches match this filter category',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Switch to "All Batches" or adjust the search query.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
              );
            }

            final paginated = controller.paginatedBatches;

            return LayoutBuilder(
              builder: (context, constraints) {
                const double minTableWidth = 1150.0;
                final double tableWidth = constraints.maxWidth < minTableWidth ? minTableWidth : constraints.maxWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Row
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAF7),
                            border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1.5)),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 18, child: _th('Batch Number')),
                              Expanded(flex: 26, child: _th('Medicine Item')),
                              Expanded(flex: 15, child: _th('Expiry Status')),
                              Expanded(flex: 18, child: _th('Available Stock')),
                              Expanded(flex: 18, child: _th('Expiry Date (FEFO)')),
                              Expanded(flex: 12, child: _th('Price')),
                              Expanded(flex: 18, child: _th('Supplier / Source')),
                              SizedBox(width: 140, child: _th('Actions', alignRight: true)),
                            ],
                          ),
                        ),

                        // Batch Rows with Herd & Cattle hover animation
                        ...paginated.asMap().entries.map((entry) {
                          final pageStartIndex = (controller.batchesCurrentPage.value - 1) * controller.batchesPerPage.value;
                          final index = pageStartIndex + entry.key;
                          final batch = entry.value;
                          final isDark = Theme.of(context).brightness == Brightness.dark;

                          return _HoverableBatchTrackerRow(
                            key: ValueKey('batch_${batch.id}_${batch.batchNumber}_$index'),
                            index: index,
                            batch: batch,
                            isDark: isDark,
                            dateFormat: dateFormat,
                            onAdjust: () {
                              DisposeStockDialog.show(context, batch: batch);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            );
          }),

          // Pagination Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: Obx(
              () => CustomPagination(
                currentPage: controller.batchesCurrentPage.value,
                totalItems: controller.filteredBatches.length,
                rowsPerPage: controller.batchesPerPage.value,
                rowsPerPageOptions: const [5, 10, 20, 50],
                onPageChanged: controller.setBatchesPage,
                onRowsPerPageChanged: controller.setBatchesPerPage,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _th(String text, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

/// Interactive table row with Herd & Cattle animated container, 3.5px left indicator,
/// glowing batch tag, and smooth 160ms transitions.
class _HoverableBatchTrackerRow extends StatefulWidget {
  final int index;
  final MedicalBatchModel batch;
  final bool isDark;
  final DateFormat dateFormat;
  final VoidCallback onAdjust;

  const _HoverableBatchTrackerRow({
    super.key,
    required this.index,
    required this.batch,
    required this.isDark,
    required this.dateFormat,
    required this.onAdjust,
  });

  @override
  State<_HoverableBatchTrackerRow> createState() => _HoverableBatchTrackerRowState();
}

class _HoverableBatchTrackerRowState extends State<_HoverableBatchTrackerRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final isDark = widget.isDark;
    final status = batch.expiryStatus;
    final isExpired = batch.isExpired;
    final progress = batch.quantity > 0
        ? (batch.availableQuantity / batch.quantity).clamp(0.0, 1.0)
        : 0.0;

    final Color primaryAccent = isExpired
        ? AppColors.error
        : (batch.isExpiringSoon ? const Color(0xFFEA580C) : (isDark ? AppColors.primaryLight : AppColors.primary));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: _isHovered
              ? (isDark
                  ? AppColors.surfaceDark.withValues(alpha: 0.85)
                  : (isExpired
                      ? const Color(0xFFFFEEEE)
                      : AppColors.primary.withValues(alpha: 0.045)))
              : (isExpired
                  ? (isDark ? Colors.red.withValues(alpha: 0.08) : const Color(0xFFFFF9F9))
                  : Colors.transparent),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 0.6,
            ),
            left: BorderSide(
              color: _isHovered ? primaryAccent : Colors.transparent,
              width: 3.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Batch Number Tag with Herd & Cattle AnimatedContainer
            Expanded(
              flex: 18,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryAccent.withValues(alpha: _isHovered ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: primaryAccent.withValues(alpha: _isHovered ? 0.50 : 0.30),
                        width: 1.0,
                      ),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: primaryAccent.withValues(alpha: 0.16),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIconsRegular.tag,
                          size: 13,
                          color: primaryAccent,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            batch.batchNumber,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Medicine Item
            Expanded(
              flex: 26,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      batch.itemName.isNotEmpty ? batch.itemName : '—',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _isHovered
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (batch.itemCode.isNotEmpty)
                      Text(
                        batch.itemCode,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),

            // Expiry Status Badge
            Expanded(
              flex: 15,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: status.backgroundColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: status.color.withValues(alpha: _isHovered ? 0.55 : 0.30),
                        width: 0.8,
                      ),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: status.color.withValues(alpha: 0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: status.color,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Available Stock + Progress
            Expanded(
              flex: 18,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${batch.availableQuantity.toStringAsFixed(0)} / ${batch.quantity.toStringAsFixed(0)} units',
                      style: TextStyle(
                        fontWeight: _isHovered ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isExpired
                              ? AppColors.error
                              : (progress < 0.25 ? AppColors.warning : AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expiry Date (FEFO)
            Expanded(
              flex: 18,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.dateFormat.format(batch.expiryDate),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isExpired ? AppColors.error : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      batch.daysRemainingLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: status.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Price
            Expanded(
              flex: 12,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Text(
                  batch.unitPrice > 0 ? '₹${batch.unitPrice.toStringAsFixed(2)}' : '-',
                  style: TextStyle(
                    fontWeight: _isHovered ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            // Supplier / Source
            Expanded(
              flex: 18,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Text(
                  batch.supplierOrDonorName?.isNotEmpty == true ? batch.supplierOrDonorName! : 'Direct Purchase',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isHovered
                        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Actions Button
            SizedBox(
              width: 140,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: batch.availableQuantity > 0
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeInOut,
                            child: CustomButton(
                              text: isExpired ? 'Dispose' : 'Adjust',
                              variant: isExpired ? ButtonVariant.danger : ButtonVariant.outlined,
                              icon: isExpired ? PhosphorIconsRegular.trash : PhosphorIconsRegular.slidersHorizontal,
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              onPressed: widget.onAdjust,
                            ),
                          ),
                        )
                      : Text('Depleted', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
