import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

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
import '../notification/widgets/notification_bell_widget.dart';
import '../../data/models/feed_stock_transaction_model.dart';
import '../../routes/app_routes.dart';
import '../dashboard/widgets/mobile_drawer.dart';
import '../dashboard/widgets/web_sidebar.dart';
import 'feed_stock_transaction_controller.dart';

/// Screen component for viewing and recording Feed Stock Movements (Inward & Outward).
class FeedStockTransactionScreen extends GetView<FeedStockTransactionController> {
  const FeedStockTransactionScreen({super.key});

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
                            _buildSummaryMetricCards(context),
                            const SizedBox(height: 16),
                            _buildStockAlertBanner(context),
                            const SizedBox(height: 8),
                            _buildTransactionsTableCard(context),
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
        title: const Text('Stock Transactions'),
        actions: [
          const NotificationBellWidget(),
          Obx(() {
            final isBusy = controller.isRefreshing.value || controller.isLoading.value;
            return IconButton(
              icon: isBusy
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh Records',
              onPressed: isBusy ? null : controller.refreshTransactions,
            );
          }),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowDownLeft, color: Color(0xFF10B981)),
            tooltip: 'Record Inward Stock',
            onPressed: () => controller.openInwardDialog(context),
          ),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowUpRight, color: Color(0xFFF59E0B)),
            tooltip: 'Record Outward Stock',
            onPressed: () => controller.openOutwardDialog(context),
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
          children: [
            _buildStockAlertBanner(context),
            _buildSearchAndFilters(context, isCompact: true),
            const SizedBox(height: 16),
            _buildTransactionsMobileList(context),
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
        title: const Text('Stock Transactions'),
        actions: [
          const NotificationBellWidget(),
          Obx(() {
            final isBusy = controller.isRefreshing.value || controller.isLoading.value;
            return IconButton(
              icon: isBusy
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh',
              onPressed: isBusy ? null : controller.refreshTransactions,
            );
          }),
        ],
      ),
      drawer: Obx(
        () => MobileDrawer(
          currentUser: controller.currentUser.value,
          onLogout: controller.logout,
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'fab_inward',
            backgroundColor: const Color(0xFF10B981),
            onPressed: () => controller.openInwardDialog(context),
            tooltip: 'Inward (+)',
            child: const Icon(PhosphorIconsRegular.arrowDownLeft, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'fab_outward',
            backgroundColor: const Color(0xFFF59E0B),
            onPressed: () => controller.openOutwardDialog(context),
            tooltip: 'Outward (-)',
            child: const Icon(PhosphorIconsRegular.arrowUpRight, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStockAlertBanner(context),
            _buildSearchAndFilters(context, isCompact: true),
            const SizedBox(height: 14),
            _buildTransactionsMobileList(context),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // DESKTOP HEADER
  // -------------------------------------------------------------
  Widget _buildDesktopHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 28),
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
                  'INVENTORY',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Feed Stock Transactions',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Obx(
                  () => Text(
                    '${controller.totalTransactionsCount} Movements Logged',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Right: Gaushala Selector, Notification Bell, Refresh & Profile
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
                  onPressed: isBusy ? null : controller.refreshTransactions,
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
                  child: const Text(
                    'Dashboard',
                    style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                const Text(
                  'Feed Stock Transactions',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Audit Log & Movement History',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),

        // Action Buttons: Inward, Outward & Feed Master link
        Row(
          children: [
            // Feed Items Master jump button
            CustomButton(
              text: 'Feed Items Master',
              icon: PhosphorIconsRegular.grains,
              variant: ButtonVariant.outlined,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onPressed: () => Get.toNamed(AppRoutes.feedItems),
            ),
            const SizedBox(width: 10),

            // Export CSV
            CustomButton(
              text: 'Export CSV',
              icon: PhosphorIconsRegular.downloadSimple,
              variant: ButtonVariant.outlined,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onPressed: controller.exportToCsv,
            ),
            const SizedBox(width: 10),

            // Record Outward Button
            CustomButton(
              text: 'Record Outward',
              icon: PhosphorIconsRegular.arrowUpRight,
              backgroundColor: const Color(0xFFF59E0B),
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: () => controller.openOutwardDialog(context),
            ),
            const SizedBox(width: 10),

            // Record Inward Button
            CustomButton(
              text: 'Record Inward',
              icon: PhosphorIconsRegular.arrowDownLeft,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: () => controller.openInwardDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // SUMMARY METRICS CARDS
  // -------------------------------------------------------------
  Widget _buildSummaryMetricCards(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final total = controller.totalTransactionsCount;
      final inCount = controller.inwardTransactionsCount;
      final inQty = controller.totalInwardQuantity;
      final outCount = controller.outwardTransactionsCount;
      final outQty = controller.totalOutwardQuantity;
      final spend = controller.totalPurchaseSpend;

      final isTypeInward = controller.selectedTypeFilter.value == 'INWARD';
      final isTypeOutward = controller.selectedTypeFilter.value == 'OUTWARD';
      final isReasonPurchase = controller.selectedReasonFilter.value == 'PURCHASE';

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          final cards = [
            _buildMetricCard(
              title: 'Total Movements',
              value: '$total',
              subtitle: 'All audit events recorded',
              icon: PhosphorIconsRegular.receipt,
              color: const Color(0xFF3B82F6),
              isDark: isDark,
              onTap: () {
                controller.setTypeFilter('ALL');
                controller.setReasonFilter('ALL');
              },
            ),
            _buildMetricCard(
              title: 'Inward Receipts',
              value: '$inCount movements',
              subtitle: '${inQty.toStringAsFixed(1)} Units Received',
              icon: PhosphorIconsRegular.arrowDownLeft,
              color: const Color(0xFF10B981),
              isDark: isDark,
              isSelected: isTypeInward,
              onTap: () {
                if (isTypeInward) {
                  controller.setTypeFilter('ALL');
                } else {
                  controller.setTypeFilter('INWARD');
                }
              },
            ),
            _buildMetricCard(
              title: 'Outward Issues',
              value: '$outCount movements',
              subtitle: '${outQty.toStringAsFixed(1)} Units Consumed',
              icon: PhosphorIconsRegular.arrowUpRight,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
              isSelected: isTypeOutward,
              onTap: () {
                if (isTypeOutward) {
                  controller.setTypeFilter('ALL');
                } else {
                  controller.setTypeFilter('OUTWARD');
                }
              },
            ),
            _buildMetricCard(
              title: 'Purchase Spend',
              value: '₹${NumberFormat('#,##,###').format(spend)}',
              subtitle: 'Procurement expenditures',
              icon: PhosphorIconsRegular.currencyInr,
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
              isSelected: isReasonPurchase,
              onTap: () {
                if (isReasonPurchase) {
                  controller.setReasonFilter('ALL');
                } else {
                  controller.setReasonFilter('PURCHASE');
                }
              },
            ),
          ];

          if (isWide) {
            return Row(
              children: cards
                  .map((card) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: card,
                        ),
                      ))
                  .toList(),
            );
          } else {
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards
                  .map((card) => SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: card,
                      ))
                  .toList(),
            );
          }
        },
      );
    });
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return _HoverableStockMetricCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      color: color,
      isDark: isDark,
      isSelected: isSelected,
      onTap: onTap,
    );
  }

  // -------------------------------------------------------------
  // STOCK DEPLETION & OUT OF STOCK WARNING ALERT BANNER
  // -------------------------------------------------------------
  Widget _buildStockAlertBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final outOfStock = controller.outOfStockItems;
      final lowStock = controller.lowStockItems;

      if (outOfStock.isEmpty && lowStock.isEmpty) {
        return const SizedBox.shrink();
      }

      final isCritical = outOfStock.isNotEmpty;
      final color = isCritical ? AppColors.error : AppColors.warning;
      final icon = isCritical ? Icons.error_outline_rounded : Icons.warning_amber_rounded;

      final title = isCritical
          ? 'Stock Depleted Alert: ${outOfStock.length} Feed Item${outOfStock.length > 1 ? "s" : ""} at 0 Stock!'
          : 'Low Stock Warning: ${lowStock.length} Feed Item${lowStock.length > 1 ? "s" : ""} Running Low!';

      final details = isCritical
          ? outOfStock.map((i) => '${i.itemName} (0.0 ${i.unit})').join(', ')
          : lowStock.map((i) => '${i.itemName} (${i.currentStock.toStringAsFixed(1)} ${i.unit})').join(', ');

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.16 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Depleted inventory: $details. Cattle feeding or consumption requires immediate replenishment.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => controller.openInwardDialog(context),
              icon: const Icon(PhosphorIconsRegular.arrowDownLeft, size: 14),
              label: const Text('Restock Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      );
    });
  }

  // -------------------------------------------------------------
  // SEARCH & FILTERS
  // -------------------------------------------------------------
  Widget _buildSearchAndFilters(BuildContext context, {bool isCompact = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            TextField(
              controller: controller.searchController,
              onChanged: controller.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search by item, bill, supplier...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: Obx(() {
                  if (controller.searchQuery.value.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => controller.setSearchQuery(''),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(() {
                return Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: controller.selectedTypeFilter.value == 'ALL',
                      onSelected: (_) => controller.setTypeFilter('ALL'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(PhosphorIconsRegular.arrowDownLeft, color: Color(0xFF10B981), size: 14),
                      label: const Text('Inward'),
                      selected: controller.selectedTypeFilter.value == 'INWARD',
                      onSelected: (_) => controller.setTypeFilter('INWARD'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(PhosphorIconsRegular.arrowUpRight, color: Color(0xFFF59E0B), size: 14),
                      label: const Text('Outward'),
                      selected: controller.selectedTypeFilter.value == 'OUTWARD',
                      onSelected: (_) => controller.setTypeFilter('OUTWARD'),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Search text field
        Expanded(
          flex: 4,
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.setSearchQuery,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search by item, bill/receipt, supplier, vehicle, notes...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: Obx(() {
                  if (controller.searchQuery.value.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () => controller.setSearchQuery(''),
                    );
                  }
                  return const SizedBox.shrink();
                }),
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
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Movement Type Filter
        _buildTypeFilterDropdown(context, isDark),
        const SizedBox(width: 12),

        // Feed Item Filter
        _buildItemFilterDropdown(context, isDark),
        const SizedBox(width: 12),

        // Reset button
        _buildResetFilterButton(context, isDark),
      ],
    );
  }

  Widget _buildTypeFilterDropdown(BuildContext context, bool isDark) {
    return Obx(() {
      final currentType = controller.selectedTypeFilter.value;
      final typeMap = {
        'ALL': 'All Types',
        'INWARD': 'Inward',
        'OUTWARD': 'Outward',
      };
      return SizedBox(
        width: 180,
        child: CustomDropdownSearch<String>(
          hint: 'All Types',
          prefixIcon: PhosphorIconsRegular.arrowsLeftRight,
          selectedItem: typeMap[currentType] ?? 'All Types',
          items: const ['All Types', 'Inward', 'Outward'],
          itemAsString: (s) => s,
          showClearButton: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          onChanged: (val) {
            if (val == 'Inward') {
              controller.setTypeFilter('INWARD');
            } else if (val == 'Outward') {
              controller.setTypeFilter('OUTWARD');
            } else {
              controller.setTypeFilter('ALL');
            }
          },
        ),
      );
    });
  }

  Widget _buildItemFilterDropdown(BuildContext context, bool isDark) {
    return Obx(() {
      final items = controller.feedItems.toList();
      final currentId = controller.selectedItemFilter.value;

      String selectedItemDisplay = 'All Items';
      if (currentId != null && currentId.isNotEmpty) {
        final match = items.firstWhereOrNull((i) => i.id == currentId);
        if (match != null) {
          selectedItemDisplay = match.itemName;
        }
      }

      final displayItems = ['All Items', ...items.map((i) => i.itemName)];

      return SizedBox(
        width: 220,
        child: CustomDropdownSearch<String>(
          hint: 'All Items',
          prefixIcon: PhosphorIconsRegular.grains,
          selectedItem: selectedItemDisplay,
          items: displayItems,
          itemAsString: (s) => s,
          compareFn: (a, b) => a == b,
          showClearButton: false,
          searchable: displayItems.length > 5,
          searchHint: 'Search item...',
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          onChanged: (val) {
            if (val == null || val == 'All Items') {
              controller.setItemFilter(null);
            } else {
              final match = items.firstWhereOrNull((i) => i.itemName == val);
              controller.setItemFilter(match?.id);
            }
          },
        ),
      );
    });
  }

  Widget _buildResetFilterButton(BuildContext context, bool isDark) {
    return Obx(() {
      final hasActiveFilter = controller.searchQuery.value.isNotEmpty ||
          controller.selectedTypeFilter.value != 'ALL' ||
          controller.selectedReasonFilter.value != 'ALL' ||
          controller.selectedItemFilter.value != null;

      return Tooltip(
        message: 'Reset Filters',
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: controller.clearFilters,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: hasActiveFilter
                  ? AppColors.error.withValues(alpha: 0.1)
                  : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasActiveFilter
                    ? AppColors.error.withValues(alpha: 0.3)
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_alt_off_rounded,
                  size: 18,
                  color: hasActiveFilter
                      ? AppColors.error
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
                if (hasActiveFilter) ...[
                  const SizedBox(width: 6),
                  const Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  // -------------------------------------------------------------
  // DESKTOP TRANSACTIONS TABLE CARD
  // -------------------------------------------------------------
  Widget _buildTransactionsTableCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Toolbar inside Card
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildSearchAndFilters(context),
          ),
          const Divider(height: 1),

          // Content: Shimmer or Table or Empty
          LayoutBuilder(
            builder: (context, constraints) {
              const double minTableWidth = 1240.0;
              final double tableWidth = constraints.maxWidth < minTableWidth
                  ? minTableWidth
                  : constraints.maxWidth;

              return Obx(() {
                if (controller.isLoading.value) {
                  return const CustomTableShimmer(
                    rowCount: 6,
                    columnFlexes: [1, 3, 4, 2, 2, 2, 3, 3, 3, 3, 2],
                    headers: [
                      '#',
                      'DATE & TIME',
                      'FEED ITEM',
                      'TYPE',
                      'REASON',
                      'QUANTITY',
                      'FINANCIALS',
                      'DEST / SOURCE',
                      'STOCK AUDIT',
                      'RECORDED BY',
                      'ACTIONS',
                    ],
                  );
                }

                final list = controller.transactions;

                if (list.isEmpty) {
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
                                border: Border(
                                  left: const BorderSide(color: Colors.transparent, width: 3.5),
                                  bottom: BorderSide(
                                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(width: 50, child: _buildTableHeaderCell('#')),
                                  SizedBox(width: 130, child: _buildTableHeaderCell('DATE & TIME')),
                                  Expanded(flex: 4, child: _buildTableHeaderCell('FEED ITEM')),
                                  SizedBox(width: 105, child: _buildTableHeaderCell('TYPE')),
                                  SizedBox(width: 115, child: _buildTableHeaderCell('REASON')),
                                  SizedBox(width: 115, child: _buildTableHeaderCell('QUANTITY')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('FINANCIALS')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('DEST / SOURCE')),
                                  SizedBox(width: 175, child: _buildTableHeaderCell('STOCK AUDIT')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('RECORDED BY')),
                                  SizedBox(width: 100, child: _buildTableHeaderCell('ACTIONS', alignRight: true)),
                                ],
                              ),
                            ),

                            // Table Data Rows
                            ...list.asMap().entries.map((entry) {
                              final pageStartIndex = (controller.currentPage.value - 1) * controller.rowsPerPage.value;
                              final index = pageStartIndex + entry.key;
                              final tx = entry.value;
                              return _HoverableStockTransactionTableRow(
                                key: ValueKey(tx.id),
                                index: index,
                                tx: tx,
                                isDark: isDark,
                                onView: () => controller.openTransactionDetailsDialog(context, tx),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),

                    // Pagination Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: CustomPagination(
                        currentPage: controller.currentPage.value,
                        rowsPerPage: controller.rowsPerPage.value,
                        totalItems: controller.totalRecords.value,
                        onPageChanged: controller.setPage,
                        onRowsPerPageChanged: controller.setRowsPerPage,
                      ),
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

  Widget _buildTableHeaderCell(String title, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Text(
        title,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // MOBILE / TABLET LIST CARDS
  // -------------------------------------------------------------
  Widget _buildTransactionsMobileList(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoading.value) {
        return const CustomShimmer(
          child: Column(
            children: [
              ShimmerPlaceholder(width: double.infinity, height: 110),
              SizedBox(height: 10),
              ShimmerPlaceholder(width: double.infinity, height: 110),
              SizedBox(height: 10),
              ShimmerPlaceholder(width: double.infinity, height: 110),
            ],
          ),
        );
      }

      final list = controller.transactions;

      if (list.isEmpty) {
        return _buildEmptyState(context);
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, index) => const SizedBox(height: 10),
        itemBuilder: (ctx, index) {
          final tx = list[index];
          return _HoverableTransactionMobileCard(
            key: ValueKey(tx.id),
            tx: tx,
            isDark: isDark,
            onTap: () => controller.openTransactionDetailsDialog(context, tx),
          );
        },
      );
    });
  }

  // -------------------------------------------------------------
  // EMPTY STATE
  // -------------------------------------------------------------
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                PhosphorIconsRegular.receipt,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Stock Transactions Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                'Record fresh inward stock from purchases/donations or issue stock for daily cattle feeding.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomButton(
                  text: 'Record Outward',
                  icon: PhosphorIconsRegular.arrowUpRight,
                  variant: ButtonVariant.outlined,
                  textColor: const Color(0xFFF59E0B),
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  onPressed: () => controller.openOutwardDialog(context),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  text: 'Record Inward Stock',
                  icon: PhosphorIconsRegular.arrowDownLeft,
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: () => controller.openInwardDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Interactive, hoverable metric card for Feed Stock summary metrics.
/// Features smooth 3D elevation floating, glowing shadow in metric accent color,
/// border highlight, and clickable filter actions.
class _HoverableStockMetricCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool isSelected;
  final VoidCallback? onTap;

  const _HoverableStockMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<_HoverableStockMetricCard> createState() => _HoverableStockMetricCardState();
}

class _HoverableStockMetricCardState extends State<_HoverableStockMetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final isDark = widget.isDark;
    final isSelected = widget.isSelected;

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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? (_isHovered
                    ? AppColors.surfaceDark
                    : (isSelected ? color.withValues(alpha: 0.12) : AppColors.cardDark))
                : (_isHovered
                    ? Colors.white
                    : (isSelected ? color.withValues(alpha: 0.05) : AppColors.cardLight)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (_isHovered || isSelected)
                  ? color.withValues(alpha: isSelected ? 0.85 : 0.60)
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: (_isHovered || isSelected) ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (_isHovered) ...[
                BoxShadow(
                  color: color.withValues(alpha: 0.20),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ] else if (isSelected) ...[
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ] else ...[
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: _isHovered || isSelected ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
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
    );
  }
}

/// Interactive, hoverable data table row for Feed Stock Transactions.
/// Incorporates the interactive animation design from Herd & Cattle (`_HoverableCowTableRow`):
/// - Smooth background tint and 3.5px primary left accent bar on hover
/// - AnimatedDefaultTextStyle on row index (#) transitioning to bold and primary color
/// - AnimatedContainer on Item Code & Category badges with subtle box-shadow glow
/// - AnimatedContainer on Type & Reason chips with elevated shadow
/// - Animated typography transitions across Date, Item name, Financials, and Destination
/// - Glowing warning badge for 0 stock audit records
/// - Action buttons (View Details eye & View Voucher receipt) illuminating on hover
class _HoverableStockTransactionTableRow extends StatefulWidget {
  final int index;
  final FeedStockTransactionModel tx;
  final bool isDark;
  final VoidCallback onView;

  const _HoverableStockTransactionTableRow({
    super.key,
    required this.index,
    required this.tx,
    required this.isDark,
    required this.onView,
  });

  @override
  State<_HoverableStockTransactionTableRow> createState() =>
      _HoverableStockTransactionTableRowState();
}

class _HoverableStockTransactionTableRowState
    extends State<_HoverableStockTransactionTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    final isDark = widget.isDark;

    final dateStr = tx.transactionDate != null
        ? DateFormat('dd MMM yyyy').format(tx.transactionDate!)
        : 'N/A';
    final timeStr = tx.transactionDate != null
        ? DateFormat('hh:mm a').format(tx.transactionDate!)
        : '';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onView,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark
                    ? AppColors.surfaceDark.withValues(alpha: 0.85)
                    : AppColors.primary.withValues(alpha: 0.045))
                : (widget.index.isEven
                    ? Colors.transparent
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.015)
                        : const Color(0xFFFAFCF9))),
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
              // 0. # INDEX
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

              // 1. DATE & TIME
              SizedBox(
                width: 130,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 160),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _isHovered ? FontWeight.bold : FontWeight.w600,
                          color: _isHovered
                              ? (isDark ? Colors.white : AppColors.primary)
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                        child: Text(dateStr),
                      ),
                      if (timeStr.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 2. FEED ITEM
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 160),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _isHovered
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                        child: Text(
                          tx.itemName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (tx.itemCode.isNotEmpty) ...[
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: _isHovered ? 0.20 : 0.12),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: _isHovered ? 0.50 : 0.25),
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
                                  const Icon(PhosphorIconsRegular.tag, size: 10.5, color: AppColors.primary),
                                  const SizedBox(width: 3.5),
                                  Text(
                                    tx.itemCode,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Flexible(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: tx.categoryEnum.color.withValues(alpha: _isHovered ? 0.18 : 0.10),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: tx.categoryEnum.color.withValues(alpha: _isHovered ? 0.45 : 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                tx.categoryEnum.label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: tx.categoryEnum.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 3. TYPE
              SizedBox(
                width: 105,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: tx.typeEnum.color.withValues(alpha: _isHovered ? 0.22 : 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: tx.typeEnum.color.withValues(alpha: _isHovered ? 0.55 : 0.25),
                            width: 1.0,
                          ),
                          boxShadow: _isHovered
                              ? [
                                  BoxShadow(
                                    color: tx.typeEnum.color.withValues(alpha: 0.18),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tx.typeEnum.icon, color: tx.typeEnum.color, size: 13),
                            const SizedBox(width: 4.5),
                            Text(
                              tx.typeEnum.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: tx.typeEnum.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 4. REASON
              SizedBox(
                width: 115,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: tx.reasonEnum.color.withValues(alpha: _isHovered ? 0.18 : 0.10),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: tx.reasonEnum.color.withValues(alpha: _isHovered ? 0.45 : 0.20),
                            width: 0.8,
                          ),
                          boxShadow: _isHovered
                              ? [
                                  BoxShadow(
                                    color: tx.reasonEnum.color.withValues(alpha: 0.14),
                                    blurRadius: 5,
                                    offset: const Offset(0, 1.5),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          tx.reasonEnum.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: tx.reasonEnum.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 5. QUANTITY
              SizedBox(
                width: 115,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 160),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: tx.isInward
                            ? (isDark ? AppColors.primaryLight : AppColors.primary)
                            : const Color(0xFFF59E0B),
                      ),
                      child: Text(
                        '${tx.isInward ? '+' : '-'}${tx.quantity.toStringAsFixed(1)} ${tx.unit}',
                      ),
                    ),
                  ),
                ),
              ),

              // 6. FINANCIALS
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: tx.totalAmount > 0
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 160),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: _isHovered
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              ),
                              child: Text(
                                '₹${NumberFormat('#,##,###.##').format(tx.totalAmount)}',
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '@ ₹${tx.ratePerUnit.toStringAsFixed(2)}/${tx.unit}',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '—',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                ),
              ),

              // 7. DEST / SOURCE
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: tx.isOutward && tx.shedName != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _isHovered
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                PhosphorIconsRegular.warehouse,
                                size: 14,
                                color: _isHovered ? AppColors.primary : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 160),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _isHovered ? FontWeight.bold : FontWeight.w600,
                                  color: _isHovered
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                ),
                                child: Text(
                                  '${tx.shedName!} (${tx.shedNumber ?? ''})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        )
                      : (tx.supplierOrDonorName.isNotEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 160),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _isHovered ? FontWeight.bold : FontWeight.w600,
                                    color: _isHovered
                                        ? (isDark ? Colors.white : Colors.black87)
                                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                  ),
                                  child: Text(
                                    tx.supplierOrDonorName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (tx.billOrReceiptNo.isNotEmpty) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    'Bill: ${tx.billOrReceiptNo}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : Text(
                              '—',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            )),
                ),
              ),

              // 8. STOCK AUDIT
              SizedBox(
                width: 175,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tx.stockBefore.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        PhosphorIconsRegular.arrowRight,
                        size: 11,
                        color: tx.isInward
                            ? (isDark ? AppColors.primaryLight : AppColors.primary)
                            : (tx.stockAfter <= 0 ? AppColors.error : const Color(0xFFF59E0B)),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: tx.stockAfter <= 0
                            ? AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: _isHovered ? 0.20 : 0.12),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: AppColors.error.withValues(alpha: _isHovered ? 0.60 : 0.35),
                                    width: 1.0,
                                  ),
                                  boxShadow: _isHovered
                                      ? [
                                          BoxShadow(
                                            color: AppColors.error.withValues(alpha: 0.20),
                                            blurRadius: 6,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 11.5,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        '${tx.stockAfter.toStringAsFixed(1)} ${tx.unit}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 160),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: _isHovered
                                      ? (tx.isInward
                                          ? (isDark ? AppColors.primaryLight : AppColors.primary)
                                          : const Color(0xFFD97706))
                                      : (tx.isInward
                                          ? (isDark ? AppColors.primaryLight : AppColors.primary)
                                          : const Color(0xFFF59E0B)),
                                ),
                                child: Text(
                                  '${tx.stockAfter.toStringAsFixed(1)} ${tx.unit}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // 9. RECORDED BY
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 160),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _isHovered ? FontWeight.w600 : FontWeight.normal,
                      color: _isHovered
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                    child: Text(
                      tx.recordedByName ?? 'Admin',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),

              // 10. ACTIONS (Details Eye + Voucher Receipt matching Herd & Cattle)
              SizedBox(
                width: 100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: 'View Details',
                            waitDuration: const Duration(milliseconds: 300),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              mouseCursor: SystemMouseCursors.click,
                              hoverColor: AppColors.primary.withValues(alpha: 0.12),
                              onTap: widget.onView,
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Icon(
                                  PhosphorIconsRegular.eye,
                                  size: 17,
                                  color: _isHovered
                                      ? AppColors.primary
                                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'View Voucher / Receipt',
                            waitDuration: const Duration(milliseconds: 300),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              mouseCursor: SystemMouseCursors.click,
                              hoverColor: AppColors.secondary.withValues(alpha: 0.12),
                              onTap: widget.onView,
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Icon(
                                  PhosphorIconsRegular.receipt,
                                  size: 17,
                                  color: _isHovered
                                      ? AppColors.secondary
                                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                ),
                              ),
                            ),
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
      ),
    );
  }
}

/// Interactive, hoverable card for Mobile and Tablet Feed Stock Transactions.
/// Emulates cattle mobile card polish with smooth elevation lift, border highlight,
/// glowing shadow, and stock audit warning badges.
class _HoverableTransactionMobileCard extends StatefulWidget {
  final FeedStockTransactionModel tx;
  final bool isDark;
  final VoidCallback onTap;

  const _HoverableTransactionMobileCard({
    super.key,
    required this.tx,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_HoverableTransactionMobileCard> createState() =>
      _HoverableTransactionMobileCardState();
}

class _HoverableTransactionMobileCardState
    extends State<_HoverableTransactionMobileCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    final isDark = widget.isDark;
    final dateStr = tx.transactionDate != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(tx.transactionDate!)
        : 'N/A';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? tx.typeEnum.color
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: tx.typeEnum.color.withValues(alpha: 0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Item Name + Tag + Quantity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            tx.itemName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tx.itemCode.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              tx.itemCode,
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '${tx.isInward ? '+' : '-'}${tx.quantity.toStringAsFixed(1)} ${tx.unit}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: tx.typeEnum.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Middle row: Badges
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tx.typeEnum.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tx.typeEnum.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: tx.typeEnum.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tx.reasonEnum.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tx.reasonEnum.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: tx.reasonEnum.color,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (tx.isOutward && tx.shedName != null)
                    Text(
                      'Shed: ${tx.shedName}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    )
                  else if (tx.totalAmount > 0)
                    Text(
                      '₹${NumberFormat('#,##,###').format(tx.totalAmount)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Bottom row: Date & Audit Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  tx.stockAfter <= 0
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Stock: ${tx.stockBefore.toStringAsFixed(0)} ➔ ',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 11, color: AppColors.error),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${tx.stockAfter.toStringAsFixed(1)} ${tx.unit} (Out of Stock)',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Stock: ${tx.stockBefore.toStringAsFixed(0)} ➔ ${tx.stockAfter.toStringAsFixed(0)} ${tx.unit}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
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

