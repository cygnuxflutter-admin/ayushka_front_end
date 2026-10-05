import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/utils/responsive_layout.dart';
import '../../core/values/app_colors.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/widgets/global_gaushala_selector.dart';
import '../../core/widgets/header_user_profile_badge.dart';
import '../dashboard/widgets/mobile_drawer.dart';
import '../dashboard/widgets/web_sidebar.dart';
import '../notification/widgets/notification_bell_widget.dart';
import 'medical_stock_controller.dart';
import 'views/batches_tracker_view.dart';
import 'views/medical_dashboard_view.dart';
import 'views/medicine_master_view.dart';
import 'views/stock_inward_view.dart';
import 'views/stock_ledger_view.dart';
import 'views/stock_outward_view.dart';
import 'widgets/medical_stock_animations.dart';

/// Master Container Screen for Veterinary / Medical Stock Management
/// Features responsive desktop sidebar, global gaushala selector,
/// clean ERP sub-navigation tabs with live badge counters, and 6 specialized views.
class MedicalStockScreen extends GetView<MedicalStockController> {
  const MedicalStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBuilder: (context) => _buildMobileScaffold(context),
      tabletBuilder: (context) => _buildTabletScaffold(context),
      desktopBuilder: (context) => _buildDesktopScaffold(context),
    );
  }

  Widget _buildTabBody() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CustomBrandedSpinner(message: 'Loading Veterinary Stock System...'));
      }

      return LazyIndexedStack(
        index: controller.selectedTab.value,
        itemBuilders: [
          (context) => const MedicalDashboardView(),
          (context) => const MedicineMasterView(),
          (context) => const StockInwardView(),
          (context) => const StockOutwardView(),
          (context) => const BatchesTrackerView(),
          (context) => const StockLedgerView(),
        ],
      );
    });
  }

  // -------------------------------------------------------------
  // DESKTOP SCAFFOLD
  // -------------------------------------------------------------
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

          // Main Module Area
          Expanded(
            child: Column(
              children: [
                // Desktop Header
                _buildDesktopHeader(context),

                // Module Navigation Sub-Tabs
                _buildModuleTabBar(context),

                // Active View Body - instant tab switching with state retention
                Expanded(
                  child: _buildTabBody(),
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
        title: const Text('Veterinary Medical Stock'),
        actions: [
          const NotificationBellWidget(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: controller.refreshAllData,
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
      body: Column(
        children: [
          _buildModuleTabBar(context, isCompact: true),
          Expanded(
            child: _buildTabBody(),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // MOBILE SCAFFOLD
  // -------------------------------------------------------------
  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Stock'),
        actions: [
          const NotificationBellWidget(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.refreshAllData,
          ),
        ],
      ),
      drawer: Obx(
        () => MobileDrawer(
          currentUser: controller.currentUser.value,
          onLogout: controller.logout,
        ),
      ),
      body: Column(
        children: [
          _buildModuleTabBar(context, isCompact: true),
          Expanded(
            child: _buildTabBody(),
          ),
        ],
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
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
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
          // Left: Module label & Title
          Row(
            children: [
              Obx(
                () => IconButton(
                  icon: Icon(
                    controller.isSidebarCollapsed.value ? Icons.menu_open_rounded : Icons.menu_rounded,
                    size: 22,
                  ),
                  tooltip: controller.isSidebarCollapsed.value ? 'Expand Sidebar' : 'Collapse Sidebar',
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
                  'VETERINARY & PHARMACY',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Medical Stock Management',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              PulsingBadge(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsRegular.shieldCheck, size: 14, color: Color(0xFF10B981)),
                      SizedBox(width: 5),
                      Text(
                        'FEFO Compliant',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Right: Gaushala Selector & Refresh & User Profile
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
                      : const Icon(Icons.refresh_rounded),
                  tooltip: isBusy ? 'Refreshing...' : 'Refresh Stock',
                  onPressed: isBusy ? null : controller.refreshAllData,
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
  // MODULE SUB-TABS NAVIGATION BAR
  // -------------------------------------------------------------
  Widget _buildModuleTabBar(BuildContext context, {bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAF7),
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() {
          final activeIndex = controller.selectedTab.value;
          final lowStockCount = controller.summary.value.lowStockItemsCount;
          final expiringCount = controller.summary.value.expiringSoonBatchesCount + controller.summary.value.expiredBatchesCount;

          return Row(
            children: [
              AnimatedModuleTabItem(
                index: 0,
                label: 'Dashboard & Summary',
                icon: PhosphorIconsRegular.chartPieSlice,
                isActive: activeIndex == 0,
                onTap: () => controller.switchTab(0),
              ),
              const SizedBox(width: 8),
              AnimatedModuleTabItem(
                index: 1,
                label: 'Medicine Master',
                icon: PhosphorIconsRegular.pill,
                isActive: activeIndex == 1,
                badge: lowStockCount > 0 ? '$lowStockCount low' : null,
                badgeColor: const Color(0xFFF59E0B),
                onTap: () => controller.switchTab(1),
              ),
              const SizedBox(width: 8),
              AnimatedModuleTabItem(
                index: 2,
                label: 'Stock Inward (Purchase)',
                icon: PhosphorIconsRegular.arrowDownLeft,
                isActive: activeIndex == 2,
                iconColor: const Color(0xFF10B981),
                onTap: () => controller.switchTab(2),
              ),
              const SizedBox(width: 8),
              AnimatedModuleTabItem(
                index: 3,
                label: 'Stock Outward (Dispense)',
                icon: PhosphorIconsRegular.arrowUpRight,
                isActive: activeIndex == 3,
                iconColor: const Color(0xFFF59E0B),
                onTap: () => controller.switchTab(3),
              ),
              const SizedBox(width: 8),
              AnimatedModuleTabItem(
                index: 4,
                label: 'Batches & Expiry Tracker',
                icon: PhosphorIconsRegular.clockCountdown,
                isActive: activeIndex == 4,
                badge: expiringCount > 0 ? '$expiringCount' : null,
                badgeColor: const Color(0xFFEA580C),
                onTap: () => controller.switchTab(4),
              ),
              const SizedBox(width: 8),
              AnimatedModuleTabItem(
                index: 5,
                label: 'Stock Ledger / Audit Log',
                icon: PhosphorIconsRegular.scroll,
                isActive: activeIndex == 5,
                onTap: () => controller.switchTab(5),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Lazy indexed stack that mounts views only upon first activation
/// and keeps them alive in memory so subsequent tab switches are instantaneous (0ms)
/// with zero reloading lag, zero frame drops, and full retention of state and scroll position.
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<WidgetBuilder> itemBuilders;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.itemBuilders,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final List<Widget?> _activatedChildren;

  @override
  void initState() {
    super.initState();
    _activatedChildren = List<Widget?>.filled(widget.itemBuilders.length, null);
    _activate(widget.index);
  }

  @override
  void didUpdateWidget(covariant LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _activate(widget.index);
  }

  void _activate(int index) {
    if (index >= 0 && index < _activatedChildren.length && _activatedChildren[index] == null) {
      _activatedChildren[index] = widget.itemBuilders[index](context);
    }
  }

  @override
  Widget build(BuildContext context) {
    _activate(widget.index);
    return IndexedStack(
      index: widget.index,
      children: List.generate(
        widget.itemBuilders.length,
        (i) => _activatedChildren[i] ?? const SizedBox.shrink(),
      ),
    );
  }
}

