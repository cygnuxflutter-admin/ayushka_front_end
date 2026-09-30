import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../values/app_colors.dart';
import '../values/app_constants.dart';
import '../../data/models/user_model.dart';
import 'custom_button.dart';

/// A beautifully styled, modern confirmation dialog for user sign out.
/// Designed specifically for the Ayushka admin portal theme with light and dark mode support.
class LogoutConfirmationDialog extends StatelessWidget {
  final UserModel? currentUser;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const LogoutConfirmationDialog({
    super.key,
    required this.onConfirm,
    this.currentUser,
    this.onCancel,
  });

  /// Displays the sign out confirmation dialog with a smooth scale and fade transition.
  static Future<bool?> show(
    BuildContext context, {
    required VoidCallback onConfirm,
    UserModel? currentUser,
    VoidCallback? onCancel,
  }) {
    final effectiveContext = context.mounted ? context : (Get.overlayContext ?? Get.context);
    if (effectiveContext == null) {
      onConfirm();
      return Future.value(true);
    }

    return showGeneralDialog<bool>(
      context: effectiveContext,
      barrierDismissible: true,
      barrierLabel: 'Sign Out Confirmation',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 240),
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curvedValue = Curves.easeOutCubic.transform(animation.value);
        return Transform.scale(
          scale: 0.90 + (curvedValue * 0.10),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return LogoutConfirmationDialog(
          currentUser: currentUser,
          onConfirm: onConfirm,
          onCancel: onCancel,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final user = currentUser;
    final String initialLetter = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim().substring(0, 1).toUpperCase()
        : 'A';
    final String displayName = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim()
        : 'Ayushka Admin';
    final String roleName = (user?.role.trim().isNotEmpty ?? false)
        ? user!.role.trim()
        : 'Admin';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      elevation: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFE2EAD9),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                  blurRadius: 32,
                  spreadRadius: 0,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top-right close button
                Positioned(
                  top: 14,
                  right: 14,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      hoverColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                      onTap: () {
                        Navigator.of(context).pop(false);
                        onCancel?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ),
                  ),
                ),

                // Main Dialog Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Prominent Glowing Logout Icon
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error.withValues(alpha: 0.08),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.18),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.error.withValues(alpha: 0.14),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: AppColors.error,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Dialog Title
                      Text(
                        'Sign Out Confirmation',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Dialog Description
                      Text(
                        'Are you sure you want to sign out? You will need to log back in to access the Ayushka admin portal.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Current User Mini Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF162316) : const Color(0xFFF3F6F1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF263826) : const Color(0xFFDFE7DA),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 19,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                initialLetter,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.verified_user_rounded,
                                        size: 12,
                                        color: Color(0xFF5A7542),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          roleName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF5A7542),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Warning / notice chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2B2215)
                              : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF4D3B1C)
                                : const Color(0xFFFDE68A),
                            width: 0.9,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 15,
                              color: isDark
                                  ? const Color(0xFFFBBF24)
                                  : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Make sure all pending changes are saved before proceeding.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? const Color(0xFFFBBF24)
                                      : const Color(0xFFB45309),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons (Cancel & Sign Out)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                side: BorderSide(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.defaultBorderRadius,
                                  ),
                                ),
                                foregroundColor: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop(false);
                                onCancel?.call();
                              },
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: 'Sign Out',
                              icon: Icons.logout_rounded,
                              variant: ButtonVariant.danger,
                              height: 44,
                              onPressed: () {
                                Navigator.of(context).pop(true);
                                onConfirm();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
