import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/dashboard_alerts_model.dart';

/// Modal dialog for rapid medical inventory inward directly from the dashboard alerts center.
class QuickMedicalInwardDialog extends StatefulWidget {
  final MedicalLowStockAlertItem? lowStockItem;
  final MedicalExpiringAlertItem? expiringItem;
  final Future<void> Function({
    required String itemId,
    required String batchNumber,
    required DateTime expiryDate,
    required double quantity,
  }) onConfirm;

  const QuickMedicalInwardDialog({
    super.key,
    this.lowStockItem,
    this.expiringItem,
    required this.onConfirm,
  }) : assert(lowStockItem != null || expiringItem != null, 'Either lowStockItem or expiringItem must be provided');

  @override
  State<QuickMedicalInwardDialog> createState() => _QuickMedicalInwardDialogState();
}

class _QuickMedicalInwardDialogState extends State<QuickMedicalInwardDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _batchCtrl;
  late final TextEditingController _quantityCtrl;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  bool _isSubmitting = false;

  String get _itemId => widget.lowStockItem?.itemId ?? widget.expiringItem!.itemId;
  String get _itemName => widget.lowStockItem?.itemName ?? widget.expiringItem!.itemName;
  String get _unit => widget.lowStockItem?.unit ?? 'UNIT';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _batchCtrl = TextEditingController(
      text: widget.expiringItem?.batchNumber != null && widget.expiringItem!.batchNumber != 'N/A'
          ? '${widget.expiringItem!.batchNumber}-NEW'
          : 'B${now.month}${now.day}-${now.minute}',
    );
    _quantityCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _batchCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = double.tryParse(_quantityCtrl.text.trim()) ?? 0.0;
    if (qty <= 0) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onConfirm(
        itemId: _itemId,
        batchNumber: _batchCtrl.text.trim(),
        expiryDate: _expiryDate,
        quantity: qty,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // Handled by controller
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.pill,
                        color: AppColors.info,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Medical Stock Inward',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Receive incoming pharmacy inventory instantly',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Medicine Context Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _itemName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (widget.lowStockItem != null)
                              Text(
                                'Current Stock: ${widget.lowStockItem!.totalStock.toStringAsFixed(1)} $_unit '
                                '(Min Alert Threshold: ${widget.lowStockItem!.minStockAlert.toStringAsFixed(1)} $_unit)',
                                style: const TextStyle(fontSize: 12, color: AppColors.error),
                              )
                            else if (widget.expiringItem != null)
                              Text(
                                'Expiring Batch: ${widget.expiringItem!.batchNumber} • ${widget.expiringItem!.daysRemaining} days left',
                                style: const TextStyle(fontSize: 12, color: AppColors.warning),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Batch Number
                CustomTextField(
                  label: 'Batch Number',
                  hint: 'e.g. B204-OCT',
                  controller: _batchCtrl,
                  prefixIcon: const Icon(PhosphorIconsRegular.barcode, size: 18),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Batch number is required' : null,
                ),
                const SizedBox(height: 14),

                // Expiry Date Picker
                InkWell(
                  onTap: _pickExpiryDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(PhosphorIconsRegular.calendarCheck, size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Batch Expiration Date',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd MMM yyyy').format(_expiryDate),
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Quantity
                CustomTextField(
                  label: 'Inward Quantity ($_unit)',
                  hint: 'Enter quantity received (e.g. 50)',
                  controller: _quantityCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(PhosphorIconsRegular.stack, size: 18),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Quantity is required';
                    final num? val = num.tryParse(v.trim());
                    if (val == null || val <= 0) return 'Quantity must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomButton(
                      text: 'Cancel',
                      variant: ButtonVariant.outlined,
                      height: 42,
                      width: 100,
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    CustomButton(
                      text: 'Record Inward',
                      icon: PhosphorIconsRegular.arrowDownLeft,
                      height: 42,
                      width: 160,
                      isLoading: _isSubmitting,
                      onPressed: _handleSubmit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
