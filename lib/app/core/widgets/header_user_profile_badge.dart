import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/services/storage_service.dart';
import '../values/app_colors.dart';

/// Standard, reusable User Profile Badge Pill displayed in the top header
/// across all modules and master screens.
class HeaderUserProfileBadge extends StatelessWidget {
  final UserModel? user;

  const HeaderUserProfileBadge({
    super.key,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve user from property or global storage service
    final resolvedUser = user ??
        (Get.isRegistered<StorageService>()
            ? Get.find<StorageService>().getUser()
            : null);

    final rawName = resolvedUser?.name.trim() ?? '';
    final rawUsername = resolvedUser?.username?.trim() ?? '';

    final String displayName = rawName.isNotEmpty
        ? rawName
        : (rawUsername.isNotEmpty ? rawUsername : 'Ayushka Admin');

    final String initial =
        displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'A';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: AppColors.primary,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            displayName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
