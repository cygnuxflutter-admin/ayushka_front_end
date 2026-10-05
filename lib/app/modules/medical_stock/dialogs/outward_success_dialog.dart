import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/medical_item_model.dart';
import '../widgets/medical_stock_animations.dart';

/// Confirmation dialog displaying the exact FEFO batch deduction breakdown after outward dispensing
class OutwardSuccessDialog extends StatelessWidget {
  final MedicalStockOutwardResponse response;

  const OutwardSuccessDialog({super.key, required this.response});

  static Future<void> show(BuildContext context, {required MedicalStockOutwardResponse response}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OutwardSuccessDialog(response: response),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final txn = response.transaction;
    final item = response.item;
    final deductions = response.deductedBatches;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 12,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success Header Banner
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF384C28), Color(0xFF2E3E21)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  PulsingBadge(
                    duration: const Duration(milliseconds: 1400),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF2E7D32),
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stock Dispensed Successfully!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'FEFO Engine completed automatic batch deduction.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Summary Information
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAF7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              txn?.itemName ?? item?.itemName ?? 'Medicine',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${txn?.quantity.toStringAsFixed(0) ?? '0'} ${txn?.unit ?? item?.unit ?? 'Units'} Dispensed',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            if (txn?.reason != null)
                              Expanded(
                                child: _infoCol('Reason', txn!.reason),
                              ),
                            if (txn?.cowTagId != null && txn!.cowTagId!.isNotEmpty)
                              Expanded(
                                child: _infoCol('Patient Cow', txn.cowTagId!),
                              ),
                            if (txn?.doctorName != null && txn!.doctorName.isNotEmpty)
                              Expanded(
                                child: _infoCol('Prescribed By', txn.doctorName),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Low stock alert warning if remaining <= minStock
                  if (response.lowStockAlert || (item != null && item.isLowStock)) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFD54F)),
                      ),
                      child: Row(
                        children: [
                          const Icon(PhosphorIconsRegular.warning, color: Color(0xFFF57F17), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Low Stock Alert: Remaining balance is ${item?.totalStock.toStringAsFixed(0) ?? 'low'}, which is at or below the reorder threshold (${item?.minStockAlert.toStringAsFixed(0)}).',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF795548)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // FEFO Batch Deduction Breakdown Section
                  Row(
                    children: [
                      const Icon(PhosphorIconsRegular.stack, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'FEFO Batch Deduction Breakdown',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${deductions.length} batch${deductions.length > 1 ? 'es' : ''} consumed',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Deductions List
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: deductions.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final d = deductions[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#${i + 1}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Batch: ${d.batchNumber}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    if (d.expiryDate != null)
                                      Text(
                                        'Exp: ${dateFormat.format(d.expiryDate!)} (FEFO Priority)',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E5F5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '- ${d.quantity.toStringAsFixed(0)} ${txn?.unit ?? item?.unit ?? 'Units'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF7B1FA2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
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
                    text: 'Close & Continue',
                    variant: ButtonVariant.primary,
                    icon: PhosphorIconsRegular.check,
                    height: 42,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
