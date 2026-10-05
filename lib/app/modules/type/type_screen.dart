import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dropdown_search/dropdown_search.dart';
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
import '../../data/models/type_model.dart';
import '../../routes/app_routes.dart';
import '../dashboard/widgets/mobile_drawer.dart';
import '../dashboard/widgets/web_sidebar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'type_controller.dart';

/// Screen for Managing Cattle Types (Master > Types).
class TypeScreen extends GetView<TypeController> {
  const TypeScreen({super.key});

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
                            _buildTypesTableCard(context),
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
        title: const Text('Types Master'),
        actions: [
          const NotificationBellWidget(),
          Obx(() {
            final isBusy = controller.isRefreshing.value || controller.isLoading.value;
            return IconButton(
              icon: isBusy
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh Types',
              onPressed: isBusy ? null : controller.refreshTypes,
            );
          }),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => controller.openAddTypeDialog(context),
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
            _buildTypeList(context),
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
        title: const Text('Types Master'),
        actions: [
          const NotificationBellWidget(),
          Obx(() {
            final isBusy = controller.isRefreshing.value || controller.isLoading.value;
            return IconButton(
              icon: isBusy
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh Types',
              onPressed: isBusy ? null : controller.refreshTypes,
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Type', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => controller.openAddTypeDialog(context),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshTypes,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSearchBox(context),
              const SizedBox(height: 16),
              _buildTypeList(context),
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
                'Cattle Types & Classifications',
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
                  tooltip: isBusy ? 'Refreshing...' : 'Refresh Types',
                  onPressed: isBusy ? null : controller.refreshTypes,
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
                  'Types',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Cattle Types Master',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage cattle life-stage and milk production classifications (e.g. Milking, Dry, Pregnant, Calf).',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
        Row(
          children: [
            CustomButton(
              text: 'Add Type',
              icon: Icons.add_rounded,
              width: 140,
              height: 44,
              onPressed: () => controller.openAddTypeDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TYPES TABLE CARD (DESKTOP)
  // -------------------------------------------------------------
  Widget _buildTypesTableCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter & Header Bar
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'All Registered Types',
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
                          '${controller.filteredTypes.length} total',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Obx(() {
                      if (controller.isLoading.value && controller.types.isNotEmpty) {
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
                      width: 260,
                      height: 38,
                      child: TextField(
                        onChanged: (val) => controller.searchQuery.value = val,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search type name or ID...',
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          suffixIcon: Obx(
                            () => controller.searchQuery.value.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16),
                                    onPressed: () => controller.searchQuery.value = '',
                                  )
                                : const SizedBox.shrink(),
                          ),
                          filled: true,
                          fillColor: isDark ? AppColors.cardDark : AppColors.backgroundLight,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
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
          const Divider(height: 1, thickness: 1),

          // Table Content
          Obx(() {
            if (controller.isLoading.value) {
              return const CustomTableShimmer(
                rowCount: 6,
                columnFlexes: [5, 4, 5, 4],
                headers: ['#', 'TYPE NAME', 'GAUSHALA', 'SYSTEM ID', 'CREATED AT'],
              );
            }

            final list = controller.filteredTypes;

            if (list.isEmpty) {
              final isSearching = controller.searchQuery.value.isNotEmpty;

              return Padding(
                padding: const EdgeInsets.all(60.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.label_off_rounded,
                        size: 48,
                        color: AppColors.textSecondaryLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isSearching
                            ? 'No types matching "${controller.searchQuery.value}"'
                            : 'No types registered for ${controller.selectedGaushalaName}.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isSearching)
                        CustomButton(
                          text: 'Clear Search',
                          icon: Icons.clear_rounded,
                          variant: ButtonVariant.outlined,
                          width: 150,
                          height: 40,
                          onPressed: controller.clearFilters,
                        )
                      else
                        CustomButton(
                          text: 'Add First Type',
                          icon: Icons.add_rounded,
                          width: 160,
                          height: 38,
                          onPressed: () => controller.openAddTypeDialog(context),
                        ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                // Table Header
                Container(
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
                      Expanded(flex: 5, child: _buildTableHeaderCell('TYPE NAME')),
                      Expanded(flex: 4, child: _buildTableHeaderCell('GAUSHALA')),
                      Expanded(flex: 5, child: _buildTableHeaderCell('SYSTEM ID')),
                      Expanded(flex: 4, child: _buildTableHeaderCell('CREATED AT')),
                    ],
                  ),
                ),
                // Table Data Rows
                ...controller.paginatedTypes.asMap().entries.map((entry) {
                  final pageStartIndex = (controller.currentPage.value - 1) * controller.rowsPerPage.value;
                  final index = pageStartIndex + entry.key;
                  final type = entry.value;
                  return _HoverableTypeTableRow(
                    key: ValueKey(type.id),
                    index: index,
                    type: type,
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

  Widget _buildGaushalaFilterDropdown(BuildContext context, bool isDark, {bool isExpanded = false}) {
    return Obx(() {
      final list = controller.gaushalas.toList();
      final canChange = controller.canChangeGaushala;
      final selectedName = controller.selectedGaushalaName;

      // If user is Non-Admin, render fixed station chip
      if (!canChange) {
        return Tooltip(
          message: 'Assigned Gaushala: $selectedName (Fixed to your account)',
          child: Container(
            width: isExpanded ? double.infinity : 240,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  PhosphorIconsRegular.lockSimple,
                  size: 13,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ],
            ),
          ),
        );
      }

      final items = list.map((g) => g.gaushalaName).toList();

      return SizedBox(
        width: isExpanded ? double.infinity : 240,
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
            if (selected != null) {
              final match = controller.findGaushala(selected);
              if (match != null) {
                controller.setGaushalaFilter(match.id);
              }
            }
          },
          dropdownBuilder: (context, selectedItem) {
            return Text(
              selectedItem ?? 'Select Gaushala',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            );
          },
          suffixProps: DropdownSuffixProps(
            dropdownButtonProps: DropdownButtonProps(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
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
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : Theme.of(context).cardColor,
              prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 8, right: 6),
                child: Icon(
                  Icons.storefront_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1.0,
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
              final bool isCurrentSelected = selectedName == item;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: isCurrentSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                child: Row(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 16,
                      color: isCurrentSelected ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrentSelected ? FontWeight.bold : FontWeight.normal,
                          color: isCurrentSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                    ),
                    if (isCurrentSelected)
                      const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                  ],
                ),
              );
            },
          ),
        ),
      );
    });
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

  // -------------------------------------------------------------
  // MOBILE / TABLET VIEWS
  // -------------------------------------------------------------
  Widget _buildSearchBox(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        _buildGaushalaFilterDropdown(context, isDark, isExpanded: true),
        const SizedBox(height: 12),
        TextField(
          onChanged: (val) => controller.searchQuery.value = val,
          decoration: InputDecoration(
            hintText: 'Search types...',
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
      ],
    );
  }

  Widget _buildTypeList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoading.value) {
        return const CustomListShimmer(itemCount: 6);
      }

      final list = controller.filteredTypes;
      if (list.isEmpty) {
        final isSearching = controller.searchQuery.value.isNotEmpty;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSearching
                      ? 'No types match "${controller.searchQuery.value}"'
                      : 'No types registered for ${controller.selectedGaushalaName}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isSearching
                      ? 'Try different keywords'
                      : 'Tap "+ Add Type" above to create a new cattle type',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                if (isSearching) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    label: const Text('Clear Search'),
                    onPressed: controller.clearFilters,
                  ),
                ],
              ],
            ),
          ),
        );
      }

      final paginatedList = controller.paginatedTypes;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: paginatedList.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final TypeModel type = paginatedList[index];
              String gaushalaName = type.gaushalaName ?? '';
              if (gaushalaName.isEmpty && type.gaushalaId != null && type.gaushalaId!.isNotEmpty) {
                final match = controller.gaushalas.firstWhereOrNull((g) => g.id == type.gaushalaId);
                if (match != null) {
                  gaushalaName = match.gaushalaName;
                }
              }

              return _HoverableListCard(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: const Icon(PhosphorIconsRegular.tag, color: AppColors.primary, size: 20),
                  ),
                  title: Text(
                    type.typeName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                        'ID: ${type.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                      Text(
                        'Created: ${formatDate(type.createdAt)}',
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
                        controller.openEditTypeDialog(context, type);
                      } else if (val == 'delete') {
                        controller.confirmDeleteType(context, type);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: AppColors.info),
                            SizedBox(width: 8),
                            Text('Edit Type'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Delete Type'),
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
// HOVERABLE TYPE TABLE ROW (DESKTOP)
// -------------------------------------------------------------
class _HoverableTypeTableRow extends StatefulWidget {
  final int index;
  final TypeModel type;
  final bool isDark;

  const _HoverableTypeTableRow({
    super.key,
    required this.index,
    required this.type,
    required this.isDark,
  });

  @override
  State<_HoverableTypeTableRow> createState() => _HoverableTypeTableRowState();
}

class _HoverableTypeTableRowState extends State<_HoverableTypeTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    final isDark = widget.isDark;
    final controller = Get.find<TypeController>();

    String gaushalaName = type.gaushalaName ?? '';
    if (gaushalaName.isEmpty && type.gaushalaId != null && type.gaushalaId!.isNotEmpty) {
      final match = controller.gaushalas.firstWhereOrNull((g) => g.id == type.gaushalaId);
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

            // Type Name Badge
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
                            PhosphorIconsRegular.tag,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            type.typeName,
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

            // Gaushala Badge
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: gaushalaName.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.secondary.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.storefront_outlined, size: 13, color: AppColors.secondary),
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
                          hoverColor: AppColors.primary.withValues(alpha: 0.08),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: type.id));
                            CustomSnackbar.showInfo(
                              title: 'Copied',
                              message: 'Type ID copied to clipboard',
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    type.id,
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
                  formatDate(type.createdAt),
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
