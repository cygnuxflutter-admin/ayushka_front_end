import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/utils/responsive_layout.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dropdown_search.dart';
import '../../../core/widgets/custom_pagination.dart';
import '../../../core/widgets/mobile_list_bottom_loader.dart';
import '../../../data/models/medical_item_model.dart';
import '../dialogs/transaction_details_dialog.dart';
import '../medical_stock_controller.dart';
import '../widgets/medical_stock_animations.dart';

/// Screen F: Stock Ledger / Transaction Audit Log
/// Immutable ledger tracking all inward additions, FEFO outward deductions,
/// expired disposals, and audit corrections with batch breakdown transparency.
class StockLedgerView extends StatelessWidget {
  const StockLedgerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MedicalStockController>();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          controller.loadMoreMobileLedger();
        }
        return false;
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -----------------------------------------------------------
                // TOP HEADER
                // -----------------------------------------------------------
                StaggeredEntrance(
                  index: 0,
                  child: _buildHeader(context, controller),
                ),
                const SizedBox(height: 18),

                // -----------------------------------------------------------
                // FILTERS BAR (DATE RANGE, TYPE, MEDICINE)
                // -----------------------------------------------------------
                StaggeredEntrance(
                  index: 1,
                  child: _buildFiltersBar(context, controller),
                ),
                const SizedBox(height: 18),

                // -----------------------------------------------------------
                // LEDGER DATA TABLE
                // -----------------------------------------------------------
                StaggeredEntrance(
                  index: 2,
                  child: _buildLedgerTableCard(context, controller, dateFormat),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MedicalStockController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(PhosphorIconsRegular.scroll, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stock Movement & Transaction Ledger',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 3),
                Obx(
                  () => Text(
                    'Immutable audit trail of purchases, treatments, and batch deductions in ${controller.activeGaushalaName}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh Ledger',
            onPressed: () => controller.refreshAllData(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar(BuildContext context, MedicalStockController controller) {
    final filterDateFormat = DateFormat('dd MMM yyyy');

    return Container(
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
          // Transaction Type Filter (Herd & Cattle style)
          Obx(() {
            final selectedCode = controller.ledgerTypeFilter.value;
            final isAll = selectedCode == 'ALL';
            final selectedLabel = isAll ? 'All Movement Types' : MedicalTransactionType.fromCode(selectedCode).label;

            return SizedBox(
              width: 225,
              child: CustomDropdownSearch<String>(
                hint: 'All Movement Types',
                prefixIcon: PhosphorIconsRegular.arrowsLeftRight,
                selectedItem: selectedLabel,
                items: [
                  'All Movement Types',
                  ...MedicalTransactionType.values.map((t) => t.label),
                ],
                itemAsString: (s) => s,
                showClearButton: false,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                onChanged: (val) {
                  if (val == null || val == 'All Movement Types') {
                    controller.ledgerTypeFilter.value = 'ALL';
                  } else {
                    final match = MedicalTransactionType.values.firstWhereOrNull((t) => t.label == val);
                    controller.ledgerTypeFilter.value = match?.code ?? 'ALL';
                  }
                  controller.ledgerPage.value = 1;
                },
                customItemBuilder: (ctx, item, isDisabled, isSelected) {
                  final isItemAll = item == 'All Movement Types';
                  final t = isItemAll ? null : MedicalTransactionType.values.firstWhereOrNull((x) => x.label == item);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    child: Row(
                      children: [
                        if (isItemAll)
                          const Icon(PhosphorIconsRegular.arrowsLeftRight, size: 16, color: AppColors.textSecondaryLight)
                        else
                          Icon(t?.icon ?? PhosphorIconsRegular.arrowsLeftRight, size: 16, color: t?.color ?? AppColors.primary),
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

          // Medicine Filter (Herd & Cattle style)
          Obx(() {
            final medicineList = controller.items.toList();
            final currentId = controller.ledgerMedicineFilter.value;
            String currentDisplay = 'All Medicines';
            if (currentId != null && currentId.isNotEmpty && currentId != 'all') {
              final match = medicineList.firstWhereOrNull((m) => m.id == currentId);
              if (match != null) {
                currentDisplay = match.itemName;
              }
            }

            return SizedBox(
              width: 240,
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
                    controller.ledgerMedicineFilter.value = null;
                  } else {
                    final match = medicineList.firstWhereOrNull((m) => m.itemName == val);
                    controller.ledgerMedicineFilter.value = match?.id;
                  }
                  controller.ledgerPage.value = 1;
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

          // Date Range: Start Date
          Obx(
            () => InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: controller.ledgerStartDate.value ?? DateTime.now().subtract(const Duration(days: 30)),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  controller.ledgerStartDate.value = picked;
                  controller.ledgerPage.value = 1;
                }
              },
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsRegular.calendarBlank, size: 16, color: AppColors.textSecondaryLight),
                    const SizedBox(width: 8),
                    Text(
                      controller.ledgerStartDate.value != null
                          ? 'From: ${filterDateFormat.format(controller.ledgerStartDate.value!)}'
                          : 'From Date',
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (controller.ledgerStartDate.value != null) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => controller.ledgerStartDate.value = null,
                        child: const Icon(Icons.close, size: 14, color: AppColors.textMutedLight),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Date Range: End Date
          Obx(
            () => InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: controller.ledgerEndDate.value ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  controller.ledgerEndDate.value = picked;
                  controller.ledgerPage.value = 1;
                }
              },
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsRegular.calendarBlank, size: 16, color: AppColors.textSecondaryLight),
                    const SizedBox(width: 8),
                    Text(
                      controller.ledgerEndDate.value != null
                          ? 'To: ${filterDateFormat.format(controller.ledgerEndDate.value!)}'
                          : 'To Date',
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (controller.ledgerEndDate.value != null) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => controller.ledgerEndDate.value = null,
                        child: const Icon(Icons.close, size: 14, color: AppColors.textMutedLight),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Clear Filters
          CustomButton(
            text: 'Reset Filters',
            icon: PhosphorIconsRegular.arrowCounterClockwise,
            variant: ButtonVariant.outlined,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            onPressed: () {
              controller.ledgerTypeFilter.value = 'ALL';
              controller.ledgerMedicineFilter.value = null;
              controller.ledgerStartDate.value = null;
              controller.ledgerEndDate.value = null;
              controller.ledgerPage.value = 1;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerTableCard(BuildContext context, MedicalStockController controller, DateFormat dateFormat) {
    return Container(
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
            final isMobile = ResponsiveLayout.isMobile(context);
            final paginated = isMobile ? controller.mobileTransactions : controller.paginatedTransactions;

            if (paginated.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(PhosphorIconsRegular.scroll, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text(
                        'No transactions found in ledger',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Try clearing the date range or transaction type filter.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: paginated.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final txn = paginated[index];
                      return _buildMobileTransactionCard(context, txn, dateFormat);
                    },
                  ),
                  MobileListBottomLoader(
                    hasMore: controller.hasMoreMobileLedger,
                    totalCount: controller.filteredTransactions.length,
                  ),
                ],
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                const double minTableWidth = 1100.0;
                final double tableWidth = constraints.maxWidth < minTableWidth ? minTableWidth : constraints.maxWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Column Headers
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAF7),
                            border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1.5)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(flex: 18, child: _thText('Date & Time')),
                              Expanded(flex: 15, child: _thText('Movement')),
                              Expanded(flex: 14, child: _thText('Reason')),
                              Expanded(flex: 22, child: _thText('Medicine Item')),
                              Expanded(flex: 14, child: _thText('Quantity')),
                              Expanded(flex: 20, child: _thText('Patient / Party')),
                              Expanded(flex: 24, child: _thText('Batches Breakdown')),
                              const SizedBox(width: 50),
                            ],
                          ),
                        ),

                        // Ledger rows with Herd & Cattle hover animation
                        ...paginated.asMap().entries.map((entry) {
                          final pageStartIndex = (controller.ledgerPage.value - 1) * controller.ledgerLimit.value;
                          final index = pageStartIndex + entry.key;
                          final txn = entry.value;
                          final isDark = Theme.of(context).brightness == Brightness.dark;

                          return _HoverableLedgerTableRow(
                            key: ValueKey('ledger_${txn.id}_$index'),
                            index: index,
                            txn: txn,
                            isDark: isDark,
                            dateFormat: dateFormat,
                            onView: () => TransactionDetailsDialog.show(context, transaction: txn),
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
          Obx(() {
            if (ResponsiveLayout.isMobile(context)) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: CustomPagination(
                currentPage: controller.ledgerPage.value,
                totalItems: controller.filteredTransactions.length,
                rowsPerPage: controller.ledgerLimit.value,
                onPageChanged: (page) => controller.ledgerPage.value = page,
                onRowsPerPageChanged: (limit) {
                  controller.ledgerLimit.value = limit;
                  controller.ledgerPage.value = 1;
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _thText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondaryLight,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildMobileTransactionCard(
    BuildContext context,
    MedicalTransactionModel txn,
    DateFormat dateFormat,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = txn.typeEnum;
    final isInward = txn.isInward;
    final Color primaryThemeColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final Color accentColor = isInward
        ? primaryThemeColor
        : (txn.isDisposal ? AppColors.error : const Color(0xFFEA580C));
    final Color badgeColor = isInward ? primaryThemeColor : type.color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: InkWell(
        onTap: () => TransactionDetailsDialog.show(context, transaction: txn),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(type.icon, size: 13, color: badgeColor),
                      const SizedBox(width: 4),
                      Text(
                        type.code,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  txn.transactionDate != null ? dateFormat.format(txn.transactionDate!) : '-',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        txn.itemName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      if (txn.itemCode.isNotEmpty)
                        Text(
                          txn.itemCode,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${isInward ? '+' : '-'} ${txn.quantity.toStringAsFixed(0)} ${txn.unit}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Reason: ${txn.reason}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (txn.cowTagId?.isNotEmpty == true || txn.supplierOrDonorName.isNotEmpty || txn.doctorName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      txn.cowTagId?.isNotEmpty == true
                          ? 'Tag: ${txn.cowTagId!}'
                          : (txn.supplierOrDonorName.isNotEmpty
                              ? txn.supplierOrDonorName
                              : 'Dr. ${txn.doctorName}'),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            if (txn.batches.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: txn.batches.map((b) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      '${b.batchNumber}: ${b.quantity.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Interactive table row with Herd & Cattle animated container, 3.5px left indicator,
/// glowing type badge, animated batch breakdown chips, and smooth 160ms transitions.
class _HoverableLedgerTableRow extends StatefulWidget {
  final int index;
  final MedicalTransactionModel txn;
  final bool isDark;
  final DateFormat dateFormat;
  final VoidCallback onView;

  const _HoverableLedgerTableRow({
    super.key,
    required this.index,
    required this.txn,
    required this.isDark,
    required this.dateFormat,
    required this.onView,
  });

  @override
  State<_HoverableLedgerTableRow> createState() => _HoverableLedgerTableRowState();
}

class _HoverableLedgerTableRowState extends State<_HoverableLedgerTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final txn = widget.txn;
    final isDark = widget.isDark;
    final type = txn.typeEnum;
    final isInward = txn.isInward;
    final Color primaryThemeColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final Color accentColor = isInward
        ? primaryThemeColor
        : (txn.isDisposal ? AppColors.error : const Color(0xFFEA580C));
    final Color badgeColor = isInward ? primaryThemeColor : type.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onView,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark
                    ? AppColors.surfaceDark.withValues(alpha: 0.85)
                    : AppColors.primary.withValues(alpha: 0.045))
                : Colors.transparent,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 0.6,
              ),
              left: BorderSide(
                color: _isHovered ? accentColor : Colors.transparent,
                width: 3.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Date & Time
              Expanded(
                flex: 18,
                child: Text(
                  txn.transactionDate != null ? widget.dateFormat.format(txn.transactionDate!) : '-',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _isHovered ? FontWeight.bold : FontWeight.w500,
                    color: _isHovered
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                ),
              ),

              // Type Badge (with animated hover glow matching app theme)
              Expanded(
                flex: 15,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: _isHovered ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: _isHovered ? 0.50 : 0.30),
                        width: 1.0,
                      ),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: badgeColor.withValues(alpha: 0.16),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(type.icon, size: 14, color: badgeColor),
                        const SizedBox(width: 6),
                        Text(
                          type.code,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Reason
              Expanded(
                flex: 14,
                child: Text(
                  txn.reason,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _isHovered ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),

              // Medicine Item
              Expanded(
                flex: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      txn.itemName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _isHovered
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                    ),
                    if (txn.itemCode.isNotEmpty)
                      Text(
                        txn.itemCode,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                      ),
                  ],
                ),
              ),

              // Quantity
              Expanded(
                flex: 14,
                child: Text(
                  '${isInward ? '+' : '-'} ${txn.quantity.toStringAsFixed(0)} ${txn.unit}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isInward
                        ? primaryThemeColor
                        : (txn.isDisposal ? AppColors.error : const Color(0xFFEA580C)),
                  ),
                ),
              ),

              // Patient / Party / Doctor
              Expanded(
                flex: 20,
                child: Text(
                  txn.cowTagId?.isNotEmpty == true
                      ? 'Cow: ${txn.cowTagId!}'
                      : (txn.supplierOrDonorName.isNotEmpty
                          ? txn.supplierOrDonorName
                          : (txn.doctorName.isNotEmpty ? 'Dr. ${txn.doctorName}' : '-')),
                  style: TextStyle(
                    fontSize: 12,
                    color: _isHovered
                        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Batches breakdown chips
              Expanded(
                flex: 24,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: txn.batches.map((b) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _isHovered
                            ? (isDark ? AppColors.surfaceDark : Colors.white)
                            : (isDark ? AppColors.surfaceDark : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _isHovered
                              ? (isDark ? AppColors.primaryLight : AppColors.primary.withValues(alpha: 0.5))
                              : (isDark ? AppColors.borderDark : Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        '${b.batchNumber}: ${b.quantity.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: _isHovered
                              ? (isDark ? AppColors.primaryLight : AppColors.primary)
                              : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                          fontWeight: _isHovered ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // View Details Action
              SizedBox(
                width: 50,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _isHovered
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Icon(
                        PhosphorIconsRegular.arrowSquareOut,
                        size: 18,
                        color: _isHovered ? AppColors.primary : AppColors.textSecondaryLight,
                      ),
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
}
