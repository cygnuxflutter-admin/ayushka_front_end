import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/values/app_colors.dart';
import '../../core/values/permission_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dropdown_search.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../data/models/gaushala_model.dart';
import '../../data/models/type_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/gaushala_session_service.dart';
import '../../data/services/permission_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'views/edit_type_screen.dart';

/// Controller managing Cattle Type Master state, operations, and navigation.
class TypeController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();
  final PermissionService? _permissionService =
      Get.isRegistered<PermissionService>() ? Get.find<PermissionService>() : null;

  bool get canAddType =>
      _permissionService?.canAdd(PermissionModules.type, PermissionSubModules.typeList) ??
      (currentUser.value?.isAdmin ?? false);

  bool get canEditType =>
      _permissionService?.canEdit(PermissionModules.type, PermissionSubModules.typeList) ??
      (currentUser.value?.isAdmin ?? false);

  bool get canDeleteType =>
      _permissionService?.canDelete(PermissionModules.type, PermissionSubModules.typeList) ??
      (currentUser.value?.isAdmin ?? false);

  // Static in-memory cache to prevent flickering / repeated loading animations on navigation
  static final List<TypeModel> _cachedTypes = [];
  static String? _cachedGaushalaId;

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isSidebarCollapsed = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isSubmitting = false.obs;

  final RxList<TypeModel> types = <TypeModel>[].obs;
  final RxList<GaushalaModel> gaushalas = <GaushalaModel>[].obs;
  final RxBool isLoadingGaushalas = false.obs;
  final RxString searchQuery = ''.obs;
  final Rxn<String> selectedGaushalaFilter = Rxn<String>();

  bool get canChangeGaushala => _gaushalaService.canChangeGaushala;

  String get selectedGaushalaName {
    final gId = selectedGaushalaFilter.value;
    if (gId != null && gId.isNotEmpty) {
      final g = findGaushala(gId);
      if (g != null) return g.gaushalaName;
    }
    return _gaushalaService.selectedGaushalaName;
  }

  GaushalaModel? findGaushala(String? idOrName) {
    if (idOrName == null || idOrName.isEmpty) return null;
    return gaushalas.firstWhereOrNull((g) => g.id == idOrName || g.gaushalaName == idOrName) ??
        _gaushalaService.findGaushala(idOrName);
  }

  // Pagination states
  final RxInt currentPage = 1.obs;
  final RxInt rowsPerPage = 5.obs;

  List<TypeModel> get filteredTypes {
    final query = searchQuery.value.trim().toLowerCase();
    final filterGId = selectedGaushalaFilter.value;

    return types.where((t) {
      // 1. Gaushala Filter
      if (filterGId != null && filterGId.isNotEmpty) {
        final matchesId = t.gaushalaId == filterGId;
        final matchesName = t.gaushalaName != null &&
            gaushalas.any((g) => g.id == filterGId && g.gaushalaName.toLowerCase() == t.gaushalaName!.toLowerCase());
        if (!matchesId && !matchesName) {
          return false;
        }
      }

      // 2. Search Query Filter
      if (query.isEmpty) return true;
      final nameMatches = t.typeName.toLowerCase().contains(query);
      final idMatches = t.id.toLowerCase().contains(query);
      final gaushalaMatches = (t.gaushalaName?.toLowerCase().contains(query) ?? false) ||
          gaushalas.any((g) => g.id == t.gaushalaId && g.gaushalaName.toLowerCase() == query);
      return nameMatches || idMatches || gaushalaMatches;
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

  // Mobile Continuous Scrolling
  final RxInt mobileLimit = 10.obs;
  List<TypeModel> get mobileTypes => filteredTypes.take(mobileLimit.value).toList();
  bool get hasMoreMobile => mobileLimit.value < filteredTypes.length;
  void loadMoreMobile() {
    if (hasMoreMobile) {
      mobileLimit.value += 10;
    }
  }

  void setGaushalaFilter(String? gaushalaId) {
    if (gaushalaId == null || gaushalaId.isEmpty || gaushalaId == 'all') return;
    if (selectedGaushalaFilter.value == gaushalaId) return;

    selectedGaushalaFilter.value = gaushalaId;
    currentPage.value = 1;
    mobileLimit.value = 10;

    // Sync global session if admin
    final match = findGaushala(gaushalaId);
    if (match != null && _gaushalaService.canChangeGaushala && _gaushalaService.selectedGaushalaId != gaushalaId) {
      _gaushalaService.setGaushala(match);
    }

    fetchTypes(gaushalaId: gaushalaId, showLoading: true);
  }

  void clearFilters() {
    searchQuery.value = '';
    currentPage.value = 1;
    mobileLimit.value = 10;
  }

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    debounce(searchQuery, (_) {
      currentPage.value = 1;
      mobileLimit.value = 10;
    }, time: const Duration(milliseconds: 100));

    // Listen to global AppBar gaushala changes
    ever(_gaushalaService.selectedGaushala, (GaushalaModel? g) {
      if (g != null && g.id.isNotEmpty && selectedGaushalaFilter.value != g.id) {
        selectedGaushalaFilter.value = g.id;
        currentPage.value = 1;
        mobileLimit.value = 10;
        fetchTypes(gaushalaId: g.id, showLoading: true);
      }
    });

    _initData();
  }

  Future<void> _initData() async {
    // 1. Ensure gaushalas are loaded
    if (_gaushalaService.gaushalas.isEmpty) {
      await _gaushalaService.initSession(user: currentUser.value);
    }
    await fetchGaushalas();

    // 2. Resolve target Gaushala ID (guaranteed valid specific gaushala)
    String targetGId = _gaushalaService.selectedGaushalaId;
    if (targetGId.isEmpty) {
      final defaultG = _gaushalaService.getUserDefaultGaushala(currentUser.value) ??
          (gaushalas.isNotEmpty ? gaushalas.first : null);
      if (defaultG != null) {
        targetGId = defaultG.id;
        _gaushalaService.selectedGaushala.value = defaultG;
      }
    }

    if (targetGId.isNotEmpty) {
      selectedGaushalaFilter.value = targetGId;
    }

    // 3. Hydrate cache if matching
    if (_cachedTypes.isNotEmpty && _cachedGaushalaId == targetGId) {
      types.assignAll(_cachedTypes);
    }

    if (targetGId.isNotEmpty) {
      await fetchTypes(gaushalaId: targetGId, showLoading: types.isEmpty);
    }
  }

  void _loadUser() {
    currentUser.value = _storageService.getUser();
  }

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  Future<void> logout() async {
    _cachedTypes.clear();
    _cachedGaushalaId = null;
    await _storageService.removeToken();
    await _storageService.removeUser();
    Get.offAllNamed(AppRoutes.auth);
  }

  /// Fetches types from GET /api/v1/types (requires valid gaushalaId)
  Future<void> fetchTypes({
    String? gaushalaId,
    bool showLoading = false,
    bool isManualRefresh = false,
  }) async {
    final gId = gaushalaId ?? selectedGaushalaFilter.value ?? _gaushalaService.selectedGaushalaId;
    if (gId.isEmpty || gId == 'all') {
      return;
    }

    if (showLoading || types.isEmpty) {
      isLoading.value = true;
    }
    if (isManualRefresh) {
      isRefreshing.value = true;
    }
    try {
      final result = await _apiService.getTypes(gaushalaId: gId);
      _cachedGaushalaId = gId;
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

  /// Fetches gaushalas for dropdown filter and selection
  Future<void> fetchGaushalas() async {
    isLoadingGaushalas.value = true;
    try {
      final result = await _apiService.getGaushalas();
      gaushalas.assignAll(result);
    } catch (e) {
      // Handled by Dio interceptor
    } finally {
      isLoadingGaushalas.value = false;
    }
  }

  /// User-initiated refresh action (triggers shimmer + spinning icon)
  Future<void> refreshTypes() async {
    if (isLoading.value || isRefreshing.value) return;
    mobileLimit.value = 10;
    await Future.wait([
      fetchTypes(
        gaushalaId: selectedGaushalaFilter.value,
        showLoading: true,
        isManualRefresh: true,
      ),
      fetchGaushalas(),
    ]);
  }

  /// Creates a new type via POST /api/v1/types
  Future<bool> createType(String typeName, {String? gaushalaId}) async {
    final trimmed = typeName.trim();
    if (trimmed.isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please enter a valid type name.',
      );
      return false;
    }

    final targetGaushalaId = (gaushalaId != null && gaushalaId.isNotEmpty)
        ? gaushalaId
        : (selectedGaushalaFilter.value ?? _gaushalaService.selectedGaushalaId);

    if (targetGaushalaId.isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please select a Gaushala for this type.',
      );
      return false;
    }

    isSubmitting.value = true;
    try {
      final newType = await _apiService.createType(trimmed, gaushalaId: targetGaushalaId);
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

  /// Updates an existing type via POST /api/v1/types/:id/update
  Future<bool> updateType(String id, String typeName, {String? gaushalaId}) async {
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
      final updated = await _apiService.updateType(id, trimmed, gaushalaId: gaushalaId);
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

  /// Reusable Gaushala Dropdown widget
  Widget _buildGaushalaDropdown({
    required BuildContext context,
    required Rxn<GaushalaModel> selectedGaushala,
  }) {
    return Obx(() {
      return CustomDropdownSearch<GaushalaModel>(
        label: 'Gaushala',
        isRequired: true,
        hint: isLoadingGaushalas.value ? 'Loading gaushalas...' : 'Select Gaushala',
        prefixIcon: Icons.storefront_outlined,
        selectedItem: selectedGaushala.value,
        items: gaushalas.toList(),
        itemAsString: (g) => g.gaushalaName,
        compareFn: (g1, g2) => g1.id == g2.id,
        searchable: true,
        searchHint: 'Search Gaushala...',
        onChanged: (selected) {
          selectedGaushala.value = selected;
        },
        validator: (selected) {
          if (selected == null && selectedGaushala.value == null) {
            return 'Gaushala is required';
          }
          return null;
        },
      );
    });
  }

  /// Open Dialog to Add a New Type
  void openAddTypeDialog(BuildContext context) {
    if (!canAddType) {
      CustomSnackbar.showWarning(
        title: 'Access Denied',
        message: 'You do not have permission to add cattle types.',
      );
      return;
    }
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();

    if (gaushalas.isEmpty) {
      fetchGaushalas();
    }

    GaushalaModel? defaultGaushala;
    final activeGId = selectedGaushalaFilter.value ?? _gaushalaService.selectedGaushalaId;
    if (activeGId.isNotEmpty) {
      defaultGaushala = gaushalas.firstWhereOrNull((g) => g.id == activeGId) ??
          _gaushalaService.findGaushala(activeGId);
    }
    final userGId = currentUser.value?.gaushalaId;
    if (defaultGaushala == null && userGId != null && userGId.isNotEmpty) {
      defaultGaushala = gaushalas.firstWhereOrNull((g) => g.id == userGId);
    }
    if (defaultGaushala == null && gaushalas.length == 1) {
      defaultGaushala = gaushalas.first;
    }
    final Rxn<GaushalaModel> selectedGaushala = Rxn<GaushalaModel>(defaultGaushala);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
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
                    'Register a new cattle classification type in the system.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 20),
                  _buildGaushalaDropdown(
                    context: context,
                    selectedGaushala: selectedGaushala,
                  ),
                  const SizedBox(height: 16),
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
                          text: 'Create Type',
                          icon: Icons.add_rounded,
                          isLoading: isSubmitting.value,
                          width: 155,
                          height: 42,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              if (selectedGaushala.value == null) {
                                CustomSnackbar.showError(
                                  title: 'Validation Error',
                                  message: 'Please select a Gaushala for this type.',
                                );
                                return;
                              }
                              final success = await createType(
                                nameController.text,
                                gaushalaId: selectedGaushala.value!.id,
                              );
                              if (success) {
                                if (Get.isDialogOpen ?? false) {
                                  Get.back();
                                } else if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pop();
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
    if (!canEditType) {
      CustomSnackbar.showWarning(
        title: 'Access Denied',
        message: 'You do not have permission to edit cattle types.',
      );
      return;
    }
    if (ResponsiveLayout.isMobile(context)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EditTypeScreen(type: type)),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: type.typeName);

    if (gaushalas.isEmpty) {
      fetchGaushalas();
    }

    GaushalaModel? initialGaushala;
    if (type.gaushalaId != null && type.gaushalaId!.isNotEmpty) {
      initialGaushala = gaushalas.firstWhereOrNull((g) => g.id == type.gaushalaId);
    }
    initialGaushala ??= _gaushalaService.selectedGaushala.value;
    final Rxn<GaushalaModel> selectedGaushala = Rxn<GaushalaModel>(initialGaushala);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
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
                    'Update the classification name for "${type.typeName}".',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 20),
                  _buildGaushalaDropdown(
                    context: context,
                    selectedGaushala: selectedGaushala,
                  ),
                  const SizedBox(height: 16),
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
                          width: 155,
                          height: 42,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final success = await updateType(
                                type.id,
                                nameController.text,
                                gaushalaId: selectedGaushala.value?.id,
                              );
                              if (success) {
                                if (Get.isDialogOpen ?? false) {
                                  Get.back();
                                } else if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pop();
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
    if (!canDeleteType) {
      CustomSnackbar.showWarning(
        title: 'Access Denied',
        message: 'You do not have permission to delete cattle types.',
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
