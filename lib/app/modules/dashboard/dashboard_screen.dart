import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/values/app_colors.dart';
import '../../core/values/app_constants.dart';
import 'dashboard_controller.dart';
import 'widgets/mobile_drawer.dart';
import 'widgets/web_sidebar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/widgets/global_gaushala_selector.dart';
import '../../routes/app_routes.dart';

/// Responsive Cattle Management Dashboard screen adapting to Web, Tablet, and Mobile.
class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileScaffold(context),
      tablet: _buildTabletScaffold(context),
      desktop: _buildDesktopScaffold(context),
    );
  }

  // -------------------------------------------------------------
  // DESKTOP & WIDE WEB SCAFFOLD
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
                    padding: const EdgeInsets.all(28.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Farm Welcome Banner
                            _buildFarmWelcomeBanner(context),
                            const SizedBox(height: 24),

                            // Farm KPI Metric Cards
                            _buildDesktopKpiGrid(context),
                            const SizedBox(height: 28),

                            // Quick Farm Operations & Health Alerts
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 7, child: _buildFarmQuickActionsCard(context)),
                                const SizedBox(width: 24),
                                Expanded(flex: 5, child: _buildHealthAlertsCard(context)),
                              ],
                            ),
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
        title: const Text('Ayushka Cattle Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.refreshFarmData,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFarmWelcomeBanner(context),
            const SizedBox(height: 20),
            _buildTabletKpiGrid(context),
            const SizedBox(height: 24),
            _buildFarmQuickActionsCard(context),
            const SizedBox(height: 20),
            _buildHealthAlertsCard(context),
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
        title: const Text(
          AppConstants.appName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.refreshFarmData,
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
        onRefresh: controller.refreshFarmData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFarmWelcomeBanner(context),
              const SizedBox(height: 16),
              _buildMobileKpiGrid(context),
              const SizedBox(height: 20),
              _buildFarmQuickActionsCard(context),
              const SizedBox(height: 16),
              _buildHealthAlertsCard(context),
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
                ),
                child: const Text(
                  'FARM ACTIVE',
                  style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Live Herd Telemetry & Milk Collection Station',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            children: [
              const GlobalGaushalaSelector(),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Refresh Farm Data',
                onPressed: controller.refreshFarmData,
              ),
              const SizedBox(width: 8),
              Obx(() {
                final user = controller.currentUser.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user?.name.substring(0, 1).toUpperCase() ?? 'F',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user?.name ?? 'Farm Manager',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // WELCOME BANNER
  // -------------------------------------------------------------
  Widget _buildFarmWelcomeBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Text(
                    'Welcome to Ayushka Farm, ${controller.currentUser.value?.name ?? 'Farm Manager'} 🌿',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ayushka Organic Living & Happiness • Cattle & Dairy Management Station. All herd telemetry, A2 milk testing, and breeding records are synced.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (!ResponsiveLayout.isMobile(context)) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    AppConstants.logoIconPath,
                    height: 44,
                    width: 44,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'ayushka',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2D17),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Organic Dairy',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // KPI GRIDS
  // -------------------------------------------------------------
  Widget _buildDesktopKpiGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Obx(
            () => _buildMetricCard(
              context,
              title: 'Total Herd',
              value: '${controller.totalCattle.value}',
              subtitle: 'Active Cattle',
              icon: PhosphorIconsRegular.cow,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Obx(
            () => _buildMetricCard(
              context,
              title: 'Milking Cows',
              value: '${controller.milkingCattle.value}',
              subtitle: 'Lactation Cycle Active',
              icon: PhosphorIconsRegular.drop,
              color: AppColors.info,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Obx(
            () => _buildMetricCard(
              context,
              title: 'Daily Milk Yield',
              value: '${controller.dailyMilkLiters.value} L',
              subtitle: 'Morning + Evening Yield',
              icon: PhosphorIconsRegular.drop,
              color: AppColors.primaryLight,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Obx(
            () => _buildMetricCard(
              context,
              title: 'Health / Vet Alerts',
              value: '${controller.healthAlerts.value}',
              subtitle: 'Checkup Scheduled',
              icon: PhosphorIconsRegular.heartbeat,
              color: AppColors.warning,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletKpiGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: [
        Obx(() => _buildMetricCard(context, title: 'Total Herd', value: '${controller.totalCattle.value}', subtitle: 'Active Cattle', icon: PhosphorIconsRegular.cow, color: AppColors.primary)),
        Obx(() => _buildMetricCard(context, title: 'Milking Cows', value: '${controller.milkingCattle.value}', subtitle: 'In Lactation', icon: PhosphorIconsRegular.drop, color: AppColors.info)),
        Obx(() => _buildMetricCard(context, title: 'Daily Yield', value: '${controller.dailyMilkLiters.value} L', subtitle: 'Today', icon: PhosphorIconsRegular.drop, color: AppColors.primaryLight)),
        Obx(() => _buildMetricCard(context, title: 'Health Alerts', value: '${controller.healthAlerts.value}', subtitle: 'Checkup needed', icon: PhosphorIconsRegular.heartbeat, color: AppColors.warning)),
      ],
    );
  }

  Widget _buildMobileKpiGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        Obx(() => _buildMetricCard(context, title: 'Total Herd', value: '${controller.totalCattle.value}', subtitle: 'Cattle', icon: PhosphorIconsRegular.cow, color: AppColors.primary, isCompact: true)),
        Obx(() => _buildMetricCard(context, title: 'Milking', value: '${controller.milkingCattle.value}', subtitle: 'In Lactation', icon: PhosphorIconsRegular.drop, color: AppColors.info, isCompact: true)),
        Obx(() => _buildMetricCard(context, title: 'Daily Milk', value: '${controller.dailyMilkLiters.value} L', subtitle: 'Yield', icon: PhosphorIconsRegular.drop, color: AppColors.primaryLight, isCompact: true)),
        Obx(() => _buildMetricCard(context, title: 'Health', value: '${controller.healthAlerts.value}', subtitle: 'Alerts', icon: PhosphorIconsRegular.heartbeat, color: AppColors.warning, isCompact: true)),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isCompact = false,
  }) {
    return _HoverableKpiCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      color: color,
      isCompact: isCompact,
    );
  }

  // -------------------------------------------------------------
  // QUICK ACTIONS
  // -------------------------------------------------------------
  Widget _buildFarmQuickActionsCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Farm Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Log daily farm operations or record livestock data',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton(
                icon: Icons.add_circle_outline_rounded,
                label: 'Register Cattle',
                color: AppColors.primary,
                onTap: () => Get.toNamed(AppRoutes.addCow),
              ),
              _buildActionButton(
                icon: Icons.water_drop_outlined,
                label: 'Log Milk Yield',
                color: AppColors.info,
                onTap: () => Get.snackbar('Milk Log', 'Daily milk collection logging.', maxWidth: 400),
              ),
              _buildActionButton(
                icon: Icons.medical_services_outlined,
                label: 'Schedule Vet Check',
                color: AppColors.warning,
                onTap: () => Get.snackbar('Veterinary', 'Vaccination and medical appointment schedule.', maxWidth: 400),
              ),
              _buildActionButton(
                icon: Icons.child_care_rounded,
                label: 'Breeding Record',
                color: AppColors.secondary,
                onTap: () => Get.snackbar('Breeding', 'Insemination and gestation records.', maxWidth: 400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // HEALTH & BREEDING ALERTS
  // -------------------------------------------------------------
  Widget _buildHealthAlertsCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
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
              Text(
                'Herd Health Alerts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '2 PENDING',
                  style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAlertItem(
            title: 'Cow #104 (Gir Breed)',
            description: 'Due for Foot & Mouth (FMD) booster vaccination.',
            icon: Icons.vaccines_rounded,
            color: AppColors.warning,
          ),
          const SizedBox(height: 12),
          _buildAlertItem(
            title: 'Cow #112 (Sahiwal Breed)',
            description: 'Expected calving date in 5 days. Relocated to maternity pen.',
            icon: Icons.child_care_rounded,
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Interactive hoverable KPI card with smooth elevation lift, border glow,
/// and reactive theme adaptation.
class _HoverableKpiCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isCompact;

  const _HoverableKpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isCompact = false,
  });

  @override
  State<_HoverableKpiCard> createState() => _HoverableKpiCardState();
}

class _HoverableKpiCardState extends State<_HoverableKpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompact = widget.isCompact;
    final color = widget.color;

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        padding: EdgeInsets.all(isCompact ? 12 : 18),
        decoration: BoxDecoration(
          color: isDark
              ? (_isHovered ? AppColors.surfaceDark : AppColors.cardDark)
              : (_isHovered ? Colors.white : AppColors.cardLight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? color.withValues(alpha: 0.55)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: _isHovered ? 1.4 : 1.0,
          ),
          boxShadow: [
            if (_isHovered) ...[
              BoxShadow(
                color: color.withValues(alpha: 0.16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.all(isCompact ? 6 : 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: _isHovered ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: color, size: isCompact ? 18 : 22),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 6 : 12),
            Text(
              widget.value,
              style: TextStyle(
                fontSize: isCompact ? 20 : 26,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            SizedBox(height: isCompact ? 2 : 4),
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            Text(
              widget.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                color: AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

