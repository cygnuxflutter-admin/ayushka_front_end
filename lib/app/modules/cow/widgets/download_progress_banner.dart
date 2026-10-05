import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../cow_controller.dart';

/// Floating animated notification banner showing real-time cattle Excel template download progress,
/// downloaded byte count, and completion badge.
class DownloadProgressBanner extends StatelessWidget {
  final CowController controller;

  const DownloadProgressBanner({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final isVisible = controller.showDownloadBanner.value;
      if (!isVisible) {
        return const SizedBox.shrink();
      }

      final isDownloading = controller.isDownloadingTemplate.value;
      final isSuccess = controller.isDownloadSuccess.value;
      final progress = controller.downloadProgress.value;
      final downloadedBytes = controller.downloadedBytes.value;
      final totalBytes = controller.totalDownloadBytes.value;

      final downloadedStr = controller.formatBytes(downloadedBytes);
      final totalStr = totalBytes > 0 ? controller.formatBytes(totalBytes) : downloadedStr;
      final percentInt = (progress * 100).toInt().clamp(0, 100);

      return AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        offset: isVisible ? Offset.zero : const Offset(0, -1),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isVisible ? 1.0 : 0.0,
          child: Container(
            width: 380,
            margin: const EdgeInsets.only(top: 16, right: 24, left: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSuccess
                    ? const Color(0xFF2E7D32).withValues(alpha: 0.5)
                    : AppColors.primary.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSuccess
                            ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                            : AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isSuccess ? Icons.check_circle_rounded : PhosphorIconsRegular.fileArrowDown,
                        size: 20,
                        color: isSuccess ? const Color(0xFF2E7D32) : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSuccess
                                ? 'Template Downloaded ($downloadedStr)'
                                : 'Downloading Template ($percentInt%)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isSuccess
                                ? 'cow_import_template.xlsx ready'
                                : '$downloadedStr / $totalStr',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      color: AppColors.textSecondaryLight,
                      splashRadius: 16,
                      onPressed: () => controller.showDownloadBanner.value = false,
                    ),
                  ],
                ),
                if (isDownloading) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
