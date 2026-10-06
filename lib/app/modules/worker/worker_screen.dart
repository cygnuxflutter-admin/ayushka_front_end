import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/values/app_colors.dart';
import '../../core/values/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dropdown_search.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/widgets/custom_pagination.dart';
import '../../core/widgets/mobile_list_bottom_loader.dart';
import '../../core/widgets/custom_shimmer.dart';
import '../../core/widgets/global_gaushala_selector.dart';
import '../../core/widgets/header_user_profile_badge.dart';
import '../notification/widgets/notification_bell_widget.dart';
import '../../data/models/worker_model.dart';
import '../../routes/app_routes.dart';
import '../dashboard/widgets/mobile_drawer.dart';
import '../dashboard/widgets/web_sidebar.dart';
import 'department_controller.dart';
import 'worker_controller.dart';
import 'widgets/department_summary_cards.dart';
import 'widgets/manage_departments_dialog.dart';

/// Screen component for Department & Worker Management.
/// Responsive layout supporting Desktop, Tablet, and Mobile Web.
class WorkerScreen extends GetView<WorkerController> {
  const WorkerScreen({super.key});

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
          // Sidebar
          Obx(
            () => WebSidebar(
              isCollapsed: controller.isSidebarCollapsed.value,
              onToggle: controller.toggleSidebar,
              currentUser: controller.currentUser.value,
              onLogout: controller.logout,
            ),
          ),

          // Main View Content
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
                            const SizedBox(height: 20),
                            const DepartmentSummaryCards(),
                            const SizedBox(height: 24),
                            _buildWorkersTableCard(context),
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

  // -------------------------------------------------------------
  // TABLET SCAFFOLD
  // -------------------------------------------------------------
  Widget _buildTabletScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workers & Departments'),
        actions: [
          const NotificationBellWidget(),
          Obx(() {
            final isBusy = controller.isRefreshing.value || controller.isLoading.value;
            return IconButton(
              icon: isBusy
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh Data',
              onPressed: isBusy ? null : controller.refreshAll,
            );
          }),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.buildings),
            tooltip: 'Manage Departments',
            onPressed: () => ManageDepartmentsDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Add Worker',
            onPressed: () => controller.openAddWorkerDialog(context),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DepartmentSummaryCards(isCompact: true),
            const SizedBox(height: 20),
            _buildWorkersTableCard(context),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // MOBILE SCAFFOLD
  // -------------------------------------------------------------
  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workers & Departments'),
        actions: [
          const NotificationBellWidget(),
          Obx(() {
            final isBusy = controller.isRefreshing.value || controller.isLoading.value;
            return IconButton(
              icon: isBusy
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh Data',
              onPressed: isBusy ? null : controller.refreshAll,
            );
          }),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.buildings),
            tooltip: 'Manage Departments',
            onPressed: () => ManageDepartmentsDialog.show(context),
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
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Worker'),
        onPressed: () => controller.openAddWorkerDialog(context),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            controller.loadMoreWorkers();
          }
          return false;
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DepartmentSummaryCards(isCompact: true),
              const SizedBox(height: 16),
              _buildWorkersTableCard(context),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // DESKTOP TOP HEADER
  // -------------------------------------------------------------
  Widget _buildDesktopHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1.0,
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
                  'OPERATIONS',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Department & Worker Management',
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
                  tooltip: isBusy ? 'Refreshing...' : 'Refresh Records',
                  onPressed: isBusy ? null : controller.refreshAll,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
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
                  'Personnel & Staff',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                const Text(
                  'Workers',
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
              'Workers & Department Roster',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              text: 'Manage Departments',
              icon: PhosphorIconsRegular.buildings,
              variant: ButtonVariant.outlined,
              height: 42,
              onPressed: () => ManageDepartmentsDialog.show(context),
            ),
            const SizedBox(width: 12),
            CustomButton(
              text: 'Add Worker',
              icon: Icons.person_add_alt_1_rounded,
              height: 42,
              onPressed: () => controller.openAddWorkerDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // WORKERS TABLE CARD (Filters + Table + Pagination)
  // -------------------------------------------------------------
  Widget _buildWorkersTableCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final deptCtrl = Get.find<DepartmentController>();

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
          // ---------------------------------------------------------
          // FILTER & SEARCH BAR
          // ---------------------------------------------------------
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Filter & Search Bar
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(PhosphorIconsRegular.identificationCard, color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          'Worker Roster',
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
                              '${controller.totalWorkers.value} Total',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        Obx(() {
                          if (controller.isLoading.value && controller.workers.isNotEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: CustomInlineLoader(size: 14, strokeWidth: 1.8),
                            );
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
                          width: 230,
                          child: TextField(
                            controller: controller.searchController,
                            onChanged: (val) => controller.searchQuery.value = val,
                            decoration: InputDecoration(
                              hintText: 'Search worker name...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 18),
                              suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                              suffixIcon: Obx(
                                () => controller.searchQuery.value.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 16),
                                        splashRadius: 16,
                                        padding: const EdgeInsets.only(right: 8),
                                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                        onPressed: () {
                                          controller.searchController.clear();
                                          controller.searchQuery.value = '';
                                        },
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Status Filter Dropdown
                        Obx(
                          () => SizedBox(
                            width: 150,
                            child: CustomDropdownSearch<String>(
                              hint: 'All Status',
                              prefixIcon: PhosphorIconsRegular.funnel,
                              selectedItem: controller.selectedStatusFilter.value,
                              items: const ['all', 'active', 'inactive'],
                              itemAsString: (s) {
                                switch (s) {
                                  case 'active':
                                    return 'Active Only';
                                  case 'inactive':
                                    return 'Inactive / Left';
                                  default:
                                    return 'All Status';
                                }
                              },
                              onChanged: (s) => controller.setStatusFilter(s ?? 'all'),
                            ),
                          ),
                        ),

                        // Reset Filters Button
                        Obx(() {
                          final hasFilter = controller.searchQuery.value.isNotEmpty ||
                              controller.selectedDepartmentFilter.value != null ||
                              controller.selectedStatusFilter.value != 'all';

                          if (!hasFilter) return const SizedBox.shrink();

                          return Tooltip(
                            message: 'Reset All Filters',
                            child: InkWell(
                              onTap: controller.clearFilters,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.errorBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.filter_alt_off_rounded,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Compact Department Filter Chips Bar
                _buildDepartmentFilterChips(context, deptCtrl, isDark),
              ],
            ),
          ),
          const Divider(height: 1),

          // ---------------------------------------------------------
          // TABLE / LIST CONTENT
          // ---------------------------------------------------------
          Obx(() {
            if (controller.isLoading.value && controller.workers.isEmpty) {
              return const CustomTableShimmer(
                rowCount: 5,
                columnFlexes: [1, 4, 3, 3, 3, 2, 2],
                headers: ['#', 'WORKER NAME', 'DEPARTMENT', 'JOINING DATE', 'LEAVING DATE', 'STATUS', 'ACTIONS'],
              );
            }

            final isMobile = ResponsiveLayout.isMobile(context);
            final list = isMobile ? controller.mobileWorkers : controller.workers;
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 50.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(PhosphorIconsRegular.usersFour, size: 48, color: AppColors.textMutedLight),
                      const SizedBox(height: 12),
                      const Text(
                        'No Workers Found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        controller.searchQuery.value.isNotEmpty ||
                                controller.selectedDepartmentFilter.value != null ||
                                controller.selectedStatusFilter.value != 'all'
                            ? 'Try clearing active filters to see all registered workers.'
                            : 'No workers have been registered for this Gaushala yet.',
                        style: TextStyle(fontSize: 13, color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Add Worker',
                        icon: Icons.person_add_alt_1_rounded,
                        variant: ButtonVariant.outlined,
                        width: 140,
                        onPressed: () => controller.openAddWorkerDialog(context),
                      ),
                    ],
                  ),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth >= 720;

                if (!isWideScreen) {
                  // Tablet/Mobile Card list view with hover feedback
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        separatorBuilder: (context, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final worker = list[index];
                          return _HoverableWorkerMobileCard(
                            key: ValueKey('${worker.id}_${worker.isActive}_${worker.leavingDate}_${worker.isDelete}'),
                            worker: worker,
                            isDark: isDark,
                            onEdit: () => controller.openEditWorkerDialog(context, worker),
                            onMarkLeft: () => controller.openMarkLeftDialog(context, worker),
                            onToggleStatus: () => controller.toggleWorkerStatus(worker),
                            onDelete: () => controller.confirmDeleteWorker(context, worker),
                          );
                        },
                      ),
                      if (isMobile)
                        MobileListBottomLoader(
                          hasMore: controller.hasMoreMobile,
                          isLoading: controller.isLoadingMore.value,
                          totalCount: controller.totalWorkers.value,
                        ),
                    ],
                  );
                }

                // Desktop Table View (Matching Herd & Cattle Table Layout & Hover Experience)
                final tableWidth = constraints.maxWidth < 900 ? 900.0 : constraints.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark.withValues(alpha: 0.6)
                                : const Color(0xFFF9FAFB),
                            border: const Border(
                              left: BorderSide(color: Colors.transparent, width: 3.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildHeaderCell('#', width: 44),
                              _buildHeaderCell('WORKER NAME', flex: 4),
                              _buildHeaderCell('DEPARTMENT', flex: 3),
                              _buildHeaderCell('JOINING DATE', flex: 3),
                              _buildHeaderCell('LEAVING DATE', flex: 3),
                              _buildHeaderCell('STATUS', flex: 2),
                              _buildHeaderCell('ACTIONS', width: 130, alignment: Alignment.centerRight),
                            ],
                          ),
                        ),

                        // Table Data Rows with Herd & Cattle Animation Style
                        ...list.asMap().entries.map((entry) {
                          final index = entry.key;
                          final worker = entry.value;
                          final serial = ((controller.currentPage.value - 1) * controller.rowsPerPage.value) + index + 1;
                          return _HoverableWorkerTableRow(
                            key: ValueKey('${worker.id}_${worker.isActive}_${worker.leavingDate}_${worker.isDelete}'),
                            index: index,
                            serial: serial,
                            worker: worker,
                            isDark: isDark,
                            onEdit: () => controller.openEditWorkerDialog(context, worker),
                            onMarkLeft: () => controller.openMarkLeftDialog(context, worker),
                            onToggleStatus: () => controller.toggleWorkerStatus(worker),
                            onDelete: () => controller.confirmDeleteWorker(context, worker),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            );
          }),

          // ---------------------------------------------------------
          // PAGINATION FOOTER
          // ---------------------------------------------------------
          Obx(() {
            if (ResponsiveLayout.isMobile(context) || controller.totalWorkers.value == 0) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: CustomPagination(
                totalItems: controller.totalWorkers.value,
                currentPage: controller.currentPage.value,
                rowsPerPage: controller.rowsPerPage.value,
                rowsPerPageOptions: const [5, 10, 20, 50],
                onPageChanged: controller.setPage,
                onRowsPerPageChanged: controller.setRowsPerPage,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDepartmentFilterChips(
    BuildContext context,
    DepartmentController deptCtrl,
    bool isDark,
  ) {
    return Obx(() {
      final depts = deptCtrl.departments.toList();
      final selectedDeptId = controller.selectedDepartmentFilter.value;
      final summary = controller.summary.value;

      return Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _DepartmentFilterChip(
                    label: 'All Departments',
                    count: summary?.totalWorkers ?? controller.totalWorkers.value,
                    isSelected: selectedDeptId == null || selectedDeptId.isEmpty || selectedDeptId == 'all',
                    isDark: isDark,
                    onTap: () => controller.setDepartmentFilter(null),
                  ),
                  const SizedBox(width: 8),
                  ...depts.map((d) {
                    final isSelected = selectedDeptId == d.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _DepartmentFilterChip(
                        label: d.departmentName,
                        code: d.departmentCode,
                        count: d.workerStats.totalWorkers,
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () => controller.setDepartmentFilter(isSelected ? null : d.id),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Sleek Manage Departments Button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              mouseCursor: SystemMouseCursors.click,
              onTap: () => ManageDepartmentsDialog.show(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(PhosphorIconsRegular.gear, size: 14, color: AppColors.primary),
                    SizedBox(width: 5),
                    Text(
                      'Manage',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildHeaderCell(
    String title, {
    int? flex,
    double? width,
    Alignment alignment = Alignment.centerLeft,
  }) {
    final widget = Container(
      alignment: alignment,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: widget);
    }
    return Expanded(flex: flex ?? 1, child: widget);
  }
}

// ---------------------------------------------------------------------------
// ANIMATED WORKER STATUS CHIP
// ---------------------------------------------------------------------------
Widget _buildWorkerStatusChip(
  WorkerModel worker, {
  bool isHovered = false,
  bool isDark = false,
}) {
  final bool isActive = worker.isActive;
  final bool hasLeft = worker.leavingDate != null;

  final Color bgColor = isActive
      ? (isDark ? AppColors.success.withValues(alpha: isHovered ? 0.22 : 0.14) : AppColors.successBg)
      : (hasLeft
          ? (isDark ? AppColors.warning.withValues(alpha: isHovered ? 0.22 : 0.14) : AppColors.warningBg)
          : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)));

  final Color textColor = isActive
      ? (isDark ? AppColors.primaryLight : AppColors.success)
      : (hasLeft
          ? AppColors.warning
          : (isDark ? AppColors.textMutedDark : const Color(0xFF64748B)));

  final String label = isActive
      ? 'Active'
      : (hasLeft ? 'Left Gaushala' : 'Inactive');

  return AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    curve: Curves.easeInOut,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: textColor.withValues(alpha: isHovered ? 0.45 : 0.20),
        width: 0.8,
      ),
      boxShadow: isHovered
          ? [
              BoxShadow(
                color: textColor.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ]
          : [],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: isHovered ? 7 : 6,
          height: isHovered ? 7 : 6,
          decoration: BoxDecoration(
            color: textColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// COMPACT DEPARTMENT FILTER CHIP (SLEEK 1-CLICK PILL)
// ---------------------------------------------------------------------------
class _DepartmentFilterChip extends StatefulWidget {
  final String label;
  final String? code;
  final int count;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _DepartmentFilterChip({
    required this.label,
    this.code,
    required this.count,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_DepartmentFilterChip> createState() => _DepartmentFilterChipState();
}

class _DepartmentFilterChipState extends State<_DepartmentFilterChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isDark = widget.isDark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (_isHovered
                    ? (isDark ? AppColors.surfaceDark : AppColors.primary.withValues(alpha: 0.08))
                    : (isDark ? AppColors.surfaceDark : const Color(0xFFF7FAF4))),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (_isHovered
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : (isDark ? AppColors.borderDark : AppColors.borderLight)),
              width: isSelected || _isHovered ? 1.4 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : (_isHovered
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.code != null && widget.code!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.code!,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.count}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HOVERABLE WORKER TABLE ROW (DESKTOP - MATCHING HERD & CATTLE MODULE)
// ---------------------------------------------------------------------------
class _HoverableWorkerTableRow extends StatefulWidget {
  final int index;
  final int serial;
  final WorkerModel worker;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onMarkLeft;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _HoverableWorkerTableRow({
    super.key,
    required this.index,
    required this.serial,
    required this.worker,
    required this.isDark,
    required this.onEdit,
    required this.onMarkLeft,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  State<_HoverableWorkerTableRow> createState() => _HoverableWorkerTableRowState();
}

class _HoverableWorkerTableRowState extends State<_HoverableWorkerTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final worker = widget.worker;
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
              ? (isDark
                  ? AppColors.surfaceDark.withValues(alpha: 0.85)
                  : AppColors.primary.withValues(alpha: 0.045))
              : (widget.index.isEven
                  ? Colors.transparent
                  : (isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAFCF9))),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 0.6,
            ),
            left: BorderSide(
              color: _isHovered
                  ? (isDark ? AppColors.primaryLight : AppColors.primary)
                  : Colors.transparent,
              width: 3.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // # Serial
            SizedBox(
              width: 44,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: _isHovered ? FontWeight.bold : FontWeight.w500,
                  color: _isHovered
                      ? (isDark ? AppColors.primaryLight : AppColors.primary)
                      : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
                child: Text('${widget.serial}'),
              ),
            ),

            // Worker Avatar & Name
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeInOut,
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: _isHovered ? 0.22 : 0.12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: _isHovered ? 0.60 : 0.20),
                        width: 1.2,
                      ),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        worker.name.isNotEmpty ? worker.name.substring(0, 1).toUpperCase() : 'W',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 160),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: _isHovered ? FontWeight.w700 : FontWeight.w600,
                        color: _isHovered
                            ? (isDark ? Colors.white : AppColors.primary)
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                      child: Text(
                        worker.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Department Badge
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: _isHovered ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: _isHovered ? 0.45 : 0.22),
                      width: 1.0,
                    ),
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsRegular.buildings, size: 13, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          worker.departmentName ?? 'General Staff',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Joining Date
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.calendarCheck,
                    size: 14,
                    color: _isHovered
                        ? AppColors.primary
                        : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                  const SizedBox(width: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 160),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                      color: _isHovered
                          ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                    child: Text(
                      worker.joiningDate != null
                          ? DateFormat('dd MMM yyyy').format(worker.joiningDate!)
                          : '—',
                    ),
                  ),
                ],
              ),
            ),

            // Leaving Date
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Icon(
                    worker.leavingDate != null
                        ? PhosphorIconsRegular.signpost
                        : PhosphorIconsRegular.checkCircle,
                    size: 14,
                    color: worker.leavingDate != null
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 160),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: worker.leavingDate != null
                          ? (_isHovered ? FontWeight.w600 : FontWeight.normal)
                          : FontWeight.w600,
                      color: worker.leavingDate != null
                          ? (_isHovered
                              ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))
                          : AppColors.success,
                    ),
                    child: Text(
                      worker.leavingDate != null
                          ? DateFormat('dd MMM yyyy').format(worker.leavingDate!)
                          : 'Active on Duty',
                    ),
                  ),
                ],
              ),
            ),

            // Status Chip
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildWorkerStatusChip(worker, isHovered: _isHovered, isDark: isDark),
              ),
            ),

            // Actions
            SizedBox(
              width: 130,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Edit Worker
                  Tooltip(
                    message: 'Edit Worker',
                    waitDuration: const Duration(milliseconds: 300),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      mouseCursor: SystemMouseCursors.click,
                      hoverColor: AppColors.primary.withValues(alpha: 0.12),
                      onTap: widget.onEdit,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          PhosphorIconsRegular.pencilSimple,
                          size: 17,
                          color: _isHovered
                              ? AppColors.primary
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Mark as Left Gaushala / Reactivate
                  if (worker.isActive)
                    Tooltip(
                      message: 'Mark as Left Gaushala',
                      waitDuration: const Duration(milliseconds: 300),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        mouseCursor: SystemMouseCursors.click,
                        hoverColor: AppColors.warning.withValues(alpha: 0.12),
                        onTap: widget.onMarkLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            PhosphorIconsRegular.signpost,
                            size: 17,
                            color: _isHovered
                                ? AppColors.warning
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                        ),
                      ),
                    )
                  else
                    Tooltip(
                      message: 'Reactivate Worker',
                      waitDuration: const Duration(milliseconds: 300),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        mouseCursor: SystemMouseCursors.click,
                        hoverColor: AppColors.success.withValues(alpha: 0.12),
                        onTap: widget.onToggleStatus,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            size: 17,
                            color: _isHovered
                                ? AppColors.success
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),

                  // Delete (Soft delete)
                  Tooltip(
                    message: 'Delete Worker',
                    waitDuration: const Duration(milliseconds: 300),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      mouseCursor: SystemMouseCursors.click,
                      hoverColor: AppColors.error.withValues(alpha: 0.12),
                      onTap: widget.onDelete,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          PhosphorIconsRegular.trash,
                          size: 17,
                          color: _isHovered
                              ? AppColors.error
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ),
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

// ---------------------------------------------------------------------------
// HOVERABLE WORKER MOBILE & TABLET CARD
// ---------------------------------------------------------------------------
class _HoverableWorkerMobileCard extends StatefulWidget {
  final WorkerModel worker;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onMarkLeft;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _HoverableWorkerMobileCard({
    super.key,
    required this.worker,
    required this.isDark,
    required this.onEdit,
    required this.onMarkLeft,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  State<_HoverableWorkerMobileCard> createState() => _HoverableWorkerMobileCardState();
}

class _HoverableWorkerMobileCardState extends State<_HoverableWorkerMobileCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final worker = widget.worker;
    final isDark = widget.isDark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isHovered
              ? (isDark
                  ? AppColors.surfaceDark.withValues(alpha: 0.85)
                  : AppColors.primary.withValues(alpha: 0.035))
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: _isHovered
                  ? (isDark ? AppColors.primaryLight : AppColors.primary)
                  : Colors.transparent,
              width: 3.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: _isHovered ? 0.22 : 0.12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: _isHovered ? 0.60 : 0.20),
                          width: 1.2,
                        ),
                        boxShadow: _isHovered
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.18),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          worker.name.isNotEmpty ? worker.name.substring(0, 1).toUpperCase() : 'W',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          worker.departmentName ?? 'General Staff',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildWorkerStatusChip(worker, isHovered: _isHovered, isDark: isDark),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Joined: ${worker.joiningDate != null ? DateFormat('dd MMM yyyy').format(worker.joiningDate!) : "—"}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (worker.leavingDate != null)
                  Text(
                    'Left: ${DateFormat('dd MMM yyyy').format(worker.leavingDate!)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.warning),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 18, color: AppColors.primary),
                  tooltip: 'Edit Worker',
                  onPressed: widget.onEdit,
                ),
                if (worker.isActive)
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.signpost, size: 18, color: AppColors.warning),
                    tooltip: 'Mark as Left Gaushala',
                    onPressed: widget.onMarkLeft,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.success),
                    tooltip: 'Reactivate Worker',
                    onPressed: widget.onToggleStatus,
                  ),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.trash, size: 18, color: AppColors.error),
                  tooltip: 'Delete Worker',
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

