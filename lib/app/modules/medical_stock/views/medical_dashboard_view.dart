import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/values/app_colors.dart';
import '../../../core/values/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../dialogs/add_edit_medicine_dialog.dart';
import '../dialogs/dispose_stock_dialog.dart';
import '../dialogs/view_batches_dialog.dart';
import '../medical_stock_controller.dart';
import '../widgets/medical_stock_animations.dart';

/// Screen A: Medical Stock Dashboard & Summary
/// Features metric overview cards, quick inward/outward action buttons,
/// and live monitoring tables for Low Stock SKUs and Expiring Batches.
class MedicalDashboardView extends StatelessWidget {
  const MedicalDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MedicalStockController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -----------------------------------------------------------
              // TOP ACTION BAR & TITLE
              // -----------------------------------------------------------
              _buildTopActionBar(context, controller),
              const SizedBox(height: 20),

              // -----------------------------------------------------------
              // 4 CORE METRIC CARDS
              // -----------------------------------------------------------
              _buildMetricCards(context, controller),
              const SizedBox(height: 24),

              // -----------------------------------------------------------
              // QUICK TABLES: LOW STOCK & EXPIRING BATCHES TABS
              // -----------------------------------------------------------
              _buildQuickTablesSection(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopActionBar(BuildContext context, MedicalStockController controller) {
    return StaggeredEntrance(
      delay: const Duration(milliseconds: 30),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 720;

          final titleWidget = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(PhosphorIconsRegular.firstAidKit, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Veterinary Medicine & Stock Control',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'FEFO (First-Expired, First-Out) batch management, automated stock alerts & audit logging',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actionButtons = Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              CustomButton(
                text: 'Add Medicine',
                icon: PhosphorIconsRegular.plus,
                height: 42,
                variant: ButtonVariant.outlined,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                onPressed: () => AddEditMedicineDialog.show(context),
              ),
              CustomButton(
                text: 'Stock Inward (Purchase)',
                icon: PhosphorIconsRegular.arrowDownLeft,
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                backgroundColor: const Color(0xFF10B981),
                onPressed: () => controller.switchTab(2),
              ),
              CustomButton(
                text: 'Stock Outward (Dispense)',
                icon: PhosphorIconsRegular.arrowUpRight,
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                variant: ButtonVariant.primary,
                onPressed: () => controller.switchTab(3),
              ),
            ],
          );

          return Container(
            padding: EdgeInsets.all(isMobile ? 14 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      titleWidget,
                      const SizedBox(height: 14),
                      actionButtons,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: titleWidget),
                      const SizedBox(width: 16),
                      actionButtons,
                    ],
                  ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4 CORE METRIC CARDS (Identical to Herd & Cattle _buildMetricCards & _HoverableMetricTile)
  // ---------------------------------------------------------------------------
  Widget _buildMetricCards(BuildContext context, MedicalStockController controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final summary = controller.summary.value;

      return LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 640;
          final isNarrow = constraints.maxWidth < 950;

          if (isCompact) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: 'Total Medicine SKUs',
                        value: '${summary.totalItems}',
                        icon: PhosphorIconsRegular.pill,
                        color: const Color(0xFF3B82F6),
                        isDark: isDark,
                        isCompact: true,
                        onTap: () => controller.switchTab(1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: 'Low Stock Alerts',
                        value: '${summary.lowStockItemsCount}',
                        icon: PhosphorIconsRegular.warningCircle,
                        color: const Color(0xFFF59E0B),
                        badgeText: summary.lowStockItemsCount > 0 ? 'REORDER' : 'OPTIMAL',
                        badgeColor: summary.lowStockItemsCount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                        isDark: isDark,
                        isCompact: true,
                        onTap: () {
                          controller.dashboardActiveSubTab.value = 0;
                          controller.lowStockOnlyFilter.value = true;
                          controller.switchTab(1);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: 'Expiring Soon',
                        value: '${summary.expiringSoonBatchesCount}',
                        icon: PhosphorIconsRegular.clockCountdown,
                        color: const Color(0xFFEA580C),
                        badgeText: 'FEFO',
                        badgeColor: const Color(0xFFEA580C),
                        isDark: isDark,
                        isCompact: true,
                        onTap: () {
                          controller.batchExpiryFilter.value = 'EXPIRING_30';
                          controller.switchTab(4);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: 'Expired Batches',
                        value: '${summary.expiredBatchesCount}',
                        icon: PhosphorIconsRegular.xCircle,
                        color: const Color(0xFFEF4444),
                        badgeText: summary.expiredBatchesCount > 0 ? 'CRITICAL' : 'CLEAN',
                        badgeColor: summary.expiredBatchesCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        isDark: isDark,
                        isCompact: true,
                        onTap: () {
                          controller.batchExpiryFilter.value = 'EXPIRED';
                          controller.switchTab(4);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          if (isNarrow) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: 'Total Medicine SKUs',
                        value: '${summary.totalItems}',
                        subtitle: 'Active veterinary medicines',
                        icon: PhosphorIconsRegular.pill,
                        color: const Color(0xFF3B82F6),
                        isDark: isDark,
                        onTap: () => controller.switchTab(1),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: 'Low Stock Alerts',
                        value: '${summary.lowStockItemsCount}',
                        subtitle: 'Stock <= Reorder threshold',
                        icon: PhosphorIconsRegular.warningCircle,
                        color: const Color(0xFFF59E0B),
                        badgeText: summary.lowStockItemsCount > 0 ? 'NEEDS REORDER' : 'OPTIMAL',
                        badgeColor: summary.lowStockItemsCount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                        isDark: isDark,
                        onTap: () {
                          controller.dashboardActiveSubTab.value = 0;
                          controller.lowStockOnlyFilter.value = true;
                          controller.switchTab(1);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: 'Expiring Soon Batches',
                        value: '${summary.expiringSoonBatchesCount}',
                        subtitle: 'Expiring within ${controller.expiringDaysThreshold.value} days',
                        icon: PhosphorIconsRegular.clockCountdown,
                        color: const Color(0xFFEA580C),
                        badgeText: 'FEFO WARNING',
                        badgeColor: const Color(0xFFEA580C),
                        isDark: isDark,
                        onTap: () {
                          controller.batchExpiryFilter.value = 'EXPIRING_30';
                          controller.switchTab(4);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: 'Expired Batches',
                        value: '${summary.expiredBatchesCount}',
                        subtitle: 'Immediate disposal required',
                        icon: PhosphorIconsRegular.xCircle,
                        color: const Color(0xFFEF4444),
                        badgeText: summary.expiredBatchesCount > 0 ? 'CRITICAL RISK' : 'CLEAN',
                        badgeColor: summary.expiredBatchesCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        isDark: isDark,
                        onTap: () {
                          controller.batchExpiryFilter.value = 'EXPIRED';
                          controller.switchTab(4);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Total Medicine SKUs',
                  value: '${summary.totalItems}',
                  subtitle: 'Active veterinary medicines',
                  icon: PhosphorIconsRegular.pill,
                  color: const Color(0xFF3B82F6),
                  isDark: isDark,
                  onTap: () => controller.switchTab(1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Low Stock Alerts',
                  value: '${summary.lowStockItemsCount}',
                  subtitle: 'Stock <= Reorder threshold',
                  icon: PhosphorIconsRegular.warningCircle,
                  color: const Color(0xFFF59E0B),
                  badgeText: summary.lowStockItemsCount > 0 ? 'NEEDS REORDER' : 'OPTIMAL',
                  badgeColor: summary.lowStockItemsCount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  isDark: isDark,
                  onTap: () {
                    controller.dashboardActiveSubTab.value = 0;
                    controller.lowStockOnlyFilter.value = true;
                    controller.switchTab(1);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Expiring Soon Batches',
                  value: '${summary.expiringSoonBatchesCount}',
                  subtitle: 'Expiring within ${controller.expiringDaysThreshold.value} days',
                  icon: PhosphorIconsRegular.clockCountdown,
                  color: const Color(0xFFEA580C),
                  badgeText: 'FEFO WARNING',
                  badgeColor: const Color(0xFFEA580C),
                  isDark: isDark,
                  onTap: () {
                    controller.batchExpiryFilter.value = 'EXPIRING_30';
                    controller.switchTab(4);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Expired Batches',
                  value: '${summary.expiredBatchesCount}',
                  subtitle: 'Immediate disposal required',
                  icon: PhosphorIconsRegular.xCircle,
                  color: const Color(0xFFEF4444),
                  badgeText: summary.expiredBatchesCount > 0 ? 'CRITICAL RISK' : 'CLEAN',
                  badgeColor: summary.expiredBatchesCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  isDark: isDark,
                  onTap: () {
                    controller.batchExpiryFilter.value = 'EXPIRED';
                    controller.switchTab(4);
                  },
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    String? badgeText,
    Color? badgeColor,
    bool isValueTextSmall = false,
    bool isCompact = false,
    VoidCallback? onTap,
  }) {
    return _HoverableMetricTile(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      color: color,
      isDark: isDark,
      badgeText: badgeText,
      badgeColor: badgeColor,
      isValueTextSmall: isValueTextSmall,
      isCompact: isCompact,
      onTap: onTap,
    );
  }

  Widget _buildQuickTablesSection(BuildContext context, MedicalStockController controller) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sub-Tab Switcher Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF7FAF4),
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 750;

                final tabsWidget = SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() {
                        final active = controller.dashboardActiveSubTab.value == 0;
                        final lowCount = controller.items.where((i) => i.isLowStock).length;
                        return _tabHeaderButton(
                          title: isNarrow ? 'Low Stock' : 'Low Stock Medicines',
                          badge: '$lowCount',
                          badgeColor: const Color(0xFFF59E0B),
                          isActive: active,
                          onTap: () => controller.dashboardActiveSubTab.value = 0,
                        );
                      }),
                      const SizedBox(width: 8),
                      Obx(() {
                        final active = controller.dashboardActiveSubTab.value == 1;
                        final expiringCount = controller.allBatches.where((b) => b.isExpiringSoon || b.isExpired).length;
                        return _tabHeaderButton(
                          title: isNarrow ? 'Expiring Batches' : 'Nearing Expiry / Expired Batches',
                          badge: '$expiringCount',
                          badgeColor: const Color(0xFFEF4444),
                          isActive: active,
                          onTap: () => controller.dashboardActiveSubTab.value = 1,
                        );
                      }),
                    ],
                  ),
                );

                final windowFilterWidget = Obx(() {
                  if (controller.dashboardActiveSubTab.value == 1) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Window:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildThresholdChip(
                            label: '30 Days',
                            isSelected: controller.expiringDaysThreshold.value == 30,
                            onTap: () => controller.expiringDaysThreshold.value = 30,
                          ),
                          const SizedBox(width: 6),
                          _buildThresholdChip(
                            label: '60 Days',
                            isSelected: controller.expiringDaysThreshold.value == 60,
                            onTap: () => controller.expiringDaysThreshold.value = 60,
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                });

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      tabsWidget,
                      Obx(() {
                        if (controller.dashboardActiveSubTab.value == 1) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: windowFilterWidget,
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  );
                }

                return Row(
                  children: [
                    tabsWidget,
                    const Spacer(),
                    windowFilterWidget,
                  ],
                );
              },
            ),
          ),

          // Sub-Tab Content with smooth animated switcher
          Obx(() {
            final activeTab = controller.dashboardActiveSubTab.value;
            return AnimatedModuleViewSwitcher(
              child: KeyedSubtree(
                key: ValueKey<int>(activeTab),
                child: activeTab == 0
                    ? _buildLowStockTable(context, controller)
                    : _buildExpiringBatchesTable(context, controller),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _tabHeaderButton({
    required String title,
    required String badge,
    required Color badgeColor,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? AppColors.borderLight : Colors.transparent),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedScale(
              scale: isActive ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 160),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: AppColors.primary.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
              width: 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(
                  PhosphorIconsRegular.check,
                  size: 13,
                  color: Colors.white,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLowStockTable(BuildContext context, MedicalStockController controller) {
    final lowStockList = controller.items.where((i) => i.isLowStock).toList();

    if (lowStockList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(PhosphorIconsRegular.checkCircle, size: 44, color: AppColors.primary.withValues(alpha: 0.6)),
              const SizedBox(height: 10),
              const Text(
                'Healthy Stock Levels',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
              ),
              const SizedBox(height: 4),
              const Text(
                'All veterinary medicines are currently above minimum alert thresholds.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double minTableWidth = 980.0;
        final double tableWidth = constraints.maxWidth < minTableWidth
            ? minTableWidth
            : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Table Header Row
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAF7),
                    border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 28, child: _th('Medicine Item')),
                      Expanded(flex: 15, child: _th('Category')),
                      Expanded(flex: 16, child: _th('Available Stock')),
                      Expanded(flex: 16, child: _th('Reorder Level')),
                      Expanded(flex: 14, child: _th('Active Batches')),
                      SizedBox(width: 150, child: _th('Quick Action', alignRight: true)),
                    ],
                  ),
                ),
                // Animated Staggered Rows with Hover Effect
                ...lowStockList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return StaggeredEntrance(
                    index: index,
                    child: HoverableTableRow(
                      child: Row(
                        children: [
                          // Item Name & SKU
                          Expanded(
                            flex: 28,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: item.categoryEnum.color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(item.categoryEnum.icon, color: item.categoryEnum.color, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.itemName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.itemCode.isNotEmpty)
                                          Text(
                                            item.itemCode,
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Category
                          Expanded(
                            flex: 15,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Text(
                                item.categoryEnum.label,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          // Current Stock with warning pill
                          Expanded(
                            flex: 16,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: item.isOutOfStock ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: item.isOutOfStock ? const Color(0xFFC62828) : const Color(0xFFE65100),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      '${item.totalStock.toStringAsFixed(0)} ${item.unit}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: item.isOutOfStock ? const Color(0xFFC62828) : const Color(0xFFE65100),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Min Stock Alert
                          Expanded(
                            flex: 16,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Text(
                                '${item.minStockAlert.toStringAsFixed(0)} ${item.unit}',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                              ),
                            ),
                          ),

                          // Active Batches Count
                          Expanded(
                            flex: 14,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Text(
                                '${item.activeBatchesCount} batch${item.activeBatchesCount != 1 ? 'es' : ''}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),

                          // Action
                          SizedBox(
                            width: 150,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: CustomButton(
                                    text: 'Inward Stock',
                                    icon: PhosphorIconsRegular.plus,
                                    height: 32,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    onPressed: () {
                                      controller.inwardSelectedItem.value = item;
                                      controller.switchTab(2);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpiringBatchesTable(BuildContext context, MedicalStockController controller) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final threshold = controller.expiringDaysThreshold.value;

    final expiringList = controller.allBatches.where((b) {
      if (b.availableQuantity <= 0) return false;
      return b.isExpired || b.daysUntilExpiry <= threshold;
    }).toList();

    expiringList.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    if (expiringList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(PhosphorIconsRegular.shieldCheck, size: 44, color: AppColors.primary.withValues(alpha: 0.6)),
              const SizedBox(height: 10),
              const Text(
                'No Expiring Batches Found',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
              ),
              const SizedBox(height: 4),
              Text(
                'All active batches have over $threshold days of shelf-life validity.',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double minTableWidth = 980.0;
        final double tableWidth = constraints.maxWidth < minTableWidth
            ? minTableWidth
            : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Table Header Row
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAF7),
                    border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 18, child: _th('Batch Number')),
                      Expanded(flex: 26, child: _th('Medicine SKU')),
                      Expanded(flex: 16, child: _th('Remaining Stock')),
                      Expanded(flex: 22, child: _th('Expiry Date')),
                      Expanded(flex: 15, child: _th('FEFO Urgency')),
                      SizedBox(width: 140, child: _th('Action', alignRight: true)),
                    ],
                  ),
                ),
                // Animated Staggered Rows with Hover Effect
                ...expiringList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final batch = entry.value;
                  final isExp = batch.isExpired;
                  final isCrit = batch.isExpiringSoon;

                  return StaggeredEntrance(
                    index: index,
                    child: HoverableTableRow(
                      normalColor: isExp ? const Color(0xFFFFF9F9) : Colors.transparent,
                      hoverColor: isExp ? const Color(0xFFFFECEC) : const Color(0xFFF6FAF3),
                      activeIndicatorColor: isExp ? AppColors.error : (isCrit ? const Color(0xFFEA580C) : AppColors.primary),
                      child: Row(
                        children: [
                          // Batch No
                          Expanded(
                            flex: 18,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Text(
                                batch.batchNumber,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isExp ? AppColors.error : AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                          ),

                          // Medicine Name
                          Expanded(
                            flex: 26,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Text(
                                batch.itemName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          // Remaining Stock
                          Expanded(
                            flex: 16,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Text(
                                '${batch.availableQuantity.toStringAsFixed(0)} units',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ),

                          // Expiry Date with days remaining chip
                          Expanded(
                            flex: 22,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Text(dateFormat.format(batch.expiryDate), style: const TextStyle(fontSize: 12)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isExp ? const Color(0xFFFFEBEE) : (isCrit ? const Color(0xFFFFF3E0) : const Color(0xFFFFFDE7)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      batch.daysRemainingLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isExp ? const Color(0xFFC62828) : (isCrit ? const Color(0xFFE65100) : const Color(0xFFF57F17)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Urgency Pill
                          Expanded(
                            flex: 15,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: isExp
                                  ? PulsingBadge(
                                      child: const Text(
                                        'EXPIRED',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      isCrit ? 'CRITICAL (<30D)' : 'WARNING (60D)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isCrit ? const Color(0xFFEA580C) : const Color(0xFFD97706),
                                      ),
                                    ),
                            ),
                          ),

                          // Action
                          SizedBox(
                            width: 140,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: isExp
                                      ? CustomButton(
                                          text: 'Dispose',
                                          variant: ButtonVariant.danger,
                                          icon: PhosphorIconsRegular.trash,
                                          height: 32,
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          onPressed: () => DisposeStockDialog.show(context, batch: batch),
                                        )
                                      : CustomButton(
                                          text: 'View Batches',
                                          variant: ButtonVariant.outlined,
                                          height: 32,
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          onPressed: () {
                                            final it = controller.items.firstWhereOrNull((i) => i.id == batch.itemId);
                                            if (it != null) {
                                              ViewBatchesDialog.show(context, item: it);
                                            }
                                          },
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _th(String text, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondaryLight,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// =============================================================================
// HOVERABLE METRIC TILE (Identical to CowScreen _HoverableMetricTile)
// =============================================================================
class _HoverableMetricTile extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final String? badgeText;
  final Color? badgeColor;
  final bool isValueTextSmall;
  final bool isCompact;
  final VoidCallback? onTap;

  const _HoverableMetricTile({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    this.badgeText,
    this.badgeColor,
    this.isValueTextSmall = false,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: widget.isCompact ? 11 : 12,
                              color: AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (widget.badgeText != null && !widget.isCompact) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: (widget.badgeColor ?? effectiveColor).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: (widget.badgeColor ?? effectiveColor).withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              widget.badgeText!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: widget.badgeColor ?? effectiveColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.isCompact
                            ? 15
                            : (widget.isValueTextSmall ? 15 : 20),
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

