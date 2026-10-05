import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/permission_constants.dart';
import '../../../data/models/dashboard_alerts_model.dart';
import '../../../data/services/gaushala_session_service.dart';
import '../../../data/services/permission_service.dart';
import '../../../routes/app_routes.dart';
import '../dashboard_controller.dart';
import 'administer_dose_quick_dialog.dart';
import 'quick_feed_inward_dialog.dart';
import 'quick_medical_inward_dialog.dart';

/// Purpose-built Mobile Dashboard view for Ayushka Cattle Management Portal.
/// Features:
/// 1. Compact Hero Header with zero overflow bugs
/// 2. Compact Daily Data Telemetry (Milk, Herd, Treatments, Fridge)
/// 3. Prominent Daily Operations Menu (Cattle, Milk, Treatments, Medical Stock, Feed, Sheds)
/// 4. Compact Smart Alerts Hub with inline quick actions
/// 5. Strict omission of Web-only Master Catalogs
class MobileDashboardView extends StatelessWidget {
  final DashboardController controller;

  const MobileDashboardView({
    super.key,
    required this.controller,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getActiveShift() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) {
      return 'Morning Milking Active';
    } else if (hour >= 16 && hour < 21) {
      return 'Evening Milking Active';
    } else {
      return 'Rest & Feeding Phase';
    }
  }

  void _openAdministerDoseDialog(BuildContext context, TreatmentAlertItem alert) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AdministerDoseQuickDialog(
        alert: alert,
        defaultDoctorName: controller.currentUser.value?.name,
        onConfirm: controller.administerTreatmentDose,
      ),
    );
  }

  void _openQuickMedicalInwardDialog(
    BuildContext context, {
    MedicalLowStockAlertItem? lowStockItem,
    MedicalExpiringAlertItem? expiringItem,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuickMedicalInwardDialog(
        lowStockItem: lowStockItem,
        expiringItem: expiringItem,
        onConfirm: controller.quickMedicalInward,
      ),
    );
  }

  void _openQuickFeedInwardDialog(BuildContext context, FeedStockAlertItem alert) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuickFeedInwardDialog(
        alert: alert,
        onConfirm: controller.quickFeedInward,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Compact Mobile Station Banner
        _buildCompactHeroBanner(context, isDark),
        const SizedBox(height: 16),

        // 2. Compact Daily Data Section ("daliy data ... thoda place par")
        _buildDailyTelemetrySection(context, isDark),
        const SizedBox(height: 18),

        // 3. Prominent Daily Operations Menu ("moblie dashborad ma manu show thava joye")
        _buildDailyOperationsMenu(context, isDark),
        const SizedBox(height: 18),

        // 4. Compact Alerts Hub ("alret set kari aapi shake thoda place par")
        _buildCompactAlertsHub(context, isDark),
        const SizedBox(height: 24),
      ],
    );
  }

  // -------------------------------------------------------------
  // 1. COMPACT HERO BANNER (No horizontal or vertical overflows)
  // -------------------------------------------------------------
  Widget _buildCompactHeroBanner(BuildContext context, bool isDark) {
    final gaushalaService = Get.isRegistered<GaushalaSessionService>()
        ? Get.find<GaushalaSessionService>()
        : null;
    final userName = controller.currentUser.value?.name ?? 'Supervisor';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF132B1A), const Color(0xFF1A3B24)]
              : [const Color(0xFF1B432A), const Color(0xFF2C633E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B432A).withValues(alpha: isDark ? 0.35 : 0.2),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live status row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'ONLINE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsRegular.clockCountdown, size: 11, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          _getActiveShift(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFDE68A),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Greeting & Station
          Text(
            '${_getGreeting()}, $userName! 👋',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Obx(
            () => Text(
              '${gaushalaService?.selectedGaushalaName ?? "Ayushka Station"} • Smart Wellness',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),

          // Attention badge if alerts exist (Wrapped with Flexible to avoid overflow!)
          Obx(() {
            final totalAlerts = controller.alertCounts.value.totalAlerts;
            final critical = controller.alertCounts.value.criticalCases;
            if (totalAlerts == 0) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.7),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFBBF24),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                        children: [
                          const TextSpan(
                            text: 'ATTENTION: ',
                            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFDE68A)),
                          ),
                          TextSpan(text: '$totalAlerts active alerts require review'),
                          if (critical > 0)
                            TextSpan(
                              text: ' ($critical critical)',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFCA5A5)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 14),

          // Fast Action Buttons Row
          Row(
            children: [
              Expanded(
                child: _MobileHeroButton(
                  icon: PhosphorIconsRegular.plusCircle,
                  label: 'Register Cattle',
                  isPrimary: true,
                  onTap: () => Get.toNamed(AppRoutes.addCow),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MobileHeroButton(
                  icon: PhosphorIconsRegular.dropHalfBottom,
                  label: 'Milking Log',
                  isPrimary: false,
                  onTap: () => Get.toNamed(AppRoutes.milk),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. COMPACT DAILY DATA SECTION ("daliy data ... thoda place par")
  // -------------------------------------------------------------
  Widget _buildDailyTelemetrySection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  PhosphorIconsRegular.chartLineUp,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Today\'s Daily Telemetry',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: controller.refreshFarmData,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 13,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Live',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 2x2 Compact Metric Grid
        Row(
          children: [
            // 1. Today's Milk
            Expanded(
              child: Obx(() {
                final total = controller.todayMilkProduced.value;
                final morning = controller.todayMorningProduced.value;
                final evening = controller.todayEveningProduced.value;
                return _DailyMetricCard(
                  icon: PhosphorIconsRegular.dropHalfBottom,
                  title: 'Today Milk',
                  value: '${total.toStringAsFixed(1)} L',
                  subtitle: 'M: ${morning.toStringAsFixed(1)} • E: ${evening.toStringAsFixed(1)}',
                  accentColor: const Color(0xFFF59E0B),
                  bgColor: isDark ? const Color(0xFF261D10) : const Color(0xFFFFFBEB),
                  borderColor: const Color(0xFFFDE68A),
                  isDark: isDark,
                  onTap: () => Get.toNamed(AppRoutes.milk),
                );
              }),
            ),
            const SizedBox(width: 10),

            // 2. Herd Strength
            Expanded(
              child: Obx(() {
                final total = controller.registeredCattleCount.value;
                final females = controller.femaleCattleCount.value;
                final males = controller.maleCattleCount.value;
                return _DailyMetricCard(
                  icon: PhosphorIconsRegular.cow,
                  title: 'Active Cattle',
                  value: '$total Head',
                  subtitle: '$females Female • $males Male',
                  accentColor: const Color(0xFF10B981),
                  bgColor: isDark ? const Color(0xFF10281D) : const Color(0xFFECFDF5),
                  borderColor: const Color(0xFFA7F3D0),
                  isDark: isDark,
                  onTap: () => Get.toNamed(AppRoutes.cows),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // 3. Treatment Doses Due
            Expanded(
              child: Obx(() {
                final doses = controller.alertCounts.value.treatmentDueDoses;
                final critical = controller.alertCounts.value.criticalCases;
                return _DailyMetricCard(
                  icon: PhosphorIconsRegular.firstAidKit,
                  title: 'Doses Due',
                  value: doses > 0 ? '$doses Scheduled' : (critical > 0 ? '$critical Alert' : '0 Pending'),
                  subtitle: critical > 0 ? '$critical Critical triage' : 'All cattle up to date',
                  accentColor: const Color(0xFFEF4444),
                  bgColor: isDark ? const Color(0xFF281313) : const Color(0xFFFEF2F2),
                  borderColor: const Color(0xFFFECACA),
                  isDark: isDark,
                  onTap: () => Get.toNamed(AppRoutes.treatments),
                );
              }),
            ),
            const SizedBox(width: 10),

            // 4. Cold Storage Available
            Expanded(
              child: Obx(() {
                final fridge = controller.fridgeMilkAvailable.value;
                return _DailyMetricCard(
                  icon: PhosphorIconsRegular.snowflake,
                  title: 'Cold Storage',
                  value: '${fridge.toStringAsFixed(1)} L',
                  subtitle: 'Bulk Fridge Stock',
                  accentColor: const Color(0xFF3B82F6),
                  bgColor: isDark ? const Color(0xFF111E30) : const Color(0xFFEFF6FF),
                  borderColor: const Color(0xFFBFDBFE),
                  isDark: isDark,
                  onTap: () => Get.toNamed(AppRoutes.milk),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 3. PROMINENT DAILY OPERATIONS MENU ("moblie dashborad ma manu show thava joye")
  //    (Strictly NO Master items: Roles, Users, Breeds, Types, Gaushalas Master are hidden)
  // -------------------------------------------------------------
  Widget _buildDailyOperationsMenu(BuildContext context, bool isDark) {
    final perm = Get.isRegistered<PermissionService>() ? Get.find<PermissionService>() : null;
    bool canView(String m, String s) => perm?.canView(m, s) ?? true;
    bool isModuleVisible(String m) => perm?.isModuleVisible(m) ?? true;

    final List<_MobileMenuItemData> menuItems = [];

    // 1. Cattle Herd
    if (isModuleVisible(PermissionModules.cow) && canView(PermissionModules.cow, PermissionSubModules.cowList)) {
      menuItems.add(
        _MobileMenuItemData(
          title: 'Cattle Herd',
          subtitle: 'Herd list, ear tags & add',
          icon: PhosphorIconsRegular.cow,
          color: const Color(0xFF10B981),
          route: AppRoutes.cows,
          badgeTextBuilder: () {
            final count = controller.registeredCattleCount.value;
            return count > 0 ? '$count Cattle' : null;
          },
        ),
      );
    }

    // 2. Milk Production & Dispatch
    if (isModuleVisible(PermissionModules.milkMgmt) &&
        (canView(PermissionModules.milkMgmt, PermissionSubModules.milkProduction) ||
            canView(PermissionModules.milkMgmt, PermissionSubModules.milkDistribution))) {
      menuItems.add(
        _MobileMenuItemData(
          title: 'Milk Production',
          subtitle: 'Daily yields & distribution',
          icon: PhosphorIconsRegular.dropHalfBottom,
          color: const Color(0xFFF59E0B),
          route: AppRoutes.milk,
          badgeTextBuilder: () {
            final milk = controller.todayMilkProduced.value;
            return milk > 0 ? '${milk.toStringAsFixed(1)}L Today' : null;
          },
        ),
      );
    }

    // 3. Treatments & Health
    if (isModuleVisible(PermissionModules.treatment) && canView(PermissionModules.treatment, PermissionSubModules.treatmentList)) {
      menuItems.add(
        _MobileMenuItemData(
          title: 'Cow Treatments',
          subtitle: 'Prescriptions & vet triage',
          icon: PhosphorIconsRegular.firstAidKit,
          color: const Color(0xFFEF4444),
          route: AppRoutes.treatments,
          badgeTextBuilder: () {
            final critical = controller.alertCounts.value.criticalCases;
            final doses = controller.alertCounts.value.treatmentDueDoses;
            if (critical > 0) return '$critical Critical';
            if (doses > 0) return '$doses Due';
            return null;
          },
        ),
      );
    }

    // 4. Pharmacy & Medical Stock
    if (isModuleVisible(PermissionModules.medicalStock) && canView(PermissionModules.medicalStock, PermissionSubModules.medicalItems)) {
      menuItems.add(
        _MobileMenuItemData(
          title: 'Medical Stock',
          subtitle: 'Pharmacy, inward & expiry',
          icon: PhosphorIconsRegular.pill,
          color: const Color(0xFF8B5CF6),
          route: AppRoutes.medicalStock,
          badgeTextBuilder: () {
            final low = controller.alertCounts.value.lowMedicalStock;
            final exp = controller.alertCounts.value.expiringMedicines;
            final total = low + exp;
            return total > 0 ? '$total Alerts' : null;
          },
        ),
      );
    }

    // 5. Feed Stock Transactions
    if (isModuleVisible(PermissionModules.feedStock) && canView(PermissionModules.feedStock, PermissionSubModules.stockTransaction)) {
      menuItems.add(
        _MobileMenuItemData(
          title: 'Feed Transactions',
          subtitle: 'Fodder stock inward/outward',
          icon: PhosphorIconsRegular.arrowsLeftRight,
          color: const Color(0xFF06B6D4),
          route: AppRoutes.feedTransactions,
          badgeTextBuilder: () {
            final low = controller.alertCounts.value.lowFeedStock;
            return low > 0 ? '$low Low' : null;
          },
        ),
      );
    }

    // 6. Barn Sheds & Transfers
    if (isModuleVisible(PermissionModules.shed) &&
        (canView(PermissionModules.shed, PermissionSubModules.shedList) || canView(PermissionModules.shed, PermissionSubModules.shedTransfer))) {
      menuItems.add(
        _MobileMenuItemData(
          title: 'Barn Sheds',
          subtitle: 'Shed capacity & transfer',
          icon: PhosphorIconsRegular.warehouse,
          color: const Color(0xFF3B82F6),
          route: AppRoutes.sheds,
          badgeTextBuilder: () => null,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIconsRegular.gridFour,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Daily Operations Menu',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Grid of Operations Tiles
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: menuItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return _MobileMenuItemTile(
              data: item,
              isDark: isDark,
              onTap: () => Get.toNamed(item.route),
            );
          },
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 4. COMPACT ALERTS HUB ("alret set kari aapi shake thoda place par")
  // -------------------------------------------------------------
  Widget _buildCompactAlertsHub(BuildContext context, bool isDark) {
    return Obx(() {
      final tabIndex = controller.selectedTabIndex.value;
      final counts = controller.alertCounts.value;
      final total = counts.totalAlerts;

      final tabs = [
        _AlertCategoryTab(
          index: 0,
          label: 'Treatments',
          count: counts.treatmentDueDoses > 0 ? counts.treatmentDueDoses : counts.criticalCases,
          icon: PhosphorIconsRegular.firstAidKit,
          color: const Color(0xFFEF4444),
        ),
        _AlertCategoryTab(
          index: 1,
          label: 'Milk Drops',
          count: counts.milkVariances,
          icon: PhosphorIconsRegular.dropHalfBottom,
          color: const Color(0xFFF59E0B),
        ),
        _AlertCategoryTab(
          index: 2,
          label: 'Pharmacy',
          count: counts.lowMedicalStock + counts.expiringMedicines,
          icon: PhosphorIconsRegular.pill,
          color: const Color(0xFF8B5CF6),
        ),
        _AlertCategoryTab(
          index: 3,
          label: 'Feed Stock',
          count: counts.lowFeedStock,
          icon: PhosphorIconsRegular.plant,
          color: const Color(0xFF10B981),
        ),
      ];

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.bellSimpleRinging,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Smart Alerts Hub',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: total > 0
                        ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                        : const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    total > 0 ? '$total Pending' : 'All Clear',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: total > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal Category Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tabs.map((t) {
                  final isSelected = tabIndex == t.index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => controller.changeTab(t.index),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? t.color.withValues(alpha: isDark ? 0.25 : 0.15)
                              : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? t.color
                                : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            width: isSelected ? 1.2 : 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon, size: 13, color: isSelected ? t.color : Colors.grey),
                            const SizedBox(width: 5),
                            Text(
                              t.label,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? t.color
                                    : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                              ),
                            ),
                            if (t.count > 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: t.color,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${t.count}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Compact Active Tab Preview
            _buildActiveTabPreview(context, isDark, tabIndex),
          ],
        ),
      );
    });
  }

  Widget _buildActiveTabPreview(BuildContext context, bool isDark, int tabIndex) {
    switch (tabIndex) {
      case 0: // Treatments
        final list = controller.treatmentAlerts;
        if (list.isEmpty) {
          return _buildEmptyAlertBanner('All cow doses and treatments are up to date!', isDark);
        }
        final top = list.take(2).toList();
        return Column(
          children: top.map((alert) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(PhosphorIconsRegular.firstAidKit, size: 15, color: Color(0xFFEF4444)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cattle ${alert.cowTag} • ${alert.diseaseName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${alert.severity} • Dose ${alert.dueDoseNumber}/${alert.totalDoses}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: () => _openAdministerDoseDialog(context, alert),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Administer', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }).toList(),
        );

      case 1: // Milk
        final list = controller.milkAlerts;
        if (list.isEmpty) {
          return _buildEmptyAlertBanner('Morning and evening milk yields are stable!', isDark);
        }
        final top = list.take(2).toList();
        return Column(
          children: top.map((alert) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(PhosphorIconsRegular.dropHalfBottom, size: 15, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cattle ${alert.cowTag}: ${alert.message}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          alert.shift != null ? 'Shift: ${alert.shift}' : 'Milking Yield Variance',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.milk),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('View Log', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                  ),
                ],
              ),
            );
          }).toList(),
        );

      case 2: // Pharmacy
        final low = controller.medicalLowStock;
        final exp = controller.medicalExpiring;
        if (low.isEmpty && exp.isEmpty) {
          return _buildEmptyAlertBanner('Pharmacy inventory healthy. No stock alerts.', isDark);
        }
        final items = <Widget>[];
        for (final item in low.take(2)) {
          items.add(
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(PhosphorIconsRegular.pill, size: 15, color: Color(0xFF8B5CF6)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Stock: ${item.totalStock} ${item.unit} (Alert: ${item.minStockAlert})',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _openQuickMedicalInwardDialog(context, lowStockItem: item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Inward', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(children: items);

      case 3: // Feed
        final list = controller.feedAlerts;
        if (list.isEmpty) {
          return _buildEmptyAlertBanner('Fodder & feed inventory is well stocked!', isDark);
        }
        final top = list.take(2).toList();
        return Column(
          children: top.map((alert) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(PhosphorIconsRegular.plant, size: 15, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.itemName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Stock: ${alert.currentStock} ${alert.unit} (Buffer: ${alert.minStockAlert})',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _openQuickFeedInwardDialog(context, alert),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Restock', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }).toList(),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmptyAlertBanner(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(PhosphorIconsRegular.checkCircle, size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// HELPER MODELS & WIDGETS
// -------------------------------------------------------------
class _MobileHeroButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _MobileHeroButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isPrimary ? const Color(0xFF1B432A) : Colors.white,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? const Color(0xFF1B432A) : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final Color bgColor;
  final Color borderColor;
  final bool isDark;
  final VoidCallback onTap;

  const _DailyMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? borderColor.withValues(alpha: 0.3) : borderColor,
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 14, color: accentColor),
                    const SizedBox(width: 5),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: accentColor.withValues(alpha: 0.7),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileMenuItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final String? Function() badgeTextBuilder;

  _MobileMenuItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    required this.badgeTextBuilder,
  });
}

class _MobileMenuItemTile extends StatelessWidget {
  final _MobileMenuItemData data;
  final bool isDark;
  final VoidCallback onTap;

  const _MobileMenuItemTile({
    required this.data,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(data.icon, size: 18, color: data.color),
                ),
                Obx(() {
                  final badge = data.badgeTextBuilder();
                  if (badge == null || badge.isEmpty) {
                    return Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    );
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: data.color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: data.color,
                      ),
                    ),
                  );
                }),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCategoryTab {
  final int index;
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _AlertCategoryTab({
    required this.index,
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });
}
