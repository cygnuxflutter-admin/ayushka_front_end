import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_constants.dart';
import '../../../core/values/permission_constants.dart';
import '../../../core/widgets/logout_confirmation_dialog.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/permission_service.dart';
import '../../../routes/app_routes.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Executive Web & Desktop Sidebar navigation for Ayushka Cattle Management Portal.
/// Features smooth hover auto-open for Master submenus, luxury organic palette,
/// and responsive collapse mechanics.
class WebSidebar extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;
  final UserModel? currentUser;
  final VoidCallback onLogout;

  const WebSidebar({
    super.key,
    required this.isCollapsed,
    required this.onToggle,
    required this.currentUser,
    required this.onLogout,
  });

  void _confirmSignOut(BuildContext context) {
    LogoutConfirmationDialog.show(
      context,
      currentUser: currentUser,
      onConfirm: onLogout,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = Get.currentRoute;

    return AnimatedContainer(
      duration: AppConstants.animationMedium,
      width: isCollapsed
          ? AppConstants.desktopSidebarCollapsedWidth
          : AppConstants.desktopSidebarWidth,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF162514), // Deep organic forest pine
            Color(0xFF0F1A0D), // Midnight emerald
          ],
        ),
        border: Border(
          right: BorderSide(color: Color(0xFF263A1D), width: 1.0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool collapsed = constraints.maxWidth < 180;

          return Column(
            children: [
              // -------------------------------------------------------------
              // Brand Logo & Sidebar Toggle Header
              // -------------------------------------------------------------
              Container(
                height: 74,
                padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 16),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF22351B), width: 0.8),
                  ),
                ),
                child: collapsed
                    ? Center(
                        child: Tooltip(
                          message: 'Expand Sidebar',
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: InkWell(
                              mouseCursor: SystemMouseCursors.click,
                              onTap: onToggle,
                              borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 44,
                              width: 44,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Center(
                                    child: Image.asset(
                                      AppConstants.logoIconPath,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                    ),
                                  ),
                                  Positioned(
                                    right: -4,
                                    bottom: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
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
                                        color: Colors.black.withValues(alpha: 0.16),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
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
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'ayushka',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            width: 5,
                                            height: 5,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF86EFAC),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          const Expanded(
                                            child: Text(
                                              'ORGANIC DAIRY',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF86EFAC),
                                                letterSpacing: 0.8,
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
                          // Collapse / Expand Toggle Button
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: InkWell(
                              onTap: onToggle,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22351B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.chevron_left_rounded,
                                  color: Color(0xFFC5D7BC),
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

              // -------------------------------------------------------------
              // Navigation Menu Links (with Section Dividers)
              // -------------------------------------------------------------
              Expanded(
                child: Builder(
                  builder: (context) {
                    final perm = Get.isRegistered<PermissionService>()
                        ? Get.find<PermissionService>()
                        : null;

                    Widget buildNavItems() {
                      bool canView(String m, String s) => perm?.canView(m, s) ?? true;
                      bool isModuleVisible(String m) => perm?.isModuleVisible(m) ?? true;
                      final bool isSuperAdmin = perm?.isSuperAdmin ?? (currentUser?.isSuperAdmin ?? false);

                  // Evaluate visible master sub-items
                  final List<_SidebarSubNavItem> masterItems = [];
                  if (isSuperAdmin && canView(PermissionModules.role, PermissionSubModules.roleList)) {
                    masterItems.add(
                      _SidebarSubNavItem(
                        icon: PhosphorIconsRegular.shieldCheck,
                        label: 'Roles',
                        isSelected: currentRoute == AppRoutes.roles,
                        onTap: () {
                          if (currentRoute != AppRoutes.roles) {
                            Get.offNamed(AppRoutes.roles);
                          }
                        },
                      ),
                    );
                  }
                  final bool isAdmin = perm?.isAdmin ?? (currentUser?.isAdmin ?? false);
                  if (isAdmin) {
                    masterItems.add(
                      _SidebarSubNavItem(
                        icon: PhosphorIconsRegular.squaresFour,
                        label: 'Modules',
                        isSelected: currentRoute == AppRoutes.moduleManagement,
                        onTap: () {
                          if (currentRoute != AppRoutes.moduleManagement) {
                            Get.offNamed(AppRoutes.moduleManagement);
                          }
                        },
                      ),
                    );
                  }
                  if (canView(PermissionModules.user, PermissionSubModules.userList)) {
                    masterItems.add(
                      _SidebarSubNavItem(
                        icon: PhosphorIconsRegular.users,
                        label: 'Users',
                        isSelected: currentRoute == AppRoutes.users,
                        onTap: () {
                          if (currentRoute != AppRoutes.users) {
                            Get.offNamed(AppRoutes.users);
                          }
                        },
                      ),
                    );
                  }
                  if (canView(PermissionModules.workerMgmt, PermissionSubModules.workerList) ||
                      canView(PermissionModules.workerMgmt, PermissionSubModules.departmentList)) {
                    masterItems.add(
                      _SidebarSubNavItem(
                        icon: PhosphorIconsRegular.identificationCard,
                        label: 'Workers',
                        isSelected: currentRoute == AppRoutes.workers || currentRoute == AppRoutes.departments,
                        onTap: () {
                          if (currentRoute != AppRoutes.workers) {
                            Get.offNamed(AppRoutes.workers);
                          }
                        },
                      ),
                    );
                  }
                  if (isSuperAdmin && canView(PermissionModules.gaushala, PermissionSubModules.gaushalaList)) {
                    masterItems.add(
                      _SidebarSubNavItem(
                        icon: PhosphorIconsRegular.barn,
                        label: 'Gaushalas',
                        isSelected: currentRoute == AppRoutes.gaushalas,
                        onTap: () {
                          if (currentRoute != AppRoutes.gaushalas) {
                            Get.offNamed(AppRoutes.gaushalas);
                          }
                        },
                      ),
                    );
                  }
                  if (canView(PermissionModules.shed, PermissionSubModules.shedList) ||
                      canView(PermissionModules.shed, PermissionSubModules.shedTransfer)) {
                    masterItems.add(
                      _SidebarSubNavItem(
                        icon: PhosphorIconsRegular.warehouse,
                        label: 'Sheds',
                        isSelected: currentRoute == AppRoutes.sheds,
                        onTap: () {
                          if (currentRoute != AppRoutes.sheds) {
                            Get.offNamed(AppRoutes.sheds);
                          }
                        },
                      ),
                    );
                  }
                  if (isSuperAdmin && canView(PermissionModules.breedType, PermissionSubModules.breedTypeList)) {
                    masterItems.add(
                      _SidebarSubNavItem(
                        icon: PhosphorIconsRegular.dna,
                        label: 'Breeds',
                        isSelected: currentRoute == AppRoutes.breeds,
                        onTap: () {
                          if (currentRoute != AppRoutes.breeds) {
                            Get.offNamed(AppRoutes.breeds);
                          }
                        },
                      ),
                    );
                  }
                  if (canView(PermissionModules.type, PermissionSubModules.typeList)) {
                    masterItems.add(
                      _SidebarSubNavItem(
                        icon: PhosphorIconsRegular.tag,
                        label: 'Types',
                        isSelected: currentRoute == AppRoutes.types,
                        onTap: () {
                          if (currentRoute != AppRoutes.types) {
                            Get.offNamed(AppRoutes.types);
                          }
                        },
                      ),
                    );
                  }
                  if (canView(PermissionModules.feedStock, PermissionSubModules.feedItems)) {
                    masterItems.add(
                      _SidebarSubNavItem(
                        icon: PhosphorIconsRegular.grains,
                        label: 'Feed Items',
                        isSelected: currentRoute == AppRoutes.feedItems,
                        onTap: () {
                          if (currentRoute != AppRoutes.feedItems) {
                            Get.offNamed(AppRoutes.feedItems);
                          }
                        },
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    children: [
                      // Section 1: Overview
                      _SectionHeader(title: 'MAIN MENU', isCollapsed: collapsed),
                      _SidebarNavItem(
                        icon: PhosphorIconsRegular.squaresFour,
                        label: 'Farm Overview',
                        isSelected: currentRoute == AppRoutes.dashboard,
                        isCollapsed: collapsed,
                        onTap: () {
                          if (currentRoute != AppRoutes.dashboard) {
                            Get.offNamed(AppRoutes.dashboard);
                          }
                        },
                      ),
                      if (isModuleVisible(PermissionModules.cow) &&
                          canView(PermissionModules.cow, PermissionSubModules.cowList)) ...[
                        const SizedBox(height: 3),
                        _SidebarNavItem(
                          icon: PhosphorIconsRegular.cow,
                          label: 'Herd & Cattle',
                          isSelected: currentRoute == AppRoutes.cows || currentRoute == AppRoutes.addCow,
                          isCollapsed: collapsed,
                          onTap: () {
                            if (currentRoute != AppRoutes.cows) {
                              Get.offNamed(AppRoutes.cows);
                            }
                          },
                        ),
                      ],
                      if (isModuleVisible(PermissionModules.feedStock) &&
                          canView(PermissionModules.feedStock, PermissionSubModules.stockTransaction)) ...[
                        const SizedBox(height: 3),
                        _SidebarNavItem(
                          icon: PhosphorIconsRegular.arrowsLeftRight,
                          label: 'Stock Transactions',
                          isSelected: currentRoute == AppRoutes.feedTransactions,
                          isCollapsed: collapsed,
                          onTap: () {
                            if (currentRoute != AppRoutes.feedTransactions) {
                              Get.offNamed(AppRoutes.feedTransactions);
                            }
                          },
                        ),
                      ],
                      if (isModuleVisible(PermissionModules.medicalStock) &&
                          canView(PermissionModules.medicalStock, PermissionSubModules.medicalItems)) ...[
                        const SizedBox(height: 3),
                        _SidebarNavItem(
                          icon: PhosphorIconsRegular.firstAidKit,
                          label: 'Medical Stock',
                          isSelected: currentRoute == AppRoutes.medicalStock,
                          isCollapsed: collapsed,
                          badge: 'FEFO',
                          badgeColor: const Color(0xFF10B981),
                          onTap: () {
                            if (currentRoute != AppRoutes.medicalStock) {
                              Get.offNamed(AppRoutes.medicalStock);
                            }
                          },
                        ),
                      ],
                      if (isModuleVisible(PermissionModules.treatment) &&
                          canView(PermissionModules.treatment, PermissionSubModules.treatmentList)) ...[
                        const SizedBox(height: 3),
                        _SidebarNavItem(
                          icon: PhosphorIconsRegular.firstAid,
                          label: 'Cow Treatments',
                          isSelected: currentRoute == AppRoutes.treatments || currentRoute == AppRoutes.treatmentDetails,
                          isCollapsed: collapsed,
                          badge: 'DOSES',
                          badgeColor: const Color(0xFFE98324),
                          onTap: () {
                            if (currentRoute != AppRoutes.treatments) {
                              Get.offNamed(AppRoutes.treatments);
                            }
                          },
                        ),
                      ],
                      if (isModuleVisible(PermissionModules.milkMgmt) &&
                          (canView(PermissionModules.milkMgmt, PermissionSubModules.milkProduction) ||
                              canView(PermissionModules.milkMgmt, PermissionSubModules.milkDistribution))) ...[
                        const SizedBox(height: 3),
                        _SidebarNavItem(
                          icon: PhosphorIconsRegular.drop,
                          label: 'Milk Production',
                          isSelected: currentRoute == AppRoutes.milk,
                          isCollapsed: collapsed,
                          badge: 'LIVE',
                          badgeColor: const Color(0xFF5A7542),
                          onTap: () {
                            if (currentRoute != AppRoutes.milk) {
                              Get.offNamed(AppRoutes.milk);
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 3),
                      _SidebarNavItem(
                        icon: PhosphorIconsRegular.heartbeat,
                        label: 'Breeding & Health',
                        isSelected: false,
                        isCollapsed: collapsed,
                        onTap: () {
                          Get.snackbar(
                            'Health Records',
                            'Vaccination schedules and breeding cycles.',
                            maxWidth: 400,
                          );
                        },
                      ),

                      // Section 2: Masters (Expandable on hover)
                      if (masterItems.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _SectionHeader(title: 'MASTERS', isCollapsed: collapsed),
                        _SidebarExpandableGroup(
                          icon: PhosphorIconsRegular.stack,
                          label: 'Masters',
                          isCollapsed: collapsed,
                          isInitiallyExpanded: currentRoute == AppRoutes.roles ||
                              currentRoute == AppRoutes.moduleManagement ||
                              currentRoute == AppRoutes.users ||
                              currentRoute == AppRoutes.workers ||
                              currentRoute == AppRoutes.departments ||
                              currentRoute == AppRoutes.gaushalas ||
                              currentRoute == AppRoutes.sheds ||
                              currentRoute == AppRoutes.breeds ||
                              currentRoute == AppRoutes.types ||
                              currentRoute == AppRoutes.feedItems,
                          children: masterItems,
                        ),
                      ],

                      // Section 3: Preferences
                      const SizedBox(height: 10),
                      _SectionHeader(title: 'PREFERENCES', isCollapsed: collapsed),
                      _SidebarNavItem(
                        icon: PhosphorIconsRegular.slidersHorizontal,
                        label: 'Farm Settings',
                        isSelected: false,
                        isCollapsed: collapsed,
                        onTap: () {
                          Get.snackbar(
                            'Settings',
                            'Farm parameters and user permissions.',
                            maxWidth: 400,
                          );
                        },
                      ),
                    ],
                  );
                }

                  if (perm == null) {
                    return buildNavItems();
                  }
                  return Obx(() {
                    final _ = perm.permissions.length;
                    return buildNavItems();
                  });
                },
              ),
            ),

              // -------------------------------------------------------------
              // User Info & Logout Button (Styled Card)
              // -------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF22351B), width: 0.8),
                  ),
                ),
                child: collapsed
                    ? Center(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: IconButton(
                            icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                            tooltip: 'Sign Out',
                            onPressed: () => _confirmSignOut(context),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B2C17),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2A3D1E)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: AppColors.primary,
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
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    currentUser?.name ?? 'Ayushka Admin',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.verified_user_rounded,
                                        size: 11,
                                        color: Color(0xFF86EFAC),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          currentUser?.role ?? 'Admin',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF86EFAC),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                tooltip: 'Sign Out',
                                onPressed: () => _confirmSignOut(context),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SECTION DIVIDER HEADER
// -----------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isCollapsed;

  const _SectionHeader({required this.title, required this.isCollapsed});

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 22,
            child: Divider(color: Color(0xFF283C1F), height: 1),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      child: Row(
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Color(0xFF8BA677),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFF263A1D),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SIDEBAR STANDARD NAV ITEM
// -----------------------------------------------------------------------------
class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isSelected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          _isHovered && !active ? 3.0 : 0.0,
          0.0,
          0.0,
        ),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFF384C28), Color(0xFF2B3D1D)],
                )
              : null,
          color: active
              ? null
              : (_isHovered ? const Color(0xFF22341A) : Colors.transparent),
          borderRadius: BorderRadius.circular(11),
          border: active
              ? Border.all(color: const Color(0xFF5A7542).withValues(alpha: 0.5), width: 1)
              : Border.all(color: Colors.transparent, width: 1),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: widget.onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCollapsed ? 12 : 12,
                vertical: 10,
              ),
              child: widget.isCollapsed
                  ? Center(
                      child: Tooltip(
                        message: widget.label,
                        child: AnimatedScale(
                          scale: _isHovered || active ? 1.12 : 1.0,
                          duration: AppConstants.animationFast,
                          child: Icon(
                            widget.icon,
                            size: 20,
                            color: active
                                ? const Color(0xFF86EFAC)
                                : (_isHovered ? Colors.white : const Color(0xFF8BA677)),
                          ),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        if (active) ...[
                          Container(
                            width: 3.5,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFF86EFAC),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF86EFAC).withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ] else ...[
                          const SizedBox(width: 3.5 + 8),
                        ],
                        AnimatedScale(
                          scale: _isHovered || active ? 1.08 : 1.0,
                          duration: AppConstants.animationFast,
                          child: Icon(
                            widget.icon,
                            size: 19,
                            color: active
                                ? const Color(0xFF86EFAC)
                                : (_isHovered ? Colors.white : const Color(0xFF8BA677)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: active
                                  ? Colors.white
                                  : (_isHovered ? Colors.white : const Color(0xFFCADBC1)),
                              fontSize: 13,
                              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (widget.badge != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (widget.badgeColor ?? const Color(0xFFF59E0B)).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.badge!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: widget.badgeColor ?? const Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SIDEBAR EXPANDABLE GROUP (SMOOTH SLIDE & EXPANSION)
// -----------------------------------------------------------------------------
class _SidebarExpandableGroup extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isCollapsed;
  final bool isInitiallyExpanded;
  final List<_SidebarSubNavItem> children;

  const _SidebarExpandableGroup({
    required this.icon,
    required this.label,
    required this.isCollapsed,
    this.isInitiallyExpanded = false,
    required this.children,
  });

  @override
  State<_SidebarExpandableGroup> createState() => _SidebarExpandableGroupState();
}

class _SidebarExpandableGroupState extends State<_SidebarExpandableGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _rotateAnimation;

  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();
  Timer? _hideTimer;

  bool _isHovered = false;
  bool _isPinnedOpen = false;

  @override
  void initState() {
    super.initState();
    final bool initiallyOpen =
        widget.isInitiallyExpanded || widget.children.any((c) => c.isSelected);
    _isPinnedOpen = initiallyOpen;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: initiallyOpen ? 1.0 : 0.0,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.12, 1.0, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void didUpdateWidget(covariant _SidebarExpandableGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isCollapsed && _overlayController.isShowing) {
      _hideFlyoutImmediately();
    }
    if (widget.isCollapsed != oldWidget.isCollapsed && _overlayController.isShowing) {
      _hideFlyoutImmediately();
    }
    final anySelected = widget.children.any((c) => c.isSelected);
    if (anySelected || widget.isInitiallyExpanded) {
      _isPinnedOpen = true;
      if (!_animController.isCompleted && _animController.status != AnimationStatus.forward) {
        _animController.forward();
      }
    } else {
      _isPinnedOpen = false;
      if (!_isHovered && !_animController.isDismissed && _animController.status != AnimationStatus.reverse) {
        _animController.reverse();
      }
      if (_overlayController.isShowing) {
        _hideFlyoutImmediately();
      }
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
    _animController.dispose();
    super.dispose();
  }

  void _showFlyout() {
    _hideTimer?.cancel();
    if (!_overlayController.isShowing) {
      _overlayController.show();
    }
  }

  void _scheduleHideFlyout() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 220), () {
      if (mounted && _overlayController.isShowing) {
        _overlayController.hide();
      }
    });
  }

  void _hideFlyoutImmediately() {
    _hideTimer?.cancel();
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
  }

  void _toggleExpand() {
    setState(() {
      _isPinnedOpen = !_isPinnedOpen;
    });
    if (_isPinnedOpen) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  void _handleHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (!_isPinnedOpen && !widget.children.any((c) => c.isSelected)) {
      if (isHovered) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool anyChildSelected = widget.children.any((c) => c.isSelected);

    // Collapsed Mode: Hover Flyout Submenu
    if (widget.isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: CompositedTransformTarget(
          link: _layerLink,
          child: OverlayPortal(
            controller: _overlayController,
            overlayChildBuilder: (context) {
              return Align(
                alignment: Alignment.topLeft,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  targetAnchor: Alignment.topRight,
                  followerAnchor: Alignment.topLeft,
                  offset: const Offset(6, -8),
                  showWhenUnlinked: false,
                  child: TapRegion(
                    groupId: _layerLink,
                    onTapOutside: (_) => _hideFlyoutImmediately(),
                    child: MouseRegion(
                      onEnter: (_) => _showFlyout(),
                      onExit: (_) => _scheduleHideFlyout(),
                      child: Padding(
                        // Invisible bridge so moving across the gap stays within hit test
                        padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 140),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset((1 - value) * -6, 0),
                                child: child,
                              ),
                            );
                          },
                          child: Material(
                            color: Colors.transparent,
                            elevation: 12,
                            shadowColor: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 200,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF162514),
                                      Color(0xFF0F1A0D),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF263A1D), width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      blurRadius: 18,
                                      spreadRadius: 2,
                                      offset: const Offset(4, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Flyout Header
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      child: Row(
                                        children: [
                                          Icon(
                                            widget.icon,
                                            size: 15,
                                            color: const Color(0xFF86EFAC),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            widget.label.toUpperCase(),
                                            style: const TextStyle(
                                              color: Color(0xFFCADBC1),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(color: Color(0xFF263A1D), height: 1),
                                    const SizedBox(height: 4),

                                    // Submenu Items
                                    ...widget.children.map((child) {
                                      return _FlyoutSubMenuItem(
                                        icon: child.icon,
                                        label: child.label,
                                        isSelected: child.isSelected,
                                        onTap: () {
                                          _hideFlyoutImmediately();
                                          child.onTap();
                                        },
                                      );
                                    }),
                                    const SizedBox(height: 6),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: TapRegion(
              groupId: _layerLink,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => _showFlyout(),
                onExit: (_) => _scheduleHideFlyout(),
                child: InkWell(
                  mouseCursor: SystemMouseCursors.click,
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    if (_overlayController.isShowing) {
                      _hideFlyoutImmediately();
                    } else {
                      _showFlyout();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: anyChildSelected
                          ? const Color(0xFF384C28).withValues(alpha: 0.5)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        widget.icon,
                        size: 20,
                        color: anyChildSelected
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFF8BA677),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Expanded Mode: Smooth animated expandable group
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Parent Header Tile
          InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: _toggleExpand,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutCubic,
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: anyChildSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF384C28), Color(0xFF283A1B)],
                      )
                    : null,
                color: anyChildSelected
                    ? null
                    : (_isHovered ? const Color(0xFF22341A) : Colors.transparent),
                borderRadius: BorderRadius.circular(11),
                border: anyChildSelected
                    ? Border.all(color: const Color(0xFF5A7542).withValues(alpha: 0.5), width: 1)
                    : Border.all(color: Colors.transparent, width: 1),
              ),
              child: Row(
                children: [
                  if (anyChildSelected) ...[
                    Container(
                      width: 3.5,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF86EFAC),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    const SizedBox(width: 3.5 + 8),
                  ],
                  Icon(
                    widget.icon,
                    size: 19,
                    color: anyChildSelected
                        ? const Color(0xFF86EFAC)
                        : (_isHovered ? Colors.white : const Color(0xFF8BA677)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: anyChildSelected
                            ? Colors.white
                            : (_isHovered ? Colors.white : const Color(0xFFCADBC1)),
                        fontSize: 13,
                        fontWeight: anyChildSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _rotateAnimation,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: anyChildSelected
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFF8BA677),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Submenu Items with Tree Guide Line (Smooth SizeTransition + SlideTransition + FadeTransition)
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1.0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Vertical Tree Guide Line
                        Container(
                          width: 1.5,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF334A26),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: widget.children,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SIDEBAR SUB-NAV ITEM (e.g. Roles, Gaushalas)
// -----------------------------------------------------------------------------
class _SidebarSubNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarSubNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarSubNavItem> createState() => _SidebarSubNavItemState();
}

class _SidebarSubNavItemState extends State<_SidebarSubNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isSelected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 2.5),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFF384C28), Color(0xFF283A1B)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: active
              ? null
              : (_isHovered ? const Color(0xFF22351A) : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: active
              ? Border.all(
                  color: const Color(0xFF5A7542).withValues(alpha: 0.65),
                  width: 1,
                )
              : Border.all(
                  color: _isHovered
                      ? const Color(0xFF384C28).withValues(alpha: 0.4)
                      : Colors.transparent,
                  width: 1,
                ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 5,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            splashColor: const Color(0xFF86EFAC).withValues(alpha: 0.12),
            highlightColor: Colors.transparent,
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOutCubic,
                    width: active ? 3.0 : 0.0,
                    height: 16,
                    margin: EdgeInsets.only(right: active ? 8.0 : 0.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF86EFAC),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  AnimatedScale(
                    scale: active ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOutCubic,
                    child: Icon(
                      widget.icon,
                      size: 16,
                      color: active
                          ? const Color(0xFF86EFAC)
                          : (_isHovered ? Colors.white : const Color(0xFF8BA677)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOutCubic,
                      style: TextStyle(
                        color: active
                            ? Colors.white
                            : (_isHovered ? Colors.white : const Color(0xFFCADBC1)),
                        fontSize: 12.5,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: active ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOutCubic,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF86EFAC),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FLYOUT SUBMENU ITEM (FOR COLLAPSED SIDEBAR HOVER POPUP)
// -----------------------------------------------------------------------------
class _FlyoutSubMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FlyoutSubMenuItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FlyoutSubMenuItem> createState() => _FlyoutSubMenuItemState();
}

class _FlyoutSubMenuItemState extends State<_FlyoutSubMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isSelected;
    final Color bgColor = active
        ? const Color(0xFF384C28).withValues(alpha: 0.6)
        : (_isHovered ? const Color(0xFF22351B) : Colors.transparent);
    final Color textColor = active
        ? const Color(0xFF86EFAC)
        : (_isHovered ? Colors.white : const Color(0xFFCADBC1));
    final Color iconColor = active
        ? const Color(0xFF86EFAC)
        : (_isHovered ? const Color(0xFF86EFAC) : const Color(0xFF8BA677));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active
                    ? const Color(0xFF86EFAC).withValues(alpha: 0.4)
                    : (_isHovered ? const Color(0xFF384C28) : Colors.transparent),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 17,
                  color: iconColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: active ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (active)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF86EFAC),
                      shape: BoxShape.circle,
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

