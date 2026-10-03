import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_shimmer.dart';
import '../../../data/models/department_summary_model.dart';
import '../worker_controller.dart';
import 'manage_departments_dialog.dart';

/// Top Dashboard widget displaying Department-wise Summary metrics and interactive filter cards.
/// Implements the exact executive hover lift animation (Matrix4 translateY, glow shadow,
/// color transition) matching Herd & Cattle module's _HoverableMetricTile.
class DepartmentSummaryCards extends StatelessWidget {
  final bool isCompact;

  const DepartmentSummaryCards({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workerCtrl = Get.find<WorkerController>();

    return Obx(() {
      final isLoading = workerCtrl.isLoadingSummary.value && workerCtrl.summary.value == null;

      if (isLoading) {
        return _buildShimmer(context, isDark);
      }

      final summary = workerCtrl.summary.value ?? const DepartmentSummaryModel();
      final totalWorkers = summary.totalWorkers;
      final activeWorkers = summary.activeWorkers;
      final inactiveWorkers = summary.inactiveWorkers;
      final totalDepartments = summary.totalDepartments;

      final currentStatus = workerCtrl.selectedStatusFilter.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -------------------------------------------------------------
          // 1. TOP METRIC TILES (4 KPI Cards with Hover Animation)
          // -------------------------------------------------------------
          if (isCompact)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  SizedBox(
                    width: 145,
                    child: _HoverableMetricTile(
                      title: 'Total Workers',
                      value: '$totalWorkers',
                      icon: PhosphorIconsRegular.users,
                      color: AppColors.primary,
                      isDark: isDark,
                      isCompact: true,
                      isSelected: currentStatus == 'all',
                      onTap: () => workerCtrl.setStatusFilter('all'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 145,
                    child: _HoverableMetricTile(
                      title: 'Active Workers',
                      value: '$activeWorkers',
                      icon: PhosphorIconsRegular.userCheck,
                      color: const Color(0xFF2E7D32),
                      isDark: isDark,
                      isCompact: true,
                      isSelected: currentStatus == 'active',
                      onTap: () => workerCtrl.setStatusFilter('active'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 145,
                    child: _HoverableMetricTile(
                      title: 'Left / Inactive',
                      value: '$inactiveWorkers',
                      icon: PhosphorIconsRegular.signpost,
                      color: const Color(0xFFD97706),
                      isDark: isDark,
                      isCompact: true,
                      isSelected: currentStatus == 'inactive',
                      onTap: () => workerCtrl.setStatusFilter('inactive'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 145,
                    child: _HoverableMetricTile(
                      title: 'Departments',
                      value: '$totalDepartments',
                      icon: PhosphorIconsRegular.buildings,
                      color: const Color(0xFF2563EB),
                      isDark: isDark,
                      isCompact: true,
                      onTap: () => ManageDepartmentsDialog.show(context),
                    ),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 950;

                if (isNarrow) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _HoverableMetricTile(
                              title: 'Total Workers',
                              value: '$totalWorkers',
                              subtitle: 'Registered staff personnel',
                              icon: PhosphorIconsRegular.users,
                              color: AppColors.primary,
                              isDark: isDark,
                              isSelected: currentStatus == 'all',
                              onTap: () => workerCtrl.setStatusFilter('all'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _HoverableMetricTile(
                              title: 'Active Workers',
                              value: '$activeWorkers',
                              subtitle: 'Currently working on duty',
                              icon: PhosphorIconsRegular.userCheck,
                              color: const Color(0xFF2E7D32),
                              isDark: isDark,
                              isSelected: currentStatus == 'active',
                              onTap: () => workerCtrl.setStatusFilter('active'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _HoverableMetricTile(
                              title: 'Left / Inactive',
                              value: '$inactiveWorkers',
                              subtitle: 'Departed or deactivated',
                              icon: PhosphorIconsRegular.signpost,
                              color: const Color(0xFFD97706),
                              isDark: isDark,
                              isSelected: currentStatus == 'inactive',
                              onTap: () => workerCtrl.setStatusFilter('inactive'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _HoverableMetricTile(
                              title: 'Departments',
                              value: '$totalDepartments',
                              subtitle: 'Operational divisions',
                              icon: PhosphorIconsRegular.buildings,
                              color: const Color(0xFF2563EB),
                              isDark: isDark,
                              onTap: () => ManageDepartmentsDialog.show(context),
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
                        title: 'Total Workers',
                        value: '$totalWorkers',
                        subtitle: 'Registered staff personnel',
                        icon: PhosphorIconsRegular.users,
                        color: AppColors.primary,
                        isDark: isDark,
                        isSelected: currentStatus == 'all',
                        onTap: () => workerCtrl.setStatusFilter('all'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _HoverableMetricTile(
                        title: 'Active Workers',
                        value: '$activeWorkers',
                        subtitle: 'Currently working on duty',
                        icon: PhosphorIconsRegular.userCheck,
                        color: const Color(0xFF2E7D32),
                        isDark: isDark,
                        isSelected: currentStatus == 'active',
                        onTap: () => workerCtrl.setStatusFilter('active'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _HoverableMetricTile(
                        title: 'Left / Inactive',
                        value: '$inactiveWorkers',
                        subtitle: 'Departed or deactivated',
                        icon: PhosphorIconsRegular.signpost,
                        color: const Color(0xFFD97706),
                        isDark: isDark,
                        isSelected: currentStatus == 'inactive',
                        onTap: () => workerCtrl.setStatusFilter('inactive'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _HoverableMetricTile(
                        title: 'Departments',
                        value: '$totalDepartments',
                        subtitle: 'Operational divisions',
                        icon: PhosphorIconsRegular.buildings,
                        color: const Color(0xFF2563EB),
                        isDark: isDark,
                        onTap: () => ManageDepartmentsDialog.show(context),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      );
    });
  }

  Widget _buildShimmer(BuildContext context, bool isDark) {
    return Row(
      children: List.generate(
        4,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 3 ? 14.0 : 0.0),
            child: const ShimmerPlaceholder(height: 80, borderRadius: 14),
          ),
        ),
      ),
    );
  }
}

/// Hoverable, responsive metric card matching Herd & Cattle module (_HoverableMetricTile).
/// Implements fluid upward lift (-4px), glow shadow, dynamic border and icon background animation.
class _HoverableMetricTile extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool isCompact;
  final bool isSelected;
  final VoidCallback? onTap;

  const _HoverableMetricTile({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    this.isCompact = false,
    this.isSelected = false,
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
          transform: Matrix4.translationValues(0, _isHovered ? -4 : (isSelected ? -2 : 0), 0),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 10 : 18,
            vertical: widget.isCompact ? 10 : 16,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? (_isHovered
                    ? AppColors.surfaceDark
                    : (isSelected ? const Color(0xFF1D2E1B) : AppColors.cardDark))
                : (_isHovered
                    ? Colors.white
                    : (isSelected ? const Color(0xFFF7FAF4) : AppColors.cardLight)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? effectiveColor.withValues(alpha: 0.60)
                  : (isSelected
                      ? effectiveColor.withValues(alpha: 0.85)
                      : (isDark ? AppColors.borderDark : AppColors.borderLight)),
              width: (isSelected || _isHovered) ? 1.5 : 1.0,
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
              ] else if (isSelected) ...[
                BoxShadow(
                  color: effectiveColor.withValues(alpha: 0.14),
                  blurRadius: 12,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                  blurRadius: 8,
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
                  color: effectiveColor.withValues(alpha: _isHovered ? 0.22 : (isSelected ? 0.18 : 0.12)),
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
                  mainAxisAlignment: MainAxisAlignment.center,
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
                        fontSize: widget.isCompact ? 15 : 20,
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

