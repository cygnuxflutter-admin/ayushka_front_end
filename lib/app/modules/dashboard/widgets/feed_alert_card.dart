import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/dashboard_alerts_model.dart';
import '../../../routes/app_routes.dart';

/// Interactive card presenting a Low Feed Inventory Alert with visual buffer meters and Quick Inward action.
class FeedAlertCard extends StatefulWidget {
  final FeedStockAlertItem alert;
  final VoidCallback onQuickInward;

  const FeedAlertCard({
    super.key,
    required this.alert,
    required this.onQuickInward,
  });

  @override
  State<FeedAlertCard> createState() => _FeedAlertCardState();
}

class _FeedAlertCardState extends State<FeedAlertCard> {
  bool _isHovered = false;

  FeedStockAlertItem get alert => widget.alert;
  VoidCallback get onQuickInward => widget.onQuickInward;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final double bufferRatio = alert.minStockAlert > 0
        ? (alert.currentStock / alert.minStockAlert).clamp(0.0, 1.0)
        : 0.0;
    final int pct = (bufferRatio * 100).toInt();
    final double deficit = (alert.minStockAlert - alert.currentStock).clamp(0.0, 999999.0);

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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isHovered
                ? AppColors.error.withValues(alpha: 0.55)
                : AppColors.error.withValues(alpha: isDark ? 0.35 : 0.2),
            width: _isHovered ? 1.5 : 1.2,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // High-Visibility Feed Alert Attention Banner
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.errorBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIconsRegular.warningOctagon, size: 12, color: AppColors.error),
                SizedBox(width: 6),
                Text(
                  '⚠️ SAFETY BUFFER BREACHED • INVENTORY INWARD REQUIRED',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Header Row: Category Badge + Alert Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsRegular.plant, size: 14, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      (alert.category ?? 'FODDER').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      'SHORTFALL: ${deficit.toStringAsFixed(1)} ${alert.unit}',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Feed Item Name
          Text(
            alert.itemName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Visual Stock vs Minimum Safety Buffer Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Stock: ${alert.currentStock.toStringAsFixed(1)} ${alert.unit}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Buffer Target: ${alert.minStockAlert.toStringAsFixed(1)} ${alert.unit} ($pct%)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 7,
                  width: double.infinity,
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: bufferRatio > 0.05 ? bufferRatio : 0.05,
                    child: Container(
                      color: bufferRatio < 0.3 ? AppColors.error : AppColors.warning,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.feedItems),
                child: const Text('Open Inventory', style: TextStyle(fontSize: 12.5)),
              ),
              const SizedBox(width: 8),
              CustomButton(
                text: 'Quick Inward',
                icon: PhosphorIconsRegular.arrowDownLeft,
                height: 38,
                width: 145,
                onPressed: onQuickInward,
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
