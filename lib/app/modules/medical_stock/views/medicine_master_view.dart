import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/values/app_colors.dart';
import '../../../core/values/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dropdown_search.dart';
import '../../../core/widgets/custom_loader.dart';
import '../../../core/widgets/custom_pagination.dart';
import '../../../core/widgets/custom_shimmer.dart';
import '../../../data/models/medical_item_model.dart';
import '../../../routes/app_routes.dart';
import '../dialogs/add_edit_medicine_dialog.dart';
import '../dialogs/medicine_details_dialog.dart';
import '../dialogs/view_batches_dialog.dart';
import '../medical_stock_controller.dart';

/// Screen: Medicine Master (Inventory List)
/// Redesigned using the Herd & Cattle module as the primary UI/UX design reference:
/// - Breadcrumb & executive action bar
/// - Interactive metric cards with hover lift animation
/// - Cattle-style table card with 16px radius, header icon/pill, and search/filters
/// - Cattle-style segmented filter tabs with animated indicator
/// - Cattle-style search input with clear button and 10px radius
/// - Hoverable table rows with 3.5px primary left border and 160ms transition
/// - Status badges, current stock boxes, threshold boxes, and batch information boxes
/// - Mobile responsive card list with 14px radius and micro-boxes
/// - Shimmer loading skeletons and empty states matching Herd & Cattle
class MedicineMasterView extends StatelessWidget {
  const MedicineMasterView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MedicalStockController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -------------------------------------------------------------
              // 1. BREADCRUMB & EXECUTIVE ACTION BAR (Herd & Cattle style)
              // -------------------------------------------------------------
              _buildBreadcrumbAndActionBar(context, controller, isDark),
              const SizedBox(height: 20),

              // -------------------------------------------------------------
              // 2. METRIC CARDS (Herd & Cattle _buildMetricCards style)
              // -------------------------------------------------------------
              _buildMetricCards(context, controller, isDark),
              const SizedBox(height: 22),

              // -------------------------------------------------------------
              // 3. RESPONSIVE INVENTORY VIEW (Table on Desktop, Cards on Mobile)
              // -------------------------------------------------------------
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 880;
                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSearchAndFiltersMobile(context, controller, isDark),
                        const SizedBox(height: 16),
                        _buildMedicineListCards(context, controller, isDark),
                      ],
                    );
                  }
                  return _buildMedicineTableCard(context, controller, isDark);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BREADCRUMB & ACTION BAR
  // ---------------------------------------------------------------------------
  Widget _buildBreadcrumbAndActionBar(
    BuildContext context,
    MedicalStockController controller,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStackNeeded = constraints.maxWidth < 800;

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
                  'Medical Stock',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                const Text(
                  'Medicine Master',
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
              'Medicine Master Catalog',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Obx(
              () => Text(
                'Managing ${controller.items.length} veterinary medicine SKUs for ${controller.activeGaushalaName}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
              ),
            ),
          ],
        );

        final actionButtons = Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Obx(() {
              final isBusy = controller.isRefreshing.value || controller.isLoading.value;
              return CustomButton(
                text: 'Refresh',
                icon: Icons.refresh_rounded,
                variant: ButtonVariant.outlined,
                height: 42,
                isLoading: isBusy,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                onPressed: isBusy ? null : controller.refreshAllData,
              );
            }),
            CustomButton(
              text: 'Add Medicine',
              icon: PhosphorIconsRegular.plus,
              variant: ButtonVariant.primary,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: () => AddEditMedicineDialog.show(context),
            ),
          ],
        );

        if (isStackNeeded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              const SizedBox(height: 14),
              actionButtons,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleSection),
            actionButtons,
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // METRIC CARDS (Herd & Cattle _buildMetricCards & _HoverableMetricTile style)
  // ---------------------------------------------------------------------------
  Widget _buildMetricCards(
    BuildContext context,
    MedicalStockController controller,
    bool isDark,
  ) {
    return Obx(() {
      final allItems = controller.items;
      final totalCount = allItems.length;
      final inStockCount = allItems.where((i) => !i.isLowStock && !i.isOutOfStock).length;
      final lowStockCount = allItems.where((i) => i.isLowStock && !i.isOutOfStock).length;
      final outStockCount = allItems.where((i) => i.isOutOfStock).length;

      return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;
          final isCompact = constraints.maxWidth < 640;

          if (isCompact) {
            if (constraints.maxWidth < 500) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _HoverableMetricTile(
                          title: 'Total',
                          value: '$totalCount',
                          icon: PhosphorIconsRegular.pill,
                          color: AppColors.primary,
                          isDark: isDark,
                          isCompact: true,
                          onTap: () => controller.setStockFilter('all'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HoverableMetricTile(
                          title: 'Adequate',
                          value: '$inStockCount',
                          icon: PhosphorIconsRegular.checkCircle,
                          color: const Color(0xFF2E7D32),
                          isDark: isDark,
                          isCompact: true,
                          onTap: () => controller.setStockFilter('in_stock'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _HoverableMetricTile(
                          title: 'Low Stock',
                          value: '$lowStockCount',
                          icon: PhosphorIconsRegular.warning,
                          color: const Color(0xFFE65100),
                          isDark: isDark,
                          isCompact: true,
                          onTap: () => controller.setStockFilter('low'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HoverableMetricTile(
                          title: 'Out of Stock',
                          value: '$outStockCount',
                          icon: PhosphorIconsRegular.warningOctagon,
                          color: const Color(0xFFC62828),
                          isDark: isDark,
                          isCompact: true,
                          onTap: () => controller.setStockFilter('out'),
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
                  child: _HoverableMetricTile(
                    title: 'Total',
                    value: '$totalCount',
                    icon: PhosphorIconsRegular.pill,
                    color: AppColors.primary,
                    isDark: isDark,
                    isCompact: true,
                    onTap: () => controller.setStockFilter('all'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HoverableMetricTile(
                    title: 'Adequate',
                    value: '$inStockCount',
                    icon: PhosphorIconsRegular.checkCircle,
                    color: const Color(0xFF2E7D32),
                    isDark: isDark,
                    isCompact: true,
                    onTap: () => controller.setStockFilter('in_stock'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HoverableMetricTile(
                    title: 'Low Stock',
                    value: '$lowStockCount',
                    icon: PhosphorIconsRegular.warning,
                    color: const Color(0xFFE65100),
                    isDark: isDark,
                    isCompact: true,
                    onTap: () => controller.setStockFilter('low'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HoverableMetricTile(
                    title: 'Out of Stock',
                    value: '$outStockCount',
                    icon: PhosphorIconsRegular.warningOctagon,
                    color: const Color(0xFFC62828),
                    isDark: isDark,
                    isCompact: true,
                    onTap: () => controller.setStockFilter('out'),
                  ),
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
                      child: _HoverableMetricTile(
                        title: 'Total Medicines',
                        value: '$totalCount',
                        subtitle: 'Registered SKUs in catalog',
                        icon: PhosphorIconsRegular.pill,
                        color: AppColors.primary,
                        isDark: isDark,
                        onTap: () => controller.setStockFilter('all'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _HoverableMetricTile(
                        title: 'Healthy Stock',
                        value: '$inStockCount',
                        subtitle: 'Above reorder alert level',
                        icon: PhosphorIconsRegular.checkCircle,
                        color: const Color(0xFF2E7D32),
                        isDark: isDark,
                        onTap: () => controller.setStockFilter('in_stock'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _HoverableMetricTile(
                        title: 'Low Stock Alert',
                        value: '$lowStockCount',
                        subtitle: 'At or below threshold',
                        icon: PhosphorIconsRegular.warning,
                        color: const Color(0xFFE65100),
                        isDark: isDark,
                        onTap: () => controller.setStockFilter('low'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _HoverableMetricTile(
                        title: 'Out of Stock',
                        value: '$outStockCount',
                        subtitle: 'Zero units remaining',
                        icon: PhosphorIconsRegular.warningOctagon,
                        color: const Color(0xFFC62828),
                        isDark: isDark,
                        onTap: () => controller.setStockFilter('out'),
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
                child: _HoverableMetricTile(
                  title: 'Total Catalog',
                  value: '$totalCount',
                  subtitle: 'Registered SKUs',
                  icon: PhosphorIconsRegular.pill,
                  color: AppColors.primary,
                  isDark: isDark,
                  onTap: () => controller.setStockFilter('all'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _HoverableMetricTile(
                  title: 'Adequate Stock',
                  value: '$inStockCount',
                  subtitle: 'Safe reorder level',
                  icon: PhosphorIconsRegular.checkCircle,
                  color: const Color(0xFF2E7D32),
                  isDark: isDark,
                  onTap: () => controller.setStockFilter('in_stock'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _HoverableMetricTile(
                  title: 'Low Stock Alerts',
                  value: '$lowStockCount',
                  subtitle: 'Needs replenishment',
                  icon: PhosphorIconsRegular.warning,
                  color: const Color(0xFFE65100),
                  isDark: isDark,
                  onTap: () => controller.setStockFilter('low'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _HoverableMetricTile(
                  title: 'Out of Stock',
                  value: '$outStockCount',
                  subtitle: 'Depleted inventory',
                  icon: PhosphorIconsRegular.warningOctagon,
                  color: const Color(0xFFC62828),
                  isDark: isDark,
                  onTap: () => controller.setStockFilter('out'),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  // ---------------------------------------------------------------------------
  // DESKTOP MEDICINE TABLE CARD (Herd & Cattle _buildCowsTableCard style)
  // ---------------------------------------------------------------------------
  Widget _buildMedicineTableCard(
    BuildContext context,
    MedicalStockController controller,
    bool isDark,
  ) {
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
          // Filter & Search bar header (Herd & Cattle style)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.pill, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Medicine Inventory',
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
                          '${controller.filteredItems.length} Listed',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    Obx(() {
                      if (controller.isLoading.value && controller.items.isNotEmpty) {
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
                    // Category Dropdown Filter
                    _buildCategoryFilterDropdown(context, controller, isDark),
                    // Unit Dropdown Filter
                    _buildUnitFilterDropdown(context, controller, isDark),
                    // Stock Status Filter Tabs (Herd & Cattle _buildGenderFilterTabs style)
                    _buildStockFilterTabs(context, controller, isDark),
                    // Cattle-style Search Input
                    _buildSearchTextField(controller, isDark, width: 240),
                    // Reset Filters Button
                    CustomButton(
                      text: 'Reset',
                      icon: Icons.filter_alt_off_rounded,
                      variant: ButtonVariant.outlined,
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: controller.clearMedicineFilters,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content: Table, Shimmer, or Empty State
          LayoutBuilder(
            builder: (context, constraints) {
              const double minTableWidth = 1080.0;
              final double tableWidth = constraints.maxWidth < minTableWidth
                  ? minTableWidth
                  : constraints.maxWidth;

              return Obx(() {
                if (controller.isLoading.value) {
                  return const CustomTableShimmer(
                    rowCount: 6,
                    columnFlexes: [4, 3, 3, 3, 3, 2],
                    headers: ['#', 'MEDICINE SKU & BRAND', 'CATEGORY & FORM', 'CURRENT STOCK', 'ALERT THRESHOLD', 'BATCHES', 'ACTIONS'],
                  );
                }

                final list = controller.filteredItems;
                if (list.isEmpty) {
                  return _buildEmptyState(context, controller);
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
                                  Expanded(flex: 5, child: _buildTableHeaderCell('MEDICINE SKU & BRAND')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('CATEGORY & FORM')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('CURRENT STOCK')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('ALERT THRESHOLD')),
                                  Expanded(flex: 3, child: _buildTableHeaderCell('BATCHES')),
                                  SizedBox(width: 175, child: _buildTableHeaderCell('ACTIONS', alignRight: true)),
                                ],
                              ),
                            ),
                            // Data Rows with Herd & Cattle hover effect
                            ...controller.paginatedItems.asMap().entries.map((entry) {
                              final pageStartIndex = (controller.itemsCurrentPage.value - 1) * controller.itemsPerPage.value;
                              final index = pageStartIndex + entry.key;
                              final item = entry.value;

                              return _HoverableMedicineTableRow(
                                key: ValueKey('med_${item.id}_$index'),
                                index: index,
                                item: item,
                                isDark: isDark,
                                onView: () => MedicineDetailsDialog.show(context, item: item),
                                onInward: () {
                                  controller.inwardSelectedItem.value = item;
                                  controller.switchTab(2);
                                },
                                onViewBatches: () => ViewBatchesDialog.show(context, item: item),
                                onEdit: () => AddEditMedicineDialog.show(context, existingItem: item),
                                onDelete: () => _confirmDelete(context, controller, item),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    // Pagination Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: CustomPagination(
                        totalItems: list.length,
                        currentPage: controller.itemsCurrentPage.value,
                        rowsPerPage: controller.itemsPerPage.value,
                        onPageChanged: (page) => controller.itemsCurrentPage.value = page,
                        onRowsPerPageChanged: (limit) {
                          controller.itemsPerPage.value = limit;
                          controller.itemsCurrentPage.value = 1;
                        },
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

  // ---------------------------------------------------------------------------
  // MOBILE / TABLET LIST CARDS (Herd & Cattle _buildCowsListCards style)
  // ---------------------------------------------------------------------------
  Widget _buildMedicineListCards(
    BuildContext context,
    MedicalStockController controller,
    bool isDark,
  ) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const CustomListShimmer(itemCount: 6);
      }

      final list = controller.paginatedItems;
      if (controller.filteredItems.isEmpty) {
        return _buildEmptyState(context, controller);
      }

      return Column(
        children: [
          ...list.map((item) {
            return _HoverableListCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: SKU, Name & Status Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (item.itemCode.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.itemCode,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                item.itemName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildMedicineStockStatusBadge(
                            context: context,
                            item: item,
                            isDark: isDark,
                            isMobile: true,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.categoryEnum.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.categoryEnum.label,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: item.categoryEnum.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Micro-Boxes Row: Current Stock, Alert Threshold, Batches
                  Row(
                    children: [
                      // Current Stock Box
                      Expanded(
                        child: _buildMicroBox(
                          isDark: isDark,
                          label: 'Current Stock',
                          value: '${item.totalStock.toStringAsFixed(0)} ${item.unit}',
                          icon: PhosphorIconsRegular.scales,
                          color: item.isOutOfStock
                              ? const Color(0xFFC62828)
                              : (item.isLowStock ? const Color(0xFFE65100) : const Color(0xFF2E7D32)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Alert Threshold Box
                      Expanded(
                        child: _buildMicroBox(
                          isDark: isDark,
                          label: 'Min Alert',
                          value: '${item.minStockAlert.toStringAsFixed(0)} ${item.unit}',
                          icon: PhosphorIconsRegular.warningCircle,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Active Batches Box
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final activeCount = controller
                                .getBatchesForItem(item.id)
                                .where((b) => b.availableQuantity > 0 && !b.isExpired)
                                .length;
                            final displayCount = activeCount > 0 ? activeCount : item.activeBatchesCount;
                            return _buildMicroBox(
                              isDark: isDark,
                              label: 'Batches',
                              value: '$displayCount Active',
                              icon: PhosphorIconsRegular.stack,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bottom Row: Manufacturer & Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.manufacturer.isNotEmpty ? item.manufacturer : 'Generic formulation',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(PhosphorIconsRegular.eye, size: 18),
                            tooltip: 'View Details',
                            onPressed: () => MedicineDetailsDialog.show(context, item: item),
                          ),
                          IconButton(
                            icon: const Icon(PhosphorIconsRegular.arrowDownLeft, size: 18, color: AppColors.primary),
                            tooltip: 'Inward Stock',
                            onPressed: () {
                              controller.inwardSelectedItem.value = item;
                              controller.switchTab(2);
                            },
                          ),
                          IconButton(
                            icon: const Icon(PhosphorIconsRegular.stack, size: 18, color: AppColors.primary),
                            tooltip: 'View Batches',
                            onPressed: () => ViewBatchesDialog.show(context, item: item),
                          ),
                          IconButton(
                            icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 18),
                            tooltip: 'Edit Medicine',
                            onPressed: () => AddEditMedicineDialog.show(context, existingItem: item),
                          ),
                          IconButton(
                            icon: const Icon(PhosphorIconsRegular.trash, size: 18, color: AppColors.error),
                            tooltip: 'Delete Medicine',
                            onPressed: () => _confirmDelete(context, controller, item),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
          const SizedBox(height: 8),
          CustomPagination(
            totalItems: controller.filteredItems.length,
            currentPage: controller.itemsCurrentPage.value,
            rowsPerPage: controller.itemsPerPage.value,
            onPageChanged: (page) => controller.itemsCurrentPage.value = page,
            onRowsPerPageChanged: (rows) {
              controller.itemsPerPage.value = rows;
              controller.itemsCurrentPage.value = 1;
            },
          ),
        ],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // MOBILE SEARCH & FILTERS BAR
  // ---------------------------------------------------------------------------
  Widget _buildSearchAndFiltersMobile(
    BuildContext context,
    MedicalStockController controller,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchTextField(controller, isDark),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildCategoryFilterDropdown(context, controller, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _buildUnitFilterDropdown(context, controller, isDark)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildStockFilterTabs(context, controller, isDark)),
            const SizedBox(width: 8),
            CustomButton(
              text: 'Reset',
              icon: Icons.filter_alt_off_rounded,
              variant: ButtonVariant.outlined,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onPressed: controller.clearMedicineFilters,
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // REUSABLE SUB-COMPONENTS
  // ---------------------------------------------------------------------------
  Widget _buildSearchTextField(
    MedicalStockController controller,
    bool isDark, {
    double? width,
  }) {
    final searchWidget = SizedBox(
      width: width,
      child: TextField(
        onChanged: (val) {
          controller.itemSearchQuery.value = val;
          controller.itemsCurrentPage.value = 1;
        },
        decoration: InputDecoration(
          hintText: 'Search SKU, brand, mfr...',
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          suffixIcon: Obx(
            () => controller.itemSearchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    onPressed: () {
                      controller.itemSearchQuery.value = '';
                      controller.itemsCurrentPage.value = 1;
                    },
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
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.8,
            ),
          ),
        ),
      ),
    );

    return searchWidget;
  }

  Widget _buildCategoryFilterDropdown(
    BuildContext context,
    MedicalStockController controller,
    bool isDark,
  ) {
    return Obx(() {
      final selectedCode = controller.selectedCategoryFilter.value;
      final isAll = selectedCode == 'ALL';
      final selectedLabel = isAll ? 'All Categories' : MedicalItemCategory.fromCode(selectedCode).label;

      return SizedBox(
        width: 195,
        child: CustomDropdownSearch<String>(
          hint: 'All Categories',
          prefixIcon: PhosphorIconsRegular.tag,
          selectedItem: selectedLabel,
          items: [
            'All Categories',
            ...MedicalItemCategory.values.map((c) => c.label),
          ],
          itemAsString: (s) => s,
          showClearButton: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
          onChanged: (val) {
            if (val == null || val == 'All Categories') {
              controller.selectedCategoryFilter.value = 'ALL';
            } else {
              final match = MedicalItemCategory.values.firstWhereOrNull((c) => c.label == val);
              controller.selectedCategoryFilter.value = match?.code ?? 'ALL';
            }
            controller.itemsCurrentPage.value = 1;
          },
        ),
      );
    });
  }

  Widget _buildUnitFilterDropdown(
    BuildContext context,
    MedicalStockController controller,
    bool isDark,
  ) {
    return Obx(() {
      final selectedCode = controller.selectedUnitFilter.value;
      final isAll = selectedCode == 'ALL';
      final selectedLabel = isAll ? 'All Units' : MedicalItemUnit.fromCode(selectedCode).label;

      return SizedBox(
        width: 175,
        child: CustomDropdownSearch<String>(
          hint: 'All Units',
          prefixIcon: PhosphorIconsRegular.scales,
          selectedItem: selectedLabel,
          items: [
            'All Units',
            ...MedicalItemUnit.values.map((u) => u.label),
          ],
          itemAsString: (s) => s,
          showClearButton: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
          onChanged: (val) {
            if (val == null || val == 'All Units') {
              controller.selectedUnitFilter.value = 'ALL';
            } else {
              final match = MedicalItemUnit.values.firstWhereOrNull((u) => u.label == val);
              controller.selectedUnitFilter.value = match?.code ?? 'ALL';
            }
            controller.itemsCurrentPage.value = 1;
          },
        ),
      );
    });
  }

  Widget _buildStockFilterTabs(
    BuildContext context,
    MedicalStockController controller,
    bool isDark,
  ) {
    return Obx(() {
      final selected = controller.selectedStockFilter.value;

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
            _buildStockTabItem(
              label: 'All',
              isActive: selected == 'all',
              isDark: isDark,
              onTap: () => controller.setStockFilter('all'),
            ),
            _buildStockTabItem(
              label: 'In Stock',
              isActive: selected == 'in_stock',
              isDark: isDark,
              onTap: () => controller.setStockFilter('in_stock'),
            ),
            _buildStockTabItem(
              label: 'Low Stock',
              isActive: selected == 'low',
              isDark: isDark,
              onTap: () => controller.setStockFilter('low'),
            ),
            _buildStockTabItem(
              label: 'Out of Stock',
              isActive: selected == 'out',
              isDark: isDark,
              onTap: () => controller.setStockFilter('out'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStockTabItem({
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

  Widget _buildMicroBox({
    required bool isDark,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, MedicalStockController controller) {
    final hasActiveFilter = controller.itemSearchQuery.value.isNotEmpty ||
        controller.selectedCategoryFilter.value != 'ALL' ||
        controller.selectedUnitFilter.value != 'ALL' ||
        controller.selectedStockFilter.value != 'all';

    return Padding(
      padding: const EdgeInsets.all(60.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsRegular.pill, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              hasActiveFilter
                  ? 'No medicines match your filter criteria'
                  : 'No medicines registered in this catalog',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              hasActiveFilter
                  ? 'Try clearing the filters or modifying your search keyword.'
                  : 'Click below to register the first medicine SKU into the system.',
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
                onPressed: controller.clearMedicineFilters,
              )
            else
              CustomButton(
                text: 'Add First Medicine',
                icon: Icons.add_rounded,
                width: 200,
                height: 40,
                onPressed: () => AddEditMedicineDialog.show(context),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    MedicalStockController controller,
    MedicalItemModel item,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medicine SKU'),
        content: Text('Are you sure you want to delete "${item.itemName}"? This will soft delete the catalog record.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.deleteMedicine(item.id);
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STATUS BADGE (Herd & Cattle _buildCowStatusBadge style)
// ---------------------------------------------------------------------------
Widget _buildMedicineStockStatusBadge({
  required BuildContext context,
  required MedicalItemModel item,
  required bool isDark,
  bool isMobile = false,
}) {
  final bool isOut = item.isOutOfStock;
  final bool isLow = item.isLowStock;

  final String text;
  final Color bg;
  final Color textColor;
  final IconData icon;

  if (isOut) {
    text = 'Out of Stock';
    bg = isDark ? Colors.red.withValues(alpha: 0.15) : const Color(0xFFFFEBEE);
    textColor = const Color(0xFFC62828);
    icon = PhosphorIconsRegular.warningOctagon;
  } else if (isLow) {
    text = 'Low Stock';
    bg = isDark ? Colors.orange.withValues(alpha: 0.15) : const Color(0xFFFFF3E0);
    textColor = const Color(0xFFE65100);
    icon = PhosphorIconsRegular.warning;
  } else {
    text = 'In Stock';
    bg = isDark ? Colors.green.withValues(alpha: 0.15) : const Color(0xFFE8F5E9);
    textColor = const Color(0xFF2E7D32);
    icon = PhosphorIconsRegular.checkCircle;
  }

  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: isMobile ? 7 : 8,
      vertical: isMobile ? 2.5 : 3.5,
    ),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(isMobile ? 10 : 16),
      border: Border.all(
        color: textColor.withValues(alpha: 0.35),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isMobile ? 11 : 12, color: textColor),
        SizedBox(width: isMobile ? 3 : 5),
        Text(
          text,
          style: TextStyle(
            fontSize: isMobile ? 10.5 : 11,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// HOVERABLE TABLE ROW (Herd & Cattle _HoverableCowTableRow style)
// ---------------------------------------------------------------------------
class _HoverableMedicineTableRow extends StatefulWidget {
  final int index;
  final MedicalItemModel item;
  final bool isDark;
  final VoidCallback onView;
  final VoidCallback onInward;
  final VoidCallback onViewBatches;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HoverableMedicineTableRow({
    super.key,
    required this.index,
    required this.item,
    required this.isDark,
    required this.onView,
    required this.onInward,
    required this.onViewBatches,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_HoverableMedicineTableRow> createState() => _HoverableMedicineTableRowState();
}

class _HoverableMedicineTableRowState extends State<_HoverableMedicineTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
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

            // Medicine SKU & Brand
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.categoryEnum.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.categoryEnum.icon, color: item.categoryEnum.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (item.itemCode.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    item.itemCode,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (item.manufacturer.isNotEmpty)
                                Flexible(
                                  child: Text(
                                    item.manufacturer,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Category & Form
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.categoryEnum.label,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.unitEnum.label,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Current Stock Box
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.isOutOfStock
                            ? (isDark ? Colors.red.withValues(alpha: 0.15) : const Color(0xFFFFEBEE))
                            : (item.isLowStock
                                ? (isDark ? Colors.orange.withValues(alpha: 0.15) : const Color(0xFFFFF3E0))
                                : (isDark ? Colors.green.withValues(alpha: 0.15) : const Color(0xFFE8F5E9))),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: item.isOutOfStock
                              ? const Color(0xFFEF4444)
                              : (item.isLowStock ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.isLowStock) ...[
                            Icon(
                              item.isOutOfStock ? PhosphorIconsRegular.warningOctagon : PhosphorIconsRegular.warning,
                              size: 13,
                              color: item.isOutOfStock ? const Color(0xFFC62828) : const Color(0xFFE65100),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            '${item.totalStock.toStringAsFixed(0)} ${item.unit}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: item.isOutOfStock
                                  ? const Color(0xFFC62828)
                                  : (item.isLowStock ? const Color(0xFFE65100) : const Color(0xFF2E7D32)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Alert Threshold Box
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(PhosphorIconsRegular.warningCircle, size: 12, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 4),
                          Text(
                            '${item.minStockAlert.toStringAsFixed(0)} ${item.unit}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Batches Box
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(PhosphorIconsRegular.stack, size: 12, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 4),
                          Builder(
                            builder: (context) {
                              final ctrl = Get.find<MedicalStockController>();
                              final activeCount = ctrl
                                  .getBatchesForItem(item.id)
                                  .where((b) => b.availableQuantity > 0 && !b.isExpired)
                                  .length;
                              final displayCount = activeCount > 0 ? activeCount : item.activeBatchesCount;
                              return Text(
                                '$displayCount Active',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions (View Details, Inward, Batches, Edit, Delete)
            SizedBox(
              width: 175,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRowActionIcon(
                      tooltip: 'View Medicine Details',
                      icon: PhosphorIconsRegular.eye,
                      color: AppColors.textSecondaryLight,
                      onTap: widget.onView,
                    ),
                    const SizedBox(width: 2),
                    _buildRowActionIcon(
                      tooltip: 'Inward Stock',
                      icon: PhosphorIconsRegular.arrowDownLeft,
                      color: AppColors.primary,
                      onTap: widget.onInward,
                    ),
                    const SizedBox(width: 2),
                    _buildRowActionIcon(
                      tooltip: 'View Batches Breakdown',
                      icon: PhosphorIconsRegular.stack,
                      color: AppColors.primary,
                      onTap: widget.onViewBatches,
                    ),
                    const SizedBox(width: 2),
                    _buildRowActionIcon(
                      tooltip: 'Edit Medicine Details',
                      icon: PhosphorIconsRegular.pencilSimple,
                      color: AppColors.textSecondaryLight,
                      onTap: widget.onEdit,
                    ),
                    const SizedBox(width: 2),
                    _buildRowActionIcon(
                      tooltip: 'Delete Medicine SKU',
                      icon: PhosphorIconsRegular.trash,
                      color: AppColors.error,
                      onTap: widget.onDelete,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowActionIcon({
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        hoverColor: color.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HOVERABLE METRIC TILE (Identical to CowScreen _HoverableMetricTile)
// ---------------------------------------------------------------------------
class _HoverableMetricTile extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool isCompact;
  final VoidCallback? onTap;

  const _HoverableMetricTile({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
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
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.value,
                      style: TextStyle(
                        fontSize: widget.isCompact ? 16 : 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    if (widget.subtitle != null && !widget.isCompact) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMutedLight,
                        ),
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

// -------------------------------------------------------------
// HOVERABLE CARD (MOBILE / TABLET)
// -------------------------------------------------------------
class _HoverableListCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  const _HoverableListCard({required this.child, this.margin});

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
        margin: widget.margin,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? (isDark ? AppColors.primaryLight : AppColors.primary.withValues(alpha: 0.45))
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
