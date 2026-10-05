import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../values/app_colors.dart';
import '../values/app_constants.dart';

/// Cross-platform adaptive snackbars with restrained widths on Desktop/Web.
class CustomSnackbar {
  CustomSnackbar._();

  static void showSuccess({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      title: title,
      message: message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_outline_rounded,
      duration: duration,
    );
  }

  static void showError({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      title: title,
      message: message,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline_rounded,
      duration: duration,
    );
  }

  static void showWarning({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      title: title,
      message: message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning_amber_rounded,
      duration: duration,
    );
  }

  static void showInfo({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      title: title,
      message: message,
      backgroundColor: AppColors.info,
      icon: Icons.info_outline_rounded,
      duration: duration,
    );
  }

  static void _show({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    // Adapt width so desktop/web widescreen doesn't stretch 2000px
    final double screenWidth = Get.width;
    final double? maxWidth = screenWidth > AppConstants.mobileBreakpoint ? 420 : null;

    Get.rawSnackbar(
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
      ),
      icon: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      backgroundColor: backgroundColor,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: AppConstants.defaultBorderRadius,
      duration: duration,
      maxWidth: maxWidth,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
      animationDuration: AppConstants.animationMedium,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }
}
