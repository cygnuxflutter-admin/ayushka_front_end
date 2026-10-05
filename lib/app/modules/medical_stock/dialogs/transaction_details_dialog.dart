import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/medical_item_model.dart';

/// Modal dialog showing complete audit details and batch breakdowns for a transaction ledger entry
class TransactionDetailsDialog extends StatelessWidget {
  final MedicalTransactionModel transaction;

  const TransactionDetailsDialog({super.key, required this.transaction});

  static Future<void> show(BuildContext context, {required MedicalTransactionModel transaction}) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => TransactionDetailsDialog(transaction: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final txn = transaction;
    final typeEnum = txn.typeEnum;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 12,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFFF7FAF4),
                border: Border(bottom: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeEnum.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(typeEnum.icon, color: typeEnum.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              typeEnum.label,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: typeEnum.color,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                txn.reason,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          txn.transactionDate != null ? dateFormat.format(txn.transactionDate!) : 'Recorded',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
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

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview cards
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _fieldBlock('Medicine Item', txn.itemName, subtext: txn.itemCode),
                              ),
                              Expanded(
                                child: _fieldBlock(
                                  'Quantity & Movement',
                                  '${txn.quantity.toStringAsFixed(0)} ${txn.unit}',
                                  highlightColor: typeEnum.color,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              if (txn.supplierOrDonorName.isNotEmpty)
                                Expanded(
                                  child: _fieldBlock('Supplier / Donor', txn.supplierOrDonorName),
                                ),
                              if (txn.billOrReceiptNo.isNotEmpty)
                                Expanded(
                                  child: _fieldBlock('Invoice / Bill No', txn.billOrReceiptNo),
                                ),
                              if (txn.cowTagId != null && txn.cowTagId!.isNotEmpty)
                                Expanded(
                                  child: _fieldBlock('Patient Tag ID', txn.cowTagId!),
                                ),
                              if (txn.doctorName.isNotEmpty)
                                Expanded(
                                  child: _fieldBlock('Prescribed By', txn.doctorName),
                                ),
                            ],
                          ),
                          if (txn.prescribedFor.isNotEmpty || txn.notes.isNotEmpty) ...[
                            const Divider(height: 20),
                            Row(
                              children: [
                                if (txn.prescribedFor.isNotEmpty)
                                  Expanded(
                                    child: _fieldBlock('Clinical Diagnosis / Indication', txn.prescribedFor),
                                  ),
                                if (txn.notes.isNotEmpty)
                                  Expanded(
                                    child: _fieldBlock('Remarks / Notes', txn.notes),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Batches involved
                    Row(
                      children: [
                        const Icon(PhosphorIconsRegular.stack, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Batches Allocation Breakdown',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                        ),
                        const Spacer(),
                        Text(
                          '${txn.batches.length} batch${txn.batches.length != 1 ? 'es' : ''}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    txn.batches.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: const Center(
                              child: Text(
                                'No specific batch record linked with this transaction.',
                                style: TextStyle(fontSize: 13, color: AppColors.textMutedLight),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2.5),
                                1: FlexColumnWidth(2.0),
                                2: FlexColumnWidth(2.0),
                                3: FlexColumnWidth(1.5),
                              },
                              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                              children: [
                                TableRow(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF4F6F1),
                                    border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                                  ),
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: Text('Batch Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: Text('Expiry Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: Text('Batch Quantity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: Text('Unit Price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                ...txn.batches.map((b) {
                                  return TableRow(
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        child: Text(
                                          b.batchNumber,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        child: Text(
                                          b.expiryDate != null ? DateFormat('dd MMM yyyy').format(b.expiryDate!) : 'N/A',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        child: Text(
                                          '${b.quantity.toStringAsFixed(0)} ${txn.unit}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: typeEnum.color,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        child: Text(
                                          b.unitPrice > 0 ? '₹${b.unitPrice.toStringAsFixed(2)}' : '-',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                  ],
                ),
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
                  Text(
                    'Recorded By: ${txn.recordedByName ?? 'Admin'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                  ),
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
  }

  Widget _fieldBlock(String label, String value, {String? subtext, Color? highlightColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: highlightColor ?? AppColors.textPrimaryLight,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (subtext != null && subtext.isNotEmpty)
          Text(subtext, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
      ],
    );
  }
}
