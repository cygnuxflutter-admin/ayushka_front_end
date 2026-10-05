import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:ayushka/app/core/utils/responsive_layout.dart';
import 'package:ayushka/app/core/values/app_colors.dart';
import 'package:ayushka/app/core/values/app_constants.dart';
import 'package:ayushka/app/core/widgets/custom_button.dart';
import 'package:ayushka/app/core/widgets/custom_loader.dart';
import 'package:ayushka/app/core/widgets/custom_pagination.dart';
import 'package:ayushka/app/core/widgets/custom_shimmer.dart';
import 'package:ayushka/app/core/widgets/global_gaushala_selector.dart';
import 'package:ayushka/app/core/widgets/header_user_profile_badge.dart';
import 'package:ayushka/app/modules/notification/widgets/notification_bell_widget.dart';
import 'package:ayushka/app/modules/dashboard/widgets/mobile_drawer.dart';
import 'package:ayushka/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:ayushka/app/data/models/cow_model.dart';
import 'package:ayushka/app/data/models/worker_model.dart';
import 'package:ayushka/app/data/models/notification_model.dart';
import '../controllers/milk_controller.dart';
import '../models/fridge_stock_model.dart';
import '../models/milk_daily_summary_model.dart';
import '../models/milk_disposal_model.dart';
import '../models/milk_distribution_model.dart';
import '../models/milk_production_model.dart';
import 'dialogs/add_distribution_dialog.dart';
import 'dialogs/add_production_dialog.dart';
import 'dialogs/dispose_milk_dialog.dart';
import 'dialogs/milk_alert_detail_dialog.dart';

/// Main Responsive Screen for Milk Production & Distribution Module
class MilkMainView extends GetView<MilkController> {
  const MilkMainView({super.key});

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
          // Sidebar
          Obx(
            () => WebSidebar(
              isCollapsed: controller.isSidebarCollapsed.value,
              onToggle: controller.toggleSidebar,
              currentUser: controller.currentUser,
              onLogout: controller.logout,
            ),
          ),

          // Main Content
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
                            // Breadcrumb & Date Navigator Bar
                            _buildTopActionBar(context),
                            const SizedBox(height: 20),

                            // Tab Bar Selector
                            _buildModuleTabs(context),
                            const SizedBox(height: 20),

                            // Tab View Contents
                            Obx(() {
                              switch (controller.selectedTab.value) {
                                case 0:
                                  return _buildOverviewTab(context);
                                case 1:
                                  return _buildProductionTab(context);
                                case 2:
                                  return _buildDistributionTab(context);
                                case 3:
                                  return _buildFridgeStockTab(context);
                                case 4:
                                  return _buildMonthlyAlertsTab(context);
                                default:
                                  return _buildOverviewTab(context);
                              }
                            }),
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
  // ===========================================================================
  // TABLET SCAFFOLD
  // ===========================================================================
  Widget _buildTabletScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Milk Management'),
        actions: [
          const NotificationBellWidget(),
          Obx(() {
            final isBusy = controller.isLoadingSummary.value ||
                controller.isLoadingProduction.value ||
                controller.isLoadingDistribution.value;
            return IconButton(
              icon: isBusy
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh',
              onPressed: isBusy ? null : controller.refreshAll,
            );
          }),
          PopupMenuButton<String>(
            tooltip: 'Quick Actions',
            icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
            onSelected: (val) {
              if (val == 'single_prod') {
                AddProductionDialog.show(context, mode: ProductionEntryMode.single);
              } else if (val == 'bulk_prod') {
                AddProductionDialog.show(context, mode: ProductionEntryMode.bulk);
              } else if (val == 'distribute') {
                AddDistributionDialog.show(context, milkDate: controller.selectedDate.value);
              } else if (val == 'dispose') {
                DisposeMilkDialog.show(context, milkDate: controller.selectedDateFormatted);
              } else if (val == 'analysis') {
                controller.runMonthlyAnalysis();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'single_prod',
                child: Row(
                  children: [
                    const Icon(PhosphorIconsRegular.drop, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    const Text('Single Cow Yield'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'bulk_prod',
                child: Row(
                  children: [
                    const Icon(Icons.groups_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    const Text('Bulk Shift Entry'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'distribute',
                child: Row(
                  children: [
                    const Icon(PhosphorIconsRegular.truck, size: 18, color: Color(0xFFE98324)),
                    const SizedBox(width: 10),
                    const Text('Distribute Milk'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'dispose',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep_rounded, size: 18, color: AppColors.error),
                    const SizedBox(width: 10),
                    const Text('Dispose Spoilage'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'analysis',
                child: Row(
                  children: [
                    const Icon(Icons.insights_rounded, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    const Text('Run Variance Analysis'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: MobileDrawer(
        currentUser: controller.currentUser,
        onLogout: controller.logout,
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopActionBar(context),
              const SizedBox(height: 16),
              _buildModuleTabs(context),
              const SizedBox(height: 16),
              Obx(() {
                switch (controller.selectedTab.value) {
                  case 0:
                    return _buildOverviewTab(context);
                  case 1:
                    return _buildProductionTab(context);
                  case 2:
                    return _buildDistributionTab(context);
                  case 3:
                    return _buildFridgeStockTab(context);
                  case 4:
                    return _buildMonthlyAlertsTab(context);
                  default:
                    return _buildOverviewTab(context);
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MOBILE SCAFFOLD
  // ===========================================================================
  Widget _buildMobileScaffold(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Milk Management'),
          actions: [
            const NotificationBellWidget(),
            Obx(() {
              final isBusy = controller.isLoadingSummary.value ||
                  controller.isLoadingProduction.value ||
                  controller.isLoadingDistribution.value;
              return IconButton(
                icon: isBusy
                    ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                    : const Icon(Icons.refresh_rounded),
                tooltip: isBusy ? 'Refreshing...' : 'Refresh',
                onPressed: isBusy ? null : controller.refreshAll,
              );
            }),
            PopupMenuButton<String>(
              tooltip: 'Quick Actions',
              icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
              onSelected: (val) {
                if (val == 'single_prod') {
                  AddProductionDialog.show(context, mode: ProductionEntryMode.single);
                } else if (val == 'bulk_prod') {
                  AddProductionDialog.show(context, mode: ProductionEntryMode.bulk);
                } else if (val == 'distribute') {
                  AddDistributionDialog.show(context, milkDate: controller.selectedDate.value);
                } else if (val == 'dispose') {
                  DisposeMilkDialog.show(context, milkDate: controller.selectedDateFormatted);
                } else if (val == 'analysis') {
                  controller.runMonthlyAnalysis();
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'single_prod',
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsRegular.drop, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      const Text('Single Cow Yield'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'bulk_prod',
                  child: Row(
                    children: [
                      const Icon(Icons.groups_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      const Text('Bulk Shift Entry'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'distribute',
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsRegular.truck, size: 18, color: Color(0xFFE98324)),
                      const SizedBox(width: 10),
                      const Text('Distribute Milk'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'dispose',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep_rounded, size: 18, color: AppColors.error),
                      const SizedBox(width: 10),
                      const Text('Dispose Spoilage'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'analysis',
                  child: Row(
                    children: [
                      const Icon(Icons.insights_rounded, size: 18, color: Color(0xFF2563EB)),
                      const SizedBox(width: 10),
                      const Text('Run Variance Analysis'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        drawer: MobileDrawer(
          currentUser: controller.currentUser,
          onLogout: controller.logout,
        ),
        floatingActionButton: Obx(() {
          final tab = controller.selectedTab.value;
          switch (tab) {
            case 1:
              return FloatingActionButton.extended(
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('Add Yield', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () => AddProductionDialog.show(
                  context,
                  mode: ProductionEntryMode.single,
                  shift: controller.productionShift.value,
                ),
              );
            case 2:
              return FloatingActionButton.extended(
                backgroundColor: const Color(0xFFE98324),
                icon: const Icon(PhosphorIconsRegular.truck, color: Colors.white),
                label: const Text('Distribute', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () => AddDistributionDialog.show(
                  context,
                  milkDate: controller.selectedDate.value,
                ),
              );
            case 3:
              return FloatingActionButton.extended(
                backgroundColor: AppColors.error,
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
                label: const Text('Dispose', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () => DisposeMilkDialog.show(
                  context,
                  milkDate: controller.selectedDateFormatted,
                ),
              );
            default:
              return FloatingActionButton.extended(
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('Record Milk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () => _showQuickActionModal(context),
              );
          }
        }),
        body: RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopActionBar(context, isCompact: true),
                const SizedBox(height: 12),
                _buildModuleTabs(context, isCompact: true),
                const SizedBox(height: 14),
                Obx(() {
                  switch (controller.selectedTab.value) {
                    case 0:
                      return _buildOverviewTab(context, isCompact: true);
                    case 1:
                      return _buildProductionTab(context);
                    case 2:
                      return _buildDistributionTab(context);
                    case 3:
                      return _buildFridgeStockTab(context);
                    case 4:
                      return _buildMonthlyAlertsTab(context);
                    default:
                      return _buildOverviewTab(context, isCompact: true);
                  }
                }),
                const SizedBox(height: 70), // FloatingActionButton clearance
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DESKTOP TOP HEADER
  // ===========================================================================
  Widget _buildDesktopHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 74,
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
          // Screen Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  PhosphorIconsRegular.drop,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Milk Production & Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Daily Balance Sheet, Cow Milking Shifts, Live Pool Stock & Spoilage Logs',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Header Right: Gaushala Selector, Notification Bell, Refresh & User Profile
          Row(
            children: [
              const GlobalGaushalaSelector(),
              const SizedBox(width: 8),
              const NotificationBellWidget(),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh All Milk Records',
                onPressed: controller.refreshAll,
              ),
              const SizedBox(width: 8),
              HeaderUserProfileBadge(user: controller.currentUser),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ===========================================================================
  // TOP ACTION BAR (Date Navigator & Quick Actions)
  // ===========================================================================
  Widget _buildTopActionBar(BuildContext context, {bool isCompact = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dateNavigator = Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: isCompact ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              tooltip: 'Previous Day',
              onPressed: controller.previousDay,
            ),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: controller.selectedDate.value,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  controller.setSelectedDate(picked);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsRegular.calendar, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      controller.selectedDateDisplay,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    if (controller.isSelectedDateToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              tooltip: 'Next Day',
              onPressed: controller.nextDay,
            ),
          ],
        ),
      ),
    );

    if (isCompact) {
      // In mobile view: Date navigator spans full width on top, followed by a sleek 1-row quick action strip
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          dateNavigator,
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: '+ Yield',
                  icon: PhosphorIconsRegular.drop,
                  height: 38,
                  onPressed: () => AddProductionDialog.show(context, mode: ProductionEntryMode.single),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  text: '+ Distribute',
                  icon: PhosphorIconsRegular.truck,
                  variant: ButtonVariant.secondary,
                  height: 38,
                  onPressed: () => AddDistributionDialog.show(
                    context,
                    milkDate: controller.selectedDate.value,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  text: '+ Waste',
                  icon: Icons.delete_sweep_rounded,
                  variant: ButtonVariant.outlined,
                  height: 38,
                  onPressed: () => DisposeMilkDialog.show(
                    context,
                    milkDate: controller.selectedDateFormatted,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final actionButtons = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        CustomButton(
          text: '+ Add Production',
          icon: PhosphorIconsRegular.drop,
          onPressed: () => AddProductionDialog.show(context, mode: ProductionEntryMode.single),
        ),
        CustomButton(
          text: '+ Distribute Milk',
          icon: PhosphorIconsRegular.truck,
          variant: ButtonVariant.secondary,
          onPressed: () => AddDistributionDialog.show(
            context,
            milkDate: controller.selectedDate.value,
          ),
        ),
        CustomButton(
          text: '+ Dispose Waste',
          icon: Icons.delete_sweep_rounded,
          variant: ButtonVariant.outlined,
          onPressed: () => DisposeMilkDialog.show(
            context,
            milkDate: controller.selectedDateFormatted,
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              dateNavigator,
              const SizedBox(height: 10),
              actionButtons,
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            dateNavigator,
            actionButtons,
          ],
        );
      },
    );
  }

  // ===========================================================================
  // MODULE TABS
  // ===========================================================================
  Widget _buildModuleTabs(BuildContext context, {bool isCompact = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tabs = [
      {'title': 'Daily Overview', 'icon': PhosphorIconsRegular.chartPieSlice},
      {'title': 'Production', 'icon': PhosphorIconsRegular.drop},
      {'title': 'Distribution', 'icon': PhosphorIconsRegular.truck},
      {'title': 'Fridge Stock & Spoilage', 'icon': Icons.kitchen_rounded},
      {'title': 'Monthly Variance & Alerts', 'icon': Icons.insights_rounded},
    ];

    return Obx(() {
      final current = controller.selectedTab.value;
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        padding: EdgeInsets.all(isCompact ? 4 : 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(tabs.length, (idx) {
              final isSelected = current == idx;
              final tab = tabs[idx];
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => controller.changeTab(idx),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 12 : 16,
                      vertical: isCompact ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab['icon'] as IconData,
                          size: isCompact ? 15 : 17,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          tab['title'] as String,
                          style: TextStyle(
                            fontSize: isCompact ? 12 : 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      );
    });
  }

  // ===========================================================================
  // TAB 1: DAILY OVERVIEW & BALANCE SHEET
  // ===========================================================================
  Widget _buildOverviewTab(BuildContext context, {bool isCompact = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoadingSummary.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CustomTableShimmer(rowCount: 4),
        );
      }

      final summary = controller.dailySummary.value ?? const MilkDailySummaryModel();
      final prod = summary.production;
      final dist = summary.distribution;
      final disp = summary.disposal;
      final stock = summary.stockBalance;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary Metrics Cards (Herd & Cattle Style with Hover Lift & Glow)
          _buildMetricCards(context, prod, dist, disp, stock, isCompact: isCompact),
          const SizedBox(height: 18),

          // In-App Milk Production Variance & Alerts Banner on Dashboard
          _buildOverviewAlertsBanner(context),
          const SizedBox(height: 18),

          // Daily Balance Sheet Visual Progression Card
          Container(
            padding: EdgeInsets.all(isCompact ? 16 : 22),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 650;
                    if (isSmall) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(PhosphorIconsRegular.scales, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Daily Milk Balance Flow',
                                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${controller.selectedDateDisplay}  •  Morning: ${stock.morningAvailable} L  |  Evening: ${stock.eveningAvailable} L',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(PhosphorIconsRegular.scales, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Daily Milk Balance Flow (${controller.selectedDateDisplay})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Morning Avail: ${stock.morningAvailable} L  |  Evening Avail: ${stock.eveningAvailable} L',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Mathematical Flow Row (2x2 grid on mobile, row on tablet/desktop)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 650;
                    if (isSmall) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildBalanceFlowItem('Produced', '${prod.totalProduced} L', const Color(0xFF384C28))),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.remove_rounded, color: Colors.grey, size: 20),
                              ),
                              Expanded(child: _buildBalanceFlowItem('Distributed', '${dist.totalDistributed} L', const Color(0xFFE98324))),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Icon(Icons.remove_rounded, color: Colors.grey, size: 20),
                          ),
                          Row(
                            children: [
                              Expanded(child: _buildBalanceFlowItem('Disposed', '${disp.totalDisposed} L', AppColors.error)),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.drag_handle_rounded, color: Colors.grey, size: 20),
                              ),
                              Expanded(child: _buildBalanceFlowItem('Remaining Fridge', '${stock.remainingFridgeMilk} L', const Color(0xFF2563EB))),
                            ],
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: _buildBalanceFlowItem('Produced', '${prod.totalProduced} L', const Color(0xFF384C28))),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.remove_rounded, color: Colors.grey, size: 22),
                        ),
                        Expanded(child: _buildBalanceFlowItem('Distributed', '${dist.totalDistributed} L', const Color(0xFFE98324))),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.remove_rounded, color: Colors.grey, size: 22),
                        ),
                        Expanded(child: _buildBalanceFlowItem('Disposed', '${disp.totalDisposed} L', AppColors.error)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.drag_handle_rounded, color: Colors.grey, size: 22),
                        ),
                        Expanded(child: _buildBalanceFlowItem('Remaining Fridge', '${stock.remainingFridgeMilk} L', const Color(0xFF2563EB))),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Shift-wise Breakdown Details
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 650;

                    final morningCard = Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE98324).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE98324).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.wb_sunny_rounded, size: 16, color: Color(0xFFE98324)),
                              SizedBox(width: 6),
                              Text(
                                'Morning Shift Breakdown',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE98324)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Produced: ${prod.morningProduced} L (${prod.morningCowsCount} cows)'),
                          Text('Distributed: ${dist.morningDistributed} L'),
                          Text('Available Shift Balance: ${stock.morningAvailable} L',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );

                    final eveningCard = Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.nights_stay_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Evening Shift Breakdown',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Produced: ${prod.eveningProduced} L (${prod.eveningCowsCount} cows)'),
                          Text('Distributed: ${dist.eveningDistributed} L'),
                          Text('Available Shift Balance: ${stock.eveningAvailable} L',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );

                    if (isSmall) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          morningCard,
                          const SizedBox(height: 12),
                          eveningCard,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: morningCard),
                        const SizedBox(width: 14),
                        Expanded(child: eveningCard),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // SUMMARY METRICS CARDS (HERD & CATTLE STYLE WITH HOVER LIFT & GLOW)
  // ---------------------------------------------------------------------------
  Widget _buildMetricCards(
    BuildContext context,
    MilkProductionSummary prod,
    MilkDistributionSummary dist,
    MilkDisposalSummary disp,
    MilkStockBalanceSummary stock, {
    bool isCompact = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tile1 = _HoverableMetricTile(
      title: isCompact ? 'Total Produced' : 'Total Day Produced',
      value: '${prod.totalProduced.toStringAsFixed(1)} L',
      subtitle: isCompact
          ? '${prod.totalCowsCount} cows (${prod.morningCowsCount}M+${prod.eveningCowsCount}E)'
          : '${prod.totalCowsCount} cows (${prod.morningCowsCount}M + ${prod.eveningCowsCount}E)',
      icon: PhosphorIconsRegular.drop,
      color: AppColors.primary,
      isDark: isDark,
      isCompact: isCompact,
      onTap: () => controller.changeTab(1),
    );

    final tile2 = _HoverableMetricTile(
      title: isCompact ? 'Distributed' : 'Total Distributed',
      value: '${dist.totalDistributed.toStringAsFixed(1)} L',
      subtitle: isCompact
          ? '₹ ${dist.totalRevenue.toStringAsFixed(0)} rev'
          : 'Revenue: ₹ ${dist.totalRevenue.toStringAsFixed(0)}',
      icon: PhosphorIconsRegular.truck,
      color: const Color(0xFFE98324),
      isDark: isDark,
      isCompact: isCompact,
      onTap: () => controller.changeTab(2),
    );

    final tile3 = _HoverableMetricTile(
      title: isCompact ? 'Fridge Stock' : 'Fridge Leftover Stock',
      value: '${stock.remainingFridgeMilk.toStringAsFixed(1)} L',
      subtitle: isCompact ? 'Chiller pool' : 'Available in fridge pool',
      icon: Icons.kitchen_rounded,
      color: const Color(0xFF2563EB),
      isDark: isDark,
      isCompact: isCompact,
      onTap: () => controller.changeTab(3),
    );

    final tile4 = _HoverableMetricTile(
      title: isCompact ? 'Disposed Waste' : 'Total Disposed / Waste',
      value: '${disp.totalDisposed.toStringAsFixed(1)} L',
      subtitle: isCompact ? 'Spoiled write-off' : 'Spoiled/sour write-off',
      icon: Icons.delete_sweep_rounded,
      color: AppColors.error,
      isDark: isDark,
      isCompact: isCompact,
      onTap: () => DisposeMilkDialog.show(context),
    );

    if (isCompact) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: tile1),
              const SizedBox(width: 8),
              Expanded(child: tile2),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: tile3),
              const SizedBox(width: 8),
              Expanded(child: tile4),
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
                  Expanded(child: tile1),
                  const SizedBox(width: 14),
                  Expanded(child: tile2),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: tile3),
                  const SizedBox(width: 14),
                  Expanded(child: tile4),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: tile1),
            const SizedBox(width: 16),
            Expanded(child: tile2),
            const SizedBox(width: 16),
            Expanded(child: tile3),
            const SizedBox(width: 16),
            Expanded(child: tile4),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DASHBOARD VIEW ALERTS BANNER
  // ---------------------------------------------------------------------------
  Widget _buildOverviewAlertsBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final alerts = controller.milkNotifications;
      final isChecking = controller.isCheckingMonthlyAlerts.value;
      final hasAlerts = alerts.isNotEmpty;

      if (hasAlerts) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF2F1D0E), const Color(0xFF1E1207)]
                  : [const Color(0xFFFFF6ED), const Color(0xFFFEF0DE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE98324).withValues(alpha: isDark ? 0.6 : 0.42),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE98324).withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 720;
                  final headerText = Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE98324),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE98324).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.crisis_alert_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Milk Production Alerts & Drop Warnings',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD32F2F),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${alerts.length} ACTIVE ALERT${alerts.length > 1 ? 'S' : ''}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Cows exhibiting yield fluctuations ≥ ±10%. Click any alert to view diagnosis & metrics.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final actionButtons = Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      CustomButton(
                        text: 'Run Monthly Analysis',
                        icon: Icons.refresh_rounded,
                        variant: ButtonVariant.outlined,
                        height: 36,
                        isLoading: isChecking,
                        onPressed: () => controller.runMonthlyAnalysis(),
                      ),
                      CustomButton(
                        text: 'View Details',
                        icon: Icons.arrow_forward_rounded,
                        variant: ButtonVariant.primary,
                        height: 36,
                        onPressed: () => controller.changeTab(4),
                      ),
                    ],
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        headerText,
                        const SizedBox(height: 14),
                        actionButtons,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: headerText),
                      const SizedBox(width: 14),
                      actionButtons,
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: const Color(0xFFE98324).withValues(alpha: 0.25),
              ),
              const SizedBox(height: 14),
              // Show up to 3 alerts directly on dashboard as clickable alert cards
              ...alerts.take(3).map((notif) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildAlertCardItem(context, notif, isDark),
                );
              }),
            ],
          ),
        );
      }

      // No alerts active state: Clean executive organic banner
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF192817) : const Color(0xFFF1F6EE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Production Variance Status: Normal',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'All cow milk yields are within expected limits (no deviations ≥ ±10%).',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CustomButton(
              text: 'Run Monthly Analysis',
              icon: Icons.insights_rounded,
              variant: ButtonVariant.outlined,
              height: 36,
              isLoading: isChecking,
              onPressed: () => controller.runMonthlyAnalysis(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAlertCardItem(BuildContext context, NotificationModel notif, bool isDark) {
    final parsed = ParsedMilkAlert.fromNotification(notif);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => MilkAlertDetailDialog.show(
          context,
          notification: notif,
          onRunAnalysis: () => controller.runMonthlyAnalysis(),
          onViewTab: () => controller.changeTab(4),
        ),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E281E) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFE98324).withValues(alpha: isDark ? 0.45 : 0.28),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top line: Alert Icon, Cow Tag, Drop Badge, and TimeAgo on the far right
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.crisis_alert_rounded,
                            size: 15,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            'Cow ${parsed.cowTag}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (parsed.dropPercent != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDE8E8),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFD32F2F).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.trending_down_rounded,
                                  size: 12,
                                  color: Color(0xFFD32F2F),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  parsed.dropPercent!,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD32F2F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (notif.timeAgo.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      notif.timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Middle line: Shift Badge, Yield Transition, and View Details button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (parsed.shift != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              parsed.shift!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        if (parsed.currentYield != null && parsed.priorYield != null)
                          Text(
                            '(${parsed.priorYield} ➔ ${parsed.currentYield})',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE98324).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE98324),
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 11,
                          color: Color(0xFFE98324),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Bottom line: Message description
              Text(
                notif.message,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF2E3A28),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceFlowItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: MILK PRODUCTION (COW-WISE & SHIFT-WISE)
  // ===========================================================================
  Widget _buildProductionTab(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
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
          // Subheader: Shift Tabs & Add Action
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 620;

                final shiftTabs = _buildProductionShiftTabs(context, isDark);
                final actionButtons = Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    CustomButton(
                      text: '+ Bulk Entry (Shift)',
                      icon: Icons.groups_rounded,
                      variant: ButtonVariant.outlined,
                      height: 40,
                      onPressed: () => AddProductionDialog.show(
                        context,
                        mode: ProductionEntryMode.bulk,
                        shift: controller.productionShift.value,
                      ),
                    ),
                    CustomButton(
                      text: '+ Single Cow Entry',
                      icon: Icons.add_rounded,
                      height: 40,
                      onPressed: () => AddProductionDialog.show(
                        context,
                        mode: ProductionEntryMode.single,
                        shift: controller.productionShift.value,
                      ),
                    ),
                  ],
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: shiftTabs,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: '+ Bulk Entry',
                              icon: Icons.groups_rounded,
                              variant: ButtonVariant.outlined,
                              height: 38,
                              onPressed: () => AddProductionDialog.show(
                                context,
                                mode: ProductionEntryMode.bulk,
                                shift: controller.productionShift.value,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomButton(
                              text: '+ Single Cow',
                              icon: Icons.add_rounded,
                              height: 38,
                              onPressed: () => AddProductionDialog.show(
                                context,
                                mode: ProductionEntryMode.single,
                                shift: controller.productionShift.value,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    shiftTabs,
                    actionButtons,
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Data Table or Mobile Cards List
          LayoutBuilder(
            builder: (context, constraints) {
              final isCardView = constraints.maxWidth < 750;
              const double minTableWidth = 980.0;
              final double tableWidth = constraints.maxWidth < minTableWidth
                  ? minTableWidth
                  : constraints.maxWidth;

              return Obx(() {
                if (controller.isLoadingProduction.value) {
                  if (isCardView) {
                    return const Padding(
                      padding: EdgeInsets.all(14),
                      child: CustomListShimmer(itemCount: 4),
                    );
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: const CustomTableShimmer(
                        rowCount: 6,
                        columnFlexes: [3, 3, 2, 2, 3, 2, 3],
                        headers: [
                          '#',
                          'TAG ID',
                          'COW NAME',
                          'SHIFT',
                          'QUANTITY',
                          'WORKER NAME',
                          'STATUS / ALERT',
                          'REMARKS',
                        ],
                      ),
                    ),
                  );
                }

                final items = controller.productionList;
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(36),
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
                            child: const Icon(PhosphorIconsRegular.cow, size: 36, color: AppColors.primary),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            controller.productionShift.value == 'all'
                                ? 'No milk production records for this date.'
                                : 'No ${controller.productionShift.value.capitalizeFirst} shift records for this date.',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Use "+ Single Cow" or "+ Bulk Entry" to record milk yields.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomButton(
                                text: '+ Bulk Entry',
                                icon: Icons.groups_rounded,
                                variant: ButtonVariant.outlined,
                                height: 38,
                                onPressed: () => AddProductionDialog.show(
                                  context,
                                  mode: ProductionEntryMode.bulk,
                                  shift: controller.productionShift.value,
                                ),
                              ),
                              const SizedBox(width: 8),
                              CustomButton(
                                text: '+ Single Cow',
                                icon: Icons.add_rounded,
                                height: 38,
                                onPressed: () => AddProductionDialog.show(
                                  context,
                                  mode: ProductionEntryMode.single,
                                  shift: controller.productionShift.value,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (isCardView) {
                  return Padding(
                    padding: const EdgeInsets.all(14),
                    child: _buildProductionCardsList(context, isDark),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Table Header matching Herd & Cattle
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
                              Expanded(flex: 3, child: _buildTableHeaderCell('TAG ID')),
                              Expanded(flex: 3, child: _buildTableHeaderCell('COW NAME')),
                              Expanded(flex: 2, child: _buildTableHeaderCell('SHIFT')),
                              Expanded(flex: 2, child: _buildTableHeaderCell('QUANTITY')),
                              Expanded(flex: 3, child: _buildTableHeaderCell('WORKER NAME')),
                              Expanded(flex: 2, child: _buildTableHeaderCell('STATUS / ALERT')),
                              Expanded(flex: 3, child: _buildTableHeaderCell('REMARKS')),
                            ],
                          ),
                        ),

                        // Table Data Rows with Herd & Cattle animation
                        ...items.asMap().entries.map((entry) {
                          final pageStartIndex = (controller.productionPage.value - 1) * controller.productionLimit.value;
                          final index = pageStartIndex + entry.key;
                          final prod = entry.value;
                          final cow = controller.findCowById(prod.cowId);
                          final worker = controller.findWorkerById(prod.workerId);

                          return _HoverableProductionTableRow(
                            key: ValueKey('${prod.id}_${prod.cowId}_${prod.quantity}_$index'),
                            index: index,
                            prod: prod,
                            cow: cow,
                            worker: worker,
                            isDark: isDark,
                          );
                        }),
                      ],
                    ),
                  ),
                );
              });
            },
          ),

          const Divider(height: 1),

          // Pagination Bar
          Obx(
            () => CustomPagination(
              totalItems: controller.productionTotal.value,
              currentPage: controller.productionPage.value,
              rowsPerPage: controller.productionLimit.value,
              onPageChanged: controller.onProductionPageChanged,
              onRowsPerPageChanged: controller.onProductionRowsPerPageChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: MILK DISTRIBUTION
  // ===========================================================================
  Widget _buildDistributionTab(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
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
          // Subheader: Shift Tabs & Add Action
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 620;
                final shiftTabs = _buildDistributionShiftTabs(context, isDark);
                final actionBtn = CustomButton(
                  text: '+ Record Distribution',
                  icon: PhosphorIconsRegular.truck,
                  onPressed: () => AddDistributionDialog.show(
                    context,
                    milkDate: controller.selectedDate.value,
                  ),
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: shiftTabs,
                      ),
                      const SizedBox(height: 12),
                      actionBtn,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    shiftTabs,
                    actionBtn,
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Data Table or Mobile Cards List
          LayoutBuilder(
            builder: (context, constraints) {
              final isCardView = constraints.maxWidth < 750;
              const double minTableWidth = 980.0;
              final double tableWidth = constraints.maxWidth < minTableWidth
                  ? minTableWidth
                  : constraints.maxWidth;

              return Obx(() {
                if (controller.isLoadingDistribution.value) {
                  if (isCardView) {
                    return const Padding(
                      padding: EdgeInsets.all(14),
                      child: CustomListShimmer(itemCount: 4),
                    );
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: const CustomTableShimmer(
                        rowCount: 6,
                        columnFlexes: [2, 2, 3, 2, 2, 2, 2, 3],
                        headers: [
                          '#',
                          'MILK DATE',
                          'SHIFT / POOL',
                          'RECIPIENT',
                          'QUANTITY (L)',
                          'RATE / L',
                          'TOTAL AMOUNT',
                          'ENTRY TYPE',
                          'REMARKS',
                        ],
                      ),
                    ),
                  );
                }

                final items = controller.distributionList;
                if (items.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(isCardView ? 24 : 50),
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
                            child: const Icon(PhosphorIconsRegular.truck, size: 36, color: AppColors.primary),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            controller.distributionShift.value == 'all'
                                ? 'No distribution records for this date.'
                                : 'No ${controller.distributionShift.value.capitalizeFirst} shift distributions for this date.',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Click "+ Record Distribution" to record customer sales or plant transfers.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          CustomButton(
                            text: '+ Record Distribution',
                            icon: PhosphorIconsRegular.truck,
                            width: 200,
                            height: 40,
                            onPressed: () => AddDistributionDialog.show(
                              context,
                              milkDate: controller.selectedDate.value,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (isCardView) {
                  return Padding(
                    padding: const EdgeInsets.all(14),
                    child: _buildDistributionCardsList(context, isDark),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Table Header matching Herd & Cattle
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
                              Expanded(flex: 2, child: _buildTableHeaderCell('MILK DATE')),
                              Expanded(flex: 2, child: _buildTableHeaderCell('SHIFT / POOL')),
                              Expanded(flex: 3, child: _buildTableHeaderCell('RECIPIENT')),
                              Expanded(flex: 2, child: _buildTableHeaderCell('QUANTITY (L)')),
                              Expanded(flex: 2, child: _buildTableHeaderCell('RATE / L')),
                              Expanded(flex: 2, child: _buildTableHeaderCell('TOTAL AMOUNT')),
                              Expanded(flex: 2, child: _buildTableHeaderCell('ENTRY TYPE')),
                              Expanded(flex: 3, child: _buildTableHeaderCell('REMARKS')),
                            ],
                          ),
                        ),

                        // Table Data Rows with Herd & Cattle animation
                        ...items.asMap().entries.map((entry) {
                          final pageStartIndex = (controller.distributionPage.value - 1) * controller.distributionLimit.value;
                          final index = pageStartIndex + entry.key;
                          final dist = entry.value;

                          return _HoverableDistributionTableRow(
                            key: ValueKey('${dist.id}_${dist.quantity}_$index'),
                            index: index,
                            dist: dist,
                            isDark: isDark,
                          );
                        }),
                      ],
                    ),
                  ),
                );
              });
            },
          ),

          const Divider(height: 1),

          // Pagination Bar
          Obx(
            () => CustomPagination(
              totalItems: controller.distributionTotal.value,
              currentPage: controller.distributionPage.value,
              rowsPerPage: controller.distributionLimit.value,
              onPageChanged: controller.onDistributionPageChanged,
              onRowsPerPageChanged: controller.onDistributionRowsPerPageChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: FRIDGE STOCK & SPOILAGE DISPOSAL
  // ===========================================================================
  Widget _buildFridgeStockTab(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Banner for Fridge Leftovers
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 650;
                  final titleWidget = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.kitchen_rounded, color: Color(0xFF2563EB), size: 22),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Pending Leftover Milk in Fridge Pool',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );

                  final actionBtn = CustomButton(
                    text: '+ Record Waste Disposal',
                    icon: Icons.delete_sweep_rounded,
                    variant: ButtonVariant.danger,
                    onPressed: () => DisposeMilkDialog.show(context),
                  );

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        titleWidget,
                        const SizedBox(height: 12),
                        actionBtn,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      titleWidget,
                      actionBtn,
                    ],
                  );
                },
              ),
              const SizedBox(height: 6),
              Text(
                'List of all past production dates where unallocated milk remains preserved in chiller stock.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 14),

              // Fridge Table or Mobile Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCardView = constraints.maxWidth < 750;
                  const double minTableWidth = 850.0;
                  final double tableWidth = constraints.maxWidth < minTableWidth
                      ? minTableWidth
                      : constraints.maxWidth;

                  return Obx(() {
                    if (controller.isLoadingFridgeStock.value) {
                      if (isCardView) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CustomListShimmer(itemCount: 3),
                        );
                      }
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: tableWidth,
                          child: const CustomTableShimmer(
                            rowCount: 4,
                            columnFlexes: [2, 2, 2, 2, 2, 2],
                            headers: [
                              '#',
                              'MILK BATCH DATE',
                              'TOTAL PRODUCED',
                              'TOTAL DISTRIBUTED',
                              'TOTAL DISPOSED',
                              'REMAINING IN FRIDGE',
                              'ACTION',
                            ],
                          ),
                        ),
                      );
                    }

                    final stocks = controller.fridgeStockList;
                    if (stocks.isEmpty) {
                      return Container(
                        padding: EdgeInsets.all(isCardView ? 24 : 32),
                        alignment: Alignment.center,
                        child: const Text(
                          'All past milk batches are distributed or accounted for. No pending fridge stock.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    if (isCardView) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildFridgeStockCardsList(context, isDark),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Table Header matching Herd & Cattle
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
                                  Expanded(flex: 2, child: _buildTableHeaderCell('MILK BATCH DATE')),
                                  Expanded(flex: 2, child: _buildTableHeaderCell('TOTAL PRODUCED')),
                                  Expanded(flex: 2, child: _buildTableHeaderCell('TOTAL DISTRIBUTED')),
                                  Expanded(flex: 2, child: _buildTableHeaderCell('TOTAL DISPOSED')),
                                  Expanded(flex: 2, child: _buildTableHeaderCell('REMAINING IN FRIDGE')),
                                  Expanded(flex: 2, child: _buildTableHeaderCell('ACTION')),
                                ],
                              ),
                            ),

                            // Table Data Rows with Herd & Cattle animation
                            ...stocks.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;

                              return _HoverableFridgeStockTableRow(
                                key: ValueKey('${item.milkDate}_$index'),
                                index: index,
                                item: item,
                                isDark: isDark,
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Disposal / Spoilage History Table Card
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(18.0),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, size: 20, color: AppColors.error),
                    SizedBox(width: 8),
                    Text(
                      'Spoiled Milk Disposal Log History',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isCardView = constraints.maxWidth < 750;
                  const double minTableWidth = 920.0;
                  final double tableWidth = constraints.maxWidth < minTableWidth
                      ? minTableWidth
                      : constraints.maxWidth;

                  return Obx(() {
                    if (controller.isLoadingDisposal.value) {
                      if (isCardView) {
                        return const Padding(
                          padding: EdgeInsets.all(14),
                          child: CustomListShimmer(itemCount: 3),
                        );
                      }
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: tableWidth,
                          child: const CustomTableShimmer(
                            rowCount: 5,
                            columnFlexes: [2, 2, 2, 3, 3, 3],
                            headers: [
                              '#',
                              'MILK BATCH DATE',
                              'DISPOSAL DATE',
                              'QUANTITY DISPOSED',
                              'REASON',
                              'REPORTED BY',
                              'REMARKS',
                            ],
                          ),
                        ),
                      );
                    }

                    final disposals = controller.disposalList;
                    if (disposals.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.all(isCardView ? 24 : 36),
                        child: const Center(
                          child: Text(
                            'No milk disposals recorded.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (isCardView) {
                      return Padding(
                        padding: const EdgeInsets.all(14),
                        child: _buildDisposalCardsList(context, isDark),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Table Header matching Herd & Cattle
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
                                  Expanded(flex: 2, child: _buildTableHeaderCell('MILK BATCH DATE')),
                                  Expanded(flex: 2, child: _buildTableHeaderCell('DISPOSAL DATE')),
                                  Expanded(flex: 2, child: _buildTableHeaderCell('QUANTITY DISPOSED')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('REASON')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('REPORTED BY')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('REMARKS')),
                                ],
                              ),
                            ),

                            // Table Data Rows with Herd & Cattle animation
                            ...disposals.asMap().entries.map((entry) {
                              final pageStartIndex = (controller.disposalPage.value - 1) * controller.disposalLimit.value;
                              final index = pageStartIndex + entry.key;
                              final d = entry.value;

                              return _HoverableDisposalTableRow(
                                key: ValueKey('${d.id}_${d.quantity}_$index'),
                                index: index,
                                disposal: d,
                                isDark: isDark,
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  });
                },
              ),

              // Pagination Bar
              Obx(
                () => CustomPagination(
                  totalItems: controller.disposalTotal.value,
                  currentPage: controller.disposalPage.value,
                  rowsPerPage: controller.disposalLimit.value,
                  onPageChanged: controller.onDisposalPageChanged,
                  onRowsPerPageChanged: controller.onDisposalRowsPerPageChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 5: MONTHLY VARIANCE & ALERTS
  // ===========================================================================
  Widget _buildMonthlyAlertsTab(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Trigger Analysis
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 680;
              final headerInfo = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE98324).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: Color(0xFFE98324),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monthly Variance Analysis & In-App Alerts',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Monitors cows with production fluctuations ≥ ±10% to catch health issues early.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final actionBtn = Obx(
                () => CustomButton(
                  text: 'Run Monthly Analysis',
                  icon: Icons.play_arrow_rounded,
                  isLoading: controller.isCheckingMonthlyAlerts.value,
                  onPressed: () => controller.runMonthlyAnalysis(),
                ),
              );

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    headerInfo,
                    const SizedBox(height: 14),
                    actionBtn,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: headerInfo),
                  const SizedBox(width: 14),
                  actionBtn,
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 18),

          // In-App Notifications List
          const Text(
            'Production Alert Notifications (Type: MILK_PRODUCTION_ALERT)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Obx(() {
            if (controller.isLoadingNotifications.value) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CustomBrandedSpinner(size: LoaderSize.small)),
              );
            }

            final alerts = controller.milkNotifications;
            if (alerts.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF22351B) : const Color(0xFFF9FAF7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 36),
                    SizedBox(height: 8),
                    Text(
                      'No Production Alerts Active',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text('All cow production logs are within normal historical limits (±10%).'),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alerts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _buildAlertCardItem(context, alerts[index], isDark);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String title, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Text(
        title,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondaryLight,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildProductionShiftTabs(BuildContext context, bool isDark) {
    return Obx(() {
      final active = controller.productionShift.value;

      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildShiftTabPill(
              label: 'All Shifts',
              isActive: active == 'all',
              isDark: isDark,
              onTap: () => controller.changeProductionShift('all'),
            ),
            _buildShiftTabPill(
              label: 'Morning',
              isActive: active == 'morning',
              isDark: isDark,
              onTap: () => controller.changeProductionShift('morning'),
            ),
            _buildShiftTabPill(
              label: 'Evening',
              isActive: active == 'evening',
              isDark: isDark,
              onTap: () => controller.changeProductionShift('evening'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDistributionShiftTabs(BuildContext context, bool isDark) {
    return Obx(() {
      final active = controller.distributionShift.value;

      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildShiftTabPill(
              label: 'All Shifts',
              isActive: active == 'all',
              isDark: isDark,
              onTap: () => controller.changeDistributionShift('all'),
            ),
            _buildShiftTabPill(
              label: 'Morning',
              isActive: active == 'morning',
              isDark: isDark,
              onTap: () => controller.changeDistributionShift('morning'),
            ),
            _buildShiftTabPill(
              label: 'Evening',
              isActive: active == 'evening',
              isDark: isDark,
              onTap: () => controller.changeDistributionShift('evening'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildShiftTabPill({
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? AppColors.primary : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? (isDark ? Colors.white : AppColors.primary)
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MOBILE / TABLET CARDS LISTS & ACTIONS (HERD & CATTLE PATTERN)
  // ===========================================================================

  Widget _buildProductionCardsList(BuildContext context, bool isDark) {
    final items = controller.productionList;
    return Column(
      children: items.asMap().entries.map((entry) {
        final prod = entry.value;
        final cow = controller.findCowById(prod.cowId);
        final worker = controller.findWorkerById(prod.workerId);

        // Resolve Cow Name (never show raw mongo id)
        String cowName = '';
        if (prod.cowName != null &&
            prod.cowName!.trim().isNotEmpty &&
            !MilkProductionModel.isMongoHexId(prod.cowName)) {
          cowName = prod.cowName!.trim();
        } else if (cow?.calfName != null &&
            cow!.calfName!.trim().isNotEmpty &&
            !MilkProductionModel.isMongoHexId(cow.calfName)) {
          cowName = cow.calfName!.trim();
        }

        // Resolve Cow Tag (never show raw mongo id)
        String cowTag = '';
        if (prod.cowTag.trim().isNotEmpty && !MilkProductionModel.isMongoHexId(prod.cowTag)) {
          cowTag = prod.cowTag.trim();
        } else if (cow?.tagId != null &&
            cow!.tagId.trim().isNotEmpty &&
            !MilkProductionModel.isMongoHexId(cow.tagId)) {
          cowTag = cow.tagId.trim();
        }

        // Resolve Worker Name (never show Worker #<mongoId>)
        String workerDisplayName = 'Assigned Worker';
        if (prod.workerName != null &&
            prod.workerName!.trim().isNotEmpty &&
            !MilkProductionModel.isMongoHexId(prod.workerName) &&
            !prod.workerName!.startsWith('Worker #')) {
          workerDisplayName = prod.workerName!.trim();
        } else if (worker?.name != null &&
            worker!.name.trim().isNotEmpty &&
            !MilkProductionModel.isMongoHexId(worker.name)) {
          workerDisplayName = worker.name.trim();
        }

        final isMorning = prod.shift.toLowerCase() == 'morning';
        final shiftColor = isMorning ? const Color(0xFFE98324) : const Color(0xFF4F46E5);
        final shiftIcon = isMorning ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded;
        final shiftLabel = isMorning ? 'Morning' : 'Evening';

        return _HoverableListCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Tag ID badge + Cow Name & Shift pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (cowTag.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                cowTag,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          if (cowName.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                cowName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Shift pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: shiftColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: shiftColor.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(shiftIcon, size: 12, color: shiftColor),
                          const SizedBox(width: 4),
                          Text(
                            shiftLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: shiftColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Middle: Quantity stat & Alert badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(PhosphorIconsRegular.drop, size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'YIELD',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              '${prod.quantity.toStringAsFixed(1)} L',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Status Badge
                    prod.alertGenerated || (prod.variance != null && prod.variance!.abs() >= 10)
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warningBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warning),
                                const SizedBox(width: 4),
                                Text(
                                  prod.variance != null ? '${prod.variance!.toStringAsFixed(1)}%' : 'Alert',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 0.8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 13, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'Normal',
                                  style: TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Footer: Worker name & Remarks
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIconsRegular.user,
                            size: 13,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              workerDisplayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (prod.remarks?.isNotEmpty == true) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          prod.remarks!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDistributionCardsList(BuildContext context, bool isDark) {
    final items = controller.distributionList;
    return Column(
      children: items.asMap().entries.map((entry) {
        final dist = entry.value;

        // Resolve Recipient Name (never show raw mongo hex id)
        String recipientDisplay = dist.recipientName.trim();
        if (recipientDisplay.isEmpty || MilkDistributionModel.isMongoHexId(recipientDisplay)) {
          if (dist.recipientType == 'staff') {
            final worker = controller.findWorkerById(dist.customerId ?? recipientDisplay);
            recipientDisplay = worker?.name ?? 'Staff Member';
          } else {
            recipientDisplay = dist.recipientTypeEnum.label;
          }
        } else if (dist.recipientType == 'staff') {
          final worker = controller.findWorkerById(dist.customerId ?? recipientDisplay);
          if (worker != null && worker.name.trim().isNotEmpty) {
            recipientDisplay = worker.name.trim();
          }
        }

        final shiftLabel = dist.isAllShiftPool
            ? 'All Shifts (Chiller)'
            : (dist.shift.toLowerCase() == 'morning' ? 'Morning Shift' : 'Evening Shift');
        final shiftIcon = dist.isAllShiftPool
            ? Icons.kitchen_rounded
            : (dist.shift.toLowerCase() == 'morning' ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded);
        final shiftColor = dist.isAllShiftPool
            ? const Color(0xFF2563EB)
            : (dist.shift.toLowerCase() == 'morning' ? const Color(0xFFE98324) : const Color(0xFF4F46E5));

        return _HoverableListCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: Recipient Avatar + Name & Shift Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: dist.recipientTypeEnum.color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              dist.recipientTypeEnum.icon,
                              size: 15,
                              color: dist.recipientTypeEnum.color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  recipientDisplay,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                Text(
                                  dist.recipientTypeEnum.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: dist.recipientTypeEnum.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: shiftColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: shiftColor.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(shiftIcon, size: 12, color: shiftColor),
                          const SizedBox(width: 4),
                          Text(
                            shiftLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: shiftColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Middle stats: Quantity & Total Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QUANTITY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dist.quantity.toStringAsFixed(1)} L',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        if (dist.ratePerLiter > 0)
                          Text(
                            '₹${dist.ratePerLiter.toStringAsFixed(2)} / L',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                      ],
                    ),
                    // Total Amount Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'TOTAL',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                          Text(
                            '₹${dist.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Footer: Date + Entry Type pill + remarks
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(PhosphorIconsRegular.calendarBlank, size: 13, color: AppColors.textMutedLight),
                        const SizedBox(width: 4),
                        Text(
                          dist.milkDate,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    dist.isDelayedDistribution
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.kitchen_rounded, size: 11, color: Color(0xFF2563EB)),
                                SizedBox(width: 3),
                                Text(
                                  'Fridge Pool',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFBBF7D0), width: 0.8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flash_on_rounded, size: 11, color: Color(0xFF16A34A)),
                                SizedBox(width: 3),
                                Text(
                                  'Direct Shift',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
                if (dist.remarks?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    dist.remarks!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFridgeStockCardsList(BuildContext context, bool isDark) {
    final stocks = controller.fridgeStockList;
    return Column(
      children: stocks.asMap().entries.map((entry) {
        final item = entry.value;

        return _HoverableListCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: Batch Date and Remaining In Fridge Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(PhosphorIconsRegular.calendarBlank, size: 15, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Text(
                          item.milkDate,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.kitchen_rounded, size: 13, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(
                            '${item.remainingFridgeMilk.toStringAsFixed(1)} L Fridge',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Flow breakdown stats: Produced -> Distributed -> Disposed
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'PRODUCED',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.totalProduced.toStringAsFixed(1)} L',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 26, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      Column(
                        children: [
                          Text(
                            'DISTRIBUTED',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.totalDistributed.toStringAsFixed(1)} L',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 26, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      Column(
                        children: [
                          Text(
                            'DISPOSED',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: item.totalDisposed > 0 ? AppColors.error : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.totalDisposed.toStringAsFixed(1)} L',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: item.totalDisposed > 0 ? AppColors.error : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action button: Dispose Milk
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorBg,
                      foregroundColor: AppColors.error,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.3), width: 0.8),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Dispose Spoiled Milk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      DisposeMilkDialog.show(
                        context,
                        milkDate: item.milkDate,
                        maxQuantity: item.remainingFridgeMilk,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDisposalCardsList(BuildContext context, bool isDark) {
    final disposals = controller.disposalList;
    return Column(
      children: disposals.asMap().entries.map((entry) {
        final d = entry.value;

        return _HoverableListCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_rounded, size: 16, color: AppColors.error),
                        const SizedBox(width: 6),
                        Text(
                          'Disposed: ${d.disposalDate}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 0.8),
                      ),
                      child: Text(
                        '-${d.quantity.toStringAsFixed(1)} L',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Batch Date: ',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                    Text(
                      d.milkDate,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    if (d.reportedByName?.isNotEmpty == true) ...[
                      Icon(PhosphorIconsRegular.user, size: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      const SizedBox(width: 4),
                      Text(
                        d.reportedByName!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
                if (d.reason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Reason: ${d.reason}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showQuickActionModal(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Milk Quick Actions',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
                  ),
                  title: const Text('Record Single Cow Yield', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Add yield for an individual cow', style: TextStyle(fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    AddProductionDialog.show(
                      context,
                      mode: ProductionEntryMode.single,
                      shift: controller.productionShift.value,
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.groups_rounded, color: Color(0xFF4F46E5), size: 20),
                  ),
                  title: const Text('Bulk Production Entry', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Enter milk for all cows in shed at once', style: TextStyle(fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    AddProductionDialog.show(
                      context,
                      mode: ProductionEntryMode.bulk,
                      shift: controller.productionShift.value,
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE98324).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(PhosphorIconsRegular.truck, color: Color(0xFFE98324), size: 20),
                  ),
                  title: const Text('Record Milk Distribution', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Log sales, staff distribution, or calf feeding', style: TextStyle(fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    AddDistributionDialog.show(
                      context,
                      milkDate: controller.selectedDate.value,
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 20),
                  ),
                  title: const Text('Record Waste Disposal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Log curdled, spoiled, or wasted milk', style: TextStyle(fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    DisposeMilkDialog.show(context);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// HOVERABLE MILK PRODUCTION TABLE ROW (HERD & CATTLE ANIMATED STYLE)
// ---------------------------------------------------------------------------
class _HoverableProductionTableRow extends StatefulWidget {
  final int index;
  final MilkProductionModel prod;
  final CowModel? cow;
  final WorkerModel? worker;
  final bool isDark;

  const _HoverableProductionTableRow({
    super.key,
    required this.index,
    required this.prod,
    this.cow,
    this.worker,
    required this.isDark,
  });

  @override
  State<_HoverableProductionTableRow> createState() => _HoverableProductionTableRowState();
}

class _HoverableProductionTableRowState extends State<_HoverableProductionTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final prod = widget.prod;
    final isDark = widget.isDark;
    final cow = widget.cow;
    final worker = widget.worker;

    // Resolve Cow Name (never show raw mongo id)
    String cowName = '';
    if (prod.cowName != null &&
        prod.cowName!.trim().isNotEmpty &&
        !MilkProductionModel.isMongoHexId(prod.cowName)) {
      cowName = prod.cowName!.trim();
    } else if (cow?.calfName != null &&
        cow!.calfName!.trim().isNotEmpty &&
        !MilkProductionModel.isMongoHexId(cow.calfName)) {
      cowName = cow.calfName!.trim();
    }

    // Resolve Cow Tag (never show raw mongo id)
    String cowTag = '';
    if (prod.cowTag.trim().isNotEmpty && !MilkProductionModel.isMongoHexId(prod.cowTag)) {
      cowTag = prod.cowTag.trim();
    } else if (cow?.tagId != null &&
        cow!.tagId.trim().isNotEmpty &&
        !MilkProductionModel.isMongoHexId(cow.tagId)) {
      cowTag = cow.tagId.trim();
    }

    // Resolve Worker Name (never show Worker #<mongoId>)
    String workerDisplayName = 'Assigned Worker';
    if (prod.workerName != null &&
        prod.workerName!.trim().isNotEmpty &&
        !MilkProductionModel.isMongoHexId(prod.workerName) &&
        !prod.workerName!.startsWith('Worker #')) {
      workerDisplayName = prod.workerName!.trim();
    } else if (worker?.name != null &&
        worker!.name.trim().isNotEmpty &&
        !MilkProductionModel.isMongoHexId(worker.name)) {
      workerDisplayName = worker.name.trim();
    }

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // # Index
            SizedBox(
              width: 50,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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

            // Tag ID (Herd & Cattle Style)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: cowTag.isNotEmpty
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: _isHovered ? 0.20 : 0.12),
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
                                const Icon(PhosphorIconsRegular.tag, size: 13, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  cowTag,
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
                        )
                      : Text(
                          '—',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                ),
              ),
            ),

            // Cow Name (Herd & Cattle Style)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Text(
                  cowName.isNotEmpty ? cowName : '—',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                    fontStyle: cowName.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                    color: cowName.isNotEmpty
                        ? (_isHovered
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight))
                        : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ),
              ),
            ),

            // Shift
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: prod.milkShift.color.withValues(alpha: _isHovered ? 0.22 : 0.14),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: prod.milkShift.color.withValues(alpha: _isHovered ? 0.50 : 0.28),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(prod.milkShift.icon, size: 13, color: prod.milkShift.color),
                        const SizedBox(width: 5),
                        Text(
                          prod.milkShift.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: prod.milkShift.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Quantity (L)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 160),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: _isHovered
                        ? (isDark ? AppColors.primaryLight : AppColors.primary)
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                  child: Text('${prod.quantity.toStringAsFixed(1)} L'),
                ),
              ),
            ),



            // Worker Name
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Text(
                  workerDisplayName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                    color: _isHovered
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                ),
              ),
            ),

            // Status / Variance
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: prod.alertGenerated || (prod.variance != null && prod.variance!.abs() >= 10)
                      ? AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: _isHovered ? 0.7 : 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Text(
                                prod.variance != null ? '${prod.variance!.toStringAsFixed(1)}%' : 'Alert',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA5D6A7), width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 13, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Normal',
                                style: TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),

            // Remarks
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Text(
                  prod.remarks?.isNotEmpty == true ? prod.remarks! : '—',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: prod.remarks?.isNotEmpty == true ? FontStyle.normal : FontStyle.italic,
                    color: prod.remarks?.isNotEmpty == true
                        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                        : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HOVERABLE MILK DISTRIBUTION TABLE ROW (HERD & CATTLE ANIMATED STYLE)
// ---------------------------------------------------------------------------
class _HoverableDistributionTableRow extends StatefulWidget {
  final int index;
  final MilkDistributionModel dist;
  final bool isDark;

  const _HoverableDistributionTableRow({
    super.key,
    required this.index,
    required this.dist,
    required this.isDark,
  });

  @override
  State<_HoverableDistributionTableRow> createState() => _HoverableDistributionTableRowState();
}

class _HoverableDistributionTableRowState extends State<_HoverableDistributionTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final dist = widget.dist;
    final isDark = widget.isDark;
    final milkCtrl = Get.find<MilkController>();

    // Resolve Recipient Name (never show raw mongo hex id)
    String recipientDisplay = dist.recipientName.trim();
    if (recipientDisplay.isEmpty || MilkDistributionModel.isMongoHexId(recipientDisplay)) {
      if (dist.recipientType == 'staff') {
        final worker = milkCtrl.findWorkerById(dist.customerId ?? recipientDisplay);
        recipientDisplay = worker?.name ?? 'Staff Member';
      } else {
        recipientDisplay = dist.recipientTypeEnum.label;
      }
    } else if (dist.recipientType == 'staff') {
      final worker = milkCtrl.findWorkerById(dist.customerId ?? recipientDisplay);
      if (worker != null && worker.name.trim().isNotEmpty) {
        recipientDisplay = worker.name.trim();
      }
    }

    final shiftLabel = dist.isAllShiftPool
        ? 'All Shifts (Chiller)'
        : (dist.shift.toLowerCase() == 'morning' ? 'Morning Shift' : 'Evening Shift');
    final shiftIcon = dist.isAllShiftPool
        ? Icons.kitchen_rounded
        : (dist.shift.toLowerCase() == 'morning' ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded);
    final shiftColor = dist.isAllShiftPool
        ? const Color(0xFF2563EB)
        : (dist.shift.toLowerCase() == 'morning' ? const Color(0xFFE98324) : const Color(0xFF4F46E5));

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // # Index
            SizedBox(
              width: 50,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
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

            // Milk Date
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsRegular.calendarBlank, size: 14, color: AppColors.textMutedLight),
                    const SizedBox(width: 6),
                    Text(
                      dist.milkDate,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Shift / Pool
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: shiftColor.withValues(alpha: _isHovered ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: shiftColor.withValues(alpha: _isHovered ? 0.50 : 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(shiftIcon, size: 13, color: shiftColor),
                        const SizedBox(width: 5),
                        Text(
                          shiftLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: shiftColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Recipient (Resolved Name - never raw hex id)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: dist.recipientTypeEnum.color.withValues(alpha: _isHovered ? 0.22 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        dist.recipientTypeEnum.icon,
                        size: 15,
                        color: dist.recipientTypeEnum.color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            recipientDisplay,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: _isHovered
                                  ? (isDark ? Colors.white : AppColors.primary)
                                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dist.recipientTypeEnum.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: dist.recipientTypeEnum.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quantity (L)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 160),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: _isHovered
                        ? (isDark ? AppColors.primaryLight : AppColors.primary)
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                  child: Text('${dist.quantity.toStringAsFixed(1)} L'),
                ),
              ),
            ),

            // Rate / L
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Text(
                  '₹${dist.ratePerLiter.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),

            // Total Amount
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: _isHovered ? 0.20 : 0.10),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: _isHovered ? 0.50 : 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '₹${dist.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Entry Type
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: dist.isDelayedDistribution
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.kitchen_rounded, size: 12.5, color: Color(0xFF2563EB)),
                              SizedBox(width: 4),
                              Text(
                                'Fridge Pool',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBBF7D0), width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flash_on_rounded, size: 12.5, color: Color(0xFF16A34A)),
                              SizedBox(width: 4),
                              Text(
                                'Direct Shift',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),

            // Remarks
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Text(
                  dist.remarks?.isNotEmpty == true ? dist.remarks! : '—',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: dist.remarks?.isNotEmpty == true ? FontStyle.normal : FontStyle.italic,
                    color: dist.remarks?.isNotEmpty == true
                        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                        : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HOVERABLE MILK DISPOSAL TABLE ROW (HERD & CATTLE ANIMATED STYLE)
// ---------------------------------------------------------------------------
class _HoverableDisposalTableRow extends StatefulWidget {
  final int index;
  final MilkDisposalModel disposal;
  final bool isDark;

  const _HoverableDisposalTableRow({
    super.key,
    required this.index,
    required this.disposal,
    required this.isDark,
  });

  @override
  State<_HoverableDisposalTableRow> createState() => _HoverableDisposalTableRowState();
}

class _HoverableDisposalTableRowState extends State<_HoverableDisposalTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.disposal;
    final isDark = widget.isDark;
    final milkCtrl = Get.find<MilkController>();

    // Resolve Worker Name (never show raw mongo id or Worker #<id>)
    String reporterName = 'Staff Member';
    if (d.reportedByName != null &&
        d.reportedByName!.trim().isNotEmpty &&
        !MilkDisposalModel.isMongoHexId(d.reportedByName) &&
        !d.reportedByName!.startsWith('Worker #')) {
      reporterName = d.reportedByName!.trim();
    } else {
      final worker = milkCtrl.findWorkerById(d.reportedBy);
      if (worker != null && worker.name.trim().isNotEmpty) {
        reporterName = worker.name.trim();
      }
    }

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
                  : AppColors.error.withValues(alpha: 0.045))
              : Colors.transparent,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 0.6,
            ),
            left: BorderSide(
              color: _isHovered ? AppColors.error : Colors.transparent,
              width: 3.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // # Index
            SizedBox(
              width: 50,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 160),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _isHovered ? FontWeight.bold : FontWeight.w500,
                    color: _isHovered ? AppColors.error : AppColors.textSecondaryLight,
                  ),
                  child: Text('${widget.index + 1}'),
                ),
              ),
            ),

            // Milk Batch Date
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.kitchen_rounded, size: 14, color: AppColors.textMutedLight),
                    const SizedBox(width: 6),
                    Text(
                      d.milkDate,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Disposal Date
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Text(
                  d.disposalDate,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),

            // Quantity Disposed
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 160),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: AppColors.error,
                  ),
                  child: Text('${d.quantity.toStringAsFixed(1)} L'),
                ),
              ),
            ),

            // Reason
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: d.disposalReasonEnum.color.withValues(alpha: _isHovered ? 0.22 : 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: d.disposalReasonEnum.color.withValues(alpha: _isHovered ? 0.50 : 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(d.disposalReasonEnum.icon, size: 13, color: d.disposalReasonEnum.color),
                        const SizedBox(width: 5),
                        Text(
                          d.disposalReasonEnum.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: d.disposalReasonEnum.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Reported By (Resolved Worker Name)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: _isHovered ? 0.20 : 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(PhosphorIconsRegular.user, size: 13, color: Colors.blueGrey),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reporterName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                          color: _isHovered
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Remarks
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Text(
                  d.remarks?.isNotEmpty == true ? d.remarks! : '—',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: d.remarks?.isNotEmpty == true ? FontStyle.normal : FontStyle.italic,
                    color: d.remarks?.isNotEmpty == true
                        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                        : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HOVERABLE FRIDGE STOCK TABLE ROW (HERD & CATTLE ANIMATED STYLE)
// ---------------------------------------------------------------------------
class _HoverableFridgeStockTableRow extends StatefulWidget {
  final int index;
  final FridgeStockModel item;
  final bool isDark;

  const _HoverableFridgeStockTableRow({
    super.key,
    required this.index,
    required this.item,
    required this.isDark,
  });

  @override
  State<_HoverableFridgeStockTableRow> createState() => _HoverableFridgeStockTableRowState();
}

class _HoverableFridgeStockTableRowState extends State<_HoverableFridgeStockTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
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
                  : const Color(0xFF2563EB).withValues(alpha: 0.045))
              : Colors.transparent,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 0.6,
            ),
            left: BorderSide(
              color: _isHovered ? const Color(0xFF2563EB) : Colors.transparent,
              width: 3.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // # Index
            SizedBox(
              width: 50,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 160),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _isHovered ? FontWeight.bold : FontWeight.w500,
                    color: _isHovered ? const Color(0xFF2563EB) : AppColors.textSecondaryLight,
                  ),
                  child: Text('${widget.index + 1}'),
                ),
              ),
            ),

            // Milk Batch Date
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsRegular.calendarBlank, size: 14, color: AppColors.textMutedLight),
                    const SizedBox(width: 6),
                    Text(
                      item.milkDate,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Total Produced
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Text(
                  '${item.totalProduced.toStringAsFixed(1)} L',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),

            // Total Distributed
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Text(
                  '${item.totalDistributed.toStringAsFixed(1)} L',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),

            // Total Disposed
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Text(
                  '${item.totalDisposed.toStringAsFixed(1)} L',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: item.totalDisposed > 0 ? AppColors.error : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                ),
              ),
            ),

            // Remaining in Fridge
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: _isHovered ? 0.22 : 0.14),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withValues(alpha: _isHovered ? 0.50 : 0.28),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '${item.remainingFridgeMilk.toStringAsFixed(1)} L',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Action: Dispose Button
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorBg,
                      foregroundColor: AppColors.error,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 15),
                    label: const Text('Dispose Milk', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      DisposeMilkDialog.show(
                        context,
                        milkDate: item.milkDate,
                        maxQuantity: item.remainingFridgeMilk,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hoverable Metric Card with luxury elevation and organic brand glow matching Herd & Cattle module
class _HoverableMetricTile extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool isCompact;
  final VoidCallback? onTap;

  const _HoverableMetricTile({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    this.isCompact = false,
    this.onTap,
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
              color: _isHovered
                  ? effectiveColor.withValues(alpha: 0.60)
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: 1.0,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.isCompact ? 11 : 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
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
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
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

/// Hoverable Card for mobile/tablet list views matching Herd & Cattle architecture
class _HoverableListCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  const _HoverableListCard({required this.child, this.margin});

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
        margin: widget.margin,
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

