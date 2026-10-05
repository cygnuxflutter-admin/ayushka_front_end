import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../cow_controller.dart';

/// Animated modal dialog for uploading cattle Excel templates with live byte progress,
/// server processing status, and final imported records counter.
class ExcelImportDialog extends StatefulWidget {
  final String fileName;
  final List<int> fileBytes;
  final CowController controller;

  const ExcelImportDialog({
    super.key,
    required this.fileName,
    required this.fileBytes,
    required this.controller,
  });

  /// Static helper to display the dialog
  static Future<void> show({
    required BuildContext context,
    required String fileName,
    required List<int> fileBytes,
    required CowController controller,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ExcelImportDialog(
        fileName: fileName,
        fileBytes: fileBytes,
        controller: controller,
      ),
    );
  }

  @override
  State<ExcelImportDialog> createState() => _ExcelImportDialogState();
}

class _ExcelImportDialogState extends State<ExcelImportDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    // Kick off upload immediately after widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.executeUploadExcel(
        fileBytes: widget.fileBytes,
        fileName: widget.fileName,
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth - 32).clamp(260.0, 520.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(side: BorderSide.none),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
          width: dialogWidth,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Obx(() {
            final isUploading = widget.controller.isUploadingExcel.value;
            final isProcessing = widget.controller.isProcessingServer.value;
            final isSuccess = widget.controller.isUploadSuccess.value;
            final error = widget.controller.uploadError.value;
            final progress = widget.controller.uploadProgress.value;
            final uploadedBytes = widget.controller.uploadedBytes.value;
            final totalBytes = widget.controller.totalUploadBytes.value;
            final importedCount = widget.controller.importedCount.value;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(isDark, canDismiss: !isUploading && !isProcessing),
                  const SizedBox(height: 20),
                  if (error != null)
                    _buildErrorState(context, isDark, error)
                  else if (isSuccess)
                    _buildSuccessState(context, isDark, importedCount)
                  else if (isProcessing)
                    _buildProcessingState(context, isDark, totalBytes)
                  else
                    _buildUploadingState(context, isDark, progress, uploadedBytes, totalBytes),
                ],
              ),
            );
          }),
        ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader(bool isDark, {required bool canDismiss}) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            PhosphorIconsRegular.fileXls,
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
                'Excel Cattle Import',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Destination: ${widget.controller.activeGaushalaName}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (canDismiss)
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppColors.textSecondaryLight,
            splashRadius: 18,
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. UPLOADING STATE (Live Bytes Progress + Animation)
  // ---------------------------------------------------------------------------
  Widget _buildUploadingState(
    BuildContext context,
    bool isDark,
    double progress,
    int uploadedBytes,
    int totalBytes,
  ) {
    final percentInt = (progress * 100).toInt().clamp(0, 100);
    final uploadedStr = widget.controller.formatBytes(uploadedBytes);
    final totalStr = widget.controller.formatBytes(totalBytes > 0 ? totalBytes : widget.fileBytes.length);

    return Column(
      children: [
        // File badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E261D) : const Color(0xFFF3F7F0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(PhosphorIconsRegular.paperclip, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.fileName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                totalStr,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Animated Uploading Graphic
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -6 * _pulseAnimation.value),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1 + (0.1 * _pulseAnimation.value)),
                ),
                child: const Icon(
                  PhosphorIconsRegular.cloudArrowUp,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        Text(
          'Uploading Spreadsheet...',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sending cattle records file to server ($uploadedStr of $totalStr)',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Animated Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Stack(
              children: [
                Container(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
                FractionallySizedBox(
                  widthFactor: progress > 0.02 ? progress : 0.02,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, Color(0xFF6B8E23)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Percentage & Bytes count row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$percentInt% Completed',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              '$uploadedStr / $totalStr',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. SERVER PROCESSING STATE
  // ---------------------------------------------------------------------------
  Widget _buildProcessingState(BuildContext context, bool isDark, int totalBytes) {
    final totalStr = widget.controller.formatBytes(totalBytes > 0 ? totalBytes : widget.fileBytes.length);

    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2E7D32).withValues(alpha: 0.12 + (0.1 * _pulseAnimation.value)),
              ),
              child: const Center(
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        Text(
          'Processing & Importing Records...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The server received $totalStr and is verifying cattle tags, lineages, and writing records to the database.',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryLight,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E261D) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text(
                '100% Uploaded • Awaiting database confirmation...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. SUCCESS STATE (Animated badge + Records count)
  // ---------------------------------------------------------------------------
  Widget _buildSuccessState(BuildContext context, bool isDark, int importedCount) {
    final totalStr = widget.controller.formatBytes(widget.controller.totalUploadBytes.value);
    final countLabel = importedCount > 0 ? '$importedCount Cattle Added' : 'Cattle Records Imported';

    return Column(
      children: [
        // Scale animated check circle
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF2E7D32),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),

        Text(
          'Import Successful!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 6),

        // Prominent imported count badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(PhosphorIconsRegular.cow, size: 18, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Text(
                countLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Summary details box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E261D) : const Color(0xFFF9FAF8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildSummaryRow(
                icon: PhosphorIconsRegular.fileXls,
                label: 'File Name',
                value: widget.fileName,
                isDark: isDark,
              ),
              const Divider(height: 14),
              _buildSummaryRow(
                icon: PhosphorIconsRegular.arrowUpRight,
                label: 'Uploaded Size',
                value: totalStr,
                isDark: isDark,
              ),
              const Divider(height: 14),
              _buildSummaryRow(
                icon: PhosphorIconsRegular.buildings,
                label: 'Gaushala',
                value: widget.controller.activeGaushalaName,
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        CustomButton(
          text: 'Done & View Herd',
          icon: Icons.check_circle_outline_rounded,
          width: double.infinity,
          height: 44,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondaryLight),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. ERROR STATE
  // ---------------------------------------------------------------------------
  Widget _buildErrorState(BuildContext context, bool isDark, String errorMessage) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error.withValues(alpha: 0.12),
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 34,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Import Failed',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: Text(
            errorMessage,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.error,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Cancel',
                variant: ButtonVariant.outlined,
                height: 42,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Retry',
                icon: Icons.refresh_rounded,
                height: 42,
                onPressed: () {
                  widget.controller.executeUploadExcel(
                    fileBytes: widget.fileBytes,
                    fileName: widget.fileName,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
