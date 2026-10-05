import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/core/values/app_colors.dart';
import '../../../data/models/treatment_model.dart';

/// Modern Clinical Multi-Dose Chronological Timeline Stepper Widget
class DoseTimelineWidget extends StatelessWidget {
  final CowTreatmentModel treatment;
  final Function(int doseNumber) onAdministerDose;
  final bool isMobile;

  const DoseTimelineWidget({
    super.key,
    required this.treatment,
    required this.onAdministerDose,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final doses = treatment.doses;

    if (doses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(
          children: [
            Icon(PhosphorIconsRegular.calendarX, size: 42, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No Scheduled Doses',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'No multi-dose schedule configured for this medical case.',
              style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Progress & Summary Header Card
        _buildProgressOverviewCard(context, isDark),
        const SizedBox(height: 20),

        // 2. Chronological Vertical Stepper
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: doses.length,
          itemBuilder: (ctx, idx) {
            final dose = doses[idx];
            return _buildTimelineStep(
              context: ctx,
              dose: dose,
              index: idx,
              totalDoses: doses.length,
              isDark: isDark,
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PROGRESS & PROTOCOL OVERVIEW CARD
  // ---------------------------------------------------------------------------
  Widget _buildProgressOverviewCard(BuildContext context, bool isDark) {
    final total = treatment.totalDoses > 0 ? treatment.totalDoses : treatment.doses.length;
    final completed = treatment.completedDoses;
    final percent = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    final percentInt = (percent * 100).toInt();

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(PhosphorIconsRegular.calendarCheck, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Multi-Dose Chronological Schedule',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track clinical dose progress, administered cycles, and pending intervals',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (treatment.hasDosesPending && !isMobile) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => onAdministerDose(
                    treatment.nextDoseNumber ?? (treatment.completedDoses + 1),
                  ),
                  icon: const Icon(PhosphorIconsRegular.syringe, size: 16),
                  label: Text('Administer Dose ${treatment.nextDoseNumber ?? (treatment.completedDoses + 1)}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: treatment.isDoseDueToday ? const Color(0xFFF59E0B) : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar & Quick Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : const Color(0xFFF8FAF6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE9EFE5)),
            ),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Protocol Progress:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$completed of $total doses administered ($percentInt%)',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (treatment.hasDosesPending && treatment.nextDoseDate != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            treatment.isDoseDueToday ? PhosphorIconsRegular.warningCircle : PhosphorIconsRegular.clock,
                            size: 14,
                            color: treatment.isDoseDueToday ? const Color(0xFFF59E0B) : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              treatment.isDoseDueToday
                                  ? 'Next Dose Due Today!'
                                  : 'Next: ${DateFormat('dd MMM yyyy').format(treatment.nextDoseDate!)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: treatment.isDoseDueToday
                                    ? const Color(0xFFF59E0B)
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 7,
                    backgroundColor: isDark ? Colors.black26 : const Color(0xFFE2E8DC),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      completed == total ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TIMELINE STEP (IntrinsicHeight with clean 2.5px vertical connecting line)
  // ---------------------------------------------------------------------------
  Widget _buildTimelineStep({
    required BuildContext context,
    required TreatmentDoseModel dose,
    required int index,
    required int totalDoses,
    required bool isDark,
  }) {
    final isGiven = dose.isGiven;
    final isDueToday = dose.isDueToday;
    final isNext = !isGiven && (treatment.nextDoseNumber == dose.doseNumber || index == treatment.completedDoses);
    final isLast = index == totalDoses - 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Vertical Stepper Column
          SizedBox(
            width: isMobile ? 32 : 40,
            child: Column(
              children: [
                // Node Avatar Circle
                Container(
                  width: isMobile ? 30 : 36,
                  height: isMobile ? 30 : 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isGiven
                        ? AppColors.success
                        : (isDueToday
                            ? const Color(0xFFF59E0B)
                            : (isDark ? AppColors.cardDark : Colors.white)),
                    border: Border.all(
                      color: isGiven
                          ? AppColors.success
                          : (isDueToday
                              ? const Color(0xFFF59E0B)
                              : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1))),
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isGiven
                                ? AppColors.success
                                : (isDueToday ? const Color(0xFFF59E0B) : Colors.black))
                            .withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isGiven
                          ? Icons.check_rounded
                          : (isDueToday ? PhosphorIconsRegular.clock : PhosphorIconsRegular.hourglass),
                      color: isGiven || isDueToday ? Colors.white : Colors.grey.shade500,
                      size: isMobile ? 15 : 17,
                    ),
                  ),
                ),

                // Connecting Line (strictly vertical, width 2.5)
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2.5,
                        color: isGiven
                            ? AppColors.success.withValues(alpha: 0.45)
                            : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: isMobile ? 8 : 14),

          // Right Dose Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: _buildDoseCard(
                context: context,
                dose: dose,
                isGiven: isGiven,
                isDueToday: isDueToday,
                isNext: isNext,
                totalDoses: totalDoses,
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DOSE CARD
  // ---------------------------------------------------------------------------
  Widget _buildDoseCard({
    required BuildContext context,
    required TreatmentDoseModel dose,
    required bool isGiven,
    required bool isDueToday,
    required bool isNext,
    required int totalDoses,
    required bool isDark,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDueToday
              ? const Color(0xFFF59E0B)
              : (isGiven
                  ? AppColors.success.withValues(alpha: 0.35)
                  : (isDark ? AppColors.borderDark : AppColors.borderLight)),
          width: isDueToday ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDueToday ? const Color(0xFFF59E0B) : Colors.black).withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Band
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 10),
            decoration: BoxDecoration(
              color: isGiven
                  ? AppColors.success.withValues(alpha: 0.04)
                  : (isDueToday
                      ? const Color(0xFFFFFBEB)
                      : (isDark ? AppColors.cardDark.withValues(alpha: 0.5) : const Color(0xFFFAFCF8))),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight.withValues(alpha: 0.7),
                  width: 0.8,
                ),
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Dose Name & Status Badges
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      'Dose ${dose.doseNumber}',
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Cycle ${dose.doseNumber} of $totalDoses',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: dose.status.bgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: dose.status.color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGiven
                                ? Icons.check_circle_rounded
                                : (isDueToday ? PhosphorIconsRegular.clock : PhosphorIconsRegular.hourglass),
                            size: 11.5,
                            color: dose.status.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dose.status.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: dose.status.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isDueToday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorIconsRegular.warningCircle, size: 11.5, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'DUE TODAY',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Date & Time Chip
                Container(
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? 180 : 320,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGiven ? PhosphorIconsRegular.calendarCheck : PhosphorIconsRegular.calendarBlank,
                        size: 13,
                        color: isGiven ? AppColors.success : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          isGiven && dose.administeredDate != null
                              ? 'Administered: ${DateFormat('dd MMM yyyy, hh:mm a').format(dose.administeredDate!)}'
                              : 'Scheduled: ${dose.scheduledDate != null ? DateFormat('dd MMM yyyy').format(dose.scheduledDate!) : "Immediate"}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isGiven ? FontWeight.w600 : FontWeight.w500,
                            color: isGiven ? AppColors.success : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Card Content Details
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Staff info row
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Icon(
                      PhosphorIconsRegular.userCircle,
                      size: 15,
                      color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                    ),
                    Text(
                      'Staff In-Charge:',
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isMobile ? 160 : 350),
                      child: Text(
                        dose.administeredBy != null && dose.administeredBy!.isNotEmpty
                            ? dose.administeredBy!
                            : (treatment.doctorName.isNotEmpty ? treatment.doctorName : 'Attending Vet'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Prescribed Medicines Section
                if (dose.medicines.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(PhosphorIconsRegular.pill, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Administered Medicines (${dose.medicines.length}):',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dose.medicines.map((m) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: m.isStockItem
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: m.isStockItem
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : const Color(0xFFFCD34D),
                          ),
                        ),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  m.isStockItem ? PhosphorIconsRegular.package : PhosphorIconsRegular.pill,
                                  size: 13,
                                  color: m.isStockItem ? AppColors.primary : const Color(0xFFB45309),
                                ),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: isMobile ? 120 : 250),
                                  child: Text(
                                    m.medicineName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: m.isStockItem ? AppColors.primary : const Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.cardDark : Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${m.dosage} • ${m.route}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: m.isStockItem ? AppColors.primary : const Color(0xFF92400E),
                                ),
                              ),
                            ),
                            Text(
                              m.isStockItem ? 'Pharmacy Stock' : 'Outside',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontStyle: FontStyle.italic,
                                color: m.isStockItem
                                    ? AppColors.primary.withValues(alpha: 0.8)
                                    : const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Clinical Observation Notes Box (Doctor's Note Card)
                if (dose.notes != null && dose.notes!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : const Color(0xFFF7FAF4),
                        border: Border(
                          left: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.8),
                            width: 3.5,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(PhosphorIconsRegular.clipboardText, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Clinical Observation & Administration Remarks:',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dose.notes!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Recovery Notes
                if (dose.recoveryNotes != null && dose.recoveryNotes!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsRegular.heartbeat, size: 15, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Post-Dose Recovery: ${dose.recoveryNotes!}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Callout for Next Pending Dose
                if (!isGiven && isNext) ...[
                  const Divider(height: 24),
                  Builder(
                    builder: (context) {
                      final isCompact = isMobile || MediaQuery.of(context).size.width < 650;
                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDueToday ? const Color(0xFFFFFBEB) : AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    PhosphorIconsRegular.info,
                                    size: 16,
                                    color: isDueToday ? const Color(0xFFF59E0B) : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isDueToday
                                        ? 'This dose is scheduled for today. Administer and record medicine stock usage.'
                                        : 'Next dose in clinical sequence. Ready for administration.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => onAdministerDose(dose.doseNumber),
                              icon: const Icon(PhosphorIconsRegular.syringe, size: 16),
                              label: Text('Administer Dose ${dose.doseNumber}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDueToday ? const Color(0xFFF59E0B) : AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDueToday ? const Color(0xFFFFFBEB) : AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              PhosphorIconsRegular.info,
                              size: 16,
                              color: isDueToday ? const Color(0xFFF59E0B) : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isDueToday
                                  ? 'This dose is scheduled for today. Administer and record medicine stock usage.'
                                  : 'Next dose in clinical sequence. Ready for administration.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => onAdministerDose(dose.doseNumber),
                            icon: const Icon(PhosphorIconsRegular.syringe, size: 16),
                            label: Text('Administer Dose ${dose.doseNumber}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDueToday ? const Color(0xFFF59E0B) : AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
