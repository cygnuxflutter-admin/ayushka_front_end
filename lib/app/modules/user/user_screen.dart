import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../models/permission_model.dart';
import '../../../screens/user_permissions_screen.dart';
import '../../../widgets/permission_guard.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/values/app_colors.dart';
import '../../core/values/app_constants.dart';
import '../../core/values/permission_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/widgets/custom_pagination.dart';
import '../../core/widgets/custom_shimmer.dart';
import '../../core/widgets/global_gaushala_selector.dart';
import '../../core/widgets/header_user_profile_badge.dart';
import '../../core/widgets/mobile_list_bottom_loader.dart';
import '../../data/models/user_model.dart';
import '../../routes/app_routes.dart';
import '../dashboard/widgets/mobile_drawer.dart';
import '../dashboard/widgets/web_sidebar.dart';
import '../notification/widgets/notification_bell_widget.dart';
import 'user_controller.dart';

/// Screen for Managing System Users (Master > Users).
/// Responsive layout supporting Desktop, Tablet, and Mobile.
class UserScreen extends GetView<UserController> {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBuilder: (context) => _buildMobileScaffold(context),
      tabletBuilder: (context) => _buildTabletScaffold(context),
      desktopBuilder: (context) => _buildDesktopScaffold(context),
    );
  }

  // -------------------------------------------------------------
  // DESKTOP SCAFFOLD
  // -------------------------------------------------------------
  Widget _buildDesktopScaffold(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Obx(
            () => WebSidebar(
              isCollapsed: controller.isSidebarCollapsed.value,
              onToggle: controller.toggleSidebar,
              currentUser: controller.currentUser.value,
              onLogout: controller.logout,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _buildDesktopHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [_buildBreadcrumbAndActionBar(context), const SizedBox(height: 24), _buildUsersTableCard(context)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TABLET SCAFFOLD
  // -------------------------------------------------------------
  Widget _buildTabletScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Master'),
        actions: [
          const NotificationBellWidget(),
          Obx(() {
            final isBusy = controller.isRefreshing.value || controller.isLoading.value;
            return IconButton(
              icon: isBusy ? const CustomInlineLoader(size: 18, strokeWidth: 2) : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh Users',
              onPressed: isBusy ? null : controller.refreshUsers,
            );
          }),
          IconButton(icon: const Icon(Icons.add_rounded), tooltip: 'Add User', onPressed: () => controller.openAddUserDialog(context)),
        ],
      ),
      drawer: Obx(() => MobileDrawer(currentUser: controller.currentUser.value, onLogout: controller.logout)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(children: [_buildSearchAndFilters(context, isMobile: false), const SizedBox(height: 16), _buildUsersCardsList(context)]),
      ),
    );
  }

  // -------------------------------------------------------------
  // MOBILE SCAFFOLD
  // -------------------------------------------------------------
  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Master'),
        actions: [
          const NotificationBellWidget(),
          Obx(() {
            final isBusy = controller.isRefreshing.value || controller.isLoading.value;
            return IconButton(
              icon: isBusy ? const CustomInlineLoader(size: 18, strokeWidth: 2) : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh Users',
              onPressed: isBusy ? null : controller.refreshUsers,
            );
          }),
        ],
      ),
      drawer: Obx(() => MobileDrawer(currentUser: controller.currentUser.value, onLogout: controller.logout)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Add User',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => controller.openAddUserDialog(context),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshUsers,
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
              controller.loadMoreMobile();
            }
            return false;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [_buildSearchAndFilters(context, isMobile: true), const SizedBox(height: 16), _buildUsersCardsList(context)]),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // DESKTOP TOP HEADER
  // -------------------------------------------------------------
  Widget _buildDesktopHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Obx(
                () => IconButton(
                  icon: Icon(controller.isSidebarCollapsed.value ? Icons.menu_open_rounded : Icons.menu_rounded, size: 22),
                  tooltip: controller.isSidebarCollapsed.value ? 'Expand Sidebar' : 'Collapse Sidebar',
                  onPressed: controller.toggleSidebar,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: const Text(
                  'MASTER',
                  style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              const Text('User & Personnel Management', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              const GlobalGaushalaSelector(),
              const SizedBox(width: 8),
              const NotificationBellWidget(),
              const SizedBox(width: 8),
              Obx(() {
                final isBusy = controller.isRefreshing.value || controller.isLoading.value;
                return IconButton(
                  icon: isBusy ? const CustomInlineLoader(size: 18, strokeWidth: 2) : const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: isBusy ? 'Refreshing...' : 'Refresh Users',
                  onPressed: isBusy ? null : controller.refreshUsers,
                );
              }),
              const SizedBox(width: 8),
              Obx(() => HeaderUserProfileBadge(user: controller.currentUser.value)),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // BREADCRUMB & ACTION BAR
  // -------------------------------------------------------------
  Widget _buildBreadcrumbAndActionBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    mouseCursor: SystemMouseCursors.click,
                    onTap: () => Get.offNamed(AppRoutes.dashboard),
                    child: const Text('Dashboard', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                const Text('Masters', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                const Text(
                  'Users',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Users Master',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ),
          ],
        ),
        Row(
          children: [
            PermissionGuard(
              moduleCode: PermissionModules.user,
              subModuleCode: PermissionSubModules.userList,
              action: PermissionAction.add,
              child: CustomButton(
                text: 'Add User',
                icon: Icons.person_add_alt_1_rounded,
                width: 140,
                height: 42,
                onPressed: () => controller.openAddUserDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // DESKTOP USERS TABLE CARD
  // -------------------------------------------------------------
  Widget _buildUsersTableCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter & Search bar header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Wrap(
              spacing: 14,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsRegular.users, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    const Text('System Users', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          '${controller.filteredUsers.length} Total',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ),
                    Obx(() {
                      if (controller.isLoading.value && controller.users.isNotEmpty) {
                        return const Padding(padding: EdgeInsets.only(left: 8.0), child: CustomInlineLoader(size: 14, strokeWidth: 1.8));
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Search input
                    SizedBox(
                      width: 240,
                      child: TextField(
                        controller: controller.searchController,
                        onChanged: (val) => controller.searchQuery.value = val,
                        decoration: InputDecoration(
                          hintText: 'Search user, email, role...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          suffixIcon: Obx(
                            () => controller.searchQuery.value.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16),
                                    splashRadius: 16,
                                    padding: const EdgeInsets.only(right: 8),
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                    onPressed: controller.clearSearch,
                                  )
                                : const SizedBox.shrink(),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                        ),
                      ),
                    ),

                    // Gaushala Filter Dropdown
                    if (controller.isSuperAdmin)
                      _buildGaushalaFilterDropdown(context, isDark, width: 230),

                    // Role Filter Dropdown
                    _buildRoleFilterDropdown(context, isDark, width: 180),

                    // Status Filter Dropdown
                    _buildStatusFilterDropdown(context, isDark, width: 170),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Table Content
          Obx(() {
            if (controller.isLoading.value && controller.users.isEmpty) {
              return const CustomTableShimmer(
                rowCount: 5,
                columnFlexes: [4, 4, 3, 3, 2, 2, 2],
                headers: ['#', 'USER', 'EMAIL', 'ROLE', 'GAUSHALA', 'STATUS', 'CREATED', 'ACTIONS'],
              );
            }

            final list = controller.filteredUsers;
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 50.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(PhosphorIconsRegular.userList, size: 48, color: AppColors.textMutedLight),
                      const SizedBox(height: 12),
                      const Text('No Users Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        controller.searchQuery.value.isNotEmpty ||
                                controller.selectedGaushalaFilter.value != null ||
                                controller.selectedRoleFilter.value != null ||
                                controller.selectedStatusFilter.value != 'all'
                            ? 'Try clearing your filters or search terms.'
                            : 'Click "Add User" to register the first system staff member.',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
              );
            }

            final pageUsers = controller.paginatedUsers;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Table Header Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.6) : const Color(0xFFF9FAFB),
                    border: const Border(left: BorderSide(color: Colors.transparent, width: 3.5)),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(width: 44, child: Text('#', style: _headerStyle)),
                      Expanded(flex: 4, child: Text('USER', style: _headerStyle)),
                      Expanded(flex: 4, child: Text('EMAIL', style: _headerStyle)),
                      Expanded(flex: 3, child: Text('ROLE', style: _headerStyle)),
                      Expanded(flex: 3, child: Text('GAUSHALA', style: _headerStyle)),
                      Expanded(flex: 2, child: Text('STATUS', style: _headerStyle)),
                      Expanded(flex: 2, child: Text('CREATED', style: _headerStyle)),
                      SizedBox(
                        width: 135,
                        child: Text('ACTIONS', style: _headerStyle, textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Table Data Rows with Herd & Cattle Animation Style
                ...pageUsers.asMap().entries.map((entry) {
                  final serial = ((controller.currentPage.value - 1) * controller.rowsPerPage.value) + entry.key + 1;
                  final user = entry.value;
                  return _HoverableUserTableRow(
                    key: ValueKey('${user.id}_${user.isActive}_${user.isDeleted}'),
                    index: entry.key,
                    serial: serial,
                    user: user,
                    isDark: isDark,
                    onToggleStatus: (val) => controller.toggleUserStatus(user, val),
                    onChangePassword: () => controller.openChangePasswordDialog(context, user),
                    onEdit: () => controller.openEditUserDialog(context, user),
                    onDelete: () => controller.confirmDeleteUser(context, user),
                  );
                }),
                const Divider(height: 1),

                // Pagination Bar
                CustomPagination(
                  totalItems: list.length,
                  currentPage: controller.currentPage.value,
                  rowsPerPage: controller.rowsPerPage.value,
                  onPageChanged: controller.setPage,
                  onRowsPerPageChanged: controller.setRowsPerPage,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // GAUSHALA FILTER DROPDOWN
  // -------------------------------------------------------------
  Widget _buildGaushalaFilterDropdown(BuildContext context, bool isDark, {double width = 230, bool isExpanded = false}) {
    return Obx(() {
      final list = controller.gaushalas.toList();
      final canChange = controller.canChangeGaushala;
      final currentFilter = controller.selectedGaushalaFilter.value;
      final isFiltered = currentFilter != null && currentFilter.isNotEmpty && currentFilter != 'all';

      String selectedName = 'All Gaushalas';
      if (isFiltered) {
        final match = controller.findGaushala(currentFilter);
        if (match != null) {
          selectedName = match.gaushalaName;
        }
      }

      final effectiveWidth = isExpanded ? double.infinity : width;

      // If user is Non-Admin, render fixed station chip
      if (!canChange) {
        final assignedName = controller.currentUser.value?.gaushalaName ?? selectedName;
        return Tooltip(
          message: 'Assigned Gaushala: $assignedName (Fixed to your account)',
          child: Container(
            width: effectiveWidth,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 1.0),
            ),
            child: Row(
              mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    assignedName.isNotEmpty ? assignedName : 'Assigned Gaushala',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(PhosphorIconsRegular.lockSimple, size: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ],
            ),
          ),
        );
      }

      final items = ['All Gaushalas', ...list.map((g) => g.gaushalaName)];

      return SizedBox(
        width: effectiveWidth,
        child: DropdownSearch<String>(
          items: (filter, infiniteScrollProps) {
            if (filter.isEmpty) return items;
            return items.where((item) => item.toLowerCase().contains(filter.toLowerCase())).toList();
          },
          selectedItem: selectedName,
          compareFn: (i1, i2) => i1 == i2,
          onSelected: (selected) {
            if (selected == null || selected == 'All Gaushalas') {
              controller.setGaushalaFilter(null);
            } else {
              final match = controller.findGaushala(selected);
              controller.setGaushalaFilter(match?.id);
            }
          },
          popupProps: PopupProps.menu(
            showSearchBox: items.length > 5,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search gaushala...',
                hintStyle: TextStyle(fontSize: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                prefixIcon: const Icon(Icons.search_rounded, size: 16),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            menuProps: MenuProps(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
              elevation: 8,
            ),
            itemBuilder: (ctx, item, isDisabled, isSelected) {
              final isCurrent = item == selectedName;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: isCurrent ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                child: Row(
                  children: [
                    Icon(
                      item == 'All Gaushalas' ? PhosphorIconsRegular.circlesFour : Icons.location_on_outlined,
                      size: 15,
                      color: isCurrent ? AppColors.primary : (isDark ? Colors.white70 : Colors.black54),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                    ),
                    if (isCurrent) const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                  ],
                ),
              );
            },
          ),
          dropdownBuilder: (context, selectedItem) {
            return Text(
              selectedItem ?? 'All Gaushalas',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            );
          },
          suffixProps: DropdownSuffixProps(
            dropdownButtonProps: DropdownButtonProps(
              iconClosed: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              iconOpened: Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: AppColors.primary),
            ),
          ),
          decoratorProps: DropDownDecoratorProps(
            baseStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : Theme.of(context).cardColor,
              prefixIcon: const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
      );
    });
  }

  // -------------------------------------------------------------
  // ROLE FILTER DROPDOWN
  // -------------------------------------------------------------
  Widget _buildRoleFilterDropdown(BuildContext context, bool isDark, {double width = 180, bool isExpanded = false}) {
    return Obx(() {
      final list = controller.roles.toList();
      final currentFilter = controller.selectedRoleFilter.value;
      final isFiltered = currentFilter != null && currentFilter.isNotEmpty && currentFilter != 'all';

      String selectedName = 'All Roles';
      if (isFiltered) {
        final match = list.firstWhereOrNull((r) => r.id == currentFilter);
        if (match != null) {
          selectedName = match.roleName;
        } else {
          final matchByName = list.firstWhereOrNull((r) => r.roleName.toLowerCase() == currentFilter.toLowerCase());
          if (matchByName != null) {
            selectedName = matchByName.roleName;
          }
        }
      }

      final effectiveWidth = isExpanded ? double.infinity : width;
      final items = ['All Roles', ...list.map((r) => r.roleName)];

      return SizedBox(
        width: effectiveWidth,
        child: DropdownSearch<String>(
          items: (filter, infiniteScrollProps) {
            if (filter.isEmpty) return items;
            return items.where((item) => item.toLowerCase().contains(filter.toLowerCase())).toList();
          },
          selectedItem: selectedName,
          compareFn: (i1, i2) => i1 == i2,
          onSelected: (selected) {
            if (selected == null || selected == 'All Roles') {
              controller.selectedRoleFilter.value = null;
            } else {
              final match = list.firstWhereOrNull((r) => r.roleName == selected);
              controller.selectedRoleFilter.value = match?.id;
            }
            controller.currentPage.value = 1;
          },
          popupProps: PopupProps.menu(
            showSearchBox: items.length > 5,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search role...',
                hintStyle: TextStyle(fontSize: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                prefixIcon: const Icon(Icons.search_rounded, size: 16),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            menuProps: MenuProps(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
              elevation: 8,
            ),
            itemBuilder: (ctx, item, isDisabled, isSelected) {
              final isCurrent = item == selectedName;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: isCurrent ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                child: Row(
                  children: [
                    Icon(
                      item == 'All Roles' ? PhosphorIconsRegular.circlesFour : Icons.shield_outlined,
                      size: 15,
                      color: isCurrent ? AppColors.primary : (isDark ? Colors.white70 : Colors.black54),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                    ),
                    if (isCurrent) const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                  ],
                ),
              );
            },
          ),
          dropdownBuilder: (context, selectedItem) {
            return Text(
              selectedItem ?? 'All Roles',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            );
          },
          suffixProps: DropdownSuffixProps(
            dropdownButtonProps: DropdownButtonProps(
              iconClosed: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              iconOpened: Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: AppColors.primary),
            ),
          ),
          decoratorProps: DropDownDecoratorProps(
            baseStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : Theme.of(context).cardColor,
              prefixIcon: const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
      );
    });
  }

  // -------------------------------------------------------------
  // STATUS FILTER DROPDOWN
  // -------------------------------------------------------------
  Widget _buildStatusFilterDropdown(BuildContext context, bool isDark, {double width = 170, bool isExpanded = false}) {
    return Obx(() {
      final status = controller.selectedStatusFilter.value;
      final selectedStatusName = status == 'active' ? 'Active Only' : (status == 'inactive' ? 'Inactive Only' : 'All Status');

      const items = ['All Status', 'Active Only', 'Inactive Only'];
      final effectiveWidth = isExpanded ? double.infinity : width;

      return SizedBox(
        width: effectiveWidth,
        child: DropdownSearch<String>(
          items: (filter, infiniteScrollProps) => items,
          selectedItem: selectedStatusName,
          compareFn: (i1, i2) => i1 == i2,
          onSelected: (selected) {
            if (selected == 'Active Only') {
              controller.selectedStatusFilter.value = 'active';
            } else if (selected == 'Inactive Only') {
              controller.selectedStatusFilter.value = 'inactive';
            } else {
              controller.selectedStatusFilter.value = 'all';
            }
            controller.currentPage.value = 1;
          },
          popupProps: PopupProps.menu(
            showSearchBox: false,
            menuProps: MenuProps(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
              elevation: 8,
            ),
            itemBuilder: (ctx, item, isDisabled, isSelected) {
              final isCurrent = item == selectedStatusName;
              IconData icon;
              Color? iconColor;
              if (item == 'Active Only') {
                icon = Icons.check_circle_outline_rounded;
                iconColor = Colors.green;
              } else if (item == 'Inactive Only') {
                icon = Icons.cancel_outlined;
                iconColor = Colors.redAccent;
              } else {
                icon = PhosphorIconsRegular.circlesFour;
                iconColor = isCurrent ? AppColors.primary : (isDark ? Colors.white70 : Colors.black54);
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: isCurrent ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                child: Row(
                  children: [
                    Icon(icon, size: 15, color: isCurrent ? AppColors.primary : iconColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                    ),
                    if (isCurrent) const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                  ],
                ),
              );
            },
          ),
          dropdownBuilder: (context, selectedItem) {
            return Text(
              selectedItem ?? 'All Status',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            );
          },
          suffixProps: DropdownSuffixProps(
            dropdownButtonProps: DropdownButtonProps(
              iconClosed: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              iconOpened: Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: AppColors.primary),
            ),
          ),
          decoratorProps: DropDownDecoratorProps(
            baseStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : Theme.of(context).cardColor,
              prefixIcon: const Icon(Icons.toggle_on_outlined, size: 16, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
      );
    });
  }

  // -------------------------------------------------------------
  // TABLET / MOBILE SEARCH & FILTERS
  // -------------------------------------------------------------
  Widget _buildSearchAndFilters(BuildContext context, {required bool isMobile}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Search Box
        TextField(
          controller: controller.searchController,
          onChanged: (val) => controller.searchQuery.value = val,
          decoration: InputDecoration(
            hintText: 'Search users by name, username, email...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: Obx(
              () => controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      splashRadius: 18,
                      padding: const EdgeInsets.only(right: 10),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: controller.clearSearch,
                    )
                  : const SizedBox.shrink(),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Filter chips / dropdowns
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Gaushala Filter Dropdown
              if (controller.isSuperAdmin) ...[
                _buildGaushalaFilterDropdown(context, isDark, width: 210),
                const SizedBox(width: 8),
              ],

              // Role Filter Dropdown
              _buildRoleFilterDropdown(context, isDark, width: 170),
              const SizedBox(width: 8),

              // Status Filter Dropdown
              _buildStatusFilterDropdown(context, isDark, width: 160),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TABLET / MOBILE CARDS LIST
  // -------------------------------------------------------------
  Widget _buildUsersCardsList(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoading.value && controller.users.isEmpty) {
        return const CustomInlineLoader();
      }

      final list = controller.filteredUsers;
      if (list.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Center(
            child: Column(
              children: [
                Icon(PhosphorIconsRegular.userList, size: 40, color: AppColors.textMutedLight),
                const SizedBox(height: 10),
                const Text('No Users Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        );
      }

      final isMobile = ResponsiveLayout.isMobile(context);
      final displayUsers = isMobile ? controller.mobileUsers : controller.paginatedUsers;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayUsers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = displayUsers[index];

              return _HoverableListCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Avatar + Name + Status switch
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildUserAvatar(user),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                if (user.username != null && user.username!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '@${user.username}',
                                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: user.isActive,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) => controller.toggleUserStatus(user, val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Email
                      Row(
                        children: [
                          const Icon(Icons.mail_outline_rounded, size: 15, color: AppColors.textMutedLight),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              user.email,
                              style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Badges Row
                      Wrap(spacing: 8, runSpacing: 6, children: [_buildRoleBadge(user.role), _buildGaushalaBadge(user.gaushalaName)]),
                      const Divider(height: 20),

                      // Bottom Row: Created date + actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            user.createdAt != null ? 'Created ${DateFormat('dd MMM yyyy').format(user.createdAt!)}' : '',
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(PhosphorIconsRegular.shieldCheck, size: 18),
                                tooltip: 'Manage Permissions',
                                color: AppColors.primary,
                                visualDensity: VisualDensity.compact,
                                onPressed: () => UserPermissionsScreen.show(
                                  context,
                                  userId: user.id,
                                  userName: user.name,
                                  userRole: user.role,
                                  isUserAdmin: user.isAdmin,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.lock_reset_rounded, size: 18),
                                tooltip: 'Change Password',
                                color: AppColors.warning,
                                visualDensity: VisualDensity.compact,
                                onPressed: () => controller.openChangePasswordDialog(context, user),
                              ),
                              if (!user.isDeleted)
                                PermissionGuard(
                                  moduleCode: PermissionModules.user,
                                  subModuleCode: PermissionSubModules.userList,
                                  action: PermissionAction.edit,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    tooltip: 'Edit User',
                                    color: AppColors.info,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => controller.openEditUserDialog(context, user),
                                  ),
                                ),
                              if (!user.isDeleted)
                                PermissionGuard(
                                  moduleCode: PermissionModules.user,
                                  subModuleCode: PermissionSubModules.userList,
                                  action: PermissionAction.delete,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                    tooltip: 'Delete User',
                                    color: AppColors.error,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => controller.confirmDeleteUser(context, user),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (isMobile) ...[
            const SizedBox(height: 16),
            MobileListBottomLoader(hasMore: controller.hasMoreMobile, totalCount: list.length),
          ] else ...[
            const SizedBox(height: 14),
            Card(
              margin: EdgeInsets.zero,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPagination(
                  totalItems: list.length,
                  currentPage: controller.currentPage.value,
                  rowsPerPage: controller.rowsPerPage.value,
                  onPageChanged: controller.setPage,
                  onRowsPerPageChanged: controller.setRowsPerPage,
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  // -------------------------------------------------------------
  // HELPER WIDGETS
  // -------------------------------------------------------------

  static Widget _buildUserAvatar(UserModel user) {
    final initial = user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U';
    final role = user.role.toLowerCase();

    Color bgColor = AppColors.primary;
    if (role.contains('admin')) {
      bgColor = const Color(0xFF2E7D32);
    } else if (role.contains('doctor')) {
      bgColor = const Color(0xFF6A1B9A);
    } else if (role.contains('manager')) {
      bgColor = const Color(0xFF00695C);
    } else if (role.contains('staff')) {
      bgColor = const Color(0xFF1565C0);
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: bgColor.withValues(alpha: 0.15),
      child: Text(
        initial,
        style: TextStyle(color: bgColor, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  static Widget _buildRoleBadge(String roleName) {
    final role = roleName.toLowerCase();
    Color color = AppColors.primary;
    Color bg = AppColors.primary.withValues(alpha: 0.12);

    if (role.contains('admin')) {
      color = const Color(0xFF2E7D32);
      bg = const Color(0xFFE8F5E9);
    } else if (role.contains('doctor')) {
      color = const Color(0xFF6A1B9A);
      bg = const Color(0xFFF3E5F5);
    } else if (role.contains('manager')) {
      color = const Color(0xFF00695C);
      bg = const Color(0xFFE0F2F1);
    } else if (role.contains('staff')) {
      color = const Color(0xFF1565C0);
      bg = const Color(0xFFE3F2FD);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsRegular.shieldCheck, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            roleName.isNotEmpty ? roleName : 'Staff',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  static Widget _buildGaushalaBadge(String? gaushalaName) {
    final name = (gaushalaName != null && gaushalaName.isNotEmpty) ? gaushalaName : 'Global / All';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5EE),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD6E3D0), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.storefront_outlined, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            name,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: AppColors.textSecondaryLight);
}

// -------------------------------------------------------------
// HOVERABLE USER TABLE ROW (DESKTOP)
// -------------------------------------------------------------
class _HoverableUserTableRow extends StatefulWidget {
  final int index;
  final int serial;
  final UserModel user;
  final bool isDark;
  final ValueChanged<bool> onToggleStatus;
  final VoidCallback onChangePassword;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HoverableUserTableRow({
    super.key,
    required this.index,
    required this.serial,
    required this.user,
    required this.isDark,
    required this.onToggleStatus,
    required this.onChangePassword,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_HoverableUserTableRow> createState() => _HoverableUserTableRowState();
}

class _HoverableUserTableRowState extends State<_HoverableUserTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isDark = widget.isDark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: _isHovered
              ? (isDark ? AppColors.surfaceDark.withValues(alpha: 0.85) : AppColors.primary.withValues(alpha: 0.045))
              : (widget.index.isEven ? Colors.transparent : (isDark ? Colors.white.withValues(alpha: 0.015) : const Color(0xFFFAFCF9))),
          border: Border(
            top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.6),
            left: BorderSide(color: _isHovered ? (isDark ? AppColors.primaryLight : AppColors.primary) : Colors.transparent, width: 3.5),
          ),
        ),
        child: Row(
          children: [
            // Serial #
            SizedBox(
              width: 44,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: _isHovered ? FontWeight.bold : FontWeight.w500,
                  color: _isHovered
                      ? (isDark ? AppColors.primaryLight : AppColors.primary)
                      : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
                child: Text('${widget.serial}'),
              ),
            ),

            // User Avatar + Name + Username
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  UserScreen._buildUserAvatar(user),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _isHovered ? FontWeight.bold : FontWeight.w600,
                            color: _isHovered
                                ? (isDark ? Colors.white : Colors.black87)
                                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user.username != null && user.username!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '@${user.username}',
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Email
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Icon(
                    Icons.mail_outline_rounded,
                    size: 14,
                    color: _isHovered ? (isDark ? AppColors.primaryLight : AppColors.primary) : AppColors.textMutedLight,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: _isHovered
                            ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Role Badge
            Expanded(
              flex: 3,
              child: Align(alignment: Alignment.centerLeft, child: UserScreen._buildRoleBadge(user.role)),
            ),

            // Gaushala Badge
            Expanded(
              flex: 3,
              child: Align(alignment: Alignment.centerLeft, child: UserScreen._buildGaushalaBadge(user.gaushalaName)),
            ),

            // Status Switch
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Transform.scale(
                  scale: 0.8,
                  alignment: Alignment.centerLeft,
                  child: Switch.adaptive(value: user.isActive, activeThumbColor: AppColors.primary, onChanged: widget.onToggleStatus),
                ),
              ),
            ),

            // Created Date
            Expanded(
              flex: 2,
              child: Text(
                user.createdAt != null ? DateFormat('dd MMM yyyy').format(user.createdAt!) : '—',
                style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
            ),

            // Actions (Permissions, Change Password, Edit & Delete)
            SizedBox(
              width: 175,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: 'Manage Permissions',
                    child: IconButton(
                      icon: const Icon(PhosphorIconsRegular.shieldCheck, size: 18),
                      color: _isHovered ? AppColors.primary : AppColors.primary.withValues(alpha: 0.8),
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          UserPermissionsScreen.show(context, userId: user.id, userName: user.name, userRole: user.role, isUserAdmin: user.isAdmin),
                    ),
                  ),
                  Tooltip(
                    message: 'Change Password',
                    child: IconButton(
                      icon: const Icon(Icons.lock_reset_rounded, size: 18),
                      color: _isHovered ? AppColors.warning : AppColors.warning.withValues(alpha: 0.8),
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onChangePassword,
                    ),
                  ),
                  if (!user.isDeleted)
                    Tooltip(
                      message: 'Edit User',
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: _isHovered ? AppColors.info : AppColors.info.withValues(alpha: 0.8),
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.onEdit,
                      ),
                    ),
                  if (!user.isDeleted)
                    Tooltip(
                      message: 'Delete User',
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        color: _isHovered ? AppColors.error : AppColors.error.withValues(alpha: 0.8),
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.onDelete,
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

// -------------------------------------------------------------
// HOVERABLE CARD (MOBILE / TABLET)
// -------------------------------------------------------------
class _HoverableListCard extends StatefulWidget {
  final Widget child;
  const _HoverableListCard({required this.child});

  @override
  State<_HoverableListCard> createState() => _HoverableListCardState();
}

class _HoverableListCardState extends State<_HoverableListCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? (isDark ? AppColors.primaryLight : AppColors.primary.withValues(alpha: 0.45))
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: _isHovered ? 1.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.03),
              blurRadius: _isHovered ? 8 : 3,
              offset: Offset(0, _isHovered ? 3 : 1),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
