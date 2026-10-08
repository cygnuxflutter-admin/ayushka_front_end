import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/values/app_colors.dart';
import '../../core/values/permission_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../data/models/role_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/permission_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'views/edit_role_screen.dart';

/// Controller managing Role Master state, operations, and navigation.
class RoleController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();
  final PermissionService? _permissionService =
      Get.isRegistered<PermissionService>() ? Get.find<PermissionService>() : null;

  bool get canAddRole =>
      _permissionService?.canAdd(PermissionModules.role, PermissionSubModules.roleList) ??
      (currentUser.value?.isAdmin ?? false);

  bool get canEditRole =>
      _permissionService?.canEdit(PermissionModules.role, PermissionSubModules.roleList) ??
      (currentUser.value?.isAdmin ?? false);

  bool get canDeleteRole =>
      _permissionService?.canDelete(PermissionModules.role, PermissionSubModules.roleList) ??
      (currentUser.value?.isAdmin ?? false);

  // Static in-memory cache to prevent flickering / repeated loading animations on navigation
  static final List<RoleModel> _cachedRoles = [];

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isSidebarCollapsed = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isSubmitting = false.obs;

  final RxList<RoleModel> roles = <RoleModel>[].obs;
  final RxString searchQuery = ''.obs;

  // Pagination states
  final RxInt currentPage = 1.obs;
  final RxInt rowsPerPage = 5.obs;

  List<RoleModel> get filteredRoles {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return roles;
    return roles.where((r) {
      final nameMatches = r.roleName.toLowerCase().contains(query);
      final idMatches = r.id.toLowerCase().contains(query);
      return nameMatches || idMatches;
    }).toList();
  }

  List<RoleModel> get paginatedRoles {
    final list = filteredRoles;
    final int start = (currentPage.value - 1) * rowsPerPage.value;
    if (start >= list.length) {
      if (list.isNotEmpty && currentPage.value > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final maxPage = (list.length / rowsPerPage.value).ceil().clamp(1, 999999);
          if (currentPage.value > maxPage) {
            currentPage.value = maxPage;
          }
        });
      }
      return list.take(rowsPerPage.value).toList();
    }
    return list.skip(start).take(rowsPerPage.value).toList();
  }

  int get totalPages => (filteredRoles.isEmpty)
      ? 1
      : (filteredRoles.length / rowsPerPage.value).ceil();

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      currentPage.value = page;
    }
  }

  void setRowsPerPage(int count) {
    rowsPerPage.value = count;
    currentPage.value = 1;
  }

  // Mobile Continuous Scrolling
  final RxInt mobileLimit = 10.obs;
  List<RoleModel> get mobileRoles => filteredRoles.take(mobileLimit.value).toList();
  bool get hasMoreMobile => mobileLimit.value < filteredRoles.length;
  void loadMoreMobile() {
    if (hasMoreMobile) {
      mobileLimit.value += 10;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    debounce(searchQuery, (_) {
      currentPage.value = 1;
      mobileLimit.value = 10;
    }, time: const Duration(milliseconds: 100));
    // Instantly hydrate existing data from cache if present
    if (_cachedRoles.isNotEmpty) {
      roles.assignAll(_cachedRoles);
    }
    // Only show full loader if cache is empty, otherwise refresh silently in background
    fetchRoles(showLoading: _cachedRoles.isEmpty);
  }

  void _loadUser() {
    currentUser.value = _storageService.getUser();
  }

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  Future<void> logout() async {
    _cachedRoles.clear();
    await _storageService.removeToken();
    await _storageService.removeUser();
    Get.offAllNamed(AppRoutes.auth);
  }

  /// Fetches all roles from GET /api/v1/roles
  Future<void> fetchRoles({
    bool showLoading = false,
    bool isManualRefresh = false,
  }) async {
    if (showLoading || roles.isEmpty) {
      isLoading.value = true;
    }
    if (isManualRefresh) {
      isRefreshing.value = true;
    }
    try {
      final result = await _apiService.getRoles();
      _cachedRoles
        ..clear()
        ..addAll(result);
      roles.assignAll(result);
      if (isManualRefresh) {
        CustomSnackbar.showSuccess(
          title: 'Refreshed',
          message: 'Roles list updated successfully.',
        );
      }
    } catch (e) {
      // Dio interceptor handles the error snackbar
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// User-initiated refresh action (triggers shimmer + spinning icon)
  Future<void> refreshRoles() async {
    if (isLoading.value || isRefreshing.value) return;
    mobileLimit.value = 10;
    await fetchRoles(showLoading: true, isManualRefresh: true);
  }

  /// Creates a new role via POST /api/v1/roles
  Future<bool> createRole(String roleName) async {
    if (roleName.trim().isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please enter a valid role name.',
      );
      return false;
    }

    isSubmitting.value = true;
    try {
      final newRole = await _apiService.createRole(roleName.trim());
      _cachedRoles.insert(0, newRole);
      roles.insert(0, newRole);
      return true;
    } catch (e) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Updates an existing role via POST /api/v1/roles/:id/update
  Future<bool> updateRole(String id, String roleName) async {
    if (roleName.trim().isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please enter a valid role name.',
      );
      return false;
    }

    isSubmitting.value = true;
    try {
      final updated = await _apiService.updateRole(id, roleName.trim());
      final index = roles.indexWhere((r) => r.id == id);
      if (index != -1) {
        roles[index] = updated;
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Deletes a role via DELETE /api/v1/roles/:id
  Future<void> deleteRole(String id) async {
    isLoading.value = true;
    try {
      final success = await _apiService.deleteRole(id);
      if (success) {
        roles.removeWhere((r) => r.id == id);
        CustomSnackbar.showSuccess(
          title: 'Role Deleted',
          message: 'Role was removed successfully.',
        );
      }
    } catch (e) {
      // Interceptor handles error
    } finally {
      isLoading.value = false;
    }
  }

  /// Open Dialog to Add a New Role
  void openAddRoleDialog(BuildContext context) {
    if (!canAddRole) {
      CustomSnackbar.showWarning(
        title: 'Access Denied',
        message: 'You do not have permission to add roles.',
      );
      return;
    }
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
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
                              PhosphorIconsRegular.shieldCheck,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Add New Role',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
                  const SizedBox(height: 8),
                  const Text(
                    'Define a new administrative or staff role for farm management.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: nameController,
                    label: 'Role Name',
                    hint: 'e.g. Manager, Doctor, Supervisor',
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Role name is required';
                      }
                      if (val.trim().length < 2) {
                        return 'Role name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                      const SizedBox(width: 12),
                      Obx(
                        () => CustomButton(
                          text: 'Create Role',
                          icon: Icons.add_rounded,
                          isLoading: isSubmitting.value,
                          width: 140,
                          height: 42,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final roleName = nameController.text.trim();
                              final success = await createRole(roleName);
                              if (success) {
                                if (Get.isDialogOpen ?? false) {
                                  Get.back();
                                } else if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pop();
                                }
                                CustomSnackbar.showSuccess(
                                  title: 'Role Created',
                                  message: 'Role "$roleName" was added successfully.',
                                );
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
      barrierDismissible: false,
    );
  }

  /// Open Dialog to Edit Role
  void openEditRoleDialog(BuildContext context, RoleModel role) {
    if (!canEditRole) {
      CustomSnackbar.showWarning(
        title: 'Access Denied',
        message: 'You do not have permission to edit roles.',
      );
      return;
    }
    if (ResponsiveLayout.isMobile(context)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EditRoleScreen(role: role)),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: role.roleName);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
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
                              color: AppColors.info.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: AppColors.info,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Edit Role',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
                  const SizedBox(height: 8),
                  Text(
                    'Update the title and permissions for "${role.roleName}".',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: nameController,
                    label: 'Role Name',
                    hint: 'e.g. Manager, Doctor, Supervisor',
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Role name is required';
                      }
                      if (val.trim().length < 2) {
                        return 'Role name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                      const SizedBox(width: 12),
                      Obx(
                        () => CustomButton(
                          text: 'Save Changes',
                          icon: Icons.check_rounded,
                          isLoading: isSubmitting.value,
                          width: 150,
                          height: 42,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final newName = nameController.text.trim();
                              final success = await updateRole(role.id, newName);
                              if (success) {
                                if (Get.isDialogOpen ?? false) {
                                  Get.back();
                                } else if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pop();
                                }
                                CustomSnackbar.showSuccess(
                                  title: 'Role Updated',
                                  message: 'Role updated to "$newName" successfully.',
                                );
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
      barrierDismissible: false,
    );
  }

  /// Confirm Delete Role
  void confirmDeleteRole(BuildContext context, RoleModel role) {
    if (!canDeleteRole) {
      CustomSnackbar.showWarning(
        title: 'Access Denied',
        message: 'You do not have permission to delete roles.',
      );
      return;
    }
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Delete Role'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the role "${role.roleName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
              } else {
                Get.back();
              }
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
              } else {
                Get.back();
              }
              deleteRole(role.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
