import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/core/values/app_colors.dart';
import '../../../../app/core/widgets/custom_button.dart';
import '../../../../app/core/widgets/custom_dropdown_search.dart';
import '../../../../app/core/widgets/custom_text_field.dart';
import '../../../../app/data/models/worker_model.dart';
import '../../controllers/milk_controller.dart';
import '../../models/milk_disposal_model.dart';

/// Modal dialog for recording spoiled/waste milk disposal
class DisposeMilkDialog extends StatefulWidget {
  final String? initialMilkDate;
  final double? maxQuantity;

  const DisposeMilkDialog({
    super.key,
    this.initialMilkDate,
    this.maxQuantity,
  });

  static Future<void> show(
    BuildContext context, {
    String? milkDate,
    double? maxQuantity,
  }) async {
    await Get.dialog(
      DisposeMilkDialog(
        initialMilkDate: milkDate,
        maxQuantity: maxQuantity,
      ),
      barrierDismissible: false,
    );
  }

  @override
  State<DisposeMilkDialog> createState() => _DisposeMilkDialogState();
}

class _DisposeMilkDialogState extends State<DisposeMilkDialog> {
  final MilkController _controller = Get.find<MilkController>();
  final _formKey = GlobalKey<FormState>();

  late DateTime _milkDate;
  late DateTime _disposalDate;

  WorkerModel? _selectedWorker;
  DisposalReason _selectedReason = DisposalReason.spoiled;

  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMilkDate != null && widget.initialMilkDate!.isNotEmpty) {
      _milkDate = DateTime.tryParse(widget.initialMilkDate!) ?? _controller.selectedDate.value;
    } else {
      _milkDate = _controller.selectedDate.value;
    }
    _disposalDate = DateTime.now();

    if (widget.maxQuantity != null && widget.maxQuantity! > 0) {
      _qtyCtrl.text = widget.maxQuantity!.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWorker == null) {
      Get.snackbar('Missing Worker', 'Please select who reported this disposal.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0.0;
    if (widget.maxQuantity != null && qty > widget.maxQuantity!) {
      Get.snackbar(
        'Quantity Exceeded',
        'Quantity cannot exceed ${widget.maxQuantity} L available from that date.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await _controller.submitDisposal(
      milkDate: DateFormat('yyyy-MM-dd').format(_milkDate),
      disposalDate: DateFormat('yyyy-MM-dd').format(_disposalDate),
      quantity: qty,
      reason: _selectedReason.value,
      reportedBy: _selectedWorker!.id,
      remarks: _remarksCtrl.text.trim(),
    );
    setState(() => _isSubmitting = false);

    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 660),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(isDark),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Caution Banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.maxQuantity != null
                                      ? 'Disposing milk produced on ${DateFormat('dd MMM yyyy').format(_milkDate)} (Leftover: ${widget.maxQuantity} L).'
                                      : 'Record disposal of spoiled or unviable milk for inventory write-off.',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF991B1B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Date Row: Milk Date & Disposal Date
                        Row(
                          children: [
                            // Milk Date
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: widget.initialMilkDate != null
                                    ? null
                                    : () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _milkDate,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime.now(),
                                        );
                                        if (picked != null) {
                                          setState(() => _milkDate = picked);
                                        }
                                      },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Milk Batch Date',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('dd MMM yyyy').format(_milkDate),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Disposal Date
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _disposalDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setState(() => _disposalDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Disposal Date',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('dd MMM yyyy').format(_disposalDate),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Quantity (L)
                        CustomTextField(
                          label: 'Quantity Disposed (Liters)',
                          hint: 'e.g. 10.0',
                          controller: _qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: const Icon(PhosphorIconsRegular.drop, size: 18),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter quantity';
                            final n = double.tryParse(val.trim());
                            if (n == null || n <= 0) return 'Enter valid quantity';
                            if (widget.maxQuantity != null && n > widget.maxQuantity!) {
                              return 'Cannot exceed ${widget.maxQuantity} L';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Reason Dropdown
                        CustomDropdownSearch<DisposalReason>(
                          label: 'Reason for Disposal',
                          isRequired: true,
                          items: DisposalReason.values,
                          selectedItem: _selectedReason,
                          itemAsString: (r) => r.label,
                          onChanged: (r) {
                            if (r != null) setState(() => _selectedReason = r);
                          },
                          prefixIcon: Icons.report_problem_rounded,
                        ),
                        const SizedBox(height: 14),

                        // Reported By (Worker)
                        CustomDropdownSearch<WorkerModel>(
                          label: 'Reported / Inspected By',
                          isRequired: true,
                          hint: 'Select worker...',
                          items: _controller.activeWorkers,
                          selectedItem: _selectedWorker,
                          itemAsString: (w) => w.name,
                          onChanged: (w) => setState(() => _selectedWorker = w),
                          prefixIcon: Icons.badge_rounded,
                        ),
                        const SizedBox(height: 14),

                        // Remarks
                        CustomTextField(
                          label: 'Remarks (Optional)',
                          hint: 'Details regarding disposal method, inspection remarks...',
                          controller: _remarksCtrl,
                          maxLines: 2,
                          prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    text: 'Cancel',
                    variant: ButtonVariant.outlined,
                    onPressed: _isSubmitting ? null : () => Get.back(),
                  ),
                  const SizedBox(width: 12),
                  CustomButton(
                    text: 'Confirm Disposal',
                    variant: ButtonVariant.danger,
                    icon: Icons.delete_sweep_rounded,
                    isLoading: _isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: AppColors.error,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record Milk Disposal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gaushala: ${_controller.selectedGaushalaName}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
        ),
      ],
    );
  }
}
