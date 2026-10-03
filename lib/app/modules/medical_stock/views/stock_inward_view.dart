import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/values/app_colors.dart';
import '../../../core/values/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dropdown_search.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/medical_item_model.dart';
import '../medical_stock_controller.dart';
import '../widgets/medical_stock_animations.dart';

/// Screen C: Stock Inward (Multi-Batch Purchase Entry)
/// Provides enterprise purchase/donation entry with dynamic multi-batch rows,
/// future expiry validation, auto-calculated line totals, and ledger integration.
class StockInwardView extends StatelessWidget {
  const StockInwardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MedicalStockController>();
    final dateFormat = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
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
              // TRANSACTION & SUPPLIER META SECTION
              // -----------------------------------------------------------
              StaggeredEntrance(
                index: 1,
                child: _buildMetaSection(context, controller, dateFormat),
              ),
              const SizedBox(height: 20),

              // -----------------------------------------------------------
              // DYNAMIC MULTI-BATCH ENTRY TABLE
              // -----------------------------------------------------------
              StaggeredEntrance(
                index: 2,
                child: _buildBatchTableCard(context, controller, dateFormat),
              ),
              const SizedBox(height: 20),

              // -----------------------------------------------------------
              // SUMMARY FOOTER & SUBMIT ACTION
              // -----------------------------------------------------------
              StaggeredEntrance(
                index: 3,
                child: _buildFooterActions(context, controller),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MedicalStockController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        final titleRow = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(PhosphorIconsRegular.arrowDownLeft, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stock Inward Entry (Multi-Batch Purchase & Inflow)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Obx(
                    () => Text(
                      'Record purchase receipts and donations with lot numbers, manufacturing, and future expiry dates for ${controller.activeGaushalaName}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final clearBtn = CustomButton(
          text: 'Clear Form',
          icon: PhosphorIconsRegular.arrowCounterClockwise,
          variant: ButtonVariant.outlined,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          onPressed: controller.clearInwardForm,
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
                    Align(alignment: Alignment.centerRight, child: clearBtn),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: titleRow),
                    const SizedBox(width: 14),
                    clearBtn,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildMetaSection(BuildContext context, MedicalStockController controller, DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inward Transaction Details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),

          // 2-Column Responsive Layout matching Cow module
          LayoutBuilder(
            builder: (context, constraints) {
              final isSingleCol = constraints.maxWidth < 700;

              final fieldMedicine = Obx(() {
                final medicineList = controller.items.toList();
                final selectedMed = controller.inwardSelectedItem.value;

                return CustomDropdownSearch<MedicalItemModel>(
                  label: 'Select Medicine SKU',
                  hint: 'Search and choose medicine...',
                  isRequired: true,
                  searchable: true,
                  prefixIcon: PhosphorIconsRegular.pill,
                  searchHint: 'Search medicine name or SKU code...',
                  items: medicineList,
                  selectedItem: selectedMed,
                  itemAsString: (item) => '${item.itemName} (${item.categoryEnum.label} - ${item.unit})',
                  onChanged: (item) {
                    controller.inwardSelectedItem.value = item;
                  },
                  customItemBuilder: (ctx, item, isDis, isSel) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: item.categoryEnum.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(item.categoryEnum.icon, color: item.categoryEnum.color, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.itemName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  'Code: ${item.itemCode.isNotEmpty ? item.itemCode : 'N/A'} • Available: ${item.totalStock.toStringAsFixed(0)} ${item.unit}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                                ),
                              ],
                            ),
                          ),
                          if (isSel)
                            const Icon(Icons.check, size: 18, color: AppColors.primary),
                        ],
                      ),
                    );
                  },
                );
              });

              final fieldReason = Obx(
                () => CustomDropdownSearch<MedicalTransactionReason>(
                  label: 'Inflow Reason',
                  isRequired: true,
                  prefixIcon: PhosphorIconsRegular.tag,
                  hint: 'Select inflow reason',
                  items: MedicalTransactionReason.inwardReasons,
                  selectedItem: controller.inwardReason.value,
                  itemAsString: (r) => r.label,
                  onChanged: (val) {
                    if (val != null) controller.inwardReason.value = val;
                  },
                ),
              );

              final fieldSupplier = CustomTextField(
                label: 'Supplier / Donor Name',
                hint: 'e.g. Vikas Pharma Traders / Donor Trust',
                controller: controller.inwardSupplierController,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                prefixIcon: const Icon(PhosphorIconsRegular.user, size: 18),
                prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              );

              final fieldBillNo = CustomTextField(
                label: 'Invoice / Bill / Challan No',
                hint: 'e.g. INV-2026-9921',
                controller: controller.inwardBillNoController,
                isUpperCase: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                prefixIcon: const Icon(PhosphorIconsRegular.receipt, size: 18),
                prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              );

              final fieldDate = Obx(
                () => _buildDateField(
                  context,
                  label: 'Transaction Date',
                  displayValue: () => dateFormat.format(controller.inwardDate.value),
                  hint: 'Select date',
                  icon: PhosphorIconsRegular.calendarBlank,
                  isRequired: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: controller.inwardDate.value,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 7)),
                    );
                    if (picked != null) {
                      controller.inwardDate.value = picked;
                    }
                  },
                ),
              );

              if (isSingleCol) {
                return Column(
                  children: [
                    fieldMedicine,
                    const SizedBox(height: 16),
                    fieldReason,
                    const SizedBox(height: 16),
                    fieldSupplier,
                    const SizedBox(height: 16),
                    fieldBillNo,
                    const SizedBox(height: 16),
                    fieldDate,
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: fieldMedicine),
                      const SizedBox(width: 20),
                      Expanded(child: fieldReason),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: fieldSupplier),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: fieldBillNo),
                      const SizedBox(width: 16),
                      SizedBox(width: 210, child: fieldDate),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBatchTableCard(BuildContext context, MedicalStockController controller, DateFormat dateFormat) {
    return Container(
      clipBehavior: Clip.antiAlias,
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
          // Table Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF7FAF4),
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 560;
                final titleWidget = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsRegular.stack, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Dynamic Batch Entry (FEFO Lot)',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                );

                final addBtn = CustomButton(
                  text: 'Add Another Batch',
                  icon: PhosphorIconsRegular.plus,
                  height: 40,
                  variant: ButtonVariant.outlined,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  onPressed: controller.addInwardBatchRow,
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      titleWidget,
                      const SizedBox(height: 10),
                      Align(alignment: Alignment.centerLeft, child: addBtn),
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    titleWidget,
                    addBtn,
                  ],
                );
              },
            ),
          ),

          // Multi-batch Rows Table
          LayoutBuilder(
            builder: (context, constraints) {
              const double minTableWidth = 1000.0;
              final double tableWidth = constraints.maxWidth < minTableWidth
                  ? minTableWidth
                  : constraints.maxWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Obx(() {
                    final rows = controller.inwardBatchRows.toList();

                    return Table(
                      columnWidths: const {
                        0: FlexColumnWidth(0.6), // #
                        1: FlexColumnWidth(2.2), // Batch No
                        2: FlexColumnWidth(2.0), // Expiry Date
                        3: FlexColumnWidth(1.8), // Mfg Date
                        4: FlexColumnWidth(1.6), // Quantity
                        5: FlexColumnWidth(1.6), // Unit Price
                        6: FlexColumnWidth(1.5), // MRP
                        7: FlexColumnWidth(1.8), // Line Total
                        8: FixedColumnWidth(60), // Action
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        // Column Headers
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAF7),
                            border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1.5)),
                          ),
                          children: [
                            _th('#'),
                            _th('Batch Number *'),
                            _th('Expiry Date *'),
                            _th('Mfg Date'),
                            _th('Quantity *'),
                            _th('Unit Price (₹)'),
                            _th('MRP (₹)'),
                            _th('Line Total'),
                            _th(''),
                          ],
                        ),

                        // Batch rows
                        ...rows.asMap().entries.map((entry) {
                          final index = entry.key;
                          final row = entry.value;
                          final exp = row.expiryDate.value;
                          final isPast = exp != null && exp.isBefore(DateTime.now());
                          final mfg = row.mfgDate.value;

                          return TableRow(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
                            ),
                            children: [
                              // Index
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMutedLight),
                                ),
                              ),

                              // Batch Number
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: TextFormField(
                                  controller: row.batchNumberController,
                                  textCapitalization: TextCapitalization.characters,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. B-2027-A',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),

                              // Expiry Date Picker (Must be in future)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: exp ?? DateTime.now().add(const Duration(days: 365)),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null) row.expiryDate.value = picked;
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isPast ? AppColors.error : AppColors.borderLight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: isPast ? const Color(0xFFFFF0F0) : Colors.white,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          exp != null ? dateFormat.format(exp) : 'Pick Expiry',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isPast ? AppColors.error : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        const Icon(PhosphorIconsRegular.calendarBlank, size: 15),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Mfg Date Picker
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: mfg ?? DateTime.now().subtract(const Duration(days: 30)),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) row.mfgDate.value = picked;
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.borderLight),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          mfg != null ? dateFormat.format(mfg) : 'Pick Mfg',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const Icon(PhosphorIconsRegular.calendarBlank, size: 15),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Quantity
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: TextFormField(
                                  controller: row.quantityController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),

                              // Unit Price
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: TextFormField(
                                  controller: row.unitPriceController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),

                              // MRP
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: TextFormField(
                                  controller: row.mrpController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),

                              // Line Total
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                child: Text(
                                  '₹${row.lineTotal.value.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),

                              // Delete Action
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                child: IconButton(
                                  icon: const Icon(PhosphorIconsRegular.trash, color: AppColors.error, size: 18),
                                  tooltip: 'Delete this batch row',
                                  onPressed: () => controller.removeInwardBatchRow(index),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    );
                  }),
                ),
              );
            },
          ),
    ],
  ),
);
  }

  Widget _buildFooterActions(BuildContext context, MedicalStockController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        final summaryPills = Obx(() {
          final med = controller.inwardSelectedItem.value;
          final totalQty = controller.inwardTotalQuantity;
          final totalVal = controller.inwardTotalValue;

          return Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _summaryPill(
                label: 'Total Quantity',
                value: '${totalQty.toStringAsFixed(0)} ${med?.unit ?? 'Units'}',
                color: AppColors.primary,
              ),
              _summaryPill(
                label: 'Total Invoice Value',
                value: '₹${totalVal.toStringAsFixed(2)}',
                color: AppColors.primary,
              ),
            ],
          );
        });

        final submitBtn = Obx(
          () => CustomButton(
            text: 'Confirm & Inward Stock',
            icon: PhosphorIconsRegular.check,
            height: 44,
            width: isMobile ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            variant: ButtonVariant.primary,
            isLoading: controller.isSubmitting.value,
            onPressed: controller.submitStockInward,
          ),
        );

        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    summaryPills,
                    const SizedBox(height: 16),
                    submitBtn,
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    summaryPills,
                    submitBtn,
                  ],
                ),
        );
      },
    );
  }

  Widget _summaryPill({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required String Function() displayValue,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryLight,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.textMutedLight),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayValue().isEmpty ? hint : displayValue(),
                    style: TextStyle(
                      fontSize: 14,
                      color: displayValue().isEmpty
                          ? AppColors.textMutedLight
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _th(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Text(
        text,
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
