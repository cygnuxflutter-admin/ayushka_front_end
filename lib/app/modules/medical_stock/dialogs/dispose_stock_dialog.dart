import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dropdown_search.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/medical_item_model.dart';
import '../medical_stock_controller.dart';
import '../widgets/medical_stock_animations.dart';

/// Modal dialog for safely disposing of expired medical stock or audit correction
class DisposeStockDialog extends StatefulWidget {
  final MedicalBatchModel batch;
  final MedicalItemModel? item;

  const DisposeStockDialog({super.key, required this.batch, this.item});

  static Future<void> show(
    BuildContext context, {
    required MedicalBatchModel batch,
    MedicalItemModel? item,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DisposeStockDialog(batch: batch, item: item),
    );
  }

  @override
  State<DisposeStockDialog> createState() => _DisposeStockDialogState();
}

class _DisposeStockDialogState extends State<DisposeStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final MedicalStockController controller = Get.find<MedicalStockController>();

  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;
  String _selectedReason = 'EXPIRED_DISPOSAL';

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.batch.availableQuantity.toStringAsFixed(0),
    );
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    if (qty <= 0) {
      Get.snackbar(
        'Invalid Quantity',
        'Quantity to dispose must be greater than zero.',
        backgroundColor: AppColors.warningBg,
        colorText: AppColors.warning,
      );
      return;
    }

    if (qty > widget.batch.availableQuantity) {
      Get.snackbar(
        'Excess Quantity',
        'Cannot dispose more than available batch stock (${widget.batch.availableQuantity}).',
        backgroundColor: AppColors.errorBg,
        colorText: AppColors.error,
      );
      return;
    }

    final success = await controller.disposeExpiredBatch(
      batch: widget.batch,
      quantity: qty,
      reason: _selectedReason,
      notes: _notesController.text.trim(),
    );
    if (success) {
      if (mounted) {
        Navigator.of(context).pop();
      } else if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isExpired = widget.batch.isExpired;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 12,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: isExpired ? const Color(0xFFFDE8E8) : const Color(0xFFF7FAF4),
                border: const Border(bottom: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  isExpired
                      ? PulsingBadge(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              PhosphorIconsRegular.trash,
                              color: AppColors.error,
                              size: 22,
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            PhosphorIconsRegular.slidersHorizontal,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isExpired ? 'Dispose Expired Stock' : 'Stock Audit Adjustment',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isExpired ? AppColors.error : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Batch: ${widget.batch.batchNumber}  •  ${widget.batch.itemName.isNotEmpty ? widget.batch.itemName : (widget.item?.itemName ?? '')}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMutedLight),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Modal Body
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Batch info card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Available in Batch', style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.batch.availableQuantity.toStringAsFixed(0)} units',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Batch Expiry Date', style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                              const SizedBox(height: 2),
                              Text(
                                dateFormat.format(widget.batch.expiryDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isExpired ? AppColors.error : AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Quantity to dispose
                    CustomTextField(
                      label: 'Quantity to Dispose / Write-off *',
                      hint: 'Enter quantity',
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(PhosphorIconsRegular.numberSquareOne, size: 18),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Quantity is required';
                        final num = double.tryParse(val.trim());
                        if (num == null || num <= 0) return 'Enter a positive quantity';
                        if (num > widget.batch.availableQuantity) return 'Cannot exceed batch stock';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Disposal Reason Dropdown (Herd & Cattle CustomDropdownSearch style)
                    CustomDropdownSearch<String>(
                      label: 'Disposal Reason',
                      isRequired: true,
                      prefixIcon: PhosphorIconsRegular.warningCircle,
                      hint: 'Select reason',
                      selectedItem: _selectedReason,
                      items: const [
                        'EXPIRED_DISPOSAL',
                        'AUDIT_CORRECTION',
                        'DAMAGED_BROKEN',
                        'OTHER',
                      ],
                      itemAsString: (val) {
                        switch (val) {
                          case 'EXPIRED_DISPOSAL':
                            return 'Expired Medicine Disposal (FEFO Protocol)';
                          case 'AUDIT_CORRECTION':
                            return 'Audit Correction / Physical Count Mismatch';
                          case 'DAMAGED_BROKEN':
                            return 'Damaged / Broken Vial / Leakage';
                          case 'OTHER':
                          default:
                            return 'Other Write-off Reason';
                        }
                      },
                      showClearButton: false,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedReason = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    CustomTextField(
                      label: 'Disposal Protocol / Audit Notes',
                      hint: 'e.g. Incinerated per bio-medical waste safety protocol.',
                      controller: _notesController,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            // Modal Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF7FAF4),
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    text: 'Cancel',
                    variant: ButtonVariant.outlined,
                    height: 42,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 14),
                  Obx(
                    () => CustomButton(
                      text: 'Confirm Disposal',
                      variant: ButtonVariant.danger,
                      icon: PhosphorIconsRegular.trash,
                      isLoading: controller.isSubmitting.value,
                      height: 42,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
