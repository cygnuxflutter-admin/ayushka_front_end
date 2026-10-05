import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/dashboard_alerts_model.dart';
import '../../../routes/app_routes.dart';

/// Interactive card presenting milk production variance or tank alerts with quick acknowledge action.
class MilkAlertCard extends StatefulWidget {
  final MilkAlertItem alert;
  final VoidCallback onDismiss;
  final bool isDismissing;

  const MilkAlertCard({
    super.key,
    required this.alert,
    required this.onDismiss,
    this.isDismissing = false,
  });

  @override
  State<MilkAlertCard> createState() => _MilkAlertCardState();
}

class _MilkAlertCardState extends State<MilkAlertCard> {
  bool _isHovered = false;

  MilkAlertItem get alert => widget.alert;
  VoidCallback get onDismiss => widget.onDismiss;
  bool get isDismissing => widget.isDismissing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const accentColor = Color(0xFFF59E0B);

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
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? accentColor.withValues(alpha: 0.5)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: _isHovered ? 1.4 : 1.0,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // High-Visibility Milk Alert Attention Banner
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accentColor.withValues(alpha: 0.35)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIconsRegular.warning, size: 12, color: accentColor),
                SizedBox(width: 6),
                Text(
                  '⚠️ PRODUCTION VARIANCE • ANIMAL REVIEW REQUIRED',
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

          // Header Row: Cow Tag / Bulk Badge + Shift Chip + Date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsRegular.dropHalfBottom, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    Text(
                      alert.cowTag.isNotEmpty ? alert.cowTag : 'Milk Batch',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
              if (alert.shift != null && alert.shift!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    alert.shift!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (alert.createdAt != null)
                Text(
                  DateFormat('dd MMM, hh:mm a').format(alert.createdAt!),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Alert Message Body
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsRegular.warningCircle,
                  color: Color(0xFFF59E0B),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.cows),
                child: const Text('View Cow Log', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              CustomButton(
                text: 'Dismiss Alert',
                icon: PhosphorIconsRegular.check,
                variant: ButtonVariant.outlined,
                height: 36,
                width: 140,
                isLoading: isDismissing,
                onPressed: onDismiss,
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
