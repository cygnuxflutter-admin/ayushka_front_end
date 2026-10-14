import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/utils/responsive_layout.dart';
import '../../core/values/app_colors.dart';
import '../../core/values/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dropdown_search.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/widgets/custom_pagination.dart';
import '../../core/widgets/custom_shimmer.dart';
import '../../core/widgets/global_gaushala_selector.dart';
import '../../core/widgets/header_user_profile_badge.dart';
import '../../core/widgets/mobile_list_bottom_loader.dart';
import '../../core/widgets/notification_bell_widget.dart';
import '../../data/models/cow_heat_model.dart';
import '../../routes/app_routes.dart';
import '../dashboard/widgets/mobile_drawer.dart';
import '../dashboard/widgets/web_sidebar.dart';
import '../mating/dialogs/add_mating_dialog.dart';
import 'dialogs/add_heat_dialog.dart';
import 'dialogs/edit_heat_dialog.dart';
import 'dialogs/heat_details_dialog.dart';
import 'heat_controller.dart';

/// Screen for Cow Heat Management & Estrus Monitoring.
class HeatScreen extends GetView<HeatController> {
  const HeatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBuilder: (context) => _buildMobileScaffold(context),
      tabletBuilder: (context) => _buildTabletScaffold(context),
      desktopBuilder: (context) => _buildDesktopScaffold(context),
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP SCAFFOLD
  // ---------------------------------------------------------------------------
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

          // Main Workspace
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
                            _buildKpiSummaryCards(context),
                            const SizedBox(height: 20),
                            _buildAlertCalloutBanner(context),
                            const SizedBox(height: 20),
                            _buildHeatsTableCard(context),
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

  // ---------------------------------------------------------------------------
  // TABLET SCAFFOLD
  // ---------------------------------------------------------------------------
  Widget _buildTabletScaffold(BuildContext context) {
    return Scaffold(
      drawer: MobileDrawer(
        currentUser: controller.currentUser.value,
        onLogout: controller.logout,
      ),
      appBar: _buildMobileAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBreadcrumbAndActionBar(context),
            const SizedBox(height: 16),
            _buildKpiSummaryCards(context, isCompact: true),
            const SizedBox(height: 16),
            _buildAlertCalloutBanner(context),
            const SizedBox(height: 16),
            _buildHeatsTableCard(context),
          ],
        ),
      ),
      floatingActionButton: Obx(
        () => controller.canAddHeat
            ? FloatingActionButton.extended(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                onPressed: () => AddHeatDialog.show(context),
                icon: const Icon(PhosphorIconsRegular.plus),
                label: const Text('Record Heat'),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE SCAFFOLD
  // ---------------------------------------------------------------------------
  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      drawer: MobileDrawer(
        currentUser: controller.currentUser.value,
        onLogout: controller.logout,
      ),
      appBar: _buildMobileAppBar(context),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            controller.loadMoreMobileHeats();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: controller.refreshData,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMobileHeaderActions(context),
                      const SizedBox(height: 14),
                      _buildKpiSummaryCards(context, isCompact: true),
                      const SizedBox(height: 14),
                      _buildAlertCalloutBanner(context),
                      const SizedBox(height: 14),
                      _buildMobileFilterBar(context),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              _buildMobileHeatList(context),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
      floatingActionButton: Obx(
        () => controller.canAddHeat
            ? FloatingActionButton(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                onPressed: () => AddHeatDialog.show(context),
                child: const Icon(PhosphorIconsRegular.plus),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP TOP HEADER
  // ---------------------------------------------------------------------------
  Widget _buildDesktopHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 28),
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
              const Icon(PhosphorIconsRegular.fire, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Estrus & Cow Heat Management',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                  onPressed: isBusy ? null : controller.refreshData,
                );
              }),
              const SizedBox(width: 10),
              Obx(() => HeaderUserProfileBadge(user: controller.currentUser.value)),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Cow Heat Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      centerTitle: false,
      actions: [
        const NotificationBellWidget(),
        Obx(() {
          final isBusy = controller.isRefreshing.value || controller.isLoading.value;
          return IconButton(
            icon: isBusy
                ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                : const Icon(Icons.refresh_rounded),
            tooltip: isBusy ? 'Refreshing...' : 'Refresh',
            onPressed: isBusy ? null : controller.refreshData,
          );
        }),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMobileHeaderActions(BuildContext context) {
    return const GlobalGaushalaSelector();
  }

  // ---------------------------------------------------------------------------
  // BREADCRUMB & ACTION BAR
  // ---------------------------------------------------------------------------
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
                InkWell(
                  onTap: () => Get.offNamed(AppRoutes.dashboard),
                  child: Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => Get.offNamed(AppRoutes.cows),
                  child: Text(
                    'Cow Management',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                const Text(
                  'Heat Monitoring',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Cow Heat Records & Admin Alerts',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Obx(
          () => controller.canAddHeat
              ? CustomButton(
                  text: 'Record Heat Cycle',
                  icon: PhosphorIconsRegular.plus,
                  onPressed: () => AddHeatDialog.show(context),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // KPI SUMMARY STRIP
  // ---------------------------------------------------------------------------
  Widget _buildKpiSummaryCards(BuildContext context, {bool isCompact = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final active = controller.activeHeatAlerts.length;
      final readyForMating = controller.heats.where((h) => h.status == HeatStatus.readyForMating).length;
      final repeat = controller.repeatHeatAlerts.length;
      final total = controller.totalItems.value;

      final activeTile = _HoverableMetricTile(
        title: 'Active In Heat',
        value: '$active',
        subtitle: 'Detected estrus cycles',
        icon: PhosphorIconsRegular.fire,
        color: const Color(0xFFF59E0B),
        isDark: isDark,
        isCompact: isCompact,
        isSelected: controller.statusFilter.value == 'OBSERVED',
        onTap: () {
          if (controller.statusFilter.value == 'OBSERVED') {
            controller.setStatusFilter('ALL');
          } else {
            controller.setStatusFilter('OBSERVED');
          }
        },
      );

      final readyTile = _HoverableMetricTile(
        title: 'Ready for Mating',
        value: '$readyForMating',
        subtitle: 'Peak standing estrus',
        icon: PhosphorIconsRegular.heartStraight,
        color: AppColors.primary,
        isDark: isDark,
        isCompact: isCompact,
        isSelected: controller.statusFilter.value == 'READY_FOR_MATING',
        onTap: () {
          if (controller.statusFilter.value == 'READY_FOR_MATING') {
            controller.setStatusFilter('ALL');
          } else {
            controller.setStatusFilter('READY_FOR_MATING');
          }
        },
      );

      final repeatTile = _HoverableMetricTile(
        title: 'Repeat Heat Alerts',
        value: '$repeat',
        subtitle: '3+ consecutive cycles (High Alert)',
        icon: PhosphorIconsRegular.warningOctagon,
        color: const Color(0xFFEF4444),
        isDark: isDark,
        isCompact: isCompact,
        isSelected: controller.isRepeatFilter.value,
        onTap: controller.toggleRepeatFilter,
      );

      final totalTile = _HoverableMetricTile(
        title: 'Total Logged Cycles',
        value: '$total',
        subtitle: 'Cumulative historical',
        icon: PhosphorIconsRegular.chartLineUp,
        color: const Color(0xFF3B82F6),
        isDark: isDark,
        isCompact: isCompact,
        isSelected: controller.statusFilter.value == 'ALL' &&
            !controller.isRepeatFilter.value &&
            controller.stageFilter.value == 'ALL' &&
            controller.intensityFilter.value == 'ALL',
        onTap: controller.resetFilters,
      );

      if (isCompact) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isVeryNarrow = constraints.maxWidth < 420;
            if (isVeryNarrow) {
              return Column(
                children: [
                  activeTile,
                  const SizedBox(height: 8),
                  readyTile,
                  const SizedBox(height: 8),
                  repeatTile,
                  const SizedBox(height: 8),
                  totalTile,
                ],
              );
            }
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: activeTile),
                    const SizedBox(width: 8),
                    Expanded(child: readyTile),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: repeatTile),
                    const SizedBox(width: 8),
                    Expanded(child: totalTile),
                  ],
                ),
              ],
            );
          },
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 950;
          if (isNarrow) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: activeTile),
                    const SizedBox(width: 14),
                    Expanded(child: readyTile),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: repeatTile),
                    const SizedBox(width: 14),
                    Expanded(child: totalTile),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: activeTile),
              const SizedBox(width: 14),
              Expanded(child: readyTile),
              const SizedBox(width: 14),
              Expanded(child: repeatTile),
              const SizedBox(width: 14),
              Expanded(child: totalTile),
            ],
          );
        },
      );
    });
  }

  // ---------------------------------------------------------------------------
  // ALERT CALLOUT BANNER
  // ---------------------------------------------------------------------------
  Widget _buildAlertCalloutBanner(BuildContext context) {
    return Obx(() {
      final repeatCount = controller.repeatHeatAlerts.length;
      final activeCount = controller.activeHeatAlerts.length;

      if (repeatCount == 0 && activeCount == 0) return const SizedBox.shrink();

      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: repeatCount > 0
              ? Colors.red.withValues(alpha: 0.08)
              : Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: repeatCount > 0 ? Colors.red.shade300 : Colors.orange.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              repeatCount > 0 ? PhosphorIconsRegular.warningOctagon : PhosphorIconsRegular.fire,
              color: repeatCount > 0 ? Colors.red.shade700 : Colors.orange.shade700,
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    repeatCount > 0
                        ? 'High Priority Alert: $repeatCount Cow(s) with 3+ Consecutive Heat Cycles (Repeat Estrus)'
                        : 'Active Estrus Alert: $activeCount Cow(s) Currently In Standing Heat Ready For Mating',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: repeatCount > 0
                          ? (isDark ? Colors.red.shade300 : Colors.red.shade900)
                          : (isDark ? Colors.orange.shade300 : Colors.orange.shade900),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    repeatCount > 0
                        ? 'These cows have not conceived after consecutive estrus periods. Schedule immediate veterinary checkup for cystic ovarian disease or uterine infection.'
                        : 'Standing heat detected. Schedule natural service or artificial insemination within 12-18 hours of first standing observation for optimal conception rate.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (repeatCount > 0)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade400),
                ),
                onPressed: () {
                  controller.isRepeatFilter.value = true;
                  controller.fetchHeats();
                },
                icon: const Icon(PhosphorIconsRegular.funnel, size: 16),
                label: const Text('View Repeat Heats'),
              ),
          ],
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // HEATS TABLE CARD (DESKTOP & TABLET)
  // ---------------------------------------------------------------------------
  Widget _buildHeatsTableCard(BuildContext context) {
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
          // Filter Toolbar
          _buildDesktopFilterToolbar(context),
          const Divider(height: 1),

          // Table Content
          LayoutBuilder(
            builder: (context, constraints) {
              const double minTableWidth = 1260.0;
              final double tableWidth = constraints.maxWidth < minTableWidth
                  ? minTableWidth
                  : constraints.maxWidth;

              return Obx(() {
                if (controller.isLoading.value) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: const CustomTableShimmer(
                        rowCount: 6,
                        columnFlexes: [3, 3, 3, 2, 2, 4, 2, 3],
                        headers: [
                          '#',
                          'COW TAG / NAME',
                          'SHED & BREED',
                          'DATE & TIME',
                          'STAGE',
                          'INTENSITY',
                          'SIGNS',
                          'CYCLE #',
                          'STATUS',
                          'ACTIONS',
                        ],
                      ),
                    ),
                  );
                }

                final items = controller.paginatedHeats;
                if (items.isEmpty) {
                  return _buildEmptyState(context);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Table Header Row
                            Container(
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
                                  SizedBox(width: 50, child: _buildTableHeaderCell('#')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('COW TAG / NAME')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('SHED & BREED')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('DATE & TIME')),
                                  Expanded(flex: 2, child: _buildTableHeaderCell('STAGE')),
                                  Expanded(flex: 2, child: _buildTableHeaderCell('INTENSITY')),
                                  Expanded(flex: 4, child: _buildTableHeaderCell('SIGNS')),
                                  Expanded(flex: 2, child: _buildTableHeaderCell('CYCLE #')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('STATUS')),
                                  SizedBox(width: 140, child: _buildTableHeaderCell('ACTIONS', alignRight: true)),
                                ],
                              ),
                            ),

                            // Data Rows with Signature Hover Effect
                            ...items.asMap().entries.map((entry) {
                              final pageStartIndex = (controller.currentPage.value - 1) * controller.rowsPerPage.value;
                              final index = pageStartIndex + entry.key;
                              final heat = entry.value;
                              return _HoverableHeatTableRow(
                                key: ValueKey(heat.id),
                                index: index,
                                heat: heat,
                                isDark: isDark,
                                canEdit: controller.canEditHeat,
                                canDelete: controller.canDeleteHeat,
                                onView: () => HeatDetailsDialog.show(context, heat),
                                onLogMating: () => AddMatingDialog.show(context, preselectedHeat: heat),
                                onEdit: () => EditHeatDialog.show(context, heat),
                                onDelete: () => _confirmDeleteHeat(context, heat),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              });
            },
          ),

          // Pagination
          const Divider(height: 1),
          Obx(
            () => CustomPagination(
              currentPage: controller.currentPage.value,
              totalItems: controller.totalItems.value,
              rowsPerPage: controller.rowsPerPage.value,
              onPageChanged: controller.onPageChanged,
              onRowsPerPageChanged: controller.onRowsPerPageChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFilterToolbar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const statusMap = {
      'ALL': 'All Statuses',
      'OBSERVED': 'Observed / In Heat',
      'READY_FOR_MATING': 'Ready for Mating',
      'MATED': 'Mated / Inseminated',
      'MISSED': 'Missed Heat',
      'EXPIRED': 'Expired / Passed',
    };
    final statusItems = statusMap.values.toList();

    const stageMap = {
      'ALL': 'All Stages',
      'EARLY': 'Proestrus (Early)',
      'STANDING': 'Estrus (Standing)',
      'LATE': 'Metestrus (Late)',
      'DIESTRUS': 'Diestrus (Resting)',
    };
    final stageItems = stageMap.values.toList();

    const intensityMap = {
      'ALL': 'All Intensities',
      'MILD': 'Mild Intensity',
      'MODERATE': 'Moderate Intensity',
      'STRONG': 'Strong / Peak',
    };
    final intensityItems = intensityMap.values.toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 980;

          final titleRow = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(PhosphorIconsRegular.fire, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Cow Heat Records',
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
                    '${controller.totalItems.value} Listed',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Obx(() {
                if ((controller.isLoading.value || controller.isRefreshing.value) && controller.heats.isNotEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: CustomInlineLoader(size: 14, strokeWidth: 1.8),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          );

          final filterControls = Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Search Box with clear button
              SizedBox(
                width: 240,
                child: TextField(
                  controller: controller.searchController,
                  onChanged: controller.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search cow tag, calf name...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: Obx(
                      () => controller.searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: controller.clearSearch,
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
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Status Filter using CustomDropdownSearch
              Obx(() {
                final currentDisplay = statusMap[controller.statusFilter.value] ?? 'All Statuses';
                return SizedBox(
                  width: 195,
                  child: CustomDropdownSearch<String>(
                    hint: 'All Statuses',
                    prefixIcon: PhosphorIconsRegular.fire,
                    selectedItem: currentDisplay,
                    items: statusItems,
                    itemAsString: (s) => s,
                    showClearButton: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                    onChanged: (val) {
                      if (val != null) {
                        final match = statusMap.entries.firstWhere(
                          (e) => e.value == val,
                          orElse: () => const MapEntry('ALL', 'All Statuses'),
                        );
                        controller.setStatusFilter(match.key);
                      }
                    },
                  ),
                );
              }),

              // Stage Filter using CustomDropdownSearch
              Obx(() {
                final currentDisplay = stageMap[controller.stageFilter.value] ?? 'All Stages';
                return SizedBox(
                  width: 185,
                  child: CustomDropdownSearch<String>(
                    hint: 'All Stages',
                    prefixIcon: PhosphorIconsRegular.clock,
                    selectedItem: currentDisplay,
                    items: stageItems,
                    itemAsString: (s) => s,
                    showClearButton: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                    onChanged: (val) {
                      if (val != null) {
                        final match = stageMap.entries.firstWhere(
                          (e) => e.value == val,
                          orElse: () => const MapEntry('ALL', 'All Stages'),
                        );
                        controller.setStageFilter(match.key);
                      }
                    },
                  ),
                );
              }),

              // Intensity Filter using CustomDropdownSearch
              Obx(() {
                final currentDisplay = intensityMap[controller.intensityFilter.value] ?? 'All Intensities';
                return SizedBox(
                  width: 180,
                  child: CustomDropdownSearch<String>(
                    hint: 'All Intensities',
                    prefixIcon: PhosphorIconsRegular.chartBar,
                    selectedItem: currentDisplay,
                    items: intensityItems,
                    itemAsString: (s) => s,
                    showClearButton: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                    onChanged: (val) {
                      if (val != null) {
                        final match = intensityMap.entries.firstWhere(
                          (e) => e.value == val,
                          orElse: () => const MapEntry('ALL', 'All Intensities'),
                        );
                        controller.setIntensityFilter(match.key);
                      }
                    },
                  ),
                );
              }),

              // Repeat Heat Alert Toggle
              Obx(
                () => FilterChip(
                  avatar: Icon(
                    PhosphorIconsRegular.warningOctagon,
                    size: 16,
                    color: controller.isRepeatFilter.value ? Colors.white : Colors.red,
                  ),
                  label: const Text('Repeat Alerts (3+)'),
                  selected: controller.isRepeatFilter.value,
                  selectedColor: Colors.red.shade700,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: controller.isRepeatFilter.value ? Colors.white : null,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (_) => controller.toggleRepeatFilter(),
                ),
              ),

              // Reset Filters Button
              Obx(() {
                final hasActiveFilter = controller.searchQuery.value.isNotEmpty ||
                    controller.statusFilter.value != 'ALL' ||
                    controller.stageFilter.value != 'ALL' ||
                    controller.intensityFilter.value != 'ALL' ||
                    controller.isRepeatFilter.value;
                if (!hasActiveFilter) return const SizedBox.shrink();
                return Tooltip(
                  message: 'Reset Filters',
                  child: InkWell(
                    onTap: controller.resetFilters,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(PhosphorIconsRegular.arrowCounterClockwise, size: 16),
                          SizedBox(width: 6),
                          Text('Reset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleRow,
                const SizedBox(height: 14),
                filterControls,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              titleRow,
              Flexible(child: filterControls),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTableHeaderCell(String title, {bool alignRight = false, bool alignCenter = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Text(
        title,
        textAlign: alignCenter
            ? TextAlign.center
            : (alignRight ? TextAlign.right : TextAlign.left),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  static Widget _buildRowActionIcon({
    required String tooltip,
    required IconData icon,
    required Color color,
    required Color hoverColor,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        mouseCursor: SystemMouseCursors.click,
        hoverColor: hoverColor.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }

  void _confirmDeleteHeat(BuildContext context, CowHeatModel heat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Heat Record'),
        content: Text('Are you sure you want to delete the heat cycle record for ${heat.cowTagId}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.deleteHeat(heat);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isSearching = controller.searchQuery.value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off_rounded : PhosphorIconsRegular.fire,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No Matching Cow Heat Records' : 'No Cow Heat Records Found',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'No records match "${controller.searchQuery.value}". Check spelling or try a different term.'
                  : 'No estrus cycles match your current filters. Try resetting filters or log a new heat cycle.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (isSearching)
              OutlinedButton.icon(
                icon: const Icon(Icons.clear_rounded, size: 16),
                label: const Text('Clear Search'),
                onPressed: controller.clearSearch,
              )
            else if (controller.canAddHeat)
              CustomButton(
                text: 'Record Heat Cycle',
                icon: PhosphorIconsRegular.plus,
                onPressed: () => AddHeatDialog.show(context),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE VIEWS
  // ---------------------------------------------------------------------------
  Widget _buildMobileFilterBar(BuildContext context) {
    const statusMap = {
      'ALL': 'All Statuses',
      'OBSERVED': 'In Heat',
      'READY_FOR_MATING': 'Ready',
      'MATED': 'Mated',
      'MISSED': 'Missed',
      'EXPIRED': 'Passed',
    };

    return Column(
      children: [
        TextField(
          controller: controller.searchController,
          onChanged: controller.onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search cow tag, calf name...',
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
            suffixIcon: Obx(
              () => controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: controller.clearSearch,
                    )
                  : const SizedBox.shrink(),
            ),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Obx(() {
                final currentDisplay = statusMap[controller.statusFilter.value] ?? 'All Statuses';
                return CustomDropdownSearch<String>(
                  hint: 'Status',
                  prefixIcon: PhosphorIconsRegular.fire,
                  selectedItem: currentDisplay,
                  items: statusMap.values.toList(),
                  itemAsString: (s) => s,
                  showClearButton: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  onChanged: (val) {
                    if (val != null) {
                      final match = statusMap.entries.firstWhere(
                        (e) => e.value == val,
                        orElse: () => const MapEntry('ALL', 'All Statuses'),
                      );
                      controller.setStatusFilter(match.key);
                    }
                  },
                );
              }),
            ),
            const SizedBox(width: 8),
            Obx(
              () => FilterChip(
                avatar: Icon(
                  PhosphorIconsRegular.warningOctagon,
                  size: 14,
                  color: controller.isRepeatFilter.value ? Colors.white : Colors.red,
                ),
                label: const Text('Repeat', style: TextStyle(fontSize: 12)),
                selected: controller.isRepeatFilter.value,
                selectedColor: Colors.red.shade700,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: controller.isRepeatFilter.value ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => controller.toggleRepeatFilter(),
              ),
            ),
            Obx(() {
              final hasActive = controller.searchQuery.value.isNotEmpty ||
                  controller.statusFilter.value != 'ALL' ||
                  controller.stageFilter.value != 'ALL' ||
                  controller.intensityFilter.value != 'ALL' ||
                  controller.isRepeatFilter.value;
              if (!hasActive) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise, size: 18),
                tooltip: 'Reset',
                onPressed: controller.resetFilters,
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileHeatList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.mobileHeats.isEmpty) {
        return SliverToBoxAdapter(
          child: SizedBox(height: 200, child: Center(child: CustomBrandedSpinner())),
        );
      }

      final items = controller.mobileDisplayHeats;
      if (items.isEmpty) {
        return SliverToBoxAdapter(child: _buildEmptyState(context));
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == items.length) {
              return MobileListBottomLoader(
                hasMore: controller.hasMoreMobileItems,
                isLoading: controller.isLoadingMore.value,
              );
            }
            final heat = items[index];
            return _HoverableHeatMobileCard(
              key: ValueKey(heat.id),
              heat: heat,
              isDark: Theme.of(context).brightness == Brightness.dark,
              onView: () => HeatDetailsDialog.show(context, heat),
              onLogMating: () => AddMatingDialog.show(context, preselectedHeat: heat),
            );
          },
          childCount: items.length + (controller.hasMoreMobileItems ? 1 : 0),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// HOVERABLE HEAT TABLE ROW (DESKTOP)
// ---------------------------------------------------------------------------
class _HoverableHeatTableRow extends StatefulWidget {
  final int index;
  final CowHeatModel heat;
  final bool isDark;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onView;
  final VoidCallback onLogMating;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HoverableHeatTableRow({
    super.key,
    required this.index,
    required this.heat,
    required this.isDark,
    required this.canEdit,
    required this.canDelete,
    required this.onView,
    required this.onLogMating,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_HoverableHeatTableRow> createState() => _HoverableHeatTableRowState();
}

class _HoverableHeatTableRowState extends State<_HoverableHeatTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final heat = widget.heat;
    final isDark = widget.isDark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: _isHovered
              ? (isDark
                  ? AppColors.surfaceDark.withValues(alpha: 0.85)
                  : AppColors.primary.withValues(alpha: 0.045))
              : Colors.transparent,
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
        child: InkWell(
          onTap: widget.onView,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 0. # Index
                SizedBox(
                  width: 50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 160),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _isHovered ? FontWeight.bold : FontWeight.w500,
                        color: _isHovered
                            ? (isDark ? AppColors.primaryLight : AppColors.primary)
                            : AppColors.textSecondaryLight,
                      ),
                      child: Text('${widget.index + 1}'),
                    ),
                  ),
                ),

                // 1. COW TAG / NAME
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 160),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _isHovered
                                ? (isDark ? AppColors.primaryLight : AppColors.primary)
                                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          ),
                          child: Text(heat.cowTagId),
                        ),
                        if (heat.cowCalfName != null && heat.cowCalfName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              heat.cowCalfName!,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // 2. SHED & BREED
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          heat.cowShedName ?? 'Unassigned',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          heat.cowBreedName ?? 'Indigenous',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. DATE & TIME
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          heat.formattedHeatDate,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (heat.heatTime ?? 'Morning').capitalizeFirst ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. STAGE
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: heat.isStanding
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : Colors.grey.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            heat.heatStage.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: heat.isStanding ? FontWeight.bold : FontWeight.w500,
                              color: heat.isStanding ? AppColors.primary : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 5. INTENSITY
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: heat.intensity.bgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            heat.intensity.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: heat.intensity.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 6. SIGNS
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: heat.heatSigns.isEmpty
                        ? Text(
                            'None',
                            style: TextStyle(
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              fontSize: 11,
                            ),
                          )
                        : Text(
                            heat.heatSigns.map(HeatSignDefinition.getLabel).join(', '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                  ),
                ),

                // 7. CYCLE #
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#${heat.consecutiveHeatCount}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            if (heat.isHighAlert) ...[
                              const SizedBox(width: 6),
                              Tooltip(
                                message: 'High Alert: ${heat.consecutiveHeatCount} consecutive cycles without conception',
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(PhosphorIconsRegular.warning, color: Colors.white, size: 10),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 8. STATUS
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: heat.status.bgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: heat.status.color.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(heat.status.icon, size: 12, color: heat.status.color),
                              const SizedBox(width: 5),
                              Text(
                                heat.status.label,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: heat.status.color),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 9. ACTIONS
                SizedBox(
                  width: 140,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        HeatScreen._buildRowActionIcon(
                          tooltip: 'View Details',
                          icon: PhosphorIconsRegular.eye,
                          color: _isHovered
                              ? AppColors.primary
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          hoverColor: AppColors.primary,
                          onTap: widget.onView,
                        ),
                        if (heat.status != HeatStatus.mated) ...[
                          const SizedBox(width: 4),
                          HeatScreen._buildRowActionIcon(
                            tooltip: 'Record Mating',
                            icon: PhosphorIconsRegular.heartStraight,
                            color: AppColors.primary,
                            hoverColor: AppColors.primary,
                            onTap: widget.onLogMating,
                          ),
                        ],
                        if (widget.canEdit) ...[
                          const SizedBox(width: 4),
                          HeatScreen._buildRowActionIcon(
                            tooltip: 'Edit Record',
                            icon: PhosphorIconsRegular.pencilSimple,
                            color: _isHovered
                                ? Colors.blue.shade600
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            hoverColor: Colors.blue.shade600,
                            onTap: widget.onEdit,
                          ),
                        ],
                        if (widget.canDelete) ...[
                          const SizedBox(width: 4),
                          HeatScreen._buildRowActionIcon(
                            tooltip: 'Delete Record',
                            icon: PhosphorIconsRegular.trash,
                            color: _isHovered
                                ? AppColors.error
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            hoverColor: AppColors.error,
                            onTap: widget.onDelete,
                          ),
                        ],
                      ],
                    ),
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

// ---------------------------------------------------------------------------
// HOVERABLE HEAT MOBILE CARD (TABLET / MOBILE)
// ---------------------------------------------------------------------------
class _HoverableHeatMobileCard extends StatefulWidget {
  final CowHeatModel heat;
  final bool isDark;
  final VoidCallback onView;
  final VoidCallback onLogMating;

  const _HoverableHeatMobileCard({
    super.key,
    required this.heat,
    required this.isDark,
    required this.onView,
    required this.onLogMating,
  });

  @override
  State<_HoverableHeatMobileCard> createState() => _HoverableHeatMobileCardState();
}

class _HoverableHeatMobileCardState extends State<_HoverableHeatMobileCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final heat = widget.heat;
    final isDark = widget.isDark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onView,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? (isDark ? AppColors.primaryLight : AppColors.primary)
                  : (heat.isHighAlert
                      ? Colors.red.shade300
                      : (isDark ? AppColors.borderDark : AppColors.borderLight)),
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: _isHovered ? 10 : 3,
                offset: Offset(0, _isHovered ? 3 : 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        heat.cowTagId,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _isHovered ? (isDark ? AppColors.primaryLight : AppColors.primary) : null,
                        ),
                      ),
                      if (heat.isHighAlert) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                          child: const Text('REPEAT ALERT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: heat.status.bgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      heat.status.label,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: heat.status.color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Stage: ${heat.heatStage.label} • Intensity: ${heat.intensity.label} • Cycle #${heat.consecutiveHeatCount}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                'Observed: ${heat.formattedHeatDate} (${heat.heatTime ?? 'Morning'})',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onView,
                    child: const Text('Details'),
                  ),
                  if (heat.status != HeatStatus.mated) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: widget.onLogMating,
                      child: const Text('Record Mating', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interactive hoverable metric card for Heat & Estrus Monitoring summary metrics.
/// Features smooth 3D elevation floating, glowing shadow in metric accent color,
/// border highlight, and clickable filter actions matching Herd and Treatment modules.
class _HoverableMetricTile extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool isCompact;
  final VoidCallback? onTap;
  final bool isSelected;

  const _HoverableMetricTile({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    this.isCompact = false,
    this.onTap,
    this.isSelected = false,
  });

  @override
  State<_HoverableMetricTile> createState() => _HoverableMetricTileState();
}

class _HoverableMetricTileState extends State<_HoverableMetricTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color;
    final isDark = widget.isDark;

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 10 : 18,
            vertical: widget.isCompact ? 10 : 16,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? (_isHovered ? AppColors.surfaceDark : AppColors.cardDark)
                : (_isHovered ? Colors.white : AppColors.cardLight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered || widget.isSelected
                  ? effectiveColor.withValues(alpha: 0.60)
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: widget.isSelected ? 1.6 : 1.0,
            ),
            boxShadow: [
              if (_isHovered) ...[
                BoxShadow(
                  color: effectiveColor.withValues(alpha: 0.18),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ] else if (widget.isSelected) ...[
                BoxShadow(
                  color: effectiveColor.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ] else ...[
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.all(widget.isCompact ? 8 : 12),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: _isHovered || widget.isSelected ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.icon,
                  color: effectiveColor,
                  size: widget.isCompact ? 18 : 22,
                ),
              ),
              SizedBox(width: widget.isCompact ? 8 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.isCompact ? 11 : 12,
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.isCompact ? 15 : 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

