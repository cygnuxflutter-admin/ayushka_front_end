import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:ayushka/app/core/values/app_colors.dart';
import 'package:ayushka/app/core/widgets/custom_button.dart';
import 'package:ayushka/app/data/models/notification_model.dart';
import '../../controllers/milk_controller.dart';

/// Helper model for parsing structured insights from milk notification messages
class ParsedMilkAlert {
  final String cowTag;
  final String? dropPercent;
  final String? currentYield;
  final String? priorYield;
  final String? shift;
  final String? date;
  final String rawTitle;
  final String rawMessage;
  final String timeAgo;

  ParsedMilkAlert({
    required this.cowTag,
    this.dropPercent,
    this.currentYield,
    this.priorYield,
    this.shift,
    this.date,
    required this.rawTitle,
    required this.rawMessage,
    required this.timeAgo,
  });

  factory ParsedMilkAlert.fromNotification(NotificationModel notif) {
    final title = notif.title;
    final msg = notif.message;
    final combined = '$title $msg';

    // 1. Cow Tag
    String tag = notif.cowTagId ?? '';
    if (tag.isEmpty) {
      final cowMatch = RegExp(r'Cow\s*#?([A-Za-z0-9_-]+)', caseSensitive: false).firstMatch(combined);
      if (cowMatch != null && cowMatch.groupCount >= 1) {
        tag = cowMatch.group(1) ?? 'Unknown';
      } else {
        tag = 'N/A';
      }
    }
    if (!tag.startsWith('#') && tag != 'N/A') {
      tag = '#$tag';
    }

    // 2. Drop / Variance Percent
    String? drop;
    final dropMatch = RegExp(r'([0-9]+(?:\.[0-9]+)?)\s*%\s*(drop|decline|decrease|fluctuation|increase)', caseSensitive: false).firstMatch(combined);
    if (dropMatch != null) {
      final pct = dropMatch.group(1);
      final word = dropMatch.group(2)?.toLowerCase() ?? 'drop';
      drop = '$pct% ${word.toUpperCase()}';
    } else {
      final pctMatch = RegExp(r'([0-9]+(?:\.[0-9]+)?)\s*%', caseSensitive: false).firstMatch(combined);
      if (pctMatch != null) {
        drop = '${pctMatch.group(1)}% DROP';
      }
    }

    // 3. Current Yield
    String? curYield;
    final curMatch = RegExp(r'produced\s*([0-9]+(?:\.[0-9]+)?\s*L?)', caseSensitive: false).firstMatch(combined);
    if (curMatch != null) {
      curYield = curMatch.group(1);
      if (curYield != null && !curYield.toUpperCase().endsWith('L')) {
        curYield = '${curYield}L';
      }
    }

    // 4. Prior Yield
    String? oldYield;
    final priorMatch = RegExp(r'prior(?:\s+production)?\s*\(?([0-9]+(?:\.[0-9]+)?\s*L?)\)?', caseSensitive: false).firstMatch(combined);
    if (priorMatch != null) {
      oldYield = priorMatch.group(1);
      if (oldYield != null && !oldYield.toUpperCase().endsWith('L')) {
        oldYield = '${oldYield}L';
      }
    }

    // 5. Shift
    String? shift;
    if (combined.toLowerCase().contains('morning')) {
      shift = 'Morning Shift';
    } else if (combined.toLowerCase().contains('evening')) {
      shift = 'Evening Shift';
    } else if (combined.toLowerCase().contains('afternoon')) {
      shift = 'Afternoon Shift';
    }

    // 6. Date
    String? date;
    final dateMatch = RegExp(r'\b(20\d\d-\d{2}-\d{2})\b').firstMatch(combined);
    if (dateMatch != null) {
      date = dateMatch.group(1);
    }

    return ParsedMilkAlert(
      cowTag: tag,
      dropPercent: drop,
      currentYield: curYield,
      priorYield: oldYield,
      shift: shift,
      date: date,
      rawTitle: title,
      rawMessage: msg,
      timeAgo: notif.timeAgo,
    );
  }

  double? get currentYieldNum {
    if (currentYield == null) return null;
    final clean = currentYield!.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean);
  }

  double? get priorYieldNum {
    if (priorYield == null) return null;
    final clean = priorYield!.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean);
  }

  String get netVarianceText {
    final cur = currentYieldNum;
    final prior = priorYieldNum;
    if (cur != null && prior != null) {
      final diff = cur - prior;
      final sign = diff > 0 ? '+' : '';
      return '$sign${diff.toStringAsFixed(1)} L';
    }
    return dropPercent ?? '-';
  }
}

/// High-priority Milk Production Alert Details Modal Dialog
class MilkAlertDetailDialog extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onRunAnalysis;
  final VoidCallback? onViewTab;

  const MilkAlertDetailDialog({
    super.key,
    required this.notification,
    this.onRunAnalysis,
    this.onViewTab,
  });

  /// Static helper to trigger the dialog smoothly
  static Future<void> show(
    BuildContext context, {
    required NotificationModel notification,
    VoidCallback? onRunAnalysis,
    VoidCallback? onViewTab,
  }) async {
    await Get.dialog(
      MilkAlertDetailDialog(
        notification: notification,
        onRunAnalysis: onRunAnalysis,
        onViewTab: onViewTab,
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final parsed = ParsedMilkAlert.fromNotification(notification);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: isDark ? const Color(0xFF1B281B) : Colors.white,
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(context, isDark, parsed),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Alert Status Banner Strip
                      _buildAlertStatusStrip(isDark, parsed),
                      const SizedBox(height: 18),

                      // Metric Comparison Matrix
                      _buildYieldMetrics(isDark, parsed),
                      const SizedBox(height: 18),

                      // Raw Message Box
                      _buildNoticeBox(isDark, parsed),
                      const SizedBox(height: 18),

                      // Farm / Vet Advisory Checklist
                      _buildActionAdvisory(isDark, parsed),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Action Buttons
              _buildActionFooter(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, bool isDark, ParsedMilkAlert parsed) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFE98324).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE98324).withValues(alpha: 0.35),
            ),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFE98324),
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'Milk Production Alert',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.shield_outlined, size: 16, color: Color(0xFFE98324)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Yield Fluctuation Warning • ${parsed.timeAgo}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          style: IconButton.styleFrom(
            backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          ),
          onPressed: () => Get.back(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STATUS BANNER STRIP
  // ---------------------------------------------------------------------------
  Widget _buildAlertStatusStrip(bool isDark, ParsedMilkAlert parsed) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE98324).withValues(alpha: isDark ? 0.22 : 0.12),
          border: const Border(
            left: BorderSide(color: Color(0xFFE98324), width: 4),
          ),
        ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.crisis_alert_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'CRITICAL YIELD DROP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Text(
              'Cow ${parsed.cowTag}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
                color: AppColors.primary,
              ),
            ),
          ),
          const Spacer(),
          if (parsed.shift != null)
            Text(
              parsed.shift!,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
        ],
      ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // YIELD METRICS COMPARISON
  // ---------------------------------------------------------------------------
  Widget _buildYieldMetrics(bool isDark, ParsedMilkAlert parsed) {
    return Row(
      children: [
        // Prior Yield
        Expanded(
          child: _buildMetricTile(
            label: 'Prior Production',
            value: parsed.priorYield ?? 'N/A',
            sub: 'Historical reference',
            icon: PhosphorIconsRegular.clockCounterClockwise,
            accentColor: AppColors.secondary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),

        // Recorded Yield
        Expanded(
          child: _buildMetricTile(
            label: 'Recorded Yield',
            value: parsed.currentYield ?? 'N/A',
            sub: parsed.date ?? 'Current shift',
            icon: PhosphorIconsRegular.drop,
            accentColor: const Color(0xFFE98324),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),

        // Fluctuation / Drop
        Expanded(
          child: _buildMetricTile(
            label: 'Net Variance',
            value: parsed.dropPercent ?? parsed.netVarianceText,
            sub: parsed.netVarianceText,
            icon: Icons.trending_down_rounded,
            accentColor: const Color(0xFFD32F2F),
            isDark: isDark,
            isWarning: true,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isWarning
            ? (isDark ? const Color(0xFF3B1B1B) : const Color(0xFFFDE8E8))
            : (isDark ? AppColors.surfaceDark : const Color(0xFFF7FAF4)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.4 : 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isWarning ? const Color(0xFFD32F2F) : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FULL NOTICE BOX
  // ---------------------------------------------------------------------------
  Widget _buildNoticeBox(bool isDark, ParsedMilkAlert parsed) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFE98324)),
              const SizedBox(width: 8),
              Text(
                'System Notification Log',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            parsed.rawMessage,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACTION ADVISORY CHECKLIST
  // ---------------------------------------------------------------------------
  Widget _buildActionAdvisory(bool isDark, ParsedMilkAlert parsed) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2F1E) : const Color(0xFFF1F6EE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.medical_services_outlined, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Recommended Farm Advisory Steps',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildCheckItem(
            'Check cow udder for mastitis or swelling.',
            isDark,
          ),
          const SizedBox(height: 6),
          _buildCheckItem(
            'Verify nutritional intake and water hydration levels.',
            isDark,
          ),
          const SizedBox(height: 6),
          _buildCheckItem(
            'Confirm shift bucket measurement with milking worker.',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FOOTER ACTIONS
  // ---------------------------------------------------------------------------
  Widget _buildActionFooter(BuildContext context, bool isDark) {
    final MilkController? controller = Get.isRegistered<MilkController>() ? Get.find<MilkController>() : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomButton(
          text: 'Close',
          variant: ButtonVariant.outlined,
          height: 38,
          onPressed: () => Get.back(),
        ),
        Wrap(
          spacing: 10,
          children: [
            if (controller != null)
              CustomButton(
                text: 'Run Analysis',
                icon: Icons.refresh_rounded,
                variant: ButtonVariant.outlined,
                height: 38,
                isLoading: controller.isCheckingMonthlyAlerts.value,
                onPressed: () {
                  controller.runMonthlyAnalysis();
                  if (onRunAnalysis != null) onRunAnalysis!();
                },
              ),
            CustomButton(
              text: 'View Monthly Variance',
              icon: Icons.arrow_forward_rounded,
              variant: ButtonVariant.primary,
              height: 38,
              onPressed: () {
                Get.back();
                if (onViewTab != null) {
                  onViewTab!();
                } else if (controller != null) {
                  controller.changeTab(4);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
