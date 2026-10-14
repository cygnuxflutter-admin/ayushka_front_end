import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/models/cow_mating_model.dart';
import 'edit_mating_dialog.dart';
import 'record_calving_dialog.dart';
import 'record_pd_dialog.dart';

/// Modal dialog displaying comprehensive Cow Mating & Breeding lifecycle details.
class MatingDetailsDialog extends StatelessWidget {
  final CowMatingModel mating;

  const MatingDetailsDialog({
    super.key,
    required this.mating,
  });

  static void show(BuildContext context, CowMatingModel mating) {
    showDialog(
      context: context,
      builder: (ctx) => MatingDetailsDialog(mating: mating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.heartStraight,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Breeding & Mating Record',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cattle: ${mating.cowTagId} • Mating Attempt #${mating.attemptCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: mating.status.bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: mating.status.color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      mating.status.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: mating.status.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            // Content Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Repeat Breeder Alert Banner (3+ attempts failed)
                    if (mating.isHighAlert) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(PhosphorIconsRegular.warningOctagon, color: Colors.red.shade700, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'HIGH ALERT: Repeat Breeder Cow (${mating.attemptCount} Breeding Attempts)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.red.shade300 : Colors.red.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'This cow has experienced 3 or more unsuccessful inseminations without conceiving. Clinical veterinary investigation for subclinical endometritis or hormonal imbalance is required.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.red.shade200 : Colors.red.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Mating & Genetics Details Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow('Cow Tag & Name', '${mating.cowTagId} ${mating.cowCalfName != null ? '(${mating.cowCalfName})' : ''}'),
                          const Divider(height: 16),
                          _buildInfoRow('Mating Date & Time', '${mating.formattedMatingDate} (${mating.matingTime ?? 'Morning'})'),
                          const Divider(height: 16),
                          _buildInfoRow('Mating Type', mating.matingType.label),
                          const Divider(height: 16),
                          if (mating.matingType == MatingType.natural) ...[
                            _buildInfoRow('Sire / Bull', mating.bullNameOrTag ?? 'Gaushala Bull'),
                          ] else ...[
                            _buildInfoRow('Semen Straw Code', mating.semenStrawCode ?? 'N/A'),
                            const Divider(height: 16),
                            _buildInfoRow('Semen Breed', mating.semenBreedName ?? 'Indigenous'),
                            const Divider(height: 16),
                            _buildInfoRow('Semen Source', mating.semenSource ?? 'N/A'),
                          ],
                          const Divider(height: 16),
                          _buildInfoRow('Inseminator', mating.inseminatorName ?? 'A.I. Technician'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Pregnancy Diagnosis (PD) Timeline Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (mating.isPDDue && mating.isPendingPD)
                            ? Colors.amber.withValues(alpha: 0.1)
                            : (isDark ? AppColors.cardDark : AppColors.cardLight),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (mating.isPDDue && mating.isPendingPD)
                              ? Colors.amber.shade400
                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(PhosphorIconsRegular.baby, size: 18, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text(
                                    'Pregnancy Diagnosis (PD) Status',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              if (mating.isPDDue && mating.isPendingPD)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade700,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'DUE / OVERDUE',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow('Expected PD Check Date', mating.formattedExpectedPDDate),
                          if (mating.pdDate != null) ...[
                            const Divider(height: 16),
                            _buildInfoRow('Actual Check Date', DateFormat('dd MMM yyyy').format(mating.pdDate!)),
                            const Divider(height: 16),
                            _buildInfoRow(
                              'PD Result',
                              mating.pdResult?.label ?? (mating.status == MatingStatus.pregnant ? 'Positive (Pregnant)' : 'N/A'),
                            ),
                            if (mating.pdPerformedBy != null && mating.pdPerformedBy!.isNotEmpty) ...[
                              const Divider(height: 16),
                              _buildInfoRow('Examined By', mating.pdPerformedBy!),
                            ],
                            if (mating.pdRemarks != null && mating.pdRemarks!.isNotEmpty) ...[
                              const Divider(height: 16),
                              _buildInfoRow('PD Notes', mating.pdRemarks!),
                            ],
                            if (mating.hasPDInconsistency) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade400),
                                ),
                                child: Row(
                                  children: [
                                    Icon(PhosphorIconsRegular.warning, color: Colors.amber.shade800, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Premature PD Check: PD examination was recorded only ${mating.daysToPDCheck} day(s) after mating (Clinical standard: 45–60 days).',
                                        style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Calving Timeline Card (if Pregnant or Calved)
                    if (mating.isPregnant || mating.isCalved) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(PhosphorIconsRegular.sparkle, size: 18, color: Color(0xFF0D9488)),
                                SizedBox(width: 8),
                                Text(
                                  'Gestation & Calving Details',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow('Expected Calving Date (~282d)', mating.formattedExpectedCalvingDate),
                            if (mating.actualCalvingDate != null) ...[
                              const Divider(height: 16),
                              _buildInfoRow('Actual Calving Date', mating.formattedActualCalvingDate),
                            ],
                            if (mating.calvingRemarks != null && mating.calvingRemarks!.isNotEmpty) ...[
                              const Divider(height: 16),
                              _buildInfoRow('Calf Notes', mating.calvingRemarks!),
                            ],
                            if (mating.hasGestationInconsistency) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade300),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(PhosphorIconsRegular.warningCircle, color: Colors.red.shade700, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Biological Inconsistency: Calving date (${mating.formattedActualCalvingDate}) matches or is too close to Mating Date (${mating.formattedMatingDate}). Gestation recorded as ${mating.actualGestationDays} days (Normal is ~282 days). Please click "Edit Record" to rectify.',
                                        style: TextStyle(fontSize: 11, color: Colors.red.shade800, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // General Remarks
                    if (mating.remarks != null && mating.remarks!.isNotEmpty) ...[
                      Text(
                        'General Remarks',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mating.remarks!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          EditMatingDialog.show(context, mating);
                        },
                        icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 16),
                        label: const Text('Edit Record'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (mating.isPendingPD)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            RecordPDDialog.show(context, mating);
                          },
                          icon: const Icon(PhosphorIconsRegular.stethoscope, size: 18),
                          label: const Text('Record PD Check Result'),
                        ),
                      if (mating.isPregnant)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            RecordCalvingDialog.show(context, mating);
                          },
                          icon: const Icon(PhosphorIconsRegular.sparkle, size: 18),
                          label: const Text('Record Calving Event'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
