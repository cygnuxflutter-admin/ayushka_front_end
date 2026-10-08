import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_constants.dart';
import '../../../core/values/permission_constants.dart';
import '../../../core/widgets/logout_confirmation_dialog.dart';
import '../../../data/models/gaushala_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/gaushala_session_service.dart';
import '../../../data/services/permission_service.dart';
import '../../../routes/app_routes.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Modern, executive Navigation Drawer for mobile and tablet devices in Ayushka Cattle Management.
/// Features user profile card, active Gaushala station switcher, dark mode toggle, and refined navigation.
class MobileDrawer extends StatelessWidget {
  final UserModel? currentUser;
  final VoidCallback onLogout;

  const MobileDrawer({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  void _showGaushalaPicker(BuildContext context) {
    if (!Get.isRegistered<GaushalaSessionService>()) return;
    final gaushalaService = Get.find<GaushalaSessionService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle pill
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(PhosphorIconsRegular.barn, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Switch Gaushala Station',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: Obx(() {
                  final list = gaushalaService.gaushalas.toList();
                  final selectedId = gaushalaService.selectedGaushalaId;

                  if (list.isEmpty) {
                    return const Center(child: Text('No gaushalas available.'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: list.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final GaushalaModel g = list[index];
                      final isSelected = g.id == selectedId || g.gaushalaName == gaushalaService.selectedGaushalaName;

                      return InkWell(
                        onTap: () {
                          gaushalaService.setGaushala(g);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : (isDark ? AppColors.cardDark : const Color(0xFFF9FAF7)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                                child: Icon(
                                  PhosphorIconsRegular.buildings,
                                  size: 18,
                                  color: isSelected ? Colors.white : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      g.gaushalaName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.primary
                                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'ID: ${g.id}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = Get.currentRoute;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final gaushalaService = Get.isRegistered<GaushalaSessionService>()
        ? Get.find<GaushalaSessionService>()
        : null;

    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: SafeArea(
        child: Column(
          children: [
            // ---------------------------------------------------------
            // DRAWER HEADER (Brand + User Profile + Active Gaushala)
            // ---------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF223617),
                    Color(0xFF162514),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          AppConstants.logoIconPath,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppConstants.appName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF86EFAC),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Expanded(
                                  child: Text(
                                    'CATTLE & DAIRY PORTAL',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Color(0xFF86EFAC),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6,
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
                  const SizedBox(height: 16),

                  // User Info Card inside Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            currentUser?.name.isNotEmpty == true
                                ? currentUser!.name.substring(0, 1).toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUser?.name ?? 'Farm Manager',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
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

                  // Active Gaushala Pill
                  if (gaushalaService != null) ...[
                    const SizedBox(height: 10),
                    Obx(() {
                      final stationName = gaushalaService.selectedGaushalaName;
                      final canChange = gaushalaService.canChangeGaushala;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF132011),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2E4624)),
                        ),
                        child: Row(
                          children: [
                            const Icon(PhosphorIconsRegular.barn, color: Color(0xFF86EFAC), size: 15),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                stationName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFD4E2CA),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (canChange)
                              InkWell(
                                onTap: () => _showGaushalaPicker(context),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Switch',
                                    style: TextStyle(
                                      color: Color(0xFF86EFAC),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const Tooltip(
                                message: 'Gaushala locked to your account',
                                child: Icon(
                                  PhosphorIconsRegular.lockSimple,
                                  size: 14,
                                  color: Color(0xFF86EFAC),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),

            // ---------------------------------------------------------
            // NAVIGATION ITEMS
            // ---------------------------------------------------------
            Expanded(
              child: Builder(
                builder: (context) {
                  final perm = Get.isRegistered<PermissionService>()
                      ? Get.find<PermissionService>()
                      : null;

                  Widget buildNavItems() {
                    final bool isAdminUser = perm != null
                        ? perm.isAdmin
                        : (currentUser == null || currentUser!.isAdmin);
                    bool hasAccess(String m, String s) =>
                        isAdminUser || (perm != null && perm.hasMenuAccess(m, s));
                    bool hasAnyAccess(String m, List<String> subs) =>
                        isAdminUser || (perm != null && perm.hasAnyMenuAccess(m, subs));
                    bool isModVisible(String m) =>
                        isAdminUser || (perm != null && perm.isModuleVisible(m));

                    final bool hasRoleMaster = isModVisible(PermissionModules.role) &&
                        hasAccess(PermissionModules.role, PermissionSubModules.roleList);
                    final bool hasUserMaster = isModVisible(PermissionModules.user) &&
                        hasAccess(PermissionModules.user, PermissionSubModules.userList);
                    final bool hasWorkerMaster = isModVisible(PermissionModules.workerMgmt) &&
                        hasAnyAccess(PermissionModules.workerMgmt, [
                          PermissionSubModules.workerList,
                          PermissionSubModules.departmentList,
                        ]);
                    final bool hasGaushalaMaster = isModVisible(PermissionModules.gaushala) &&
                        hasAccess(PermissionModules.gaushala, PermissionSubModules.gaushalaList);
                    final bool hasShedMaster = isModVisible(PermissionModules.shed) &&
                        hasAnyAccess(PermissionModules.shed, [
                          PermissionSubModules.shedList,
                          PermissionSubModules.shedTransfer,
                        ]);
                    final bool hasBreedMaster = isModVisible(PermissionModules.breedType) &&
                        hasAccess(PermissionModules.breedType, PermissionSubModules.breedTypeList);
                    final bool hasTypeMaster = isModVisible(PermissionModules.type) &&
                        hasAccess(PermissionModules.type, PermissionSubModules.typeList);
                    final bool hasFeedMaster = isModVisible(PermissionModules.feedStock) &&
                        hasAccess(PermissionModules.feedStock, PermissionSubModules.feedItems);

                    final bool hasAnyMaster = hasRoleMaster ||
                        hasUserMaster ||
                        hasWorkerMaster ||
                        hasGaushalaMaster ||
                        hasShedMaster ||
                        hasBreedMaster ||
                        hasTypeMaster ||
                        hasFeedMaster;

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                    if (isModVisible(PermissionModules.cow) &&
                        hasAnyAccess(PermissionModules.cow, [
                          PermissionSubModules.cowList,
                          PermissionSubModules.shedTransfer,
                        ]))
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
                    if (isModVisible(PermissionModules.milkMgmt) &&
                        hasAnyAccess(PermissionModules.milkMgmt, [
                          PermissionSubModules.milkProduction,
                          PermissionSubModules.milkDistribution,
                        ]))
                      _DrawerItem(
                        icon: PhosphorIconsRegular.drop,
                        label: 'Milk Production',
                        isSelected: currentRoute == AppRoutes.milk,
                        onTap: () {
                          Get.back();
                          if (currentRoute != AppRoutes.milk) {
                            Get.offNamed(AppRoutes.milk);
                          }
                        },
                      ),
                    if (isModVisible(PermissionModules.treatment) &&
                        hasAnyAccess(PermissionModules.treatment, [
                          PermissionSubModules.treatmentList,
                          PermissionSubModules.doseSchedule,
                        ]))
                      _DrawerItem(
                        icon: PhosphorIconsRegular.firstAid,
                        label: 'Cow Treatments',
                        isSelected: currentRoute == AppRoutes.treatments || currentRoute == AppRoutes.treatmentDetails,
                        onTap: () {
                          Get.back();
                          if (currentRoute != AppRoutes.treatments) {
                            Get.offNamed(AppRoutes.treatments);
                          }
                        },
                      ),
                    if (isModVisible(PermissionModules.medicalStock) &&
                        hasAnyAccess(PermissionModules.medicalStock, [
                          PermissionSubModules.medicalItems,
                          PermissionSubModules.stockTransaction,
                        ]))
                      _DrawerItem(
                        icon: PhosphorIconsRegular.firstAidKit,
                        label: 'Medical Stock',
                        isSelected: currentRoute == AppRoutes.medicalStock,
                        onTap: () {
                          Get.back();
                          if (currentRoute != AppRoutes.medicalStock) {
                            Get.offNamed(AppRoutes.medicalStock);
                          }
                        },
                      ),
                    if (isModVisible(PermissionModules.feedStock) &&
                        hasAccess(PermissionModules.feedStock, PermissionSubModules.stockTransaction))
                      _DrawerItem(
                        icon: PhosphorIconsRegular.arrowsLeftRight,
                        label: 'Stock Transactions',
                        isSelected: currentRoute == AppRoutes.feedTransactions,
                        onTap: () {
                          Get.back();
                          if (currentRoute != AppRoutes.feedTransactions) {
                            Get.offNamed(AppRoutes.feedTransactions);
                          }
                        },
                      ),
                    if (isAdminUser ||
                        (isModVisible(PermissionModules.treatment) &&
                            hasAccess(PermissionModules.treatment, PermissionSubModules.treatmentList)))
                      _DrawerItem(
                        icon: PhosphorIconsRegular.heartbeat,
                        label: 'Health & Breeding',
                        isSelected: false,
                        onTap: () {
                          Get.back();
                          Get.snackbar('Health Records', 'Vaccination and medical records station.', maxWidth: 400);
                        },
                      ),
                    // Section 2: Master Catalogs (Admin & Super Admin only)
                    if (isAdminUser && hasAnyMaster) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 16, bottom: 6),
                        child: Text(
                          'MASTER CATALOGS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                      if (hasRoleMaster)
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
                      if (hasUserMaster)
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
                      if (hasWorkerMaster)
                        _DrawerItem(
                          icon: PhosphorIconsRegular.identificationCard,
                          label: 'Workers & Staff',
                          isSelected: currentRoute == AppRoutes.workers || currentRoute == AppRoutes.departments,
                          onTap: () {
                            Get.back();
                            if (currentRoute != AppRoutes.workers) {
                              Get.offNamed(AppRoutes.workers);
                            }
                          },
                        ),
                      if (hasGaushalaMaster)
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
                      if (hasShedMaster)
                        _DrawerItem(
                          icon: PhosphorIconsRegular.warehouse,
                          label: 'Barn Sheds',
                          isSelected: currentRoute == AppRoutes.sheds,
                          onTap: () {
                            Get.back();
                            if (currentRoute != AppRoutes.sheds) {
                              Get.offNamed(AppRoutes.sheds);
                            }
                          },
                        ),
                      if (hasBreedMaster)
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
                      if (hasTypeMaster)
                        _DrawerItem(
                          icon: PhosphorIconsRegular.tag,
                          label: 'Cattle Types',
                          isSelected: currentRoute == AppRoutes.types,
                          onTap: () {
                            Get.back();
                            if (currentRoute != AppRoutes.types) {
                              Get.offNamed(AppRoutes.types);
                            }
                          },
                        ),
                      if (hasFeedMaster)
                        _DrawerItem(
                          icon: PhosphorIconsRegular.grains,
                          label: 'Feed Items',
                          isSelected: currentRoute == AppRoutes.feedItems,
                          onTap: () {
                            Get.back();
                            if (currentRoute != AppRoutes.feedItems) {
                              Get.offNamed(AppRoutes.feedItems);
                            }
                          },
                        ),
                    ],
                  ],
                );
              }

                if (perm == null) {
                  return buildNavItems();
                }
                return Obx(() {
                  perm.rxPermissions.length;
                  perm.rxIsAdmin.value;
                  perm.rxIsLoading.value;
                  perm.rxVersion.value;
                  return buildNavItems();
                });
              },
            ),
          ),

            // ---------------------------------------------------------
            // SIGN OUT & FOOTER
            // ---------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 0.8,
                  ),
                ),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      Get.back();
                      LogoutConfirmationDialog.show(
                        Get.context ?? context,
                        currentUser: currentUser,
                        onConfirm: onLogout,
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2026 Ayushka • Organic Living',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
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
        color: isSelected
            ? AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(
                color: AppColors.primary.withValues(alpha: isDark ? 0.40 : 0.25),
                width: 1.0,
              )
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
