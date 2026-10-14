import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/cow_heat_model.dart';
import '../../../data/models/cow_mating_model.dart';
import '../../../routes/app_routes.dart';
import '../../heat/dialogs/heat_details_dialog.dart';
import '../../mating/dialogs/add_mating_dialog.dart';
import '../../mating/dialogs/mating_details_dialog.dart';
import '../../mating/dialogs/record_pd_dialog.dart';

/// Card component to display Cow Heat and Mating alerts in the Dashboard Smart Alerts Center.
class BreedingAlertCard extends StatefulWidget {
  final CowHeatModel? heatAlert;
  final CowMatingModel? matingAlert;
  final VoidCallback? onActionCompleted;

  const BreedingAlertCard.heat({
    super.key,
    required CowHeatModel heat,
    this.onActionCompleted,
  })  : heatAlert = heat,
        matingAlert = null;

  const BreedingAlertCard.mating({
    super.key,
    required CowMatingModel mating,
    this.onActionCompleted,
  })  : heatAlert = null,
        matingAlert = mating;

  @override
  State<BreedingAlertCard> createState() => _BreedingAlertCardState();
}

class _BreedingAlertCardState extends State<BreedingAlertCard> {
  bool _isHovered = false;

  bool get isHeat => widget.heatAlert != null;
  CowHeatModel? get heat => widget.heatAlert;
  CowMatingModel? get mating => widget.matingAlert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isHighAlert = isHeat
        ? (heat!.isRepeatHeatAlert || heat!.consecutiveHeatCount >= 3)
        : (mating!.isRepeatBreederAlert || mating!.isDueForPD);

    final accentColor = isHighAlert ? AppColors.error : AppColors.primary;
    final bgColor = isHighAlert
        ? (isDark ? const Color(0xFF2E1717) : const Color(0xFFFFF5F5))
        : (isDark ? AppColors.cardDark : AppColors.cardLight);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: _isHovered
            ? Matrix4.translationValues(0.0, -3.0, 0.0)
            : Matrix4.identity(),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? accentColor.withValues(alpha: 0.6)
                : (isHighAlert
                    ? AppColors.error.withValues(alpha: isDark ? 0.4 : 0.25)
                    : (isDark ? AppColors.borderDark : AppColors.borderLight)),
            width: isHighAlert ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.02),
              blurRadius: _isHovered ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isHeat ? _buildHeatContent(isDark) : _buildMatingContent(isDark),
      ),
    );
  }

  Widget _buildHeatContent(bool isDark) {
    final h = heat!;
    final isRepeat = h.isRepeatHeatAlert || h.consecutiveHeatCount >= 3;
    final cowName = h.cowCalfName?.isNotEmpty == true ? h.cowCalfName! : 'Cow #${h.cowTagId}';
    final dateStr = h.heatDate != null ? DateFormat('dd MMM yyyy').format(h.heatDate!) : 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isRepeat ? AppColors.error : const Color(0xFFF43F5E))
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isRepeat ? PhosphorIconsRegular.warningOctagon : PhosphorIconsRegular.flame,
                color: isRepeat ? AppColors.error : const Color(0xFFF43F5E),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        h.cowTagId.isNotEmpty ? 'Tag #${h.cowTagId}' : 'ID: ${h.cowId}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($cowName)',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      const Spacer(),
                      if (isRepeat)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(PhosphorIconsRegular.warning, size: 12, color: AppColors.error),
                              const SizedBox(width: 4),
                              Text(
                                'REPEAT ESTRUS (${h.consecutiveHeatCount} CYCLES)',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            h.status.label.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Observed: $dateStr (${h.heatTime})',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      Text(
                        '• Stage: ${h.heatStage.label}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      Text(
                        '• Intensity: ${h.intensity.label}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      if (h.cowShedName != null && h.cowShedName!.isNotEmpty)
                        Text(
                          '• Shed: ${h.cowShedName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (h.heatSigns.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: h.heatSigns.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  HeatSignDefinition.getLabel(s),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () {
                HeatDetailsDialog.show(context, h);
              },
              icon: const Icon(PhosphorIconsRegular.info, size: 16),
              label: const Text('View Heat Details'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            CustomButton(
              text: 'Record Mating',
              icon: PhosphorIconsRegular.heartbeat,
              backgroundColor: const Color(0xFFF43F5E),
              textColor: Colors.white,
              onPressed: () async {
                final result = await AddMatingDialog.show(
                  context,
                  preselectedHeat: h,
                );
                if (result == true) {
                  widget.onActionCompleted?.call();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMatingContent(bool isDark) {
    final m = mating!;
    final isRepeatBreeder = m.isRepeatBreederAlert || m.failedMatingAttempts >= 3;
    final isDuePD = m.isDueForPD || m.status == MatingStatus.pendingPd;
    final cowName = m.cowCalfName?.isNotEmpty == true ? m.cowCalfName! : 'Cow #${m.cowTagId}';
    final matingDateStr = m.matingDate != null ? DateFormat('dd MMM yyyy').format(m.matingDate!) : 'N/A';
    final pdDueStr = m.expectedPDDate != null ? DateFormat('dd MMM yyyy').format(m.expectedPDDate!) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isRepeatBreeder ? AppColors.error : const Color(0xFF8B5CF6))
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isRepeatBreeder ? PhosphorIconsRegular.warningOctagon : PhosphorIconsRegular.stethoscope,
                color: isRepeatBreeder ? AppColors.error : const Color(0xFF8B5CF6),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        m.cowTagId.isNotEmpty ? 'Tag #${m.cowTagId}' : 'ID: ${m.cowId}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($cowName)',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      const Spacer(),
                      if (isRepeatBreeder)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(PhosphorIconsRegular.warning, size: 12, color: AppColors.error),
                              const SizedBox(width: 4),
                              Text(
                                'REPEAT BREEDER (${m.failedMatingAttempts} FAILS)',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (isDuePD)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PD CHECK DUE',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Mated: $matingDateStr (${m.matingType.label})',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      if (m.matingType == MatingType.natural && m.bullDisplayName.isNotEmpty)
                        Text(
                          '• Sire: ${m.bullDisplayName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      if (m.matingType == MatingType.artificial && m.semenStrawCode != null)
                        Text(
                          '• Straw: ${m.semenStrawCode}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      if (pdDueStr != null)
                        Text(
                          '• Expected PD: $pdDueStr',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDuePD ? const Color(0xFFD97706) : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () {
                MatingDetailsDialog.show(context, m);
              },
              icon: const Icon(PhosphorIconsRegular.info, size: 16),
              label: const Text('View Mating Details'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            if (isDuePD || m.status == MatingStatus.pendingPd) ...[
              CustomButton(
                text: 'Record PD Result',
                icon: PhosphorIconsRegular.checkCircle,
                backgroundColor: const Color(0xFF8B5CF6),
                textColor: Colors.white,
                onPressed: () async {
                  final result = await RecordPDDialog.show(context, m);
                  if (result == true) {
                    widget.onActionCompleted?.call();
                  }
                },
              ),
            ] else ...[
              CustomButton(
                text: 'View Mating Registry',
                icon: PhosphorIconsRegular.arrowRight,
                backgroundColor: AppColors.primary,
                textColor: Colors.white,
                onPressed: () => Get.toNamed(AppRoutes.matings),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
