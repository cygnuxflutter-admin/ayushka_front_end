import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_constants.dart';
import '../../../core/widgets/logout_confirmation_dialog.dart';
import '../../../data/models/user_model.dart';
import '../../../routes/app_routes.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Navigation Drawer for mobile and tablet devices in Cattle Management.
class MobileDrawer extends StatelessWidget {
  final UserModel? currentUser;
  final VoidCallback onLogout;

  const MobileDrawer({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = Get.currentRoute;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.primaryDark,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      AppConstants.logoIconPath,
                      height: 42,
                      width: 42,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppConstants.appName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentUser?.email ?? 'admin@ayushka.com',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                children: [
                  _DrawerItem(
                    icon: PhosphorIconsRegular.squaresFour,
                    label: 'Farm Overview',
                    isSelected: currentRoute == AppRoutes.dashboard,
                    onTap: () {
                      Get.back();
                      if (currentRoute != AppRoutes.dashboard) {
                        Get.offNamed(AppRoutes.dashboard);
                      }
                    },
                  ),
                  _DrawerItem(
                    icon: PhosphorIconsRegular.cow,
                    label: 'Herd & Cattle',
                    isSelected: currentRoute == AppRoutes.cows || currentRoute == AppRoutes.addCow,
                    onTap: () {
                      Get.back();
                      if (currentRoute != AppRoutes.cows) {
                        Get.offNamed(AppRoutes.cows);
                      }
                    },
                  ),

                  _DrawerItem(
                    icon: PhosphorIconsRegular.drop,
                    label: 'Milk Production',
                    isSelected: false,
                    onTap: () {
                      Get.back();
                      Get.snackbar('Milk Records', 'Daily yield logging.', maxWidth: 400);
                    },
                  ),
                  _DrawerItem(
                    icon: PhosphorIconsRegular.heartbeat,
                    label: 'Health & Breeding',
                    isSelected: false,
                    onTap: () {
                      Get.back();
                      Get.snackbar('Health', 'Vaccination and medical records.', maxWidth: 400);
                    },
                  ),
                  const Divider(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Text(
                      'MASTERS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ),
                  _DrawerItem(
                    icon: PhosphorIconsRegular.shieldCheck,
                    label: 'Roles',
                    isSelected: currentRoute == AppRoutes.roles,
                    onTap: () {
                      Get.back();
                      if (currentRoute != AppRoutes.roles) {
                        Get.offNamed(AppRoutes.roles);
                      }
                    },
                  ),
                  _DrawerItem(
                    icon: PhosphorIconsRegular.users,
                    label: 'Users',
                    isSelected: currentRoute == AppRoutes.users,
                    onTap: () {
                      Get.back();
                      if (currentRoute != AppRoutes.users) {
                        Get.offNamed(AppRoutes.users);
                      }
                    },
                  ),
                  _DrawerItem(
                    icon: PhosphorIconsRegular.barn,
                    label: 'Gaushalas',
                    isSelected: currentRoute == AppRoutes.gaushalas,
                    onTap: () {
                      Get.back();
                      if (currentRoute != AppRoutes.gaushalas) {
                        Get.offNamed(AppRoutes.gaushalas);
                      }
                    },
                  ),
                  _DrawerItem(
                    icon: PhosphorIconsRegular.warehouse,
                    label: 'Sheds',
                    isSelected: currentRoute == AppRoutes.sheds,
                    onTap: () {
                      Get.back();
                      if (currentRoute != AppRoutes.sheds) {
                        Get.offNamed(AppRoutes.sheds);
                      }
                    },
                  ),
                  _DrawerItem(
                    icon: PhosphorIconsRegular.dna,
                    label: 'Breeds',
                    isSelected: currentRoute == AppRoutes.breeds,
                    onTap: () {
                      Get.back();
                      if (currentRoute != AppRoutes.breeds) {
                        Get.offNamed(AppRoutes.breeds);
                      }
                    },
                  ),
                  _DrawerItem(
                    icon: PhosphorIconsRegular.tag,
                    label: 'Types',
                    isSelected: currentRoute == AppRoutes.types,
                    onTap: () {
                      Get.back();
                      if (currentRoute != AppRoutes.types) {
                        Get.offNamed(AppRoutes.types);
                      }
                    },
                  ),
                  const Divider(height: 20),
                  _DrawerItem(
                    icon: PhosphorIconsRegular.slidersHorizontal,
                    label: 'Farm Settings',
                    isSelected: false,
                    onTap: () {
                      Get.back();
                      Get.snackbar('Settings', 'Farm configuration parameters.', maxWidth: 400);
                    },
                  ),
                ],
              ),
            ),

            // Logout Option
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tileColor: AppColors.errorBg,
                onTap: () {
                  Get.back();
                  LogoutConfirmationDialog.show(
                    Get.context ?? context,
                    currentUser: currentUser,
                    onConfirm: onLogout,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
