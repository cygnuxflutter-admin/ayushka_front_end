import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/values/app_colors.dart';
import '../../core/values/app_constants.dart';
import '../../core/widgets/global_gaushala_selector.dart';
import '../../core/widgets/header_user_profile_badge.dart';
import '../../routes/app_routes.dart';
import '../notification/widgets/notification_bell_widget.dart';
import 'dashboard_controller.dart';
import 'widgets/dashboard_farm_telemetry_card.dart';
import 'widgets/dashboard_hero_banner.dart';
import 'widgets/dashboard_kpi_strip.dart';
import 'widgets/mobile_drawer.dart';
import 'widgets/smart_alerts_center.dart';
import 'widgets/web_sidebar.dart';

/// Production-ready Smart Alerts Center & Dashboard for Ayushka Admin Portal.
/// Features module-wise operational alerts, inline fast actions, and telemetry KPIs.
class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

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
          // Persistent Web Sidebar
          Obx(
            () => WebSidebar(
              isCollapsed: controller.isSidebarCollapsed.value,
              onToggle: controller.toggleSidebar,
              currentUser: controller.currentUser.value,
              onLogout: controller.logout,
            ),
          ),

          // Main Farm Workplace
          Expanded(
            child: Column(
              children: [
                // Top Header
                _buildDesktopHeader(context),

                // Main Content Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: _buildDashboardContent(context),
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
        title: const Text('Ayushka Farm Dashboard'),
        actions: [
          const NotificationBellWidget(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.refreshFarmData,
            tooltip: 'Refresh Farm Data',
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
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _buildDashboardContent(context),
          ),
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
        title: const Text(
          AppConstants.appName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          const NotificationBellWidget(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.refreshFarmData,
            tooltip: 'Refresh Farm Data',
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
        padding: const EdgeInsets.all(16.0),
        child: _buildDashboardContent(context),
      ),
    );
  }

  // -------------------------------------------------------------
  // TOP DESKTOP HEADER
  // -------------------------------------------------------------
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
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'STATION ONLINE',
                      style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Ayushka Smart Dairy Workplace',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            children: [
              const GlobalGaushalaSelector(),
              const SizedBox(width: 8),
              const NotificationBellWidget(),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Refresh Farm Data',
                onPressed: controller.refreshFarmData,
              ),
              const SizedBox(width: 10),
              Obx(() => HeaderUserProfileBadge(user: controller.currentUser.value)),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // MAIN DASHBOARD CONTENT
  // -------------------------------------------------------------
  Widget _buildDashboardContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);
    final isTablet = ResponsiveLayout.isTablet(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Ultra-Creative Forest Green Hero Station Banner
        DashboardHeroBanner(controller: controller),
        const SizedBox(height: 20),

        // 2. Interactive KPI Header Strip with Live Metric Status
        Obx(
          () => DashboardKpiStrip(
            counts: controller.alertCounts.value,
            selectedTabIndex: controller.selectedTabIndex.value,
            onTabSelected: controller.changeTab,
          ),
        ),
        const SizedBox(height: 20),

        // 3. Operational Main Workspace (Two-column layout on Desktop, stacked on Mobile/Tablet)
        if (!isMobile && !isTablet)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: 67% for Smart Alerts & Operations Center
              Expanded(
                flex: 67,
                child: SmartAlertsCenter(controller: controller),
              ),
              const SizedBox(width: 20),
              // Right Column: 33% for Herd Demographics, Shifts & Fast Actions
              Expanded(
                flex: 33,
                child: DashboardFarmTelemetryCard(controller: controller),
              ),
            ],
          )
        else ...[
          SmartAlertsCenter(controller: controller),
          const SizedBox(height: 20),
          DashboardFarmTelemetryCard(controller: controller),
        ],
        const SizedBox(height: 24),

        // 4. Quick Module Navigation Strip
        _buildModuleShortcuts(context, isDark, isMobile),
      ],
    );
  }

  Widget _buildModuleShortcuts(BuildContext context, bool isDark, bool isMobile) {
    final shortcuts = [
      _ShortcutItem(
        title: 'Cattle Herd',
        icon: PhosphorIconsRegular.cow,
        route: AppRoutes.cows,
        color: AppColors.primary,
      ),
      _ShortcutItem(
        title: 'Barn Sheds',
        icon: PhosphorIconsRegular.warehouse,
        route: AppRoutes.sheds,
        color: const Color(0xFF3B82F6),
      ),
      _ShortcutItem(
        title: 'Vet & Treatments',
        icon: PhosphorIconsRegular.firstAidKit,
        route: AppRoutes.treatments,
        color: const Color(0xFFEF4444),
      ),
      _ShortcutItem(
        title: 'Pharmacy Stock',
        icon: PhosphorIconsRegular.pill,
        route: AppRoutes.medicalStock,
        color: const Color(0xFF8B5CF6),
      ),
      _ShortcutItem(
        title: 'Feed Inventory',
        icon: PhosphorIconsRegular.plant,
        route: AppRoutes.feedItems,
        color: const Color(0xFF10B981),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(
            'Quick Module Navigation',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: shortcuts.map((s) {
            return _ShortcutChip(
              item: s,
              isDark: isDark,
              onTap: () => Get.toNamed(s.route),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ShortcutChip extends StatefulWidget {
  final _ShortcutItem item;
  final bool isDark;
  final VoidCallback onTap;

  const _ShortcutChip({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ShortcutChip> createState() => _ShortcutChipState();
}

class _ShortcutChipState extends State<_ShortcutChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: _isHovered
              ? Matrix4.translationValues(0.0, -3.0, 0.0)
              : Matrix4.identity(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isDark
                ? (_isHovered ? Colors.white.withValues(alpha: 0.08) : AppColors.cardDark)
                : (_isHovered ? Colors.white : AppColors.cardLight),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? item.color.withValues(alpha: 0.6)
                  : (widget.isDark ? AppColors.borderDark : AppColors.borderLight),
              width: _isHovered ? 1.2 : 1.0,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: item.color.withValues(alpha: 0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Icon(item.icon, size: 16, color: item.color),
              ),
              const SizedBox(width: 8),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _isHovered && !widget.isDark ? item.color : null,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedSlide(
                offset: _isHovered ? const Offset(0.25, 0.0) : Offset.zero,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: _isHovered
                      ? item.color
                      : (widget.isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutItem {
  final String title;
  final IconData icon;
  final String route;
  final Color color;

  const _ShortcutItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.color,
  });
}
