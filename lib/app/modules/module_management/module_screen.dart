import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/values/app_colors.dart';
import '../../core/values/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/widgets/custom_pagination.dart';
import '../../core/widgets/custom_shimmer.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../core/widgets/global_gaushala_selector.dart';
import '../../core/widgets/header_user_profile_badge.dart';
import '../../core/widgets/mobile_list_bottom_loader.dart';
import '../../data/models/module_model.dart';
import '../../routes/app_routes.dart';
import '../dashboard/widgets/mobile_drawer.dart';
import '../dashboard/widgets/web_sidebar.dart';
import '../notification/widgets/notification_bell_widget.dart';
import 'module_controller.dart';

/// Screen for Managing System Modules and Sub-Modules (Master > Modules).
class ModuleScreen extends GetView<ModuleController> {
  const ModuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBuilder: (context) => _buildMobileScaffold(context),
      tabletBuilder: (context) => _buildTabletScaffold(context),
      desktopBuilder: (context) => _buildDesktopScaffold(context),
    );
  }

  // ===========================================================================
  // DESKTOP SCAFFOLD
  // ===========================================================================
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
                          children: [
                            _buildBreadcrumbAndActionBar(context),
                            const SizedBox(height: 24),
                            _buildModulesTableCard(context),
                          ],
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

  // ===========================================================================
  // TABLET SCAFFOLD
  // ===========================================================================
  Widget _buildTabletScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Module Management'),
        actions: [
          const NotificationBellWidget(),
          Obx(() {
            final isBusy = controller.isRefreshing.value || controller.isLoading.value;
            return IconButton(
              icon: isBusy
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh Modules',
              onPressed: isBusy ? null : controller.refreshModules,
            );
          }),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.fileCode),
            tooltip: 'Bulk Import (JSON)',
            onPressed: () => controller.openBulkImportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Module',
            onPressed: () => controller.openAddModuleDialog(context),
          ),
        ],
      ),
      drawer: Obx(
        () => MobileDrawer(
          currentUser: controller.currentUser.value,
          onLogout: controller.logout,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildSearchAndFilterControls(context),
            const SizedBox(height: 16),
            _buildModulesCardsList(context),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // MOBILE SCAFFOLD
  // ===========================================================================
  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modules Master'),
        actions: [
          const NotificationBellWidget(),
          Obx(() {
            final isBusy = controller.isRefreshing.value || controller.isLoading.value;
            return IconButton(
              icon: isBusy
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh Modules',
              onPressed: isBusy ? null : controller.refreshModules,
            );
          }),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.fileCode),
            tooltip: 'Bulk Import',
            onPressed: () => controller.openBulkImportDialog(context),
          ),
        ],
      ),
      drawer: Obx(
        () => MobileDrawer(
          currentUser: controller.currentUser.value,
          onLogout: controller.logout,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Module',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => controller.openAddModuleDialog(context),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.extentAfter < 300 && controller.hasMoreMobile) {
            controller.loadMoreMobile();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: controller.refreshModules,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSearchAndFilterControls(context),
                const SizedBox(height: 16),
                _buildModulesCardsList(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DESKTOP HEADER
  // ===========================================================================
  Widget _buildDesktopHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Obx(
                () => IconButton(
                  icon: Icon(
                    controller.isSidebarCollapsed.value
                        ? Icons.menu_open_rounded
                        : Icons.menu_rounded,
                    size: 22,
                  ),
                  tooltip: controller.isSidebarCollapsed.value
                      ? 'Expand Sidebar'
                      : 'Collapse Sidebar',
                  onPressed: controller.toggleSidebar,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'MASTER',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Module & Sub-Module Management',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
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
                  icon: isBusy
                      ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                      : const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: isBusy ? 'Refreshing...' : 'Refresh Modules',
                  onPressed: isBusy ? null : controller.refreshModules,
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

  // ===========================================================================
  // BREADCRUMB & ACTION BAR
  // ===========================================================================
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
                    child: const Text(
                      'Dashboard',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                const Text(
                  'Masters',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                const Text(
                  'Modules',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Module Management',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Configure core system modules, codes, and granular sub-modules.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
        Row(
          children: [
            CustomButton(
              text: 'Bulk Import (JSON)',
              icon: PhosphorIconsRegular.fileCode,
              variant: ButtonVariant.outlined,
              width: 175,
              height: 42,
              onPressed: () => controller.openBulkImportDialog(context),
            ),
            const SizedBox(width: 12),
            CustomButton(
              text: '+ Add New Module',
              icon: Icons.add_rounded,
              width: 175,
              height: 42,
              onPressed: () => controller.openAddModuleDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // DESKTOP MODULES TABLE CARD
  // ===========================================================================
  Widget _buildModulesTableCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter & Search bar header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.squaresFour, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Configured Modules',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${controller.filteredModules.length} Total',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    Obx(() {
                      if (controller.isLoading.value && controller.modules.isNotEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: CustomInlineLoader(size: 14, strokeWidth: 1.8),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
                Row(
                  children: [
                    // Status filter dropdown
                    Obx(
                      () => Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: controller.statusFilter.value,
                            icon: const Icon(Icons.arrow_drop_down, size: 18),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'ALL', child: Text('Status: All')),
                              DropdownMenuItem(value: 'ACTIVE', child: Text('Status: Active')),
                              DropdownMenuItem(value: 'INACTIVE', child: Text('Status: Inactive')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                controller.setStatusFilter(val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Search input
                    SizedBox(
                      width: 280,
                      height: 38,
                      child: TextField(
                        onChanged: (val) => controller.searchQuery.value = val,
                        decoration: InputDecoration(
                          hintText: 'Search by name or code...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          suffixIcon: Obx(
                            () => controller.searchQuery.value.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16),
                                    onPressed: () => controller.searchQuery.value = '',
                                  )
                                : const SizedBox.shrink(),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content: Table or Loading or Empty
          Obx(() {
            if (controller.isLoading.value && controller.modules.isEmpty) {
              return const CustomTableShimmer(
                rowCount: 6,
                columnFlexes: [5, 3, 5, 3, 2, 3],
                headers: ['#', 'MODULE NAME', 'CODE', 'DESCRIPTION', 'SUB-MODULES', 'STATUS', 'ACTIONS'],
              );
            }

            final list = controller.filteredModules;
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(60.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(PhosphorIconsRegular.squaresFour, size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.searchQuery.value.isNotEmpty
                          ? 'No modules match "${controller.searchQuery.value}"'
                          : 'No modules found in system',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Click below to register your first module or use bulk JSON import.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomButton(
                          text: 'Add First Module',
                          icon: Icons.add_rounded,
                          width: 170,
                          height: 40,
                          onPressed: () => controller.openAddModuleDialog(context),
                        ),
                        const SizedBox(width: 12),
                        CustomButton(
                          text: 'Bulk Import (JSON)',
                          icon: PhosphorIconsRegular.fileCode,
                          variant: ButtonVariant.outlined,
                          width: 170,
                          height: 40,
                          onPressed: () => controller.openBulkImportDialog(context),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Table Header
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark.withValues(alpha: 0.6)
                        : const Color(0xFFF9FAFB),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 50, child: _buildTableHeaderCell('#')),
                      Expanded(flex: 5, child: _buildTableHeaderCell('MODULE NAME')),
                      Expanded(flex: 3, child: _buildTableHeaderCell('CODE')),
                      Expanded(flex: 5, child: _buildTableHeaderCell('DESCRIPTION')),
                      Expanded(flex: 3, child: _buildTableHeaderCell('SUB-MODULES')),
                      Expanded(flex: 2, child: _buildTableHeaderCell('STATUS')),
                      Expanded(flex: 3, child: _buildTableHeaderCell('ACTIONS', alignRight: true)),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Table Data Rows
                ...controller.paginatedModules.asMap().entries.map((entry) {
                  final pageStartIndex = (controller.currentPage.value - 1) * controller.rowsPerPage.value;
                  final index = pageStartIndex + entry.key;
                  final module = entry.value;
                  return _HoverableModuleTableRow(
                    key: ValueKey(module.id.isNotEmpty ? module.id : module.code),
                    index: index,
                    module: module,
                    isDark: isDark,
                  );
                }),

                const Divider(height: 1),
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

  Widget _buildTableHeaderCell(String title, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        title,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  // ===========================================================================
  // TABLET / MOBILE SEARCH & FILTER CONTROLS
  // ===========================================================================
  Widget _buildSearchAndFilterControls(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        TextField(
          onChanged: (val) => controller.searchQuery.value = val,
          decoration: InputDecoration(
            hintText: 'Search modules by name or code...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: Obx(
              () => controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => controller.searchQuery.value = '',
                    )
                  : const SizedBox.shrink(),
            ),
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Obx(
          () => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All Modules', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('ACTIVE', 'Active', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('INACTIVE', 'Inactive', isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, bool isDark) {
    final isSelected = controller.statusFilter.value == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.setStatusFilter(value),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  // ===========================================================================
  // MOBILE / TABLET MODULE CARDS LIST
  // ===========================================================================
  Widget _buildModulesCardsList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoading.value && controller.modules.isEmpty) {
        return const CustomListShimmer(itemCount: 6);
      }

      final list = ResponsiveLayout.isMobile(context)
          ? controller.mobileModules
          : controller.filteredModules;

      if (list.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text(
              controller.searchQuery.value.isNotEmpty
                  ? 'No modules match "${controller.searchQuery.value}"'
                  : 'No modules found.',
              style: const TextStyle(color: AppColors.textSecondaryLight),
            ),
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length + (ResponsiveLayout.isMobile(context) && controller.hasMoreMobile ? 1 : 0),
        separatorBuilder: (context, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == list.length) {
            return MobileListBottomLoader(hasMore: controller.hasMoreMobile);
          }

          final module = list[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              PhosphorIconsRegular.squaresFour,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  module.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  module.code,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(module.isActive),
                  ],
                ),
                if (module.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    module.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => controller.openSubModulesDialog(context, module),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(
                              PhosphorIconsRegular.stack,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${module.subModules.length} Sub-modules',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 18),
                          tooltip: 'Edit Module',
                          onPressed: () => controller.openEditModuleDialog(context, module),
                        ),
                        IconButton(
                          icon: const Icon(PhosphorIconsRegular.trash, size: 18, color: AppColors.error),
                          tooltip: 'Delete Module',
                          onPressed: () => controller.confirmDeleteModule(context, module),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

  // ===========================================================================
  // STATUS CHIP HELPER
  // ===========================================================================
  static Widget _buildStatusChip(bool isActive) {
    final color = isActive ? AppColors.success : Colors.grey;
    final text = isActive ? 'Active' : 'Inactive';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HOVERABLE DESKTOP TABLE ROW
// =============================================================================
class _HoverableModuleTableRow extends StatefulWidget {
  final int index;
  final ModuleModel module;
  final bool isDark;

  const _HoverableModuleTableRow({
    super.key,
    required this.index,
    required this.module,
    required this.isDark,
  });

  @override
  State<_HoverableModuleTableRow> createState() => _HoverableModuleTableRowState();
}

class _HoverableModuleTableRowState extends State<_HoverableModuleTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ModuleController>();
    final module = widget.module;
    final isDark = widget.isDark;

    final Color rowBg = _isHovered
        ? (isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.9)
            : AppColors.primary.withValues(alpha: 0.04))
        : (widget.index.isEven
            ? Colors.transparent
            : (isDark
                ? Colors.white.withValues(alpha: 0.015)
                : const Color(0xFFFCFDFB)));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: rowBg,
          border: Border(
            left: BorderSide(
              color: _isHovered ? AppColors.primary : Colors.transparent,
              width: 3.5,
            ),
            bottom: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 0.6,
            ),
          ),
        ),
        child: Row(
          children: [
            // # Index
            SizedBox(
              width: 50,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Text(
                  '${widget.index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Module Name
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.squaresFour,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        module.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Code Chip
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Tooltip(
                    message: 'Click to copy code',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: module.code));
                        CustomSnackbar.showInfo(
                          title: 'Copied',
                          message: 'Module code copied to clipboard',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              module.code,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.copy_rounded,
                              size: 11,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Description
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Tooltip(
                  message: module.description.isNotEmpty ? module.description : 'No description',
                  child: Text(
                    module.description.isNotEmpty ? module.description : '-',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            ),

            // Sub-modules Count Chip
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Tooltip(
                    message: 'View & Manage Sub-modules',
                    child: InkWell(
                      onTap: () => controller.openSubModulesDialog(context, module),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blueGrey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              PhosphorIconsRegular.stack,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${module.subModules.length} Sub-modules',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Status Badge
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ModuleScreen._buildStatusChip(module.isActive),
                ),
              ),
            ),

            // Actions
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.stack, size: 18),
                      tooltip: 'Manage Sub-modules',
                      hoverColor: AppColors.primary.withValues(alpha: 0.1),
                      onPressed: () => controller.openSubModulesDialog(context, module),
                    ),
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 18),
                      tooltip: 'Edit Module Details',
                      hoverColor: AppColors.primary.withValues(alpha: 0.1),
                      onPressed: () => controller.openEditModuleDialog(context, module),
                    ),
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.trash, size: 18, color: AppColors.error),
                      tooltip: 'Delete Module',
                      hoverColor: AppColors.error.withValues(alpha: 0.1),
                      onPressed: () => controller.confirmDeleteModule(context, module),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
