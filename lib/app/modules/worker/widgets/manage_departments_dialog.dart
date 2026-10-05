import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_loader.dart';
import '../../../data/models/department_model.dart';
import '../department_controller.dart';
import '../worker_controller.dart';

/// Modal dialog to view, search, create, edit, and delete Gaushala Departments.
class ManageDepartmentsDialog extends StatelessWidget {
  const ManageDepartmentsDialog({super.key});

  static void show(BuildContext context) {
    Get.dialog(
      const ManageDepartmentsDialog(),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final deptCtrl = Get.find<DepartmentController>();
    final workerCtrl = Get.isRegistered<WorkerController>() ? Get.find<WorkerController>() : null;

    final searchFieldCtrl = TextEditingController(text: deptCtrl.searchQuery.value);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width < 500 ? 12 : 20,
        vertical: 20,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 680),
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 500 ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------------------------------------------------------
              // HEADER
              // ---------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            PhosphorIconsRegular.buildings,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Department Management',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Create and configure farm functional divisions & worker allocations.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    tooltip: 'Close',
                    onPressed: () {
                      if (Get.isDialogOpen ?? false) {
                        Get.back();
                      } else if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 18),

              // ---------------------------------------------------------
              // ACTION & SEARCH BAR
              // ---------------------------------------------------------
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 480;

                  final searchField = SizedBox(
                    height: 42,
                    child: TextField(
                      controller: searchFieldCtrl,
                      onChanged: (val) => deptCtrl.searchQuery.value = val,
                      decoration: InputDecoration(
                        hintText: 'Search department by name or code...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        suffixIcon: Obx(() {
                          if (deptCtrl.searchQuery.value.isNotEmpty) {
                            return IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                searchFieldCtrl.clear();
                                deptCtrl.searchQuery.value = '';
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                      ),
                    ),
                  );

                  final addBtn = CustomButton(
                    text: 'Add Department',
                    icon: Icons.add_rounded,
                    height: 42,
                    onPressed: () {
                      deptCtrl.openAddDepartmentDialog(
                        context,
                        onSuccess: () {
                          workerCtrl?.fetchDepartmentSummary();
                        },
                      );
                    },
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        searchField,
                        const SizedBox(height: 10),
                        addBtn,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: searchField),
                      const SizedBox(width: 12),
                      addBtn,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // ---------------------------------------------------------
              // DEPARTMENTS LIST
              // ---------------------------------------------------------
              Expanded(
                child: Obx(() {
                  if (deptCtrl.isLoading.value && deptCtrl.departments.isEmpty) {
                    return const Center(child: CustomBrandedSpinner());
                  }

                  final list = deptCtrl.filteredDepartments;
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsRegular.buildings,
                            size: 48,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No Departments Found',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            deptCtrl.searchQuery.value.isNotEmpty
                                ? 'No department matches "${deptCtrl.searchQuery.value}".'
                                : 'No departments have been added for this Gaushala yet.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'Create First Department',
                            icon: Icons.add_rounded,
                            variant: ButtonVariant.outlined,
                            onPressed: () {
                              deptCtrl.openAddDepartmentDialog(
                                context,
                                onSuccess: () => workerCtrl?.fetchDepartmentSummary(),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (context, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final dept = list[index];
                        return _HoverableDepartmentItem(
                          parentContext: context,
                          dept: dept,
                          deptCtrl: deptCtrl,
                          workerCtrl: workerCtrl,
                          isDark: isDark,
                        );
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),
              // Footer close button
              Align(
                alignment: Alignment.centerRight,
                child: CustomButton(
                  text: 'Close',
                  variant: ButtonVariant.outlined,
                  width: 90,
                  height: 38,
                  onPressed: () {
                    if (Get.isDialogOpen ?? false) {
                      Get.back();
                    } else if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildCountBadge({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverableDepartmentItem extends StatefulWidget {
  final BuildContext parentContext;
  final DepartmentModel dept;
  final DepartmentController deptCtrl;
  final WorkerController? workerCtrl;
  final bool isDark;

  const _HoverableDepartmentItem({
    required this.parentContext,
    required this.dept,
    required this.deptCtrl,
    required this.workerCtrl,
    required this.isDark,
  });

  @override
  State<_HoverableDepartmentItem> createState() => _HoverableDepartmentItemState();
}

class _HoverableDepartmentItemState extends State<_HoverableDepartmentItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final stats = widget.dept.workerStats;
    final isDark = widget.isDark;

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isHovered
              ? (isDark
                  ? AppColors.surfaceDark.withValues(alpha: 0.85)
                  : AppColors.primary.withValues(alpha: 0.045))
              : (isDark ? AppColors.surfaceDark : Colors.white),
          border: Border(
            left: BorderSide(
              color: _isHovered
                  ? (isDark ? AppColors.primaryLight : AppColors.primary)
                  : Colors.transparent,
              width: 3.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Department Code Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Text(
                widget.dept.departmentCode.isNotEmpty ? widget.dept.departmentCode : 'DEPT',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name & Description
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.dept.departmentName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.dept.isActive ? AppColors.successBg : AppColors.errorBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.dept.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: widget.dept.isActive ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.dept.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.dept.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Worker Counts Badge
            Expanded(
              flex: 3,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  ManageDepartmentsDialog._buildCountBadge(
                    label: 'Total',
                    count: stats.totalWorkers,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    bgColor: isDark ? AppColors.cardDark : const Color(0xFFF0F4ED),
                  ),
                  ManageDepartmentsDialog._buildCountBadge(
                    label: 'Active',
                    count: stats.activeWorkers,
                    color: AppColors.success,
                    bgColor: AppColors.successBg,
                  ),
                  if (stats.inactiveWorkers > 0)
                    ManageDepartmentsDialog._buildCountBadge(
                      label: 'Left',
                      count: stats.inactiveWorkers,
                      color: AppColors.warning,
                      bgColor: AppColors.warningBg,
                    ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 18, color: AppColors.primary),
                  tooltip: 'Edit Department',
                  splashRadius: 18,
                  onPressed: () {
                    widget.deptCtrl.openEditDepartmentDialog(
                      widget.parentContext,
                      widget.dept,
                      onSuccess: () => widget.workerCtrl?.fetchDepartmentSummary(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.trash, size: 18, color: AppColors.error),
                  tooltip: 'Delete Department',
                  splashRadius: 18,
                  onPressed: () {
                    widget.deptCtrl.confirmDeleteDepartment(
                      widget.parentContext,
                      widget.dept,
                      onSuccess: () => widget.workerCtrl?.fetchDepartmentSummary(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
