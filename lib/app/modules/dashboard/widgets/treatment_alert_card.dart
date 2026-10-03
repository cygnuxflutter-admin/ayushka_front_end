import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/dashboard_alerts_model.dart';
import '../../../routes/app_routes.dart';

/// Interactive card presenting a treatment dose due or critical condition with inline Administer action.
class TreatmentAlertCard extends StatefulWidget {
  final TreatmentAlertItem alert;
  final VoidCallback onAdminister;

  const TreatmentAlertCard({
    super.key,
    required this.alert,
    required this.onAdminister,
  });

  @override
  State<TreatmentAlertCard> createState() => _TreatmentAlertCardState();
}

class _TreatmentAlertCardState extends State<TreatmentAlertCard> {
  bool _isHovered = false;

  TreatmentAlertItem get alert => widget.alert;
  VoidCallback get onAdminister => widget.onAdminister;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isCritical = widget.alert.isCritical;
    final accentColor = isCritical ? AppColors.error : AppColors.warning;
    final bgColor = isCritical
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
                : (isCritical
                    ? AppColors.error.withValues(alpha: isDark ? 0.4 : 0.25)
                    : (isDark ? AppColors.borderDark : AppColors.borderLight)),
            width: isCritical ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: accentColor.withValues(alpha: isCritical ? 0.16 : 0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            else
              BoxShadow(
                color: isCritical
                    ? AppColors.error.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // High-Visibility Alert Attention Banner
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accentColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isCritical ? '⚠️ CRITICAL HEALTH ALERT • IMMEDIATE ACTION' : '⚠️ SCHEDULED DOSE DUE TODAY',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Top Row: Tag, Calf, Severity Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsRegular.cow, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      alert.cowTag,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (alert.calfName != null && alert.calfName!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  alert.calfName!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  alert.severity,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Disease Name
          Text(
            alert.diseaseName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

          // Metadata Row: Dose progress and Barn / Date
          Wrap(
            spacing: 16,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(PhosphorIconsRegular.clock, size: 14, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    'Dose #${alert.dueDoseNumber} of ${alert.totalDoses}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              if (alert.shedNumber != null && alert.shedNumber!.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsRegular.warehouse, size: 14, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      'Shed: ${alert.shedNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              if (alert.nextDoseDate != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsRegular.calendarBlank, size: 14, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      DateFormat('dd MMM, hh:mm a').format(alert.nextDoseDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Button Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.treatments),
                child: const Text('View Treatments', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              CustomButton(
                text: 'Administer Dose',
                icon: PhosphorIconsRegular.firstAidKit,
                height: 36,
                width: 155,
                onPressed: onAdminister,
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
