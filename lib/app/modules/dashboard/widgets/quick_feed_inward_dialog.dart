import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/dashboard_alerts_model.dart';

/// Modal dialog for rapid fodder/feed inventory replenishment directly from the dashboard.
class QuickFeedInwardDialog extends StatefulWidget {
  final FeedStockAlertItem alert;
  final Future<void> Function({
    required String itemId,
    required double quantity,
    required String unit,
    required String reason,
  }) onConfirm;

  const QuickFeedInwardDialog({
    super.key,
    required this.alert,
    required this.onConfirm,
  });

  @override
  State<QuickFeedInwardDialog> createState() => _QuickFeedInwardDialogState();
}

class _QuickFeedInwardDialogState extends State<QuickFeedInwardDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityCtrl;
  String _selectedReason = 'PURCHASE';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _quantityCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = double.tryParse(_quantityCtrl.text.trim()) ?? 0.0;
    if (qty <= 0) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onConfirm(
        itemId: widget.alert.itemId,
        quantity: qty,
        unit: widget.alert.unit,
        reason: _selectedReason,
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
        constraints: const BoxConstraints(maxWidth: 480),
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
                        color: AppColors.successBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.plant,
                        color: AppColors.success,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Feed Stock Inward',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Record fodder inward to maintain cattle nutrition safety',
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

                // Feed Item Context Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : const Color(0xFFF7FAF7),
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
                              widget.alert.itemName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Current Stock: ${widget.alert.currentStock.toStringAsFixed(1)} ${widget.alert.unit} '
                              '• Buffer Target: ${widget.alert.minStockAlert.toStringAsFixed(1)} ${widget.alert.unit}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Inward Quantity
                CustomTextField(
                  label: 'Quantity Received (${widget.alert.unit})',
                  hint: 'e.g. 500',
                  controller: _quantityCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(PhosphorIconsRegular.scales, size: 18),
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
                const SizedBox(height: 16),

                // Source / Reason Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Procurement Source / Reason',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedReason,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: const [
                            DropdownMenuItem(value: 'PURCHASE', child: Text('Direct Purchase')),
                            DropdownMenuItem(value: 'DONATION', child: Text('Charitable Donation')),
                            DropdownMenuItem(value: 'OTHER', child: Text('Other / Internal Transfer')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedReason = val);
                          },
                        ),
                      ),
                    ),
                  ],
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
