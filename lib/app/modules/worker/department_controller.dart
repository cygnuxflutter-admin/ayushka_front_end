import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/values/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../data/models/department_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/gaushala_session_service.dart';
import 'views/edit_department_screen.dart';

/// Controller managing Departments (Master & Filtering).
class DepartmentController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();

  final RxList<DepartmentModel> departments = <DepartmentModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxString searchQuery = ''.obs;

  String get currentGaushalaId => _gaushalaService.selectedGaushalaId;

  List<DepartmentModel> get filteredDepartments {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return departments.toList();
    return departments.where((d) {
      return d.departmentName.toLowerCase().contains(query) ||
          d.departmentCode.toLowerCase().contains(query) ||
          d.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    final gId = currentGaushalaId;
    if (gId.isNotEmpty) {
      fetchDepartments(gaushalaId: gId);
    }

    ever(_gaushalaService.selectedGaushala, (g) {
      if (g != null && g.id.isNotEmpty) {
        fetchDepartments(gaushalaId: g.id);
      } else {
        departments.clear();
      }
    });
  }

  /// Fetches departments for the active gaushala
  Future<void> fetchDepartments({
    String? gaushalaId,
    String? search,
    bool showLoading = false,
  }) async {
    final gId = gaushalaId ?? currentGaushalaId;
    if (gId.isEmpty || gId == 'all') {
      departments.clear();
      return;
    }

    if (showLoading || departments.isEmpty) {
      isLoading.value = true;
    }

    try {
      final list = await _apiService.getDepartments(
        gaushalaId: gId,
        search: search ?? (searchQuery.value.isNotEmpty ? searchQuery.value : null),
      );
      departments.assignAll(list);
    } catch (e) {
      if (e is DioException) {
        final msg = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to load departments.';
        CustomSnackbar.showError(title: 'Error', message: msg);
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Create a new department
  Future<bool> createDepartment({
    required String departmentName,
    required String departmentCode,
    String? description,
  }) async {
    final gId = currentGaushalaId;
    if (gId.isEmpty) {
      CustomSnackbar.showError(title: 'Error', message: 'No active Gaushala selected.');
      return false;
    }

    final trimmedName = departmentName.trim();
    final trimmedCode = departmentCode.trim().toUpperCase();

    if (trimmedName.isEmpty || trimmedCode.isEmpty) {
      CustomSnackbar.showError(title: 'Validation Error', message: 'Department Name and Code are required.');
      return false;
    }

    isSubmitting.value = true;
    try {
      final newDept = await _apiService.createDepartment(
        gaushalaId: gId,
        departmentName: trimmedName,
        departmentCode: trimmedCode,
        description: description?.trim(),
      );
      departments.insert(0, newDept);
      CustomSnackbar.showSuccess(
        title: 'Department Created',
        message: 'Department "${newDept.departmentName}" ($trimmedCode) created successfully.',
      );
      return true;
    } catch (e) {
      String msg = 'Failed to create department.';
      if (e is DioException) {
        msg = e.response?.data?['message']?.toString() ?? e.message ?? msg;
      }
      CustomSnackbar.showError(title: 'Error', message: msg);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Update an existing department
  Future<bool> updateDepartment(
    String id, {
    required String departmentName,
    required String departmentCode,
    String? description,
    bool isActive = true,
  }) async {
    final trimmedName = departmentName.trim();
    final trimmedCode = departmentCode.trim().toUpperCase();

    if (trimmedName.isEmpty || trimmedCode.isEmpty) {
      CustomSnackbar.showError(title: 'Validation Error', message: 'Department Name and Code are required.');
      return false;
    }

    isSubmitting.value = true;
    try {
      final updated = await _apiService.updateDepartment(
        id,
        departmentName: trimmedName,
        departmentCode: trimmedCode,
        description: description?.trim(),
        isActive: isActive,
      );

      final index = departments.indexWhere((d) => d.id == id);
      if (index != -1) {
        departments[index] = updated;
      }

      CustomSnackbar.showSuccess(
        title: 'Department Updated',
        message: 'Department "${updated.departmentName}" updated successfully.',
      );
      return true;
    } catch (e) {
      String msg = 'Failed to update department.';
      if (e is DioException) {
        msg = e.response?.data?['message']?.toString() ?? e.message ?? msg;
      }
      CustomSnackbar.showError(title: 'Error', message: msg);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Delete a department (Backend validates that no workers are assigned)
  Future<bool> deleteDepartment(DepartmentModel dept) async {
    isSubmitting.value = true;
    try {
      final success = await _apiService.deleteDepartment(dept.id);
      if (success) {
        departments.removeWhere((d) => d.id == dept.id);
        CustomSnackbar.showSuccess(
          title: 'Department Deleted',
          message: 'Department "${dept.departmentName}" was removed.',
        );
        return true;
      } else {
        CustomSnackbar.showError(
          title: 'Cannot Delete',
          message: 'Could not delete department. Please ensure no workers are assigned.',
        );
        return false;
      }
    } catch (e) {
      String msg = 'Cannot delete department with assigned workers.';
      if (e is DioException) {
        msg = e.response?.data?['message']?.toString() ?? e.message ?? msg;
      }
      CustomSnackbar.showError(title: 'Error', message: msg);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Open Dialog to Add Department
  void openAddDepartmentDialog(BuildContext context, {VoidCallback? onSuccess}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final descController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              PhosphorIconsRegular.buildings,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Add Department',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
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
                  const SizedBox(height: 6),
                  const Text(
                    'Define a functional department unit in the Gaushala (e.g., Milking, Feeding, Medical, Cleaning).',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Department Name *',
                    hint: 'e.g. Dairy & Milking Operations',
                    controller: nameController,
                    prefixIcon: const Icon(Icons.apartment_rounded, size: 18),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Department name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Department Code *',
                    hint: 'e.g. MILK, FEED, MED, CLEAN',
                    controller: codeController,
                    isUpperCase: true,
                    prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Department code is required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Description',
                    hint: 'Brief description of department scope...',
                    controller: descController,
                    maxLines: 3,
                    prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomButton(
                        text: 'Cancel',
                        variant: ButtonVariant.outlined,
                        width: 100,
                        onPressed: () {
                          if (Get.isDialogOpen ?? false) {
                            Get.back();
                          } else if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      Obx(
                        () => CustomButton(
                          text: 'Save Department',
                          variant: ButtonVariant.primary,
                          isLoading: isSubmitting.value,
                          width: 160,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final ok = await createDepartment(
                                departmentName: nameController.text,
                                departmentCode: codeController.text,
                                description: descController.text,
                              );
                              if (ok) {
                                if (Get.isDialogOpen ?? false) {
                                  Get.back();
                                } else if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pop();
                                }
                                onSuccess?.call();
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Open Dialog to Edit Department
  void openEditDepartmentDialog(BuildContext context, DepartmentModel dept, {VoidCallback? onSuccess}) {
    if (ResponsiveLayout.isMobile(context)) {
      Get.to(() => EditDepartmentScreen(department: dept, onSuccess: onSuccess));
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: dept.departmentName);
    final codeController = TextEditingController(text: dept.departmentCode);
    final descController = TextEditingController(text: dept.description);
    final RxBool isActive = dept.isActive.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              PhosphorIconsRegular.pencilSimple,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Edit Department',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
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
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Department Name *',
                    hint: 'e.g. Dairy & Milking Operations',
                    controller: nameController,
                    prefixIcon: const Icon(Icons.apartment_rounded, size: 18),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Department name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Department Code *',
                    hint: 'e.g. MILK, FEED',
                    controller: codeController,
                    isUpperCase: true,
                    prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Department code is required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Description',
                    hint: 'Brief description...',
                    controller: descController,
                    maxLines: 3,
                    prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Active Status',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        isActive.value ? 'Department is active' : 'Department is deactivated',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                      value: isActive.value,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) => isActive.value = val,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomButton(
                        text: 'Cancel',
                        variant: ButtonVariant.outlined,
                        width: 100,
                        onPressed: () {
                          if (Get.isDialogOpen ?? false) {
                            Get.back();
                          } else if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      Obx(
                        () => CustomButton(
                          text: 'Save Changes',
                          variant: ButtonVariant.primary,
                          isLoading: isSubmitting.value,
                          width: 150,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final ok = await updateDepartment(
                                dept.id,
                                departmentName: nameController.text,
                                departmentCode: codeController.text,
                                description: descController.text,
                                isActive: isActive.value,
                              );
                              if (ok) {
                                if (Get.isDialogOpen ?? false) {
                                  Get.back();
                                } else if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pop();
                                }
                                onSuccess?.call();
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Confirm Delete Department
  void confirmDeleteDepartment(BuildContext context, DepartmentModel dept, {VoidCallback? onSuccess}) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Delete Department'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete department "${dept.departmentName}" (${dept.departmentCode})?\n\nNote: Backend validates that no workers are assigned to this department.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Get.isDialogOpen ?? false) {
                Get.back();
              } else if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (Get.isDialogOpen ?? false) {
                Get.back();
              } else if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
              }
              final ok = await deleteDepartment(dept);
              if (ok) {
                onSuccess?.call();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
