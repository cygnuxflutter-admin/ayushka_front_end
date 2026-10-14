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
import '../../data/models/cow_mating_model.dart';
import '../../routes/app_routes.dart';
import '../dashboard/widgets/mobile_drawer.dart';
import '../dashboard/widgets/web_sidebar.dart';
import 'dialogs/add_mating_dialog.dart';
import 'dialogs/edit_mating_dialog.dart';
import 'dialogs/mating_details_dialog.dart';
import 'dialogs/record_calving_dialog.dart';
import 'dialogs/record_pd_dialog.dart';
import 'mating_controller.dart';

/// Screen for Cow Mating & Breeding Management.
class MatingScreen extends GetView<MatingController> {
  const MatingScreen({super.key});

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
                            _buildMatingsTableCard(context),
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
            _buildMatingsTableCard(context),
          ],
        ),
      ),
      floatingActionButton: Obx(
        () => controller.canAddMating
            ? FloatingActionButton.extended(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                onPressed: () => AddMatingDialog.show(context),
                icon: const Icon(PhosphorIconsRegular.plus),
                label: const Text('Record Mating'),
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
            controller.loadMoreMobileMatings();
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
              _buildMobileMatingList(context),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
      floatingActionButton: Obx(
        () => controller.canAddMating
            ? FloatingActionButton(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                onPressed: () => AddMatingDialog.show(context),
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
              const Icon(PhosphorIconsRegular.heartStraight, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Breeding & Artificial Insemination (AI)',
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
      title: const Text('Mating & Breeding', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  'Mating & Breeding',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Cow Mating Records & Pregnancy Diagnosis (PD)',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Obx(
          () => controller.canAddMating
              ? CustomButton(
                  text: 'Record Mating',
                  icon: PhosphorIconsRegular.plus,
                  onPressed: () => AddMatingDialog.show(context),
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
      final pendingPDCount = controller.pendingPDAlerts.length;
      final pregnantCount = controller.matings.where((m) => m.status == MatingStatus.pregnant).length;
      final repeatBreeders = controller.repeatBreederAlerts.length;
      final calvedCount = controller.matings.where((m) => m.status == MatingStatus.calved).length;

      final pendingTile = _HoverableMetricTile(
        title: 'Pending PD Checks',
        value: '$pendingPDCount',
        subtitle: 'Due at ~45-60 days',
        icon: PhosphorIconsRegular.clock,
        color: const Color(0xFFF59E0B),
        isDark: isDark,
        isCompact: isCompact,
        isSelected: controller.statusFilter.value == 'PENDING_PD',
        onTap: () {
          if (controller.statusFilter.value == 'PENDING_PD') {
            controller.setStatusFilter('ALL');
          } else {
            controller.setStatusFilter('PENDING_PD');
          }
        },
      );

      final pregnantTile = _HoverableMetricTile(
        title: 'Confirmed Pregnant',
        value: '$pregnantCount',
        subtitle: 'Active gestations (~282d)',
        icon: PhosphorIconsRegular.baby,
        color: AppColors.primary,
        isDark: isDark,
        isCompact: isCompact,
        isSelected: controller.statusFilter.value == 'PREGNANT',
        onTap: () {
          if (controller.statusFilter.value == 'PREGNANT') {
            controller.setStatusFilter('ALL');
          } else {
            controller.setStatusFilter('PREGNANT');
          }
        },
      );

      final repeatTile = _HoverableMetricTile(
        title: 'Repeat Breeders',
        value: '$repeatBreeders',
        subtitle: '3+ failed services (High Alert)',
        icon: PhosphorIconsRegular.warningOctagon,
        color: const Color(0xFFEF4444),
        isDark: isDark,
        isCompact: isCompact,
        isSelected: controller.isRepeatBreederFilter.value,
        onTap: controller.toggleRepeatBreederFilter,
      );

      final calvedTile = _HoverableMetricTile(
        title: 'Calved Successfully',
        value: '$calvedCount',
        subtitle: 'Completed gestations',
        icon: PhosphorIconsRegular.sparkle,
        color: const Color(0xFF0D9488),
        isDark: isDark,
        isCompact: isCompact,
        isSelected: controller.statusFilter.value == 'CALVED',
        onTap: () {
          if (controller.statusFilter.value == 'CALVED') {
            controller.setStatusFilter('ALL');
          } else {
            controller.setStatusFilter('CALVED');
          }
        },
      );

      if (isCompact) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isVeryNarrow = constraints.maxWidth < 420;
            if (isVeryNarrow) {
              return Column(
                children: [
                  pendingTile,
                  const SizedBox(height: 8),
                  pregnantTile,
                  const SizedBox(height: 8),
                  repeatTile,
                  const SizedBox(height: 8),
                  calvedTile,
                ],
              );
            }
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: pendingTile),
                    const SizedBox(width: 8),
                    Expanded(child: pregnantTile),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: repeatTile),
                    const SizedBox(width: 8),
                    Expanded(child: calvedTile),
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
                    Expanded(child: pendingTile),
                    const SizedBox(width: 14),
                    Expanded(child: pregnantTile),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: repeatTile),
                    const SizedBox(width: 14),
                    Expanded(child: calvedTile),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: pendingTile),
              const SizedBox(width: 14),
              Expanded(child: pregnantTile),
              const SizedBox(width: 14),
              Expanded(child: repeatTile),
              const SizedBox(width: 14),
              Expanded(child: calvedTile),
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
      final repeatBreeders = controller.repeatBreederAlerts.length;
      final pendingPDs = controller.pendingPDAlerts.length;

      if (repeatBreeders == 0 && pendingPDs == 0) return const SizedBox.shrink();

      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: repeatBreeders > 0
              ? Colors.red.withValues(alpha: 0.08)
              : Colors.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: repeatBreeders > 0 ? Colors.red.shade300 : Colors.amber.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              repeatBreeders > 0 ? PhosphorIconsRegular.warningOctagon : PhosphorIconsRegular.stethoscope,
              color: repeatBreeders > 0 ? Colors.red.shade700 : Colors.amber.shade800,
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    repeatBreeders > 0
                        ? 'High Priority Alert: $repeatBreeders Repeat Breeder Cattle (>= 3 Inseminations Failed)'
                        : 'Pregnancy Diagnosis Due: $pendingPDs Cow(s) Awaiting PD Confirmation (<= Today)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: repeatBreeders > 0
                          ? (isDark ? Colors.red.shade300 : Colors.red.shade900)
                          : (isDark ? Colors.amber.shade300 : Colors.amber.shade900),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    repeatBreeders > 0
                        ? 'These cattle have failed to conceive after 3 consecutive matings. Perform rectal palpation or ultrasound to evaluate reproductive health before re-insemination.'
                        : 'These matings have reached expected PD check window (~45-60 days post mating). Perform examination and record PD status to establish pregnancy or open status.',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (repeatBreeders > 0)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade400),
                ),
                onPressed: () {
                  controller.isRepeatBreederFilter.value = true;
                  controller.fetchMatings();
                },
                icon: const Icon(PhosphorIconsRegular.funnel, size: 16),
                label: const Text('View Repeat Breeders'),
              )
            else if (pendingPDs > 0)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber.shade800,
                  side: BorderSide(color: Colors.amber.shade600),
                ),
                onPressed: () {
                  controller.statusFilter.value = 'PENDING_PD';
                  controller.fetchMatings();
                },
                icon: const Icon(PhosphorIconsRegular.funnel, size: 16),
                label: const Text('View Due PDs'),
              ),
          ],
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // MATINGS TABLE CARD (DESKTOP & TABLET)
  // ---------------------------------------------------------------------------
  Widget _buildMatingsTableCard(BuildContext context) {
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
          _buildDesktopFilterToolbar(context),
          const Divider(height: 1),
          // Table Content
          LayoutBuilder(
            builder: (context, constraints) {
              const double minTableWidth = 1320.0;
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
                        columnFlexes: [3, 3, 2, 3, 3, 4, 3, 3],
                        headers: [
                          '#',
                          'COW TAG / NAME',
                          'MATING DATE',
                          'TYPE',
                          'SIRE / STRAW CODE',
                          'INSEMINATOR',
                          'STATUS',
                          'EXP. PD DATE',
                          'EXP. CALVING',
                          'ACTIONS',
                        ],
                      ),
                    ),
                  );
                }

                final items = controller.paginatedMatings;
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
                                  Expanded(flex: 3, child: _buildTableHeaderCell('MATING DATE')),
                                  Expanded(flex: 2, child: _buildTableHeaderCell('TYPE')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('SIRE / STRAW CODE')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('INSEMINATOR')),
                                  Expanded(flex: 4, child: _buildTableHeaderCell('STATUS')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('EXP. PD DATE')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('EXP. CALVING')),
                                  SizedBox(width: 140, child: _buildTableHeaderCell('ACTIONS', alignRight: true)),
                                ],
                              ),
                            ),

                            // Data Rows with Signature Hover Effect
                            ...items.asMap().entries.map((entry) {
                              final pageStartIndex = (controller.currentPage.value - 1) * controller.rowsPerPage.value;
                              final index = pageStartIndex + entry.key;
                              final mating = entry.value;
                              return _HoverableMatingTableRow(
                                key: ValueKey(mating.id),
                                index: index,
                                mating: mating,
                                isDark: isDark,
                                canEdit: controller.canEditMating,
                                canDelete: controller.canDeleteMating,
                                onView: () => MatingDetailsDialog.show(context, mating),
                                onRecordPd: () => RecordPDDialog.show(context, mating),
                                onRecordCalving: () => RecordCalvingDialog.show(context, mating),
                                onEdit: () => EditMatingDialog.show(context, mating),
                                onDelete: () => _confirmDeleteMating(context, mating),
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
      'PENDING_PD': 'Pending PD Check',
      'PREGNANT': 'Confirmed Pregnant',
      'FAILED': 'Mating Failed / Open',
      'CALVED': 'Calved Successfully',
      'ABORTED': 'Aborted',
    };
    final statusItems = statusMap.values.toList();

    const typeMap = {
      'ALL': 'All Types',
      'ARTIFICIAL': 'Artificial Insemination (AI)',
      'NATURAL': 'Natural Service',
    };
    final typeItems = typeMap.values.toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 980;

          final titleRow = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(PhosphorIconsRegular.heartStraight, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Mating Records',
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
                if ((controller.isLoading.value || controller.isRefreshing.value) && controller.matings.isNotEmpty) {
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
                    hintText: 'Search cow tag, bull, straw...',
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
                    prefixIcon: PhosphorIconsRegular.pulse,
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

              // Type Filter using CustomDropdownSearch
              Obx(() {
                final currentDisplay = typeMap[controller.typeFilter.value] ?? 'All Types';
                return SizedBox(
                  width: 195,
                  child: CustomDropdownSearch<String>(
                    hint: 'All Types',
                    prefixIcon: PhosphorIconsRegular.arrowsLeftRight,
                    selectedItem: currentDisplay,
                    items: typeItems,
                    itemAsString: (s) => s,
                    showClearButton: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                    onChanged: (val) {
                      if (val != null) {
                        final match = typeMap.entries.firstWhere(
                          (e) => e.value == val,
                          orElse: () => const MapEntry('ALL', 'All Types'),
                        );
                        controller.setTypeFilter(match.key);
                      }
                    },
                  ),
                );
              }),

              // Repeat Breeder Alert Toggle
              Obx(
                () => FilterChip(
                  avatar: Icon(
                    PhosphorIconsRegular.warningOctagon,
                    size: 16,
                    color: controller.isRepeatBreederFilter.value ? Colors.white : Colors.red,
                  ),
                  label: const Text('Repeat Breeders (3+)'),
                  selected: controller.isRepeatBreederFilter.value,
                  selectedColor: Colors.red.shade700,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: controller.isRepeatBreederFilter.value ? Colors.white : null,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (_) => controller.toggleRepeatBreederFilter(),
                ),
              ),

              // Reset Filters Button
              Obx(() {
                final hasActiveFilter = controller.searchQuery.value.isNotEmpty ||
                    controller.statusFilter.value != 'ALL' ||
                    controller.typeFilter.value != 'ALL' ||
                    controller.isRepeatBreederFilter.value;
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

  void _confirmDeleteMating(BuildContext context, CowMatingModel mating) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Mating Record'),
        content: Text('Are you sure you want to delete the mating record for ${mating.cowTagId}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.deleteMating(mating);
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
                isSearching ? Icons.search_off_rounded : PhosphorIconsRegular.heartStraight,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No Matching Mating Records' : 'No Mating Records Found',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'No records match "${controller.searchQuery.value}". Check spelling or try a different term.'
                  : 'No breeding or insemination records match your current criteria. Record a new service.',
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
            else if (controller.canAddMating)
              CustomButton(
                text: 'Record Mating',
                icon: PhosphorIconsRegular.plus,
                onPressed: () => AddMatingDialog.show(context),
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
      'PENDING_PD': 'Pending PD',
      'PREGNANT': 'Pregnant',
      'FAILED': 'Failed',
      'CALVED': 'Calved',
      'ABORTED': 'Aborted',
    };

    return Column(
      children: [
        TextField(
          controller: controller.searchController,
          onChanged: controller.onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search cow tag, bull, straw...',
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
                  prefixIcon: PhosphorIconsRegular.pulse,
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
                  color: controller.isRepeatBreederFilter.value ? Colors.white : Colors.red,
                ),
                label: const Text('Repeat', style: TextStyle(fontSize: 12)),
                selected: controller.isRepeatBreederFilter.value,
                selectedColor: Colors.red.shade700,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: controller.isRepeatBreederFilter.value ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => controller.toggleRepeatBreederFilter(),
              ),
            ),
            Obx(() {
              final hasActive = controller.searchQuery.value.isNotEmpty ||
                  controller.statusFilter.value != 'ALL' ||
                  controller.typeFilter.value != 'ALL' ||
                  controller.isRepeatBreederFilter.value;
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

  Widget _buildMobileMatingList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.mobileMatings.isEmpty) {
        return SliverToBoxAdapter(
          child: SizedBox(height: 200, child: Center(child: CustomBrandedSpinner())),
        );
      }

      final items = controller.mobileDisplayMatings;
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
            final mating = items[index];
            return _HoverableMatingMobileCard(
              key: ValueKey(mating.id),
              mating: mating,
              isDark: Theme.of(context).brightness == Brightness.dark,
              onView: () => MatingDetailsDialog.show(context, mating),
              onRecordPd: () => RecordPDDialog.show(context, mating),
              onRecordCalving: () => RecordCalvingDialog.show(context, mating),
            );
          },
          childCount: items.length + (controller.hasMoreMobileItems ? 1 : 0),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// HOVERABLE MATING TABLE ROW (DESKTOP)
// ---------------------------------------------------------------------------
class _HoverableMatingTableRow extends StatefulWidget {
  final int index;
  final CowMatingModel mating;
  final bool isDark;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onView;
  final VoidCallback onRecordPd;
  final VoidCallback onRecordCalving;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HoverableMatingTableRow({
    super.key,
    required this.index,
    required this.mating,
    required this.isDark,
    required this.canEdit,
    required this.canDelete,
    required this.onView,
    required this.onRecordPd,
    required this.onRecordCalving,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_HoverableMatingTableRow> createState() => _HoverableMatingTableRowState();
}

class _HoverableMatingTableRowState extends State<_HoverableMatingTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final mating = widget.mating;
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
                        Row(
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
                              child: Text(mating.cowTagId),
                            ),
                            if (mating.isHighAlert) ...[
                              const SizedBox(width: 6),
                              Tooltip(
                                message: 'Repeat Breeder: ${mating.attemptCount} insemination attempts',
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(PhosphorIconsRegular.warning, color: Colors.white, size: 9),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (mating.cowCalfName != null && mating.cowCalfName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              mating.cowCalfName!,
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

                // 2. MATING DATE
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mating.formattedMatingDate,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (mating.matingTime ?? 'Morning').capitalizeFirst ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. TYPE
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(mating.matingType.icon, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          mating.matingType == MatingType.artificial ? 'AI' : 'Natural',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. SIRE / STRAW CODE
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mating.matingType == MatingType.artificial
                              ? (mating.semenStrawCode ?? 'Straw Code N/A')
                              : (mating.bullNameOrTag ?? 'Bull Sire'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        if (mating.matingType == MatingType.artificial && mating.semenBreedName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${mating.semenBreedName!} (${mating.semenSource ?? 'Source'})',
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

                // 5. INSEMINATOR
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      mating.inseminatorName ?? 'Technician',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),

                // 6. STATUS
                Expanded(
                  flex: 4,
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
                            color: mating.status.bgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: mating.status.color.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(mating.status.icon, size: 12, color: mating.status.color),
                              const SizedBox(width: 5),
                              Text(
                                mating.status.label,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mating.status.color),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 7. EXP. PD DATE
                Expanded(
                  flex: 3,
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
                              mating.formattedExpectedPDDate,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: mating.isPDDue ? FontWeight.bold : FontWeight.normal,
                                color: (mating.isPDDue && mating.isPendingPD) ? Colors.amber.shade800 : null,
                              ),
                            ),
                            if (mating.isPDDue && mating.isPendingPD) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(4)),
                                child: const Text('DUE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 8. EXP. CALVING
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mating.isPregnant || mating.isCalved ? mating.formattedExpectedCalvingDate : '—',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (mating.hasGestationInconsistency) ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Biological inconsistency: Calving recorded ${mating.actualGestationDays} days after mating (Normal is ~282 days).',
                            child: Icon(PhosphorIconsRegular.warningCircle, size: 14, color: Colors.red.shade700),
                          ),
                        ],
                      ],
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
                        MatingScreen._buildRowActionIcon(
                          tooltip: 'View Details',
                          icon: PhosphorIconsRegular.eye,
                          color: _isHovered
                              ? AppColors.primary
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          hoverColor: AppColors.primary,
                          onTap: widget.onView,
                        ),
                        if (mating.isPendingPD) ...[
                          const SizedBox(width: 4),
                          MatingScreen._buildRowActionIcon(
                            tooltip: 'Record Pregnancy Diagnosis (PD)',
                            icon: PhosphorIconsRegular.stethoscope,
                            color: Colors.amber.shade700,
                            hoverColor: Colors.amber.shade700,
                            onTap: widget.onRecordPd,
                          ),
                        ],
                        if (mating.isPregnant) ...[
                          const SizedBox(width: 4),
                          MatingScreen._buildRowActionIcon(
                            tooltip: 'Record Calving Event',
                            icon: PhosphorIconsRegular.sparkle,
                            color: const Color(0xFF0D9488),
                            hoverColor: const Color(0xFF0D9488),
                            onTap: widget.onRecordCalving,
                          ),
                        ],
                        if (widget.canEdit) ...[
                          const SizedBox(width: 4),
                          MatingScreen._buildRowActionIcon(
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
                          MatingScreen._buildRowActionIcon(
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
// HOVERABLE MATING MOBILE CARD (TABLET / MOBILE)
// ---------------------------------------------------------------------------
class _HoverableMatingMobileCard extends StatefulWidget {
  final CowMatingModel mating;
  final bool isDark;
  final VoidCallback onView;
  final VoidCallback onRecordPd;
  final VoidCallback onRecordCalving;

  const _HoverableMatingMobileCard({
    super.key,
    required this.mating,
    required this.isDark,
    required this.onView,
    required this.onRecordPd,
    required this.onRecordCalving,
  });

  @override
  State<_HoverableMatingMobileCard> createState() => _HoverableMatingMobileCardState();
}

class _HoverableMatingMobileCardState extends State<_HoverableMatingMobileCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final mating = widget.mating;
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
                  : (mating.isHighAlert
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
                        mating.cowTagId,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _isHovered ? (isDark ? AppColors.primaryLight : AppColors.primary) : null,
                        ),
                      ),
                      if (mating.isHighAlert) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                          child: const Text('REPEAT BREEDER', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: mating.status.bgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      mating.status.label,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: mating.status.color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Type: ${mating.matingType.label} • Attempt #${mating.attemptCount}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                'Mated: ${mating.formattedMatingDate} • Exp. PD: ${mating.formattedExpectedPDDate}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: mating.isPDDue && mating.isPendingPD ? Colors.amber.shade800 : null,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onView,
                    child: const Text('Details'),
                  ),
                  if (mating.isPendingPD) ...[
                    const SizedBox(width: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: widget.onRecordPd,
                      child: const Text('Record PD', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  if (mating.isPregnant) ...[
                    const SizedBox(width: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: widget.onRecordCalving,
                      child: const Text('Calving', style: TextStyle(fontSize: 12)),
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

/// Interactive hoverable metric card for Breeding & Insemination summary metrics.
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

