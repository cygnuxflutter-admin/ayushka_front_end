import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/utils/responsive_layout.dart';
import '../../core/values/app_colors.dart';
import '../../core/values/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/widgets/custom_pagination.dart';
import '../../core/widgets/custom_shimmer.dart';
import '../../core/widgets/mobile_list_bottom_loader.dart';
import '../../core/widgets/global_gaushala_selector.dart';
import '../../core/widgets/header_user_profile_badge.dart';
import '../../data/models/treatment_model.dart';
import '../../routes/app_routes.dart';
import '../dashboard/widgets/mobile_drawer.dart';
import '../dashboard/widgets/web_sidebar.dart';
import '../notification/widgets/notification_bell_widget.dart';
import 'treatment_controller.dart';

/// Screen 1: Cow Treatment Dashboard & Multi-Dose Management Screen
class TreatmentListScreen extends GetView<TreatmentController> {
  const TreatmentListScreen({super.key});

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
          // Persistent Web Sidebar
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
                // Desktop Header
                _buildDesktopHeader(context),

                // Main Content Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Breadcrumbs & Action Bar
                            _buildBreadcrumbAndActionBar(context),
                            const SizedBox(height: 20),

                            // Top Summary Cards
                            _buildTopSummaryCards(context),
                            const SizedBox(height: 24),

                            // Today Due Doses Alert Banner
                            _buildTodayDueBanner(context),

                            // Treatments Table Card with integrated header & pagination
                            _buildTreatmentsTableCard(context),
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
      appBar: AppBar(
        title: const Text('Cow Treatment Management'),
        actions: [
          const NotificationBellWidget(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: controller.refreshData,
          ),
          const SizedBox(width: 8),
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
            _buildTopSummaryCards(context, isCompact: true),
            const SizedBox(height: 16),
            _buildTodayDueBanner(context),
            const SizedBox(height: 16),
            _buildSearchAndFiltersMobile(context),
            const SizedBox(height: 16),
            _buildTreatmentsCardsList(context),
            const SizedBox(height: 16),
            _buildPaginationBar(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Case', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => controller.openAddTreatmentDialog(context),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE SCAFFOLD
  // ---------------------------------------------------------------------------
  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Treatments & Doses'),
        actions: [
          const NotificationBellWidget(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: controller.refreshData,
          ),
        ],
      ),
      drawer: Obx(
        () => MobileDrawer(
          currentUser: controller.currentUser.value,
          onLogout: controller.logout,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
              controller.loadMoreMobileTreatments();
            }
            return false;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildTopSummaryCards(context, isCompact: true),
                const SizedBox(height: 14),
                _buildTodayDueBanner(context),
                const SizedBox(height: 14),
                _buildSearchAndFiltersMobile(context),
                const SizedBox(height: 14),
                _buildTreatmentsCardsList(context),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Case', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => controller.openAddTreatmentDialog(context),
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
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                    'VETERINARY',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Flexible(
                  child: Text(
                    'Cow Treatment & Multi-Dose Veterinary Schedules',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Global Gaushala Selector
              const GlobalGaushalaSelector(),
              const SizedBox(width: 8),

              // In-App Notification Bell with Live Red Badge
              const NotificationBellWidget(),
              const SizedBox(width: 8),

              // Refresh Button
              Obx(() {
                final isBusy = controller.isRefreshing.value || controller.isLoading.value;
                return IconButton(
                  icon: isBusy
                      ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                      : const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: isBusy ? 'Refreshing...' : 'Refresh Treatment Cases',
                  onPressed: isBusy ? null : controller.refreshData,
                );
              }),
              const SizedBox(width: 8),

              // User Profile Avatar
              Obx(() => HeaderUserProfileBadge(user: controller.currentUser.value)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BREADCRUMB & ACTION BAR (Herd & Cattle Style)
  // ---------------------------------------------------------------------------
  Widget _buildBreadcrumbAndActionBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isStackNeeded = constraints.maxWidth < 990;

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                  'Cow Treatments',
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
              'Cow Treatments & Veterinary Care',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Comprehensive multi-dose antibiotic logs, vital symptoms, and recovery schedules.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
            ),
          ],
        );

        final actionButtons = Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Obx(
              () => CustomButton(
                text: 'Due Doses Today',
                icon: PhosphorIconsRegular.clockAfternoon,
                variant: controller.filterOnlyDueToday.value ? ButtonVariant.primary : ButtonVariant.outlined,
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                onPressed: () => controller.toggleDueTodayFilter(),
              ),
            ),
            CustomButton(
              text: 'Add Treatment Case',
              icon: Icons.add_rounded,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: () => controller.openAddTreatmentDialog(context),
            ),
          ],
        );

        if (isStackNeeded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              const SizedBox(height: 16),
              actionButtons,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: titleSection),
            const SizedBox(width: 16),
            actionButtons,
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TOP SUMMARY CARDS (Active, Critical, Due Doses Today, Recovered)
  // ---------------------------------------------------------------------------
  Widget _buildTopSummaryCards(BuildContext context, {bool isCompact = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final s = controller.summary.value;

      final activeTile = _HoverableMetricTile(
        title: 'Active Cases',
        value: '${s.activeCases}',
        subtitle: 'Under treatment protocol',
        icon: PhosphorIconsRegular.firstAid,
        color: const Color(0xFF3B82F6),
        isDark: isDark,
        isCompact: isCompact,
        isSelected: controller.statusFilter.value == 'UNDER_TREATMENT',
        onTap: () {
          if (controller.statusFilter.value == 'UNDER_TREATMENT') {
            controller.setStatusFilter('ALL');
          } else {
            controller.setStatusFilter('UNDER_TREATMENT');
          }
        },
      );

      final criticalTile = _HoverableMetricTile(
        title: 'Critical Cases',
        value: '${s.criticalCases}',
        subtitle: 'High attention required',
        icon: PhosphorIconsRegular.warningOctagon,
        color: const Color(0xFFEF4444),
        isDark: isDark,
        isCompact: isCompact,
        isSelected: controller.severityFilter.value == 'CRITICAL',
        onTap: () {
          if (controller.severityFilter.value == 'CRITICAL') {
            controller.setSeverityFilter('ALL');
          } else {
            controller.setSeverityFilter('CRITICAL');
          }
        },
      );

      final dueTile = _HoverableMetricTile(
        title: 'Due Doses Today',
        value: '${s.todayDueDoses}',
        subtitle: 'Doses scheduled today',
        icon: PhosphorIconsRegular.clockAfternoon,
        color: const Color(0xFFF59E0B),
        isDark: isDark,
        isCompact: isCompact,
        isSelected: controller.filterOnlyDueToday.value,
        onTap: () => controller.toggleDueTodayFilter(),
      );

      final recoveredTile = _HoverableMetricTile(
        title: 'Recovered This Month',
        value: '${s.recoveredThisMonth}',
        subtitle: 'Discharged & cured',
        icon: PhosphorIconsRegular.checkCircle,
        color: const Color(0xFF10B981),
        isDark: isDark,
        isCompact: isCompact,
        isSelected: controller.statusFilter.value == 'RECOVERED',
        onTap: () {
          if (controller.statusFilter.value == 'RECOVERED') {
            controller.setStatusFilter('ALL');
          } else {
            controller.setStatusFilter('RECOVERED');
          }
        },
      );

      if (isCompact) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: activeTile),
                const SizedBox(width: 8),
                Expanded(child: criticalTile),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: dueTile),
                const SizedBox(width: 8),
                Expanded(child: recoveredTile),
              ],
            ),
          ],
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
                    Expanded(child: criticalTile),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: dueTile),
                    const SizedBox(width: 14),
                    Expanded(child: recoveredTile),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: activeTile),
              const SizedBox(width: 16),
              Expanded(child: criticalTile),
              const SizedBox(width: 16),
              Expanded(child: dueTile),
              const SizedBox(width: 16),
              Expanded(child: recoveredTile),
            ],
          );
        },
      );
    });
  }

  // ---------------------------------------------------------------------------
  // TODAY DUE DOSES BANNER
  // ---------------------------------------------------------------------------
  Widget _buildTodayDueBanner(BuildContext context) {
    return Obx(() {
      final dueCount = controller.todayDueTreatments.isNotEmpty
          ? controller.todayDueTreatments.length
          : controller.summary.value.todayDueDoses;
      if (dueCount <= 0) return const SizedBox.shrink();

      final isFiltered = controller.filterOnlyDueToday.value;

      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;

            final bannerText = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'TODAY DUE DOSES ALERT ($dueCount Case${dueCount > 1 ? 's' : ''})',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                        letterSpacing: 0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'ACTION REQUIRED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Cattle treatments have doses scheduled for administration today. Ensure timely medicine delivery.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: const Color(0xFF78350F).withValues(alpha: 0.85),
                  ),
                ),
              ],
            );

            final viewBtn = ElevatedButton.icon(
              onPressed: () => controller.toggleDueTodayFilter(),
              icon: Icon(
                isFiltered ? PhosphorIconsRegular.arrowCounterClockwise : PhosphorIconsRegular.eye,
                size: 16,
              ),
              label: Text(isFiltered ? 'Show All Cases' : 'View Due Doses'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB45309),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(PhosphorIconsRegular.syringe, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: bannerText),
                    ],
                  ),
                  const SizedBox(height: 12),
                  viewBtn,
                ],
              );
            }

            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(PhosphorIconsRegular.syringe, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(child: bannerText),
                const SizedBox(width: 14),
                viewBtn,
              ],
            );
          },
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // DESKTOP TREATMENTS TABLE CARD (Integrated Header, Filters & Pagination)
  // ---------------------------------------------------------------------------
  Widget _buildTreatmentsTableCard(BuildContext context) {
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
          // Filter & Search bar header (exact Cattle Records layout & styling)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.firstAidKit, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Treatment Records',
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
                      if ((controller.isLoading.value || controller.isRefreshing.value) && controller.treatments.isNotEmpty) {
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
                    // Status Filter Dropdown
                    _buildStatusFilterDropdown(context, isDark),
                    // Severity Filter Dropdown
                    _buildSeverityFilterDropdown(context, isDark),
                    // Search box
                    SizedBox(
                      width: 240,
                      child: TextField(
                        controller: controller.searchController,
                        onChanged: (val) => controller.searchQuery.value = val,
                        decoration: InputDecoration(
                          hintText: 'Search Tag ID, disease...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          suffixIcon: Obx(
                            () => controller.searchQuery.value.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16),
                                    onPressed: () {
                                      controller.searchController.clear();
                                      controller.searchQuery.value = '';
                                      controller.fetchTreatments();
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
                    // Reset filter button
                    Obx(() {
                      final hasFilter = controller.searchQuery.value.isNotEmpty ||
                          controller.statusFilter.value != 'ALL' ||
                          controller.severityFilter.value != 'ALL' ||
                          controller.filterOnlyDueToday.value;
                      if (!hasFilter) return const SizedBox.shrink();
                      return Tooltip(
                        message: 'Reset Filters',
                        child: InkWell(
                          onTap: controller.clearFilters,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              ),
                            ),
                            child: const Icon(PhosphorIconsRegular.arrowCounterClockwise, size: 18),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content: Table or Loading Shimmer or Empty
          LayoutBuilder(
            builder: (context, constraints) {
              const double minTableWidth = 1180.0;
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
                        columnFlexes: [3, 4, 5, 3, 4, 3, 3, 3],
                        headers: [
                          '#',
                          'TREATMENT #',
                          'COW TAG / NAME',
                          'DISEASE & SYMPTOMS',
                          'SEVERITY',
                          'DOSES PROGRESS',
                          'NEXT DOSE',
                          'STATUS',
                          'ACTIONS',
                        ],
                      ),
                    ),
                  );
                }

                final items = controller.treatments;

                if (items.isEmpty) {
                  return _buildEmptyTreatmentsState(context, isDark);
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
                            // Table Header
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
                                  Expanded(flex: 3, child: _buildTableHeaderCell('TREATMENT #')),
                                  Expanded(flex: 4, child: _buildTableHeaderCell('COW TAG / NAME')),
                                  Expanded(flex: 5, child: _buildTableHeaderCell('DISEASE & SYMPTOMS')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('SEVERITY')),
                                  Expanded(flex: 4, child: _buildTableHeaderCell('DOSES PROGRESS')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('NEXT DOSE')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('STATUS')),
                                  SizedBox(width: 155, child: _buildTableHeaderCell('ACTIONS', alignRight: true)),
                                ],
                              ),
                            ),

                            // Table Data Rows
                            ...items.asMap().entries.map((entry) {
                              final pageStartIndex = (controller.currentPage.value - 1) * controller.rowsPerPage.value;
                              final index = pageStartIndex + entry.key;
                              final t = entry.value;
                              return _HoverableTreatmentTableRow(
                                key: ValueKey(t.id),
                                index: index,
                                treatment: t,
                                isDark: isDark,
                                onView: () => controller.goToTreatmentDetails(t, context),
                                onAdministerDose: () => controller.openAdministerDoseDialog(context, t),
                                onChangeStatus: () => controller.openChangeStatusDialog(context, t),
                                onDelete: () => controller.deleteTreatment(context, t),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    // Integrated Pagination Bar inside Table Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _buildPaginationBar(context),
                    ),
                  ],
                );
              });
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // SEVERITY FILTER DROPDOWN (App-style DropdownSearch)
  // ---------------------------------------------------------------------------
  Widget _buildSeverityFilterDropdown(BuildContext context, bool isDark, {bool isExpanded = false}) {
    return Obx(() {
      final selected = controller.severityFilter.value;
      const severityMap = {
        'ALL': 'All Severities',
        'MILD': 'Mild Severity',
        'MODERATE': 'Moderate Severity',
        'CRITICAL': 'Critical Severity',
      };
      final selectedLabel = severityMap[selected] ?? 'All Severities';
      final items = severityMap.values.toList();

      return SizedBox(
        width: isExpanded ? double.infinity : 165,
        child: DropdownSearch<String>(
          items: (filter, infiniteScrollProps) => items,
          selectedItem: selectedLabel,
          compareFn: (i1, i2) => i1 == i2,
          onSelected: (selected) {
            if (selected != null) {
              final match = severityMap.entries.firstWhere(
                (e) => e.value == selected,
                orElse: () => const MapEntry('ALL', 'All Severities'),
              );
              controller.setSeverityFilter(match.key);
            }
          },
          popupProps: PopupProps.menu(
            fit: FlexFit.loose,
            menuProps: MenuProps(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
              elevation: 8,
            ),
            itemBuilder: (ctx, item, isDisabled, isSelected) {
              final isCurrent = item == selectedLabel;
              Color dotColor;
              if (item.contains('Critical')) {
                dotColor = AppColors.error;
              } else if (item.contains('Moderate')) {
                dotColor = AppColors.warning;
              } else if (item.contains('Mild')) {
                dotColor = AppColors.success;
              } else {
                dotColor = isDark ? Colors.white70 : Colors.black54;
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: isCurrent
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent
                              ? AppColors.primary
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                    ),
                    if (isCurrent)
                      const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                  ],
                ),
              );
            },
          ),
          dropdownBuilder: (context, selectedItem) {
            return Text(
              selectedItem ?? 'All Severities',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            );
          },
          suffixProps: DropdownSuffixProps(
            dropdownButtonProps: DropdownButtonProps(
              iconClosed: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ),
          decoratorProps: DropDownDecoratorProps(
            baseStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : Theme.of(context).cardColor,
              prefixIcon: const Icon(
                PhosphorIconsRegular.warningCircle,
                size: 16,
                color: AppColors.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // STATUS FILTER DROPDOWN (App-style DropdownSearch)
  // ---------------------------------------------------------------------------
  Widget _buildStatusFilterDropdown(BuildContext context, bool isDark, {bool isExpanded = false}) {
    return Obx(() {
      final selected = controller.statusFilter.value;
      const statusMap = {
        'ALL': 'All Statuses',
        'UNDER_TREATMENT': 'Under Treatment',
        'CRITICAL': 'Critical',
        'RECOVERED': 'Recovered',
        'CLOSED': 'Closed',
        'DECEASED': 'Deceased',
      };
      final selectedLabel = statusMap[selected] ?? 'All Statuses';
      final items = statusMap.values.toList();

      return SizedBox(
        width: isExpanded ? double.infinity : 175,
        child: DropdownSearch<String>(
          items: (filter, infiniteScrollProps) => items,
          selectedItem: selectedLabel,
          compareFn: (i1, i2) => i1 == i2,
          onSelected: (selected) {
            if (selected != null) {
              final match = statusMap.entries.firstWhere(
                (e) => e.value == selected,
                orElse: () => const MapEntry('ALL', 'All Statuses'),
              );
              controller.setStatusFilter(match.key);
            }
          },
          popupProps: PopupProps.menu(
            fit: FlexFit.loose,
            menuProps: MenuProps(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
              elevation: 8,
            ),
            itemBuilder: (ctx, item, isDisabled, isSelected) {
              final isCurrent = item == selectedLabel;
              Color dotColor;
              if (item == 'Under Treatment') {
                dotColor = const Color(0xFF3B82F6);
              } else if (item == 'Critical') {
                dotColor = const Color(0xFFEF4444);
              } else if (item == 'Recovered') {
                dotColor = const Color(0xFF10B981);
              } else if (item == 'Deceased') {
                dotColor = const Color(0xFF6B7280);
              } else if (item == 'Closed') {
                dotColor = const Color(0xFF9CA3AF);
              } else {
                dotColor = isDark ? Colors.white70 : Colors.black54;
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: isCurrent ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent
                              ? AppColors.primary
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                    ),
                    if (isCurrent)
                      const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                  ],
                ),
              );
            },
          ),
          dropdownBuilder: (context, selectedItem) {
            return Text(
              selectedItem ?? 'All Statuses',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            );
          },
          suffixProps: DropdownSuffixProps(
            dropdownButtonProps: DropdownButtonProps(
              iconClosed: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ),
          decoratorProps: DropDownDecoratorProps(
            baseStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : Theme.of(context).cardColor,
              prefixIcon: const Icon(
                PhosphorIconsRegular.firstAid,
                size: 16,
                color: AppColors.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // MOBILE SEARCH & FILTERS (Herd & Cattle Style)
  // ---------------------------------------------------------------------------
  Widget _buildSearchAndFiltersMobile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.searchController,
                onChanged: (val) => controller.searchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'Search Tag ID, disease...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: Obx(
                    () => controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              controller.searchController.clear();
                              controller.searchQuery.value = '';
                              controller.fetchTreatments();
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
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatusFilterDropdown(context, isDark, isExpanded: true)),
            const SizedBox(width: 10),
            Expanded(child: _buildSeverityFilterDropdown(context, isDark, isExpanded: true)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Obx(() {
              final isDue = controller.filterOnlyDueToday.value;
              return FilterChip(
                selected: isDue,
                label: const Text('Due Today'),
                avatar: Icon(
                  PhosphorIconsRegular.clock,
                  size: 14,
                  color: isDue ? Colors.white : AppColors.warning,
                ),
                selectedColor: AppColors.warning,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isDue ? AppColors.warning : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                ),
                onSelected: (v) => controller.toggleDueTodayFilter(v),
              );
            }),
          ],
        ),
      ],
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

  Widget _buildEmptyTreatmentsState(BuildContext context, bool isDark) {
    final hasActiveFilter = controller.searchQuery.value.isNotEmpty ||
        controller.statusFilter.value != 'ALL' ||
        controller.severityFilter.value != 'ALL' ||
        controller.filterOnlyDueToday.value;

    return Padding(
      padding: const EdgeInsets.all(60.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsRegular.firstAidKit, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              hasActiveFilter
                ? 'No treatment records match the selected filters'
                : 'No treatment cases registered yet',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              hasActiveFilter
                  ? 'Try clearing the filters or modifying your search query.'
                  : 'Click below to register the first cow treatment case.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 18),
            if (hasActiveFilter)
              CustomButton(
                text: 'Clear Filters',
                icon: Icons.filter_alt_off_rounded,
                variant: ButtonVariant.outlined,
                width: 160,
                height: 40,
                onPressed: controller.clearFilters,
              )
            else
              CustomButton(
                text: 'Add Treatment Case',
                icon: Icons.add_rounded,
                width: 200,
                height: 40,
                onPressed: () => controller.openAddTreatmentDialog(context),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TABLET / MOBILE CARDS LIST
  // ---------------------------------------------------------------------------
  Widget _buildTreatmentsCardsList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);

    return Obx(() {
      if (controller.isLoading.value) {
        return const CustomListShimmer(itemCount: 6);
      }

      final items = isMobile ? controller.mobileTreatments : controller.treatments;
      if (items.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              const Icon(PhosphorIconsRegular.firstAidKit, size: 40, color: AppColors.textMutedLight),
              const SizedBox(height: 12),
              const Text('No treatment records found.', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Try changing your filters or add a new case.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (ctx, idx) {
              final t = items[idx];
              return _HoverableTreatmentMobileCard(
                key: ValueKey(t.id),
                treatment: t,
                isDark: isDark,
                onView: () => controller.goToTreatmentDetails(t, context),
                onAdministerDose: () => controller.openAdministerDoseDialog(context, t),
                onChangeStatus: () => controller.openChangeStatusDialog(context, t),
                onDelete: () => controller.deleteTreatment(context, t),
              );
            },
          ),
          if (isMobile)
            MobileListBottomLoader(
              hasMore: controller.hasMoreMobileTreatments,
              isLoading: controller.isLoadingMoreTreatments.value,
              totalCount: controller.totalItems.value,
            ),
        ],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // PAGINATION BAR
  // ---------------------------------------------------------------------------
  Widget _buildPaginationBar(BuildContext context) {
    if (ResponsiveLayout.isMobile(context)) return const SizedBox.shrink();
    return Obx(
      () => CustomPagination(
        totalItems: controller.totalItems.value,
        currentPage: controller.currentPage.value,
        rowsPerPage: controller.rowsPerPage.value,
        onPageChanged: controller.onPageChanged,
        onRowsPerPageChanged: controller.onRowsPerPageChanged,
        rowsPerPageOptions: const [5, 10, 20, 50],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HOVERABLE TREATMENT TABLE ROW (Desktop)
// ---------------------------------------------------------------------------
class _HoverableTreatmentTableRow extends StatefulWidget {
  final int index;
  final CowTreatmentModel treatment;
  final bool isDark;
  final VoidCallback onView;
  final VoidCallback onAdministerDose;
  final VoidCallback onChangeStatus;
  final VoidCallback onDelete;

  const _HoverableTreatmentTableRow({
    super.key,
    required this.index,
    required this.treatment,
    required this.isDark,
    required this.onView,
    required this.onAdministerDose,
    required this.onChangeStatus,
    required this.onDelete,
  });

  @override
  State<_HoverableTreatmentTableRow> createState() => _HoverableTreatmentTableRowState();
}

class _HoverableTreatmentTableRowState extends State<_HoverableTreatmentTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.treatment;
    final isDark = widget.isDark;
    final isDue = t.isDoseDueToday;

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

                // 1. Treatment #
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: _isHovered ? 0.20 : 0.10),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: _isHovered ? 0.50 : 0.30),
                              width: 1.0,
                            ),
                            boxShadow: _isHovered
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.16),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(PhosphorIconsRegular.firstAidKit, size: 13, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                t.treatmentNumber.isNotEmpty
                                    ? t.treatmentNumber
                                    : (t.id.length > 8 ? t.id.substring(0, 8) : t.id),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Cow Tag / Name
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: _isHovered ? 0.20 : 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(PhosphorIconsRegular.cow, size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                t.displayCowTag,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _isHovered
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${t.displayCowName} • Shed: ${t.cowShedName ?? "Unassigned"}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Disease & Symptoms
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          t.diseaseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _isHovered
                                ? (isDark ? Colors.white : Colors.black87)
                                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          ),
                        ),
                        if (t.symptoms.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            t.symptoms.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 4. Severity Badge
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: t.severity.bgColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: t.severity.color.withValues(alpha: _isHovered ? 0.6 : 0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(t.severity.icon, size: 12, color: t.severity.color),
                              const SizedBox(width: 5),
                              Text(
                                t.severity.label,
                                style: TextStyle(
                                  color: t.severity.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 5. Doses Progress
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                '${t.completedDoses} of ${t.totalDoses} doses done',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${t.progressPercent}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: t.progressRatio,
                            minHeight: 6,
                            backgroundColor: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              t.isRecovered
                                  ? AppColors.success
                                  : (t.progressRatio >= 1.0 ? AppColors.success : AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 6. Next Dose
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (t.hasDosesPending && t.nextDoseDate != null) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isDue) ...[
                                const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
                                const SizedBox(width: 4),
                              ],
                              Flexible(
                                child: Text(
                                  DateFormat('dd MMM yyyy').format(t.nextDoseDate!),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isDue ? FontWeight.bold : FontWeight.w500,
                                    color: isDue ? AppColors.error : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isDue
                                ? 'Due Today (Dose ${t.nextDoseNumber ?? (t.completedDoses + 1)})'
                                : 'Dose ${t.nextDoseNumber ?? (t.completedDoses + 1)} scheduled',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isDue ? FontWeight.bold : FontWeight.normal,
                              color: isDue ? AppColors.error : Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else if (t.isRecovered) ...[
                          const Text(
                            'All Doses Given',
                            style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ] else ...[
                          const Text('None pending', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ),

                // 7. Status Badge
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: t.status.bgColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: t.status.color.withValues(alpha: _isHovered ? 0.6 : 0.3),
                          ),
                        ),
                        child: Text(
                          t.status.label,
                          style: TextStyle(
                            color: t.status.color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),

                // 8. Actions
                SizedBox(
                  width: 155,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // View Details
                        _buildRowActionIcon(
                          tooltip: 'View Treatment Details',
                          icon: PhosphorIconsRegular.eye,
                          color: _isHovered
                              ? AppColors.primary
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          hoverColor: AppColors.primary,
                          onTap: widget.onView,
                        ),
                        const SizedBox(width: 4),

                        // Administer Next Dose (if pending)
                        if (t.hasDosesPending) ...[
                          _buildRowActionIcon(
                            tooltip: 'Administer Next Dose',
                            icon: PhosphorIconsRegular.syringe,
                            color: isDue
                                ? const Color(0xFFF59E0B)
                                : (_isHovered
                                    ? AppColors.primary
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                            hoverColor: const Color(0xFFF59E0B),
                            onTap: widget.onAdministerDose,
                          ),
                          const SizedBox(width: 4),
                        ] else
                          const SizedBox(width: 28),

                        // Change Status
                        _buildRowActionIcon(
                          tooltip: 'Change Status',
                          icon: PhosphorIconsRegular.arrowsClockwise,
                          color: _isHovered
                              ? Colors.blue.shade700
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          hoverColor: Colors.blue.shade700,
                          onTap: widget.onChangeStatus,
                        ),
                        const SizedBox(width: 4),

                        // Delete
                        _buildRowActionIcon(
                          tooltip: 'Delete Record',
                          icon: PhosphorIconsRegular.trash,
                          color: _isHovered
                              ? AppColors.error
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          hoverColor: AppColors.error,
                          onTap: widget.onDelete,
                        ),
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

  Widget _buildRowActionIcon({
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
}

// ---------------------------------------------------------------------------
// HOVERABLE TREATMENT MOBILE CARD (Tablet / Mobile)
// ---------------------------------------------------------------------------
class _HoverableTreatmentMobileCard extends StatefulWidget {
  final CowTreatmentModel treatment;
  final bool isDark;
  final VoidCallback onView;
  final VoidCallback onAdministerDose;
  final VoidCallback onChangeStatus;
  final VoidCallback onDelete;

  const _HoverableTreatmentMobileCard({
    super.key,
    required this.treatment,
    required this.isDark,
    required this.onView,
    required this.onAdministerDose,
    required this.onChangeStatus,
    required this.onDelete,
  });

  @override
  State<_HoverableTreatmentMobileCard> createState() => _HoverableTreatmentMobileCardState();
}

class _HoverableTreatmentMobileCardState extends State<_HoverableTreatmentMobileCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.treatment;
    final isDue = t.isDoseDueToday;
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? (isDark ? AppColors.primaryLight : AppColors.primary)
                  : (isDue
                      ? const Color(0xFFF59E0B)
                      : (isDark ? AppColors.borderDark : AppColors.borderLight)),
              width: _isHovered ? 1.8 : (isDue ? 1.5 : 1.0),
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: _isHovered ? 0.20 : 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      t.treatmentNumber.isNotEmpty
                          ? t.treatmentNumber
                          : (t.id.length > 8 ? t.id.substring(0, 8) : t.id),
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: t.status.bgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      t.status.label,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: t.status.color),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: t.severity.bgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      t.severity.label,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: t.severity.color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cow Info & Disease
              Row(
                children: [
                  const Icon(PhosphorIconsRegular.cow, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Cow ${t.displayCowTag}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${t.displayCowName})',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Disease: ${t.diseaseName}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              if (t.symptoms.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Symptoms: ${t.symptoms.join(', ')}',
                  style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 10),

              // Doses Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Doses: ${t.completedDoses} of ${t.totalDoses} done',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${t.progressPercent}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: t.progressRatio,
                  minHeight: 6,
                  backgroundColor: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    t.isRecovered
                        ? AppColors.success
                        : (t.progressRatio >= 1.0 ? AppColors.success : AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Next Dose Alert
              if (t.hasDosesPending && t.nextDoseDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDue ? AppColors.warningBg : (isDark ? AppColors.surfaceDark : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIconsRegular.clock, size: 14, color: isDue ? AppColors.warning : Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        isDue
                            ? 'Dose ${t.nextDoseNumber ?? (t.completedDoses + 1)} Due Today!'
                            : 'Next: Dose ${t.nextDoseNumber ?? (t.completedDoses + 1)} on ${DateFormat('dd MMM').format(t.nextDoseDate!)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isDue ? FontWeight.bold : FontWeight.w500,
                          color: isDue ? AppColors.warning : (isDark ? AppColors.textPrimaryDark : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 20),

              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(PhosphorIconsRegular.eye, size: 16),
                    label: const Text('Details'),
                    onPressed: widget.onView,
                  ),
                  const SizedBox(width: 8),
                  if (t.hasDosesPending)
                    ElevatedButton.icon(
                      icon: const Icon(PhosphorIconsRegular.syringe, size: 16),
                      label: Text('Dose ${t.nextDoseNumber ?? (t.completedDoses + 1)}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDue ? const Color(0xFFF59E0B) : AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: widget.onAdministerDose,
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.arrowsClockwise, size: 16),
                    tooltip: 'Change Status',
                    onPressed: widget.onChangeStatus,
                  ),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.error),
                    tooltip: 'Delete',
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HOVERABLE METRIC TILE (Obx Header Summary Cards)
// ---------------------------------------------------------------------------
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
                  color: effectiveColor.withValues(alpha: _isHovered ? 0.22 : 0.12),
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
