import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/values/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../data/models/type_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Controller managing Cattle Type Master state, operations, and navigation.
class TypeController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  // Static in-memory cache to prevent flickering / repeated loading animations on navigation
  static final List<TypeModel> _cachedTypes = [];

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isSidebarCollapsed = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isSubmitting = false.obs;

  final RxList<TypeModel> types = <TypeModel>[].obs;
  final RxString searchQuery = ''.obs;

  // Pagination states
  final RxInt currentPage = 1.obs;
  final RxInt rowsPerPage = 5.obs;

  List<TypeModel> get filteredTypes {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return types;
    return types.where((t) {
      final nameMatches = t.typeName.toLowerCase().contains(query);
      final idMatches = t.id.toLowerCase().contains(query);
      return nameMatches || idMatches;
    }).toList();
  }

  List<TypeModel> get paginatedTypes {
    final list = filteredTypes;
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

  int get totalPages => (filteredTypes.isEmpty)
      ? 1
      : (filteredTypes.length / rowsPerPage.value).ceil();

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      currentPage.value = page;
    }
  }

  void setRowsPerPage(int count) {
    rowsPerPage.value = count;
    currentPage.value = 1;
  }

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    debounce(searchQuery, (_) => currentPage.value = 1, time: const Duration(milliseconds: 100));
    // Instantly hydrate existing data from cache if present
    if (_cachedTypes.isNotEmpty) {
      types.assignAll(_cachedTypes);
    }
    // Only show full loader if cache is empty, otherwise refresh silently in background
    fetchTypes(showLoading: _cachedTypes.isEmpty);
  }

  void _loadUser() {
    currentUser.value = _storageService.getUser();
  }

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  Future<void> logout() async {
    _cachedTypes.clear();
    await _storageService.removeToken();
    await _storageService.removeUser();
    Get.offAllNamed(AppRoutes.auth);
  }

  /// Fetches all types from GET /api/v1/types
  Future<void> fetchTypes({
    bool showLoading = false,
    bool isManualRefresh = false,
  }) async {
    if (showLoading || types.isEmpty) {
      isLoading.value = true;
    }
    if (isManualRefresh) {
      isRefreshing.value = true;
    }
    try {
      final result = await _apiService.getTypes();
      _cachedTypes
        ..clear()
        ..addAll(result);
      types.assignAll(result);
      if (isManualRefresh) {
        CustomSnackbar.showSuccess(
          title: 'Refreshed',
          message: 'Types list updated successfully.',
        );
      }
    } catch (e) {
      // Dio interceptor handles network error snackbars
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// User-initiated refresh action (triggers shimmer + spinning icon)
  Future<void> refreshTypes() async {
    if (isLoading.value || isRefreshing.value) return;
    await fetchTypes(showLoading: true, isManualRefresh: true);
  }

  /// Creates a new type via POST /api/v1/types
  Future<bool> createType(String typeName) async {
    final trimmed = typeName.trim();
    if (trimmed.isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please enter a valid type name.',
      );
      return false;
    }

    isSubmitting.value = true;
    try {
      final newType = await _apiService.createType(trimmed);
      _cachedTypes.insert(0, newType);
      types.insert(0, newType);
      CustomSnackbar.showSuccess(
        title: 'Type Created',
        message: 'Type "${newType.typeName}" was added successfully.',
      );
      return true;
    } catch (e) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Updates an existing type via PUT /api/v1/types/:id
  Future<bool> updateType(String id, String typeName) async {
    final trimmed = typeName.trim();
    if (trimmed.isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please enter a valid type name.',
      );
      return false;
    }

    isSubmitting.value = true;
    try {
      final updated = await _apiService.updateType(id, trimmed);
      final index = types.indexWhere((t) => t.id == id);
      if (index != -1) {
        types[index] = updated;
      }
      final cacheIndex = _cachedTypes.indexWhere((t) => t.id == id);
      if (cacheIndex != -1) {
        _cachedTypes[cacheIndex] = updated;
      }
      CustomSnackbar.showSuccess(
        title: 'Type Updated',
        message: 'Type updated to "${updated.typeName}" successfully.',
      );
      return true;
    } catch (e) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Deletes a type via DELETE /api/v1/types/:id
  Future<void> deleteType(String id) async {
    isLoading.value = true;
    try {
      final success = await _apiService.deleteType(id);
      if (success) {
        types.removeWhere((t) => t.id == id);
        _cachedTypes.removeWhere((t) => t.id == id);
        CustomSnackbar.showSuccess(
          title: 'Type Deleted',
          message: 'Type was removed successfully.',
        );
      }
    } catch (e) {
      // Interceptor handles error
    } finally {
      isLoading.value = false;
    }
  }

  /// Open Dialog to Add a New Type
  void openAddTypeDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
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
                              PhosphorIconsRegular.tag,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Add New Type',
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
                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                          } else {
                            Get.back();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Register a new cattle classification type in the system.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: nameController,
                    label: 'Type Name',
                    hint: 'e.g. Milking, Dry, Pregnant, Heifer, Calf',
                    prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Type name is required';
                      }
                      if (val.trim().length < 2) {
                        return 'Type name must be at least 2 characters';
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
                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                          } else {
                            Get.back();
                          }
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      Obx(
                        () => CustomButton(
                          text: 'Create Type',
                          icon: Icons.add_rounded,
                          isLoading: isSubmitting.value,
                          width: 155,
                          height: 42,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final success = await createType(nameController.text);
                              if (success) {
                                if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pop();
                                } else {
                                  Get.back();
                                }
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

  /// Open Dialog to Edit Type
  void openEditTypeDialog(BuildContext context, TypeModel type) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: type.typeName);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
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
                            'Edit Type',
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
                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                          } else {
                            Get.back();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Update the classification name for "${type.typeName}".',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: nameController,
                    label: 'Type Name',
                    hint: 'e.g. Milking, Dry, Pregnant',
                    prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Type name is required';
                      }
                      if (val.trim().length < 2) {
                        return 'Type name must be at least 2 characters';
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
                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                          } else {
                            Get.back();
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
                          width: 155,
                          height: 42,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final success = await updateType(type.id, nameController.text);
                              if (success) {
                                if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pop();
                                } else {
                                  Get.back();
                                }
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

  /// Confirm Delete Type Dialog
  void confirmDeleteType(BuildContext context, TypeModel type) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Delete Type'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the type "${type.typeName}"? This action cannot be undone.',
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
              deleteType(type.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
