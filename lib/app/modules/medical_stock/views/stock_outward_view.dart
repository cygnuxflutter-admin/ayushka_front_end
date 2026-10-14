import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/values/app_colors.dart';
import '../../../core/values/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dropdown_search.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/medical_item_model.dart';
import '../../../data/models/shed_model.dart';
import '../dialogs/outward_success_dialog.dart';
import '../medical_stock_controller.dart';
import '../widgets/medical_stock_animations.dart';

/// Screen D: Stock Outward / Dispensing (FEFO Smart UI)
/// Features real-time visual simulation of FEFO batch consumption,
/// patient cow & shed association, doctor prescriptions, and exact deduction confirmation.
class StockOutwardView extends StatelessWidget {
  const StockOutwardView({super.key});

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
          _buildHeader(context, controller),
          const SizedBox(height: 18),

          // -----------------------------------------------------------
          // MAIN WORKSPACE: FORM (LEFT) + REAL-TIME FEFO PREVIEW (RIGHT)
          // -----------------------------------------------------------
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 880;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Dispense Form
                    Expanded(
                      flex: 6,
                      child: _buildDispenseForm(context, controller, dateFormat),
                    ),
                    const SizedBox(width: 20),

                    // Right: Real-time FEFO Preview
                    Expanded(
                      flex: 5,
                      child: _buildFefoPreviewCard(context, controller, dateFormat),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildDispenseForm(context, controller, dateFormat),
                    const SizedBox(height: 20),
                    _buildFefoPreviewCard(context, controller, dateFormat),
                  ],
                );
              }
            },
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
              child: const Icon(PhosphorIconsRegular.arrowUpRight, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stock Outward & Dispensing (FEFO Smart Engine)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Obx(
                    () => Text(
                      'Real-time automated First-Expired First-Out deduction for treatments and herd care in ${controller.activeGaushalaName}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final resetBtn = CustomButton(
          text: 'Reset Form',
          icon: PhosphorIconsRegular.arrowCounterClockwise,
          variant: ButtonVariant.outlined,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          onPressed: controller.clearOutwardForm,
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
                    Align(alignment: Alignment.centerRight, child: resetBtn),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: titleRow),
                    const SizedBox(width: 14),
                    resetBtn,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildDispenseForm(BuildContext context, MedicalStockController controller, DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(22),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(PhosphorIconsRegular.prescription, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Dispensing Parameters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 1. Medicine Autocomplete
          Obx(() {
            final medicineList = controller.items.toList();
            final selectedMed = controller.outwardSelectedItem.value;

            return CustomDropdownSearch<MedicalItemModel>(
              label: 'Select Medicine SKU to Dispense *',
              hint: 'Search and choose medicine...',
              isRequired: true,
              searchable: true,
              prefixIcon: PhosphorIconsRegular.pill,
              searchHint: 'Type medicine name or code...',
              items: medicineList,
              selectedItem: selectedMed,
              itemAsString: (item) => '${item.itemName} (${item.categoryEnum.label} - ${item.unit})',
              onChanged: controller.onOutwardItemChanged,
            );
          }),
          const SizedBox(height: 16),

          // 2. Quantity & Reason
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quantity
              Expanded(
                child: Obx(
                  () => CustomTextField(
                    label: controller.outwardIsManualBatchMode.value
                        ? 'Total Quantity to Dispense (From Batches) *'
                        : 'Quantity to Dispense *',
                    hint: 'e.g. 50',
                    controller: controller.outwardQuantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    prefixIcon: const Icon(PhosphorIconsRegular.numberSquareOne, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Reason
              Expanded(
                child: Obx(
                  () => CustomDropdownSearch<MedicalTransactionReason>(
                    label: 'Reason / Purpose *',
                    hint: 'Select reason...',
                    isRequired: true,
                    searchable: false,
                    prefixIcon: PhosphorIconsRegular.tag,
                    items: MedicalTransactionReason.outwardReasons,
                    selectedItem: controller.outwardReason.value,
                    itemAsString: (rsn) => rsn.label,
                    onChanged: (val) {
                      if (val != null) controller.outwardReason.value = val;
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Optional Shed Selection
          Obx(() {
            final shedsList = controller.sheds.toList();
            final selectedShed = controller.outwardSelectedShed.value;

            return CustomDropdownSearch<ShedModel>(
              label: 'Target Shed (Optional)',
              hint: 'Select shed...',
              searchable: false,
              prefixIcon: PhosphorIconsRegular.warehouse,
              items: shedsList,
              selectedItem: selectedShed,
              itemAsString: (s) => s.shedNumber.isNotEmpty ? 'Shed ${s.shedNumber}' : s.shedName,
              onChanged: (s) => controller.outwardSelectedShed.value = s,
            );
          }),
          const SizedBox(height: 16),

          // 4. Doctor Name & Prescribed For
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Veterinary Doctor / Prescribed By',
                  hint: 'e.g. Dr. Ramesh Sharma',
                  controller: controller.outwardDoctorController,
                  prefixIcon: const Icon(PhosphorIconsRegular.userGear, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: CustomTextField(
                  label: 'Diagnosis / Prescribed For',
                  hint: 'e.g. Joint inflammation, Mastitis',
                  controller: controller.outwardPrescribedForController,
                  prefixIcon: const Icon(PhosphorIconsRegular.stethoscope, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5. Notes
          CustomTextField(
            label: 'Administration Instructions / Notes',
            hint: 'e.g. 10ml administered intramuscularly twice daily.',
            controller: controller.outwardNotesController,
            maxLines: 2,
          ),
          const SizedBox(height: 22),

          // Submit Button
          Obx(() {
            final isManual = controller.outwardIsManualBatchMode.value;
            final isExcess = isManual ? false : controller.outwardHasExcessStockError.value;
            final isBusy = controller.isSubmitting.value;
            final item = controller.outwardSelectedItem.value;
            final totalReq = isManual
                ? controller.totalManualAllocatedQuantity
                : controller.outwardRequestedQuantity.value;
            final hasZero = totalReq <= 0;

            String buttonText = 'Authorize & Dispense Stock (FEFO)';
            if (isExcess) {
              buttonText = 'Insufficient Stock to Dispense';
            } else if (hasZero && isManual) {
              buttonText = 'Select & Allocate Batch Quantity';
            } else if (isManual) {
              buttonText =
                  'Authorize & Dispense (${totalReq.toStringAsFixed(0)} ${item?.unit ?? ''} - ${controller.selectedBatchesCount} Batches)';
            } else {
              buttonText = 'Authorize & Dispense Stock (FEFO)';
            }

            return CustomButton(
              text: buttonText,
              icon: PhosphorIconsRegular.checkCircle,
              height: 44,
              variant: (isExcess || (hasZero && isManual)) ? ButtonVariant.outlined : ButtonVariant.primary,
              isLoading: isBusy,
              onPressed: (isExcess || (hasZero && isManual))
                  ? null
                  : () async {
                      final res = await controller.submitStockOutward();
                      if (res != null && context.mounted) {
                        OutwardSuccessDialog.show(context, response: res);
                      }
                    },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFefoPreviewCard(BuildContext context, MedicalStockController controller, DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(22),
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
      child: Obx(() {
        final item = controller.outwardSelectedItem.value;
        final previews = controller.outwardFefoPreviews;
        final reqQty = controller.outwardRequestedQuantity.value;
        final hasExcess = controller.outwardHasExcessStockError.value;
        final availStock = controller.outwardItemAvailableStock;
        final isManual = controller.outwardIsManualBatchMode.value;

        if (item == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIconsRegular.arrowElbowDownRight, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text(
                    'Real-time Batch Deduction',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select a medicine on the left to configure automatic FEFO or choose specific batches.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final activeBatches = item.fefoBatches.isNotEmpty
            ? item.fefoBatches
            : controller.getBatchesForItem(item.id).where((b) => b.availableQuantity > 0 && !b.isExpired).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isManual ? PhosphorIconsRegular.stack : PhosphorIconsRegular.hourglassMedium,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isManual ? 'Manual Batch Selection' : 'FEFO Batch Deduction Simulation',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${availStock.toStringAsFixed(0)} ${item.unit} Safe Stock',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Mode Selector Pill (Auto FEFO vs Manual Multi-Batch Selection)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  // Tab 1: Auto FEFO
                  Expanded(
                    child: InkWell(
                      onTap: () => controller.setOutwardBatchMode(false),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !isManual ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: !isManual
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorIconsRegular.lightning,
                              size: 15,
                              color: !isManual ? AppColors.primary : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Auto FEFO Engine',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: !isManual ? FontWeight.bold : FontWeight.w500,
                                color: !isManual ? AppColors.primary : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Tab 2: Manual Batch Selection
                  Expanded(
                    child: InkWell(
                      onTap: () => controller.setOutwardBatchMode(true),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isManual ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isManual
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorIconsRegular.check,
                              size: 15,
                              color: isManual ? AppColors.primary : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Select Batches Manually',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isManual ? FontWeight.bold : FontWeight.w500,
                                color: isManual ? AppColors.primary : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (!isManual) ...[
              // -------------------------------------------------------------
              // AUTO FEFO VIEW
              // -------------------------------------------------------------
              if (hasExcess) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEF5350)),
                  ),
                  child: Row(
                    children: [
                      PulsingBadge(
                        child: const Icon(PhosphorIconsRegular.warningCircle, color: Color(0xFFC62828), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Requested $reqQty ${item.unit} exceeds total safe stock of ${availStock.toStringAsFixed(0)} ${item.unit} by ${(reqQty - availStock).toStringAsFixed(0)} units!',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC62828)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const Text(
                'Batches are strictly ordered by earliest expiry date. Earliest batches will be consumed first.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 14),

              if (previews.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Center(
                    child: Text(
                      'Enter a positive quantity to preview batch breakdown.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                  ),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: previews.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final p = previews[i];
                    final isConsumed = p.deductedQuantity > 0;
                    final isFully = p.isFullyConsumed;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isConsumed
                            ? (isFully ? const Color(0xFFFBF4EB) : const Color(0xFFF9FBF7))
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isConsumed
                              ? (isFully ? const Color(0xFFE98324) : AppColors.primary)
                              : AppColors.borderLight,
                          width: isConsumed ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isConsumed ? AppColors.primary : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Priority #${i + 1}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isConsumed ? Colors.white : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Batch: ${p.batch.batchNumber}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              if (p.batch.isExpiringSoon)
                                PulsingBadge(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Exp: ${dateFormat.format(p.batch.expiryDate)} (${p.batch.daysRemainingLabel})',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE65100),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Exp: ${dateFormat.format(p.batch.expiryDate)} (${p.batch.daysRemainingLabel})',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Available: ${p.batch.availableQuantity.toStringAsFixed(0)} ${item.unit}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                              ),
                              if (isConsumed)
                                Text(
                                  '- ${p.deductedQuantity.toStringAsFixed(0)} ${item.unit} (${isFully ? '100% Depleted' : 'Remaining: ${p.remainingQuantity.toStringAsFixed(0)}'})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isFully ? const Color(0xFFD97706) : AppColors.primary,
                                  ),
                                )
                              else
                                const Text(
                                  'Untouched (Sufficient stock in earlier batches)',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ] else ...[
              // -------------------------------------------------------------
              // MANUAL MULTI-BATCH SELECTION VIEW
              // -------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Select which batch(es) to deduct from and enter quantity for each:',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: controller.selectAllBatches,
                    icon: const Icon(PhosphorIconsRegular.check, size: 14),
                    label: const Text('Select All', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: controller.deselectAllBatches,
                    icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise, size: 14),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (activeBatches.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Center(
                    child: Text(
                      'No safe active batches available for this medicine.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                  ),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeBatches.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final b = activeBatches[i];
                    final isSelected = controller.isBatchSelected(b);
                    final allocated = controller.getBatchAllocatedQuantity(b);
                    final remaining = b.availableQuantity - allocated;
                    final qtyController = controller.getBatchQtyController(b);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF9FBF7) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.borderLight,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Batch Header & Selection Checkbox
                          InkWell(
                            onTap: () => controller.toggleBatchSelection(b),
                            borderRadius: BorderRadius.circular(6),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (_) => controller.toggleBatchSelection(b),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Batch: ${b.batchNumber}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const SizedBox(width: 8),
                                          if (b.isExpiringSoon)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFF3E0),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Exp: ${dateFormat.format(b.expiryDate)} (${b.daysRemainingLabel})',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFE65100),
                                                ),
                                              ),
                                            )
                                          else
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8F5E9),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Exp: ${dateFormat.format(b.expiryDate)} (${b.daysRemainingLabel})',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2E7D32),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Available: ${b.availableQuantity.toStringAsFixed(0)} ${item.unit}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Quantity Allocation Bar when Selected
                          if (isSelected) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text(
                                  'Deduct Qty:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 10),
                                // Quick Minus
                                IconButton(
                                  onPressed: allocated > 1
                                      ? () {
                                          final next = (allocated - 1).clamp(0.0, b.availableQuantity);
                                          qtyController.text = next.toStringAsFixed(0);
                                          controller.updateBatchAllocation(b, next);
                                        }
                                      : null,
                                  icon: const Icon(PhosphorIconsRegular.minus, size: 14),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                  splashRadius: 16,
                                ),
                                const SizedBox(width: 4),
                                // Text Input
                                SizedBox(
                                  width: 80,
                                  height: 36,
                                  child: TextField(
                                    controller: qtyController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                    ],
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onChanged: (val) {
                                      final parsed = double.tryParse(val.trim()) ?? 0.0;
                                      controller.updateBatchAllocation(b, parsed);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Quick Plus
                                IconButton(
                                  onPressed: allocated < b.availableQuantity
                                      ? () {
                                          final next = (allocated + 1).clamp(0.0, b.availableQuantity);
                                          qtyController.text = next.toStringAsFixed(0);
                                          controller.updateBatchAllocation(b, next);
                                        }
                                      : null,
                                  icon: const Icon(PhosphorIconsRegular.plus, size: 14),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                  splashRadius: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.unit,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                ),
                                const Spacer(),
                                // Max Button
                                InkWell(
                                  onTap: () => controller.setBatchMaxAllocation(b),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Max',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Remaining in batch: ${remaining.toStringAsFixed(0)} ${item.unit}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: remaining == 0 ? Colors.orange.shade800 : Colors.grey.shade600,
                                  ),
                                ),
                                if (allocated > b.availableQuantity)
                                  const Text(
                                    'Exceeds batch stock!',
                                    style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Manual Summary Strip
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Manual Deduction',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${controller.totalManualAllocatedQuantity.toStringAsFixed(0)} ${item.unit}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: controller.selectedBatchesCount > 0 ? AppColors.primary : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${controller.selectedBatchesCount} Batches Selected',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        );
      }),
    );
  }
}
