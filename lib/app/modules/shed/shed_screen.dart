import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/values/app_colors.dart';
import '../../core/values/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/widgets/custom_pagination.dart';
import '../../core/widgets/custom_shimmer.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../core/widgets/global_gaushala_selector.dart';
import '../../core/widgets/header_user_profile_badge.dart';
import '../notification/widgets/notification_bell_widget.dart';
import '../../data/models/shed_model.dart';
import '../../routes/app_routes.dart';
import '../dashboard/widgets/mobile_drawer.dart';
import '../dashboard/widgets/web_sidebar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'shed_controller.dart';

/// Screen for Managing Cattle Sheds (Master > Sheds).
class ShedScreen extends GetView<ShedController> {
  const ShedScreen({super.key});

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
          Obx(
            () => WebSidebar(
              isCollapsed: controller.isSidebarCollapsed.value,
              onToggle: controller.toggleSidebar,
              currentUser: controller.currentUser.value,
              onLogout: controller.logout,
            ),
          ),
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
                            const SizedBox(height: 24),
                            _buildShedsTableCard(context),
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
        title: const Text('Sheds Master'),
        actions: [
          const NotificationBellWidget(),
          Obx(() {
            final isBusy = controller.isRefreshing.value || controller.isLoading.value;
            return IconButton(
              icon: isBusy
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh Sheds',
              onPressed: isBusy ? null : controller.refreshSheds,
            );
          }),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.clockCounterClockwise),
            tooltip: 'Transfer History',
            onPressed: () => controller.openTransferHistoryDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Shed',
            onPressed: () => controller.openAddShedDialog(context),
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
            _buildSearchBox(context),
            const SizedBox(height: 16),
            _buildShedList(context),
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
        title: const Text('Sheds Master'),
        actions: [
          const NotificationBellWidget(),
          Obx(() {
            final isBusy = controller.isRefreshing.value || controller.isLoading.value;
            return IconButton(
              icon: isBusy
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh Sheds',
              onPressed: isBusy ? null : controller.refreshSheds,
            );
          }),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.clockCounterClockwise),
            tooltip: 'Transfer History',
            onPressed: () => controller.openTransferHistoryDialog(context),
          ),
        ],
      ),
      drawer: Obx(
        () => MobileDrawer(
          currentUser: controller.currentUser.value,
          onLogout: controller.logout,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Shed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => controller.openAddShedDialog(context),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshSheds,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSearchBox(context),
              const SizedBox(height: 16),
              _buildShedList(context),
            ],
          ),
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
                'Cattle Sheds & Barns Management',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                  tooltip: isBusy ? 'Refreshing...' : 'Refresh Sheds',
                  onPressed: isBusy ? null : controller.refreshSheds,
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
                  'Masters',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                const Text(
                  'Sheds',
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
              'Sheds Master',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        Row(
          children: [
            CustomButton(
              text: 'Transfer History',
              icon: PhosphorIconsRegular.clockCounterClockwise,
              variant: ButtonVariant.outlined,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onPressed: () => controller.openTransferHistoryDialog(context),
            ),
            const SizedBox(width: 10),
            CustomButton(
              text: 'Add Shed',
              icon: Icons.add_rounded,
              width: 130,
              height: 42,
              onPressed: () => controller.openAddShedDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // DESKTOP SHEDS TABLE CARD
  // -------------------------------------------------------------
  Widget _buildShedsTableCard(BuildContext context) {
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
          // Filter & Search bar header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.warehouse, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Registered Sheds',
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
                          '${controller.filteredSheds.length} Total',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    Obx(() {
                      if (controller.isLoading.value && controller.sheds.isNotEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: CustomInlineLoader(size: 14, strokeWidth: 1.8),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGaushalaFilterDropdown(context, isDark),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 240,
                      child: TextField(
                        onChanged: (val) => controller.searchQuery.value = val,
                        decoration: InputDecoration(
                          hintText: 'Search sheds...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          suffixIcon: Obx(
                            () => controller.searchQuery.value.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16),
                                    onPressed: () => controller.searchQuery.value = '',
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
              ],
            ),
          ),
          const Divider(height: 1),

          // Content: Table or Loading or Empty
          Obx(() {
            if (controller.isLoading.value) {
              return const CustomTableShimmer(
                rowCount: 6,
                columnFlexes: [5, 3, 4, 5, 4],
                headers: ['#', 'SHED NAME', 'SHED NUMBER', 'GAUSHALA', 'SYSTEM ID', 'CREATED AT'],
              );
            }

            final list = controller.filteredSheds;
            if (list.isEmpty) {
              final isSearching = controller.searchQuery.value.isNotEmpty;
              final isGaushalaFiltered = controller.selectedGaushalaFilter.value != null;

              return Padding(
                padding: const EdgeInsets.all(60.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(PhosphorIconsRegular.warehouse, size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSearching
                          ? 'No sheds match "${controller.searchQuery.value}"'
                          : (isGaushalaFiltered
                              ? 'No sheds found for selected gaushala'
                              : 'No sheds registered in system'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (isSearching || isGaushalaFiltered)
                          ? 'Try clearing the filter or changing your search criteria.'
                          : 'Click below to register a new cattle housing shed.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 18),
                    if (isSearching || isGaushalaFiltered)
                      CustomButton(
                        text: 'Clear Filters',
                        icon: Icons.filter_alt_off_rounded,
                        variant: ButtonVariant.outlined,
                        width: 150,
                        height: 40,
                        onPressed: controller.clearFilters,
                      )
                    else
                      CustomButton(
                        text: 'Add First Shed',
                        icon: Icons.add_rounded,
                        width: 170,
                        height: 40,
                        onPressed: () => controller.openAddShedDialog(context),
                      ),
                  ],
                ),
              );
            }

            return Column(
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
                      SizedBox(width: 56.5, child: _buildTableHeaderCell('#')),
                      Expanded(flex: 5, child: _buildTableHeaderCell('SHED NAME')),
                      Expanded(flex: 3, child: _buildTableHeaderCell('SHED NUMBER')),
                      Expanded(flex: 4, child: _buildTableHeaderCell('GAUSHALA')),
                      Expanded(flex: 5, child: _buildTableHeaderCell('SYSTEM ID')),
                      Expanded(flex: 4, child: _buildTableHeaderCell('CREATED AT')),
                    ],
                  ),
                ),
                // Table Data Rows
                ...controller.paginatedSheds.asMap().entries.map((entry) {
                  final pageStartIndex = (controller.currentPage.value - 1) * controller.rowsPerPage.value;
                  final index = pageStartIndex + entry.key;
                  final shed = entry.value;
                  return _HoverableShedTableRow(
                    key: ValueKey(shed.id),
                    index: index,
                    shed: shed,
                    isDark: isDark,
                  );
                }),
                const Divider(height: 1),
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

  Widget _buildTableHeaderCell(String title, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        width: isExpanded ? double.infinity : 250,
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
          dropdownBuilder: (context, selectedItem) {
            final displayText = (selectedItem != null && selectedItem.isNotEmpty)
                ? selectedItem
                : 'All Gaushalas';
            return Text(
              displayText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isFiltered ? FontWeight.w600 : FontWeight.w500,
                color: isFiltered
                    ? AppColors.primary
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            );
          },
          suffixProps: DropdownSuffixProps(
            clearButtonProps: ClearButtonProps(
              isVisible: isFiltered,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              icon: Icon(
                Icons.close_rounded,
                size: 15,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            dropdownButtonProps: DropdownButtonProps(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              iconClosed: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: isFiltered ? AppColors.primary : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
            ),
          ),
          decoratorProps: DropDownDecoratorProps(
            baseStyle: TextStyle(
              fontSize: 13,
              fontWeight: isFiltered ? FontWeight.w600 : FontWeight.w500,
              color: isFiltered
                  ? AppColors.primary
                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9.5),
              filled: true,
              fillColor: isFiltered
                  ? AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08)
                  : (isDark ? AppColors.surfaceDark : Theme.of(context).cardColor),
              prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 8, right: 6),
                child: Icon(
                  Icons.filter_alt_outlined,
                  size: 16,
                  color: isFiltered
                      ? AppColors.primary
                      : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isFiltered
                      ? AppColors.primary
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  width: isFiltered ? 1.4 : 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isFiltered
                      ? AppColors.primary
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  width: isFiltered ? 1.4 : 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          popupProps: PopupProps.menu(
            showSearchBox: items.length > 5,
            fit: FlexFit.loose,
            constraints: const BoxConstraints(maxHeight: 280),
            menuProps: MenuProps(
              backgroundColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            searchFieldProps: TextFieldProps(
              autofocus: true,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: 'Search gaushala...',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
                prefixIcon: Icon(
                  PhosphorIconsRegular.magnifyingGlass,
                  size: 15,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            itemBuilder: (context, item, isDisabled, isSelected) {
              final bool isAllOption = item == 'All Gaushalas';
              final bool isCurrentSelected = (isAllOption && !isFiltered) ||
                  (!isAllOption && selectedName == item);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: isCurrentSelected
                    ? AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08)
                    : Colors.transparent,
                child: Row(
                  children: [
                    Icon(
                      isAllOption ? PhosphorIconsRegular.circlesFour : PhosphorIconsRegular.barn,
                      size: 16,
                      color: isCurrentSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrentSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isCurrentSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                    ),
                    if (isCurrentSelected)
                      const Icon(
                        PhosphorIconsRegular.check,
                        size: 16,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    });
  }

  // -------------------------------------------------------------
  // MOBILE / TABLET VIEWS
  // -------------------------------------------------------------
  Widget _buildSearchBox(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        TextField(
          onChanged: (val) => controller.searchQuery.value = val,
          decoration: InputDecoration(
            hintText: 'Search sheds...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: Obx(
              () => controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => controller.searchQuery.value = '',
                    )
                  : const SizedBox.shrink(),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildGaushalaFilterDropdown(context, isDark, isExpanded: true),
      ],
    );
  }

  Widget _buildShedList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      if (controller.isLoading.value) {
        return const CustomListShimmer(itemCount: 6);
      }

      final list = controller.filteredSheds;
      if (list.isEmpty) {
        final isSearching = controller.searchQuery.value.isNotEmpty;
        final isGaushalaFiltered = controller.selectedGaushalaFilter.value != null;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              children: [
                Text(
                  isSearching
                      ? 'No sheds match "${controller.searchQuery.value}"'
                      : (isGaushalaFiltered
                          ? 'No sheds found for selected gaushala.'
                          : 'No sheds found.'),
                  style: const TextStyle(color: AppColors.textSecondaryLight),
                ),
                if (isSearching || isGaushalaFiltered) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                    label: const Text('Clear Filters'),
                    onPressed: controller.clearFilters,
                  ),
                ],
              ],
            ),
          ),
        );
      }

      final paginatedList = controller.paginatedSheds;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: paginatedList.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final ShedModel shed = paginatedList[index];
              String gaushalaName = shed.gaushalaName ?? '';
              if (gaushalaName.isEmpty && shed.gaushalaId != null && shed.gaushalaId!.isNotEmpty) {
                final match = controller.gaushalas.firstWhereOrNull((g) => g.id == shed.gaushalaId);
                if (match != null) {
                  gaushalaName = match.gaushalaName;
                }
              }

              return _HoverableListCard(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: const Icon(PhosphorIconsRegular.warehouse, color: AppColors.primary, size: 20),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          shed.shedName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          shed.shedNumber,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (gaushalaName.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.storefront_outlined, size: 13, color: AppColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              gaushalaName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${shed.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                      Text(
                        'Created: ${formatDate(shed.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    onSelected: (val) {
                      if (val == 'edit') {
                        controller.openEditShedDialog(context, shed);
                      } else if (val == 'delete') {
                        controller.confirmDeleteShed(context, shed);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: AppColors.info),
                            SizedBox(width: 8),
                            Text('Edit Shed'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Delete Shed'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPagination(
                totalItems: list.length,
                currentPage: controller.currentPage.value,
                rowsPerPage: controller.rowsPerPage.value,
                onPageChanged: controller.setPage,
                onRowsPerPageChanged: controller.setRowsPerPage,
              ),
            ),
          ),
        ],
      );
    });
  }
}

// -------------------------------------------------------------
// HOVERABLE SHED TABLE ROW (DESKTOP)
// -------------------------------------------------------------
class _HoverableShedTableRow extends StatefulWidget {
  final int index;
  final ShedModel shed;
  final bool isDark;

  const _HoverableShedTableRow({
    super.key,
    required this.index,
    required this.shed,
    required this.isDark,
  });

  @override
  State<_HoverableShedTableRow> createState() => _HoverableShedTableRowState();
}

class _HoverableShedTableRowState extends State<_HoverableShedTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final shed = widget.shed;
    final isDark = widget.isDark;
    final controller = Get.find<ShedController>();

    String gaushalaName = shed.gaushalaName ?? '';
    if (gaushalaName.isEmpty && shed.gaushalaId != null && shed.gaushalaId!.isNotEmpty) {
      final match = controller.gaushalas.firstWhereOrNull((g) => g.id == shed.gaushalaId);
      if (match != null) {
        gaushalaName = match.gaushalaName;
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
              width: 56.5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

            // Shed Name Badge
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: _isHovered ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: _isHovered ? 0.50 : 0.30),
                          width: _isHovered ? 1.2 : 1.0,
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
                          const Icon(
                            PhosphorIconsRegular.warehouse,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            shed.shedName,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Shed Number
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: _isHovered ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.blueGrey.withValues(alpha: _isHovered ? 0.50 : 0.30),
                        ),
                      ),
                      child: Text(
                        shed.shedNumber,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Gaushala Name
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: gaushalaName.isNotEmpty
                    ? Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: _isHovered ? 0.20 : 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.secondary.withValues(alpha: _isHovered ? 0.45 : 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.storefront_outlined,
                                    size: 13,
                                    color: AppColors.secondary,
                                  ),
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

            // System ID (with copy feedback)
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Flexible(
                      child: Tooltip(
                        message: 'Click to copy ID',
                        waitDuration: const Duration(milliseconds: 350),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          mouseCursor: SystemMouseCursors.click,
                          hoverColor: AppColors.primary.withValues(alpha: 0.08),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: shed.id));
                            CustomSnackbar.showInfo(
                              title: 'Copied',
                              message: 'Shed ID copied to clipboard',
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    shed.id,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: _isHovered
                                          ? (isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimaryLight)
                                          : AppColors.textSecondaryLight,
                                      fontWeight: _isHovered ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                AnimatedOpacity(
                                  opacity: _isHovered ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 160),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 6.0),
                                    child: Icon(
                                      Icons.copy_rounded,
                                      size: 13,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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

            // Created At
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Text(
                  formatDate(shed.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: _isHovered
                        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    fontWeight: _isHovered ? FontWeight.w500 : FontWeight.normal,
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

// -------------------------------------------------------------
// HELPERS
// -------------------------------------------------------------
String formatDate(DateTime? dt) {
  if (dt == null) return '-';
  final local = dt.toLocal();
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final month = months[local.month - 1];
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final ampm = local.hour >= 12 ? 'PM' : 'AM';
  final min = local.minute.toString().padLeft(2, '0');
  return '$month ${local.day}, ${local.year} $hour:$min $ampm';
}
