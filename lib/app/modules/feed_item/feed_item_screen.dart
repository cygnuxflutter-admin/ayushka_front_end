import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/utils/responsive_layout.dart';
import '../../core/values/app_colors.dart';
import '../../core/values/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/widgets/custom_pagination.dart';
import '../../core/widgets/mobile_list_bottom_loader.dart';
import '../../core/widgets/custom_shimmer.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/global_gaushala_selector.dart';
import '../../core/widgets/header_user_profile_badge.dart';
import '../notification/widgets/notification_bell_widget.dart';
import '../../data/models/feed_item_model.dart';
import '../../routes/app_routes.dart';
import '../dashboard/widgets/mobile_drawer.dart';
import '../dashboard/widgets/web_sidebar.dart';
import 'feed_item_controller.dart';

/// Screen component for managing Feed Stock Items Master.
class FeedItemScreen extends GetView<FeedItemController> {
  const FeedItemScreen({super.key});

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
                            const SizedBox(height: 24),
                            _buildFeedItemsTableCard(context),
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
        title: const Text('Feed Items Master'),
        actions: [
          const NotificationBellWidget(),
          Obx(() {
            final isBusy = controller.isRefreshing.value || controller.isLoading.value;
            return IconButton(
              icon: isBusy
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh Items',
              onPressed: isBusy ? null : controller.refreshFeedItems,
            );
          }),
          if (controller.canAddFeedItem)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add Feed Item',
              onPressed: () => controller.openAddFeedItemDialog(context),
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
            _buildSearchAndFilters(context, isCompact: true),
            const SizedBox(height: 16),
            _buildFeedItemList(context),
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
        title: const Text('Feed Items Master'),
        actions: [
          const NotificationBellWidget(),
          Obx(() {
            final isBusy = controller.isRefreshing.value || controller.isLoading.value;
            return IconButton(
              icon: isBusy
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh Items',
              onPressed: isBusy ? null : controller.refreshFeedItems,
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
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            controller.loadMoreMobile();
          }
          return false;
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSearchAndFilters(context, isCompact: true),
              const SizedBox(height: 14),
              _buildFeedItemList(context),
            ],
          ),
        ),
      ),
      floatingActionButton: controller.canAddFeedItem
          ? FloatingActionButton.extended(
              onPressed: () => controller.openAddFeedItemDialog(context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Item'),
            )
          : null,
    );
  }

  // -------------------------------------------------------------
  // DESKTOP TOP HEADER / APP BAR
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
          // Left: Screen Title & Badge
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
                  'MASTER',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Feed Stock Items & Fodder',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Obx(
                  () => Text(
                    '${controller.feedItems.length} Total Items',
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
                  onPressed: isBusy ? null : controller.refreshFeedItems,
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
  // BREADCRUMBS & TOP ACTION BAR
  // -------------------------------------------------------------
  Widget _buildBreadcrumbAndActionBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Breadcrumb
        Row(
          children: [
            Text(
              'Masters',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            const SizedBox(width: 6),
            Text(
              'Feed Stock Items',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),

        // Action Buttons
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(PhosphorIconsRegular.arrowsLeftRight, size: 16),
              label: const Text('Stock Transactions'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Get.toNamed(AppRoutes.feedTransactions),
            ),
            if (controller.canAddFeedItem) ...[
              const SizedBox(width: 10),
              CustomButton(
                text: 'Add Feed Item',
                icon: Icons.add_rounded,
                onPressed: () => controller.openAddFeedItemDialog(context),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // SUMMARY METRICS CARDS
  // -------------------------------------------------------------
  Widget _buildSummaryMetricCards(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;
        final cardWidth = isNarrow ? double.infinity : (constraints.maxWidth - 32) / 3;

        return Obx(() {
          final totalCount = controller.feedItems.length;
          final lowCount = controller.feedItems.where((i) => i.isLowStock).length;
          final activeCount = controller.feedItems.where((i) => i.isActive).length;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _HoverableFeedMetricCard(
                title: 'Total Feed Items',
                count: '$totalCount',
                subtitle: 'Registered fodder & feeds',
                icon: PhosphorIconsRegular.grains,
                accentColor: AppColors.primary,
                isDark: isDark,
                width: cardWidth,
                onTap: controller.clearFilters,
              ),
              _HoverableFeedMetricCard(
                title: 'Low Stock Alerts',
                count: '$lowCount',
                subtitle: 'At or below threshold',
                icon: PhosphorIconsRegular.warningCircle,
                accentColor: AppColors.warning,
                isDark: isDark,
                width: cardWidth,
              ),
              _HoverableFeedMetricCard(
                title: 'Active Items',
                count: '$activeCount',
                subtitle: 'Available for daily diet',
                icon: PhosphorIconsRegular.checkCircle,
                accentColor: AppColors.success,
                isDark: isDark,
                width: cardWidth,
              ),
            ],
          );
        });
      },
    );
  }

  // -------------------------------------------------------------
  // DESKTOP TABLE CARD
  // -------------------------------------------------------------
  Widget _buildFeedItemsTableCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter & Search Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildSearchAndFilters(context),
          ),
          const Divider(height: 1),

          // Main Table Area
          Obx(() {
            if (controller.isLoading.value && controller.feedItems.isEmpty) {
              return const CustomTableShimmer(
                rowCount: 6,
                columnFlexes: [5, 4, 4, 4, 3, 3, 3],
              );
            }

            final list = controller.filteredFeedItems;
            if (list.isEmpty) {
              return _buildEmptyState(context);
            }

            return Column(
              children: [
                // Table Column Header Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardDark.withValues(alpha: 0.6)
                        : AppColors.backgroundLight.withValues(alpha: 0.8),
                    border: const Border(
                      left: BorderSide(color: Colors.transparent, width: 3.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 56.5, child: _buildTableHeaderCell('#')),
                      Expanded(flex: 5, child: _buildTableHeaderCell('ITEM NAME & CODE')),
                      Expanded(flex: 4, child: _buildTableHeaderCell('CATEGORY')),
                      Expanded(flex: 4, child: _buildTableHeaderCell('GAUSHALA')),
                      Expanded(flex: 4, child: _buildTableHeaderCell('STOCK LEVEL')),
                      Expanded(flex: 3, child: _buildTableHeaderCell('STATUS')),
                      SizedBox(width: 90, child: _buildTableHeaderCell('ACTIONS', alignRight: true)),
                    ],
                  ),
                ),

                // Table Rows
                ...controller.paginatedFeedItems.asMap().entries.map((entry) {
                  final pageStartIndex = (controller.currentPage.value - 1) * controller.rowsPerPage.value;
                  final index = pageStartIndex + entry.key;
                  final item = entry.value;
                  return _HoverableFeedItemTableRow(
                    key: ValueKey(item.id),
                    index: index,
                    item: item,
                    isDark: isDark,
                  );
                }),

                const Divider(height: 1),

                // Pagination
                CustomPagination(
                  totalItems: list.length,
                  currentPage: controller.currentPage.value,
                  rowsPerPage: controller.rowsPerPage.value,
                  onPageChanged: controller.setPage,
                  onRowsPerPageChanged: controller.setRowsPerPage,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SEARCH & FILTER BAR
  // -------------------------------------------------------------
  Widget _buildSearchAndFilters(BuildContext context, {bool isCompact = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            hint: 'Search by item name, code, category...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            onChanged: (val) => controller.searchQuery.value = val,
          ),
          const SizedBox(height: 10),
          _buildGaushalaFilterDropdown(context, isDark, isExpanded: true),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryFilterChips(context),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        // Search Input
        Expanded(
          flex: 4,
          child: CustomTextField(
            hint: 'Search by item name, code, category, gaushala...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            onChanged: (val) => controller.searchQuery.value = val,
          ),
        ),
        const SizedBox(width: 12),

        // Gaushala Filter Dropdown
        _buildGaushalaFilterDropdown(context, isDark),
        const SizedBox(width: 12),

        // Category Filter Dropdown
        _buildCategoryFilterDropdown(context, isDark),
        const SizedBox(width: 12),

        // Clear Filters (if active)
        Obx(() {
          final hasFilters = controller.searchQuery.value.isNotEmpty ||
              controller.selectedCategoryFilter.value != 'ALL' ||
              controller.selectedStockFilter.value != 'ALL' ||
              controller.selectedStatusFilter.value != 'ALL';

          if (!hasFilters) return const SizedBox.shrink();

          return Tooltip(
            message: 'Clear all filters',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: controller.clearFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_alt_off_rounded, size: 16, color: AppColors.error),
                    SizedBox(width: 6),
                    Text('Reset', style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGaushalaFilterDropdown(BuildContext context, bool isDark, {bool isExpanded = false}) {
    return Obx(() {
      final list = controller.gaushalas.toList();
      final currentFilter = controller.selectedGaushalaFilter.value ?? '';
      final isFiltered = currentFilter.isNotEmpty;

      String selectedName = 'All Gaushalas';
      if (isFiltered) {
        final match = list.firstWhereOrNull((g) => g.id == currentFilter);
        if (match != null) {
          selectedName = match.gaushalaName;
        }
      }

      final items = ['All Gaushalas', ...list.map((g) => g.gaushalaName)];

      return SizedBox(
        width: isExpanded ? double.infinity : 220,
        child: DropdownSearch<String>(
          items: (filter, infiniteScrollProps) {
            if (filter.isEmpty) return items;
            return items
                .where((item) => item.toLowerCase().contains(filter.toLowerCase()))
                .toList();
          },
          selectedItem: selectedName,
          compareFn: (i1, i2) => i1 == i2,
          onSelected: (selected) {
            if (selected == null || selected == 'All Gaushalas') {
              controller.setGaushalaFilter(null);
            } else {
              final match = list.firstWhereOrNull((g) => g.gaushalaName == selected);
              controller.setGaushalaFilter(match?.id);
            }
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
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              prefixIcon: const Icon(Icons.storefront_outlined, size: 17),
              filled: true,
              fillColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
            ),
          ),
          popupProps: PopupProps.menu(
            showSearchBox: items.length > 6,
            menuProps: MenuProps(
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCategoryFilterDropdown(BuildContext context, bool isDark) {
    return Obx(() {
      final currentCategory = controller.selectedCategoryFilter.value;

      final categories = [
        {'code': 'ALL', 'label': 'All Categories'},
        ...FeedItemCategory.values.map((c) => {'code': c.code, 'label': c.label}),
      ];

      return SizedBox(
        width: 200,
        child: DropdownSearch<Map<String, String>>(
          items: (filter, infiniteScrollProps) => categories,
          itemAsString: (c) => c['label'] ?? '',
          compareFn: (c1, c2) => c1['code'] == c2['code'],
          selectedItem: categories.firstWhere((c) => c['code'] == currentCategory),
          onSelected: (selected) {
            if (selected != null) {
              controller.setCategoryFilter(selected['code']!);
            }
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
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              prefixIcon: const Icon(PhosphorIconsRegular.tag, size: 17),
              filled: true,
              fillColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
            ),
          ),
          popupProps: PopupProps.menu(
            menuProps: MenuProps(
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCategoryFilterChips(BuildContext context) {
    return Obx(() {
      final currentCategory = controller.selectedCategoryFilter.value;

      return Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: currentCategory == 'ALL',
            onSelected: (_) => controller.setCategoryFilter('ALL'),
          ),
          const SizedBox(width: 8),
          ...FeedItemCategory.values.map((cat) {
            final isSelected = currentCategory == cat.code;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(cat.code.replaceAll('_', ' ')),
                selected: isSelected,
                selectedColor: cat.color.withValues(alpha: 0.2),
                checkmarkColor: cat.color,
                onSelected: (_) => controller.setCategoryFilter(cat.code),
              ),
            );
          }),
        ],
      );
    });
  }

  // -------------------------------------------------------------
  // MOBILE / TABLET LIST VIEW
  // -------------------------------------------------------------
  Widget _buildFeedItemList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoading.value && controller.feedItems.isEmpty) {
        return const CustomListShimmer(itemCount: 5);
      }

      final list = controller.filteredFeedItems;
      if (list.isEmpty) {
        return _buildEmptyState(context);
      }

      final isMobile = ResponsiveLayout.isMobile(context);
      final displayList = isMobile ? controller.mobileFeedItems : controller.paginatedFeedItems;

      return Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayList.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = displayList[index];
              return _HoverableListCard(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Item Name, Code & Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: item.categoryEnum.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.itemName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Tooltip(
                            message: 'Click to ${item.isActive ? "deactivate" : "activate"}',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => controller.toggleFeedItemStatus(item),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: item.isActive
                                      ? AppColors.success.withValues(alpha: 0.12)
                                      : AppColors.error.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: item.isActive ? AppColors.success : AppColors.error,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Code & Category
                      Row(
                        children: [
                          if (item.itemCode.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.itemCode,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            item.categoryEnum.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Stock Row
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Stock: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                              Text(
                                '${item.currentStock} ${item.unitEnum.shortLabel}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: item.isOutOfStock
                                      ? AppColors.error
                                      : (item.isLowStock ? AppColors.warning : AppColors.success),
                                ),
                              ),
                              if (item.isOutOfStock) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
                                  ),
                                  child: const Text(
                                    'Out of Stock',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ] else if (item.isLowStock) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
                                  ),
                                  child: const Text(
                                    'Low Stock',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            'Min alert: ${item.minStockAlert} ${item.unitEnum.shortLabel}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(PhosphorIconsRegular.eye, size: 18),
                            tooltip: 'View Details',
                            onPressed: () => controller.showFeedItemDetailsDialog(context, item),
                          ),
                          if (controller.canEditFeedItem)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Edit Item',
                              onPressed: () => controller.openEditFeedItemDialog(context, item),
                            ),
                          if (controller.canDeleteFeedItem)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                              color: AppColors.error,
                              tooltip: 'Delete Item',
                              onPressed: () => controller.confirmDeleteFeedItem(context, item),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (isMobile) ...[
            const SizedBox(height: 16),
            MobileListBottomLoader(
              hasMore: controller.hasMoreMobile,
              totalCount: list.length,
            ),
          ] else ...[
            const SizedBox(height: 14),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: CustomPagination(
                totalItems: list.length,
                currentPage: controller.currentPage.value,
                rowsPerPage: controller.rowsPerPage.value,
                onPageChanged: controller.setPage,
                onRowsPerPageChanged: controller.setRowsPerPage,
              ),
            ),
          ],
        ],
      );
    });
  }

  // -------------------------------------------------------------
  // EMPTY STATE
  // -------------------------------------------------------------
  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFiltered = controller.searchQuery.value.isNotEmpty ||
        controller.selectedCategoryFilter.value != 'ALL';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
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
                PhosphorIconsRegular.grains,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isFiltered ? 'No Matching Feed Items' : 'No Feed Items Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered
                  ? 'Try adjusting your search criteria or category filters.'
                  : 'Start by adding your first fodder or concentrate feed item.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (isFiltered)
              CustomButton(
                text: 'Reset Filters',
                icon: Icons.filter_alt_off_rounded,
                onPressed: controller.clearFilters,
              )
            else if (controller.canAddFeedItem)
              CustomButton(
                text: 'Add Feed Item',
                icon: Icons.add_rounded,
                onPressed: () => controller.openAddFeedItemDialog(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String title, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Text(
        title,
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
}

// -------------------------------------------------------------
// HOVERABLE TABLE ROW
// -------------------------------------------------------------
class _HoverableFeedItemTableRow extends StatefulWidget {
  final int index;
  final FeedItemModel item;
  final bool isDark;

  const _HoverableFeedItemTableRow({
    super.key,
    required this.index,
    required this.item,
    required this.isDark,
  });

  @override
  State<_HoverableFeedItemTableRow> createState() => _HoverableFeedItemTableRowState();
}

class _HoverableFeedItemTableRowState extends State<_HoverableFeedItemTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = widget.isDark;
    final controller = Get.find<FeedItemController>();

    String gaushalaName = item.gaushalaName ?? '';
    if (gaushalaName.isEmpty && item.gaushalaId != null && item.gaushalaId!.isNotEmpty) {
      final match = controller.gaushalas.firstWhereOrNull((g) => g.id == item.gaushalaId);
      if (match != null) {
        gaushalaName = match.gaushalaName;
      }
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: _isHovered
              ? (isDark
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.primary.withValues(alpha: 0.04))
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 0.8,
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
              width: 56.5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Text(
                  '${widget.index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _isHovered ? FontWeight.bold : FontWeight.w500,
                    color: _isHovered
                        ? (isDark ? AppColors.primaryLight : AppColors.primary)
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ),

            // Item Name & Code
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.itemName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _isHovered
                                  ? (isDark ? AppColors.primaryLight : AppColors.primary)
                                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.itemCode.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          item.itemCode,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Category Pill
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.categoryEnum.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: item.categoryEnum.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      item.categoryEnum.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: item.categoryEnum.color,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Gaushala Badge
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: gaushalaName.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.storefront_outlined, size: 14, color: AppColors.secondary),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              gaushalaName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        '-',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
              ),
            ),

            // Current Stock Level
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${item.currentStock} ${item.unitEnum.shortLabel}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: item.isOutOfStock
                                ? AppColors.error
                                : (item.isLowStock ? AppColors.warning : AppColors.success),
                          ),
                        ),
                        if (item.isOutOfStock) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
                            ),
                            child: const Text(
                              'Out of Stock',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ] else if (item.isLowStock) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
                            ),
                            child: const Text(
                              'Low Stock',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Min alert: ${item.minStockAlert} ${item.unitEnum.shortLabel}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),


            // Status Badge
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Tooltip(
                    message: 'Click to ${item.isActive ? "deactivate" : "activate"}',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => controller.toggleFeedItemStatus(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.isActive
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: item.isActive
                                ? AppColors.success.withValues(alpha: 0.25)
                                : AppColors.error.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          item.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: item.isActive ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Actions (View, Edit & Delete)
            SizedBox(
              width: 110,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: const EdgeInsets.all(4),
                      icon: const Icon(PhosphorIconsRegular.eye, size: 17),
                      tooltip: 'View Details',
                      hoverColor: AppColors.primary.withValues(alpha: 0.1),
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      onPressed: () => controller.showFeedItemDetailsDialog(context, item),
                    ),
                    if (controller.canEditFeedItem) ...[
                      const SizedBox(width: 2),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: const EdgeInsets.all(4),
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        tooltip: 'Edit Item',
                        hoverColor: AppColors.primary.withValues(alpha: 0.1),
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        onPressed: () => controller.openEditFeedItemDialog(context, item),
                      ),
                    ],
                    if (controller.canDeleteFeedItem) ...[
                      const SizedBox(width: 2),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: const EdgeInsets.all(4),
                        icon: const Icon(Icons.delete_outline_rounded, size: 17),
                        tooltip: 'Delete Item',
                        hoverColor: AppColors.error.withValues(alpha: 0.1),
                        color: AppColors.error,
                        onPressed: () => controller.confirmDeleteFeedItem(context, item),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// HOVERABLE METRIC CARD
// -------------------------------------------------------------
class _HoverableFeedMetricCard extends StatefulWidget {
  final String title;
  final String count;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isDark;
  final double width;
  final VoidCallback? onTap;

  const _HoverableFeedMetricCard({
    required this.title,
    required this.count,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.isDark,
    required this.width,
    this.onTap,
  });

  @override
  State<_HoverableFeedMetricCard> createState() => _HoverableFeedMetricCardState();
}

class _HoverableFeedMetricCardState extends State<_HoverableFeedMetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor;
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
          width: widget.width,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? (_isHovered ? AppColors.surfaceDark : AppColors.cardDark)
                : (_isHovered ? Colors.white : AppColors.cardLight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? accentColor.withValues(alpha: 0.60)
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: 1.0,
            ),
            boxShadow: [
              if (_isHovered) ...[
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.18),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: _isHovered ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.count,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
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

// -------------------------------------------------------------
// HOVERABLE CARD (MOBILE / TABLET)
// -------------------------------------------------------------
class _HoverableListCard extends StatefulWidget {
  final Widget child;
  const _HoverableListCard({required this.child});

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
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? (isDark ? AppColors.primaryLight : AppColors.primary.withValues(alpha: 0.4))
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
