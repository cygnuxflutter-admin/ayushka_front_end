import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/values/app_colors.dart';
import '../../core/values/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/widgets/custom_pagination.dart';
import '../../core/widgets/custom_shimmer.dart';
import '../../core/widgets/global_gaushala_selector.dart';
import '../../data/models/cow_model.dart';
import '../../routes/app_routes.dart';
import '../dashboard/widgets/mobile_drawer.dart';
import '../dashboard/widgets/web_sidebar.dart';
import 'cow_controller.dart';
import 'widgets/download_progress_banner.dart';

/// Screen for managing cattle records (Herd & Cattle list).
class CowScreen extends GetView<CowController> {
  const CowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBuilder: (context) => _buildMobileScaffold(context),
      tabletBuilder: (context) => _buildTabletScaffold(context),
      desktopBuilder: (context) => _buildDesktopScaffold(context),
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP SCAFFOLD
  // ---------------------------------------------------------------------------
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
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(28.0),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildBreadcrumbAndActionBar(context),
                                const SizedBox(height: 20),
                                _buildMetricCards(context),
                                const SizedBox(height: 24),
                                _buildCowsTableCard(context),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 28,
                        child: DownloadProgressBanner(controller: controller),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TABLET SCAFFOLD
  // ---------------------------------------------------------------------------
  Widget _buildTabletScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Herd & Cattle'),
        actions: [
          Obx(() {
            final isBusy = controller.isRefreshing.value || controller.isLoading.value;
            return IconButton(
              icon: isBusy
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh Herd',
              onPressed: isBusy ? null : controller.refreshCows,
            );
          }),
          Obx(() {
            final isDownloading = controller.isDownloadingTemplate.value;
            return IconButton(
              icon: isDownloading
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(PhosphorIconsRegular.fileArrowDown),
              tooltip: 'Download Template (.xlsx)',
              onPressed: isDownloading ? null : controller.downloadTemplate,
            );
          }),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.fileArrowUp),
            tooltip: 'Import Excel (.xlsx)',
            onPressed: () => controller.pickAndUploadExcel(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Register Cow',
            onPressed: controller.goToAddCow,
          ),
        ],
      ),
      drawer: Obx(
        () => MobileDrawer(
          currentUser: controller.currentUser.value,
          onLogout: controller.logout,
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildMetricCards(context, isCompact: true),
                const SizedBox(height: 16),
                _buildSearchAndFiltersMobile(context),
                const SizedBox(height: 16),
                _buildCowsListCards(context),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 16,
            left: 16,
            child: Center(
              child: DownloadProgressBanner(controller: controller),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE SCAFFOLD
  // ---------------------------------------------------------------------------
  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Herd & Cattle'),
        actions: [
          Obx(() {
            final isBusy = controller.isRefreshing.value || controller.isLoading.value;
            return IconButton(
              icon: isBusy
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh',
              onPressed: isBusy ? null : controller.refreshCows,
            );
          }),
          Obx(() {
            final isDownloading = controller.isDownloadingTemplate.value;
            return IconButton(
              icon: isDownloading
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(PhosphorIconsRegular.fileArrowDown),
              tooltip: 'Download Template (.xlsx)',
              onPressed: isDownloading ? null : controller.downloadTemplate,
            );
          }),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.fileArrowUp),
            tooltip: 'Import Excel (.xlsx)',
            onPressed: () => controller.pickAndUploadExcel(context),
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
        label: const Text('Register Cow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: controller.goToAddCow,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: controller.refreshCows,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildMetricCards(context, isCompact: true),
                  const SizedBox(height: 14),
                  _buildSearchAndFiltersMobile(context),
                  const SizedBox(height: 16),
                  _buildCowsListCards(context),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 12,
            left: 12,
            child: Center(
              child: DownloadProgressBanner(controller: controller),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP TOP HEADER
  // ---------------------------------------------------------------------------
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
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                  'LIVESTOCK',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Flexible(
                child: Text(
                  'Herd & Cattle Management Station',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
              // Global Gaushala Selector in top header bar (Admin can switch; User sees assigned)
              const GlobalGaushalaSelector(),
              const SizedBox(width: 12),
              Obx(() {
                final isBusy = controller.isRefreshing.value || controller.isLoading.value;
                return IconButton(
                  icon: isBusy
                      ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                      : const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: isBusy ? 'Refreshing...' : 'Refresh Herd',
                  onPressed: isBusy ? null : controller.refreshCows,
                );
              }),
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
                          user?.name.isNotEmpty == true
                              ? user!.name.substring(0, 1).toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user?.name ?? 'Admin',
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

  // ---------------------------------------------------------------------------
  // BREADCRUMB & ACTION BAR
  // ---------------------------------------------------------------------------
  Widget _buildBreadcrumbAndActionBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isStackNeeded = constraints.maxWidth < 990;

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                  'Herd & Cattle',
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
              'Herd & Cattle Registry',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Centralized cattle inventory, lineage, lactation stage & shed allocations.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
            ),
          ],
        );

        final actionButtons = Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Obx(() {
              final isDownloading = controller.isDownloadingTemplate.value;
              final progress = controller.downloadProgress.value;
              final pct = (progress * 100).toInt();
              return CustomButton(
                text: isDownloading ? 'Downloading ($pct%)' : 'Download Template',
                icon: isDownloading ? null : PhosphorIconsRegular.fileArrowDown,
                isLoading: isDownloading,
                variant: ButtonVariant.outlined,
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                onPressed: isDownloading ? null : controller.downloadTemplate,
              );
            }),
            CustomButton(
              text: 'Import Excel',
              icon: PhosphorIconsRegular.fileArrowUp,
              variant: ButtonVariant.outlined,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onPressed: () => controller.pickAndUploadExcel(context),
            ),
            CustomButton(
              text: 'Register New Cow',
              icon: Icons.add_rounded,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: controller.goToAddCow,
            ),
          ],
        );

        if (isStackNeeded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              const SizedBox(height: 16),
              actionButtons,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: titleSection),
            const SizedBox(width: 16),
            actionButtons,
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SUMMARY METRICS CARDS
  // ---------------------------------------------------------------------------
  Widget _buildMetricCards(BuildContext context, {bool isCompact = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final counts = controller.counts.value;
      final totalCattle = counts.total > 0 ? counts.total : controller.cows.length;
      final femaleCattle = counts.female > 0 ? counts.female : controller.cows.where((c) => c.isFemale).length;
      final maleCattle = counts.male > 0 ? counts.male : controller.cows.where((c) => !c.isFemale).length;

      final selectedGaushalaName = controller.activeGaushalaName;

      if (isCompact) {
        return Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                context,
                title: 'Total Herd',
                value: '$totalCattle',
                icon: PhosphorIconsRegular.cow,
                color: AppColors.primary,
                isDark: isDark,
                isCompact: true,
                onTap: () => controller.selectedGenderFilter.value = 'all',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                context,
                title: 'Female (Cows)',
                value: '$femaleCattle',
                icon: PhosphorIconsRegular.genderFemale,
                color: const Color(0xFF2E7D32),
                isDark: isDark,
                isCompact: true,
                onTap: () => controller.selectedGenderFilter.value = 'female',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                context,
                title: 'Male (Bulls)',
                value: '$maleCattle',
                icon: PhosphorIconsRegular.genderMale,
                color: Colors.blue.shade700,
                isDark: isDark,
                isCompact: true,
                onTap: () => controller.selectedGenderFilter.value = 'male',
              ),
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
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: 'Total Cattle',
                        value: '$totalCattle',
                        subtitle: 'Active Registered Herd',
                        icon: PhosphorIconsRegular.cow,
                        color: AppColors.primary,
                        isDark: isDark,
                        onTap: () => controller.selectedGenderFilter.value = 'all',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: 'Female (Cows)',
                        value: '$femaleCattle',
                        subtitle: 'Milking / Dry / Heifers',
                        icon: PhosphorIconsRegular.genderFemale,
                        color: const Color(0xFF2E7D32),
                        isDark: isDark,
                        onTap: () => controller.selectedGenderFilter.value = 'female',
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
                        title: 'Male (Bulls)',
                        value: '$maleCattle',
                        subtitle: 'Bulls / Sires / Calves',
                        icon: PhosphorIconsRegular.genderMale,
                        color: Colors.blue.shade700,
                        isDark: isDark,
                        onTap: () => controller.selectedGenderFilter.value = 'male',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: 'Active Gaushala',
                        value: selectedGaushalaName,
                        subtitle: 'Selected Station',
                        icon: PhosphorIconsRegular.buildings,
                        color: const Color(0xFFD97706),
                        isDark: isDark,
                        isValueTextSmall: true,
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
                  title: 'Total Cattle',
                  value: '$totalCattle',
                  subtitle: 'Active Registered Herd',
                  icon: PhosphorIconsRegular.cow,
                  color: AppColors.primary,
                  isDark: isDark,
                  onTap: () => controller.selectedGenderFilter.value = 'all',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Female (Cows)',
                  value: '$femaleCattle',
                  subtitle: 'Milking / Dry / Heifers',
                  icon: PhosphorIconsRegular.genderFemale,
                  color: const Color(0xFF2E7D32),
                  isDark: isDark,
                  onTap: () => controller.selectedGenderFilter.value = 'female',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Male (Bulls)',
                  value: '$maleCattle',
                  subtitle: 'Bulls / Sires / Calves',
                  icon: PhosphorIconsRegular.genderMale,
                  color: Colors.blue.shade700,
                  isDark: isDark,
                  onTap: () => controller.selectedGenderFilter.value = 'male',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Active Gaushala',
                  value: selectedGaushalaName,
                  subtitle: 'Selected Station',
                  icon: PhosphorIconsRegular.buildings,
                  color: const Color(0xFFD97706),
                  isDark: isDark,
                  isValueTextSmall: true,
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
      isValueTextSmall: isValueTextSmall,
      isCompact: isCompact,
      onTap: onTap,
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP COWS TABLE CARD
  // ---------------------------------------------------------------------------
  Widget _buildCowsTableCard(BuildContext context) {
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
                    const Icon(PhosphorIconsRegular.cow, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Cattle Records',
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
                          '${controller.filteredCows.length} Listed',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    Obx(() {
                      if (controller.isLoading.value && controller.cows.isNotEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: CustomInlineLoader(size: 14, strokeWidth: 1.8),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Gaushala Filter Dropdown
                    _buildGaushalaFilterDropdown(context, isDark),
                    const SizedBox(width: 12),
                    // Gender Filter Tabs
                    _buildGenderFilterTabs(context, isDark),
                    const SizedBox(width: 12),
                    // Search box
                    SizedBox(
                      width: 240,
                      child: TextField(
                        onChanged: (val) => controller.searchQuery.value = val,
                        decoration: InputDecoration(
                          hintText: 'Search Tag ID, breed, shed...',
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
                columnFlexes: [4, 3, 3, 4, 3, 4, 3, 3, 2],
                headers: ['#', 'TAG ID', 'ALIAS', 'GENDER', 'BREED', 'TYPE', 'GAUSHALA', 'SHED & NO.', 'STATUS', 'ACTIONS'],
              );
            }

            final list = controller.filteredCows;
            if (list.isEmpty) {
              final isSearching = controller.searchQuery.value.isNotEmpty;
              final isGenderFiltered = controller.selectedGenderFilter.value != 'all';
              final isGaushalaFiltered = controller.selectedGaushalaId.value != null &&
                  controller.selectedGaushalaId.value != controller.globalGaushalaId;
              final hasActiveFilter = isSearching || isGenderFiltered || isGaushalaFiltered;

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
                      child: const Icon(PhosphorIconsRegular.cow, size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSearching
                          ? 'No cattle match "${controller.searchQuery.value}"'
                          : (isGenderFiltered
                              ? 'No cattle found for ${controller.selectedGenderFilter.value} filter'
                              : 'No cattle registered in this gaushala'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasActiveFilter
                          ? 'Try clearing the filters or modifying your search keyword.'
                          : 'Click below to register the first cow into the system.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 18),
                    if (hasActiveFilter)
                      CustomButton(
                        text: 'Clear Filters',
                        icon: Icons.filter_alt_off_rounded,
                        variant: ButtonVariant.outlined,
                        width: 160,
                        height: 40,
                        onPressed: controller.clearFilters,
                      )
                    else
                      CustomButton(
                        text: 'Register First Cow',
                        icon: Icons.add_rounded,
                        width: 200,
                        height: 40,
                        onPressed: controller.goToAddCow,
                      ),
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                const double minTableWidth = 1100.0;
                final double tableWidth = constraints.maxWidth < minTableWidth
                    ? minTableWidth
                    : constraints.maxWidth;

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
                                  SizedBox(width: 50, child: _buildTableHeaderCell('#')),
                                  Expanded(flex: 4, child: _buildTableHeaderCell('TAG ID')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('ALIAS')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('GENDER')),
                                  Expanded(flex: 4, child: _buildTableHeaderCell('BREED')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('TYPE')),
                                  Expanded(flex: 4, child: _buildTableHeaderCell('GAUSHALA')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('SHED & NO.')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('STATUS')),
                                  SizedBox(width: 125, child: _buildTableHeaderCell('ACTIONS', alignRight: true)),
                                ],
                              ),
                            ),
                            // Table Data Rows
                            ...controller.paginatedCows.asMap().entries.map((entry) {
                              final pageStartIndex = (controller.currentPage.value - 1) * controller.rowsPerPage.value;
                              final index = pageStartIndex + entry.key;
                              final cow = entry.value;
                              return _HoverableCowTableRow(
                                key: ValueKey('${cow.id}_${cow.isActive}_${cow.sendDiedDate}_${cow.isDeleted}_${cow.isDied}'),
                                index: index,
                                cow: cow,
                                isDark: isDark,
                                isUpdatingStatus: controller.updatingStatusCowIds.contains(cow.id),
                                isUpdatingDied: controller.updatingDiedCowIds.contains(cow.id),
                                onView: () => controller.openCowDetailsDialog(context, cow),
                                onEdit: () => controller.goToEditCow(cow),
                                onToggleStatus: () => controller.toggleCowStatus(cow),
                                onMarkDied: () => controller.showMarkDiedDialog(context, cow),
                                onDelete: () => controller.confirmDeleteCow(context, cow),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
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
          letterSpacing: 0.6,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }


  // ---------------------------------------------------------------------------
  // GAUSHALA FILTER DROPDOWN
  // ---------------------------------------------------------------------------
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
                  Icons.location_on_outlined,
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
                controller.setGaushala(match.id);
              }
            }
          },
          popupProps: PopupProps.menu(
            showSearchBox: items.length > 5,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search gaushala...',
                prefixIcon: const Icon(Icons.search_rounded, size: 16),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
            ),
            menuProps: MenuProps(
              borderRadius: BorderRadius.circular(12),
              backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
              elevation: 8,
            ),
            itemBuilder: (ctx, item, isDisabled, isSelected) {
              final isCurrent = item == selectedName;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: isCurrent
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: isCurrent ? AppColors.primary : (isDark ? Colors.white70 : Colors.black54),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent
                              ? AppColors.primary
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                    ),
                    if (isCurrent)
                      const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                  ],
                ),
              );
            },
          ),
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
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // GENDER FILTER TABS
  // ---------------------------------------------------------------------------
  Widget _buildGenderFilterTabs(BuildContext context, bool isDark) {
    return Obx(() {
      final selected = controller.selectedGenderFilter.value;

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
            _buildGenderTabItem(
              label: 'All',
              isActive: selected == 'all',
              isDark: isDark,
              onTap: () => controller.setGenderFilter('all'),
            ),
            _buildGenderTabItem(
              label: '♀ Female',
              isActive: selected == 'female',
              isDark: isDark,
              onTap: () => controller.setGenderFilter('female'),
            ),
            _buildGenderTabItem(
              label: '♂ Male',
              isActive: selected == 'male',
              isDark: isDark,
              onTap: () => controller.setGenderFilter('male'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildGenderTabItem({
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? (isDark ? Colors.white : AppColors.primary)
                  : (isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE SEARCH & FILTERS
  // ---------------------------------------------------------------------------
  Widget _buildSearchAndFiltersMobile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _buildGaushalaFilterDropdown(context, isDark, isExpanded: true),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (val) => controller.searchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'Search Tag ID, breed...',
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
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildGenderFilterTabs(context, isDark),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE & TABLET CARDS LIST
  // ---------------------------------------------------------------------------
  Widget _buildCowsListCards(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoading.value) {
        return const CustomListShimmer(itemCount: 6);
      }

      final list = controller.paginatedCows;
      if (controller.filteredCows.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              const Icon(PhosphorIconsRegular.cow, size: 40, color: AppColors.textMutedLight),
              const SizedBox(height: 12),
              const Text('No cattle records found.', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Try changing your filters or add a new cow.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
            ],
          ),
        );
      }

      return Column(
        children: [
          ...list.map((cow) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            cow.tagId,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (cow.calfName?.isNotEmpty == true) ...[
                          const SizedBox(width: 8),
                          Text(
                            cow.calfName!,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildCowStatusBadge(
                          context: context,
                          cow: cow,
                          isDark: isDark,
                          isUpdatingStatus: controller.updatingStatusCowIds.contains(cow.id),
                          isUpdatingDied: controller.updatingDiedCowIds.contains(cow.id),
                          onToggleStatus: () => controller.toggleCowStatus(cow),
                          onMarkDied: () => controller.showMarkDiedDialog(context, cow),
                          isMobile: true,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cow.isFemale
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            cow.isFemale ? '♀ Female' : '♂ Male',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: cow.isFemale ? AppColors.primary : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Breed', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                          Text(cow.breed?.breedName ?? 'Unspecified', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Type', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                          Text(cow.cowType?.typeName ?? 'Unspecified', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Shed', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                          Text(
                            cow.shed != null ? '${cow.shed!.shedName} (${cow.shed!.shedNumber})' : 'Unassigned',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cow.gaushala?.gaushalaName ?? '',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(PhosphorIconsRegular.eye, size: 18),
                          tooltip: 'View Details',
                          onPressed: () => controller.openCowDetailsDialog(context, cow),
                        ),
                        if (cow.canEdit)
                          IconButton(
                            icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 18),
                            tooltip: 'Edit Cattle',
                            onPressed: () => controller.goToEditCow(cow),
                          ),
                        Theme(
                          data: Theme.of(context).copyWith(
                            cardColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                          ),
                          child: PopupMenuButton<String>(
                            tooltip: 'More options',
                            icon: const Icon(PhosphorIconsRegular.dotsThreeVertical, size: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              ),
                            ),
                            color: isDark ? AppColors.cardDark : AppColors.cardLight,
                            elevation: 6,
                            onSelected: (val) {
                              if (val == 'status') {
                                controller.toggleCowStatus(cow);
                              } else if (val == 'died') {
                                controller.showMarkDiedDialog(context, cow);
                              } else if (val == 'delete') {
                                controller.confirmDeleteCow(context, cow);
                              }
                            },
                            itemBuilder: (ctx) => [
                              if (!cow.isDeleted && !cow.isDelete && !cow.isDead && !cow.isDied)
                                PopupMenuItem(
                                  value: 'status',
                                  height: 38,
                                  child: Row(
                                    children: [
                                      Icon(
                                        cow.isActive
                                            ? Icons.power_settings_new_rounded
                                            : Icons.check_circle_outline_rounded,
                                        size: 16,
                                        color: cow.isActive ? Colors.orange : AppColors.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        cow.isActive ? 'Set InActive' : 'Set Active',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              if (!cow.isDeleted && !cow.isDelete)
                                PopupMenuItem(
                                  value: 'died',
                                  height: 38,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.heart_broken_rounded,
                                        size: 16,
                                        color: Colors.red.shade700,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        (cow.isDead || cow.isDied) ? 'Update Death Date' : 'Mark as Died',
                                        style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                              if (!cow.isDeleted && !cow.isDelete) ...[
                                const PopupMenuDivider(height: 1),
                                const PopupMenuItem(
                                  value: 'delete',
                                  height: 38,
                                  child: Row(
                                    children: [
                                      Icon(
                                        PhosphorIconsRegular.trash,
                                        size: 16,
                                        color: AppColors.error,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Delete Record',
                                        style: TextStyle(fontSize: 13, color: AppColors.error),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            );
          }),
          const SizedBox(height: 8),
          CustomPagination(
            totalItems: controller.filteredCows.length,
            currentPage: controller.currentPage.value,
            rowsPerPage: controller.rowsPerPage.value,
            onPageChanged: (page) => controller.currentPage.value = page,
            onRowsPerPageChanged: (rows) {
              controller.rowsPerPage.value = rows;
              controller.currentPage.value = 1;
            },
          ),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// COW STATUS BADGE (HIERARCHY: DELETED -> DIED -> INACTIVE -> ACTIVE)
// ---------------------------------------------------------------------------
Widget _buildCowStatusBadge({
  required BuildContext context,
  required CowModel cow,
  required bool isDark,
  required bool isUpdatingStatus,
  required bool isUpdatingDied,
  required VoidCallback onToggleStatus,
  required VoidCallback onMarkDied,
  bool isMobile = false,
}) {
  // Hierarchy check:
  // 1. Delete -> "Deleted"
  // 2. Died -> "Died"
  // 3. InActive -> "InActive"
  // 4. Active -> "Active"

  // 1. First check: Is cattle deleted?
  if (cow.isDeleted || cow.isDelete) {
    return Tooltip(
      message: 'Deleted Cattle Record',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 7 : 8,
          vertical: isMobile ? 2.5 : 3.5,
        ),
        decoration: BoxDecoration(
          color: isDark ? Colors.red.withValues(alpha: 0.15) : AppColors.errorBg,
          borderRadius: BorderRadius.circular(isMobile ? 10 : 16),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsRegular.trash,
              size: isMobile ? 11 : 12,
              color: AppColors.error,
            ),
            SizedBox(width: isMobile ? 3 : 5),
            Text(
              'Deleted',
              style: TextStyle(
                fontSize: isMobile ? 10.5 : 11,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Second check: If not deleted, is cattle died?
  if (cow.isDied || cow.isDead) {
    final dateStr = cow.sendDiedDate?.isNotEmpty == true ? ' on ${cow.sendDiedDate}' : '';
    return Tooltip(
      message: 'Died$dateStr (Click to edit)',
      child: InkWell(
        borderRadius: BorderRadius.circular(isMobile ? 10 : 16),
        mouseCursor: SystemMouseCursors.click,
        onTap: isUpdatingDied ? null : onMarkDied,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 7 : 8,
            vertical: isMobile ? 2.5 : 3.5,
          ),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(isMobile ? 10 : 16),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.heart_broken_rounded,
                size: isMobile ? 11 : 12,
                color: Colors.red.shade700,
              ),
              SizedBox(width: isMobile ? 3 : 5),
              Text(
                'Died',
                style: TextStyle(
                  fontSize: isMobile ? 10.5 : 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Third check: If not died, is cattle active or inactive?
  final bool isActive = cow.isActive;
  return Tooltip(
    message: isActive ? 'Active (Click to Deactivate)' : 'InActive (Click to Activate)',
    child: InkWell(
      borderRadius: BorderRadius.circular(isMobile ? 10 : 16),
      mouseCursor: SystemMouseCursors.click,
      onTap: isUpdatingStatus ? null : onToggleStatus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 7 : 8,
          vertical: isMobile ? 2.5 : 3.5,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? Colors.white10 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(isMobile ? 10 : 16),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.35)
                : (isDark ? AppColors.borderDark : Colors.grey.shade400),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isUpdatingStatus)
              SizedBox(
                width: isMobile ? 9 : 10,
                height: isMobile ? 9 : 10,
                child: const CircularProgressIndicator(strokeWidth: 1.5),
              )
            else
              Container(
                width: isMobile ? 6 : 7,
                height: isMobile ? 6 : 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppColors.primary : Colors.grey.shade600,
                ),
              ),
            SizedBox(width: isMobile ? 4 : 5),
            Text(
              isActive ? 'Active' : 'InActive',
              style: TextStyle(
                fontSize: isMobile ? 10.5 : 11,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? AppColors.primary
                    : (isDark ? AppColors.textSecondaryDark : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// HOVERABLE TABLE ROW (DESKTOP)
// ---------------------------------------------------------------------------
class _HoverableCowTableRow extends StatefulWidget {
  final int index;
  final CowModel cow;
  final bool isDark;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onMarkDied;
  final VoidCallback onDelete;
  final bool isUpdatingStatus;
  final bool isUpdatingDied;

  const _HoverableCowTableRow({
    super.key,
    required this.index,
    required this.cow,
    required this.isDark,
    required this.onView,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onMarkDied,
    required this.onDelete,
    this.isUpdatingStatus = false,
    this.isUpdatingDied = false,
  });

  @override
  State<_HoverableCowTableRow> createState() => _HoverableCowTableRowState();
}

class _HoverableCowTableRowState extends State<_HoverableCowTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cow = widget.cow;
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

            // Tag ID
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
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
                            cow.tagId,
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
                  ),
                ),
              ),
            ),

            // Alias / Calf Name
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Text(
                  cow.calfName?.isNotEmpty == true ? cow.calfName! : '—',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                    fontStyle: cow.calfName?.isNotEmpty == true ? FontStyle.normal : FontStyle.italic,
                    color: cow.calfName?.isNotEmpty == true
                        ? (_isHovered
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight))
                        : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ),
              ),
            ),

            // Gender Badge
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: cow.isFemale
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: cow.isFemale
                              ? const Color(0xFFA5D6A7)
                              : const Color(0xFF90CAF9),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cow.isFemale
                                ? PhosphorIconsRegular.genderFemale
                                : PhosphorIconsRegular.genderMale,
                            size: 13,
                            color: cow.isFemale ? AppColors.primary : Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cow.isFemale ? 'Female' : 'Male',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: cow.isFemale ? AppColors.primary : Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Breed
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Row(
                  children: [
                    Flexible(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: _isHovered ? 0.18 : 0.10),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.teal.withValues(alpha: _isHovered ? 0.45 : 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(PhosphorIconsRegular.dna, size: 12, color: Colors.teal),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                cow.breed?.breedName ?? '—',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Cow Type
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Row(
                  children: [
                    Flexible(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withValues(alpha: _isHovered ? 0.20 : 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.blueGrey.withValues(alpha: _isHovered ? 0.50 : 0.30),
                          ),
                        ),
                        child: Text(
                          cow.cowType?.typeName ?? '—',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Gaushala
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Row(
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
                                cow.gaushala?.gaushalaName ?? '—',
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
                ),
              ),
            ),

            // Shed & Number
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: cow.shed != null
                    ? Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${cow.shed!.shedName} (${cow.shed!.shedNumber})',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                                color: _isHovered
                                    ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Unassigned',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      ),
              ),
            ),

            // Status: Hierarchy (Deleted -> Died -> InActive -> Active)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _buildCowStatusBadge(
                      context: context,
                      cow: cow,
                      isDark: isDark,
                      isUpdatingStatus: widget.isUpdatingStatus,
                      isUpdatingDied: widget.isUpdatingDied,
                      onToggleStatus: widget.onToggleStatus,
                      onMarkDied: widget.onMarkDied,
                      isMobile: false,
                    ),
                  ),
                ),
              ),
            ),

            // Actions (View, Edit, More 3-dots Menu)
            SizedBox(
              width: 125,
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
                        if (cow.canEdit) ...[
                          const SizedBox(width: 3),
                          Tooltip(
                            message: 'Edit Cattle',
                            waitDuration: const Duration(milliseconds: 300),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              mouseCursor: SystemMouseCursors.click,
                              hoverColor: AppColors.secondary.withValues(alpha: 0.12),
                              onTap: widget.onEdit,
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Icon(
                                  PhosphorIconsRegular.pencilSimple,
                                  size: 17,
                                  color: _isHovered
                                      ? AppColors.secondary
                                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 3),
                        Theme(
                          data: Theme.of(context).copyWith(
                            cardColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                          ),
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: PopupMenuButton<String>(
                              tooltip: 'More actions',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                PhosphorIconsRegular.dotsThreeVertical,
                                size: 18,
                                color: _isHovered
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                ),
                              ),
                              color: isDark ? AppColors.cardDark : AppColors.cardLight,
                              elevation: 6,
                              onSelected: (val) {
                                if (val == 'status') {
                                  widget.onToggleStatus();
                                } else if (val == 'died') {
                                  widget.onMarkDied();
                                } else if (val == 'delete') {
                                  widget.onDelete();
                                }
                              },
                        itemBuilder: (ctx) => [
                          if (!cow.isDeleted && !cow.isDelete && !cow.isDead && !cow.isDied)
                            PopupMenuItem(
                              value: 'status',
                              height: 38,
                              child: Row(
                                children: [
                                  Icon(
                                    cow.isActive
                                        ? Icons.power_settings_new_rounded
                                        : Icons.check_circle_outline_rounded,
                                    size: 16,
                                    color: cow.isActive ? Colors.orange : AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    cow.isActive ? 'Set InActive' : 'Set Active',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          if (!cow.isDeleted && !cow.isDelete)
                            PopupMenuItem(
                              value: 'died',
                              height: 38,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.heart_broken_rounded,
                                    size: 16,
                                    color: Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    (cow.isDead || cow.isDied) ? 'Update Death Date' : 'Mark as Died',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (!cow.isDeleted && !cow.isDelete) ...[
                            const PopupMenuDivider(height: 1),
                            const PopupMenuItem(
                              value: 'delete',
                              height: 38,
                              child: Row(
                                children: [
                                  Icon(
                                    PhosphorIconsRegular.trash,
                                    size: 16,
                                    color: AppColors.error,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Delete Record',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
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
);
  }
}

/// Interactive hoverable metric tile with smooth elevation lift, border glow,
/// and reactive theme adaptation.
class _HoverableMetricTile extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
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
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.isCompact ? 11 : 12,
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
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

