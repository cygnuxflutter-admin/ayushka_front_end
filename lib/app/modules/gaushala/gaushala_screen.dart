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
import '../../data/models/gaushala_model.dart';
import '../../routes/app_routes.dart';
import '../dashboard/widgets/mobile_drawer.dart';
import '../dashboard/widgets/web_sidebar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'gaushala_controller.dart';

/// Screen for Managing Gaushalas (Master > Gaushalas).
class GaushalaScreen extends GetView<GaushalaController> {
  const GaushalaScreen({super.key});

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
                            _buildGaushalasTableCard(context),
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
        title: const Text('Gaushalas Master'),
        actions: [
          const NotificationBellWidget(),
          Obx(() {
            final isBusy = controller.isRefreshing.value || controller.isLoading.value;
            return IconButton(
              icon: isBusy
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh Gaushalas',
              onPressed: isBusy ? null : controller.refreshGaushalas,
            );
          }),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => controller.openAddGaushalaDialog(context),
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
            _buildGaushalaList(context),
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
        title: const Text('Gaushalas Master'),
        actions: [
          const NotificationBellWidget(),
          Obx(() {
            final isBusy = controller.isRefreshing.value || controller.isLoading.value;
            return IconButton(
              icon: isBusy
                  ? const CustomInlineLoader(size: 18, strokeWidth: 2)
                  : const Icon(Icons.refresh_rounded),
              tooltip: isBusy ? 'Refreshing...' : 'Refresh Gaushalas',
              onPressed: isBusy ? null : controller.refreshGaushalas,
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
        label: const Text('Add Gaushala', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => controller.openAddGaushalaDialog(context),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshGaushalas,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSearchBox(context),
              const SizedBox(height: 16),
              _buildGaushalaList(context),
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
                'Gaushalas & Farms Management',
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
                  tooltip: isBusy ? 'Refreshing...' : 'Refresh Gaushalas',
                  onPressed: isBusy ? null : controller.refreshGaushalas,
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
                  'Gaushalas',
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
              'Gaushalas Master',
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
              text: 'Add Gaushala',
              icon: Icons.add_rounded,
              width: 160,
              height: 42,
              onPressed: () => controller.openAddGaushalaDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // DESKTOP GAUSHALAS TABLE CARD
  // -------------------------------------------------------------
  Widget _buildGaushalasTableCard(BuildContext context) {
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
                    const Icon(PhosphorIconsRegular.barn, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Registered Gaushalas',
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
                          '${controller.filteredGaushalas.length} Total',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    Obx(() {
                      if (controller.isLoading.value && controller.gaushalas.isNotEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: CustomInlineLoader(size: 14, strokeWidth: 1.8),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    onChanged: (val) => controller.searchQuery.value = val,
                    decoration: InputDecoration(
                      hintText: 'Search gaushalas...',
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
          ),
          const Divider(height: 1),

          // Content: Table or Loading or Empty
          Obx(() {
            if (controller.isLoading.value) {
              return const CustomTableShimmer(
                rowCount: 6,
                columnFlexes: [6, 6, 5],
                headers: ['#', 'GAUSHALA NAME', 'SYSTEM ID', 'CREATED AT'],
              );
            }

            final list = controller.filteredGaushalas;
            if (list.isEmpty) {
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
                      child: const Icon(PhosphorIconsRegular.barn, size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.searchQuery.value.isNotEmpty
                          ? 'No gaushalas match "${controller.searchQuery.value}"'
                          : 'No gaushalas registered in system',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Click below to register a new cattle farm unit.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 18),
                    CustomButton(
                      text: 'Add First Gaushala',
                      icon: Icons.add_rounded,
                      width: 190,
                      height: 40,
                      onPressed: () => controller.openAddGaushalaDialog(context),
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
                      Expanded(flex: 6, child: _buildTableHeaderCell('GAUSHALA NAME')),
                      Expanded(flex: 6, child: _buildTableHeaderCell('SYSTEM ID')),
                      Expanded(flex: 5, child: _buildTableHeaderCell('CREATED AT')),
                    ],
                  ),
                ),
                // Table Data Rows
                ...controller.paginatedGaushalas.asMap().entries.map((entry) {
                  final pageStartIndex = (controller.currentPage.value - 1) * controller.rowsPerPage.value;
                  final index = pageStartIndex + entry.key;
                  final gaushala = entry.value;
                  return _HoverableGaushalaTableRow(
                    key: ValueKey(gaushala.id),
                    index: index,
                    gaushala: gaushala,
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

  // -------------------------------------------------------------
  // MOBILE / TABLET VIEWS
  // -------------------------------------------------------------
  Widget _buildSearchBox(BuildContext context) {
    return TextField(
      onChanged: (val) => controller.searchQuery.value = val,
      decoration: InputDecoration(
        hintText: 'Search gaushalas...',
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
    );
  }

  Widget _buildGaushalaList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoading.value) {
        return const CustomListShimmer(itemCount: 6);
      }

      final list = controller.filteredGaushalas;
      if (list.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text(
              controller.searchQuery.value.isNotEmpty
                  ? 'No gaushalas match "${controller.searchQuery.value}"'
                  : 'No gaushalas found.',
              style: const TextStyle(color: AppColors.textSecondaryLight),
            ),
          ),
        );
      }

      final paginatedList = controller.paginatedGaushalas;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: paginatedList.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final GaushalaModel gaushala = paginatedList[index];

              return _HoverableListCard(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: const Icon(PhosphorIconsRegular.barn, color: AppColors.primary, size: 20),
                  ),
                  title: Text(
                    gaushala.gaushalaName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('ID: ${gaushala.id}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                      Text('Created: ${formatDate(gaushala.createdAt)}', style: const TextStyle(fontSize: 11)),
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
// HOVERABLE GAUSHALA TABLE ROW (DESKTOP)
// -------------------------------------------------------------
class _HoverableGaushalaTableRow extends StatefulWidget {
  final int index;
  final GaushalaModel gaushala;
  final bool isDark;

  const _HoverableGaushalaTableRow({
    super.key,
    required this.index,
    required this.gaushala,
    required this.isDark,
  });

  @override
  State<_HoverableGaushalaTableRow> createState() => _HoverableGaushalaTableRowState();
}

class _HoverableGaushalaTableRowState extends State<_HoverableGaushalaTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final gaushala = widget.gaushala;
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

            // Gaushala Name Badge
            Expanded(
              flex: 6,
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
                            Icons.storefront_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            gaushala.gaushalaName,
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

            // System ID (with copy feedback)
            Expanded(
              flex: 6,
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
                            Clipboard.setData(ClipboardData(text: gaushala.id));
                            CustomSnackbar.showInfo(
                              title: 'Copied',
                              message: 'Gaushala ID copied to clipboard',
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    gaushala.id,
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
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Text(
                  formatDate(gaushala.createdAt),
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
