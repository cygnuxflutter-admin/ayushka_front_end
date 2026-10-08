import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/values/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../data/models/module_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';

/// Controller managing Module and Sub-Module Master state, operations, and navigation.
class ModuleController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  // Static in-memory cache to prevent flickering / repeated loading animations on navigation
  static final List<ModuleModel> _cachedModules = [];

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isSidebarCollapsed = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isSubmittingSubModule = false.obs;
  final RxBool isBulkImporting = false.obs;

  final RxList<ModuleModel> modules = <ModuleModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxString statusFilter = 'ALL'.obs; // 'ALL', 'ACTIVE', 'INACTIVE'

  // Pagination states
  final RxInt currentPage = 1.obs;
  final RxInt rowsPerPage = 10.obs;

  // Mobile Continuous Scrolling
  final RxInt mobileLimit = 10.obs;
  List<ModuleModel> get mobileModules => filteredModules.take(mobileLimit.value).toList();
  bool get hasMoreMobile => mobileLimit.value < filteredModules.length;

  void loadMoreMobile() {
    if (hasMoreMobile) {
      mobileLimit.value += 10;
    }
  }

  /// Filtered modules based on search query (name, code, description) and status filter
  List<ModuleModel> get filteredModules {
    final query = searchQuery.value.trim().toLowerCase();
    final filter = statusFilter.value;

    return modules.where((m) {
      final matchesStatus = filter == 'ALL' ||
          (filter == 'ACTIVE' && m.isActive) ||
          (filter == 'INACTIVE' && !m.isActive);

      if (!matchesStatus) return false;

      if (query.isEmpty) return true;

      final nameMatches = m.name.toLowerCase().contains(query);
      final codeMatches = m.code.toLowerCase().contains(query);
      final descMatches = m.description.toLowerCase().contains(query);

      return nameMatches || codeMatches || descMatches;
    }).toList();
  }

  /// Paginated list of modules for Desktop/Tablet view
  List<ModuleModel> get paginatedModules {
    final list = filteredModules;
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

  int get totalPages => (filteredModules.isEmpty)
      ? 1
      : (filteredModules.length / rowsPerPage.value).ceil();

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      currentPage.value = page;
    }
  }

  void setRowsPerPage(int count) {
    rowsPerPage.value = count;
    currentPage.value = 1;
  }

  void setStatusFilter(String filter) {
    statusFilter.value = filter;
    currentPage.value = 1;
    mobileLimit.value = 10;
  }

  @override
  void onInit() {
    super.onInit();
    _loadUser();

    // Verify admin privileges
    if (currentUser.value != null && !currentUser.value!.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        CustomSnackbar.showWarning(
          title: 'Access Restricted',
          message: 'Only Administrators can manage system modules.',
        );
        Get.offAllNamed(AppRoutes.dashboard);
      });
      return;
    }

    debounce(searchQuery, (_) {
      currentPage.value = 1;
      mobileLimit.value = 10;
    }, time: const Duration(milliseconds: 150));

    // Hydrate existing data from cache if present
    if (_cachedModules.isNotEmpty) {
      modules.assignAll(_cachedModules);
    }

    // Fetch fresh modules from backend
    fetchModules(showLoading: _cachedModules.isEmpty);
  }

  void _loadUser() {
    currentUser.value = _storageService.getUser();
  }

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  Future<void> logout() async {
    _cachedModules.clear();
    await _storageService.removeToken();
    await _storageService.removeUser();
    Get.offAllNamed(AppRoutes.auth);
  }

  // ---------------------------------------------------------------------------
  // API ACTIONS
  // ---------------------------------------------------------------------------

  /// Fetches all modules from GET /api/v1/modules
  Future<void> fetchModules({
    bool showLoading = false,
    bool isManualRefresh = false,
  }) async {
    if (showLoading || modules.isEmpty) {
      isLoading.value = true;
    }
    if (isManualRefresh) {
      isRefreshing.value = true;
    }

    try {
      final result = await _apiService.getModules();
      _cachedModules
        ..clear()
        ..addAll(result);
      modules.assignAll(result);

      if (isManualRefresh) {
        CustomSnackbar.showSuccess(
          title: 'Refreshed',
          message: 'Modules list updated successfully.',
        );
      }
    } catch (e) {
      // Dio interceptor handles network error snackbars
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// User-initiated refresh action
  Future<void> refreshModules() async {
    if (isLoading.value || isRefreshing.value) return;
    await fetchModules(showLoading: true, isManualRefresh: true);
  }

  /// Creates or updates a module
  Future<bool> saveModule({
    ModuleModel? existingModule,
    required String name,
    required String code,
    required String description,
    required bool isActive,
  }) async {
    final trimmedName = name.trim();
    final trimmedCode = code.trim().toUpperCase();
    final trimmedDesc = description.trim();

    if (trimmedName.isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Module name is required.',
      );
      return false;
    }

    if (trimmedCode.isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Module code is required.',
      );
      return false;
    }

    isSubmitting.value = true;
    try {
      if (existingModule != null) {
        // Update Module: PUT /api/v1/modules/:id
        final payload = {
          'name': trimmedName,
          'description': trimmedDesc,
          'isActive': isActive,
        };

        final updated = await _apiService.updateModule(existingModule.id, payload);
        final index = modules.indexWhere((m) => m.id == existingModule.id);
        if (index != -1) {
          modules[index] = updated;
        }
        final cacheIndex = _cachedModules.indexWhere((m) => m.id == existingModule.id);
        if (cacheIndex != -1) {
          _cachedModules[cacheIndex] = updated;
        }

        CustomSnackbar.showSuccess(
          title: 'Module Updated',
          message: 'Module "${updated.name}" was updated successfully.',
        );
      } else {
        // Create Module: POST /api/v1/modules
        final payload = {
          'name': trimmedName,
          'code': trimmedCode,
          'description': trimmedDesc,
          'isActive': isActive,
          'subModules': [],
        };

        final created = await _apiService.createModule(payload);
        _cachedModules.insert(0, created);
        modules.insert(0, created);

        CustomSnackbar.showSuccess(
          title: 'Module Created',
          message: 'Module "${created.name}" was registered successfully.',
        );
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Deletes a module by ID
  Future<bool> deleteModule(String id, {String? moduleName}) async {
    isSubmitting.value = true;
    try {
      final success = await _apiService.deleteModule(id);
      if (success) {
        modules.removeWhere((m) => m.id == id);
        _cachedModules.removeWhere((m) => m.id == id);
        CustomSnackbar.showSuccess(
          title: 'Module Deleted',
          message: moduleName != null
              ? 'Module "$moduleName" was deleted successfully.'
              : 'Module deleted successfully.',
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Adds a sub-module to an existing module
  Future<bool> addSubModule(
    String moduleId,
    String name,
    String code,
    String description,
  ) async {
    final trimmedName = name.trim();
    final trimmedCode = code.trim().toUpperCase();
    final trimmedDesc = description.trim();

    if (trimmedName.isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Sub-module name is required.',
      );
      return false;
    }

    if (trimmedCode.isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Sub-module code is required.',
      );
      return false;
    }

    isSubmittingSubModule.value = true;
    try {
      final payload = {
        'name': trimmedName,
        'code': trimmedCode,
        'description': trimmedDesc,
      };

      final updatedModule = await _apiService.addSubModule(moduleId, payload);
      final index = modules.indexWhere((m) => m.id == moduleId);
      if (index != -1) {
        modules[index] = updatedModule;
      }
      final cacheIndex = _cachedModules.indexWhere((m) => m.id == moduleId);
      if (cacheIndex != -1) {
        _cachedModules[cacheIndex] = updatedModule;
      }

      CustomSnackbar.showSuccess(
        title: 'Sub-module Added',
        message: 'Sub-module "$trimmedName" added successfully.',
      );
      return true;
    } catch (e) {
      return false;
    } finally {
      isSubmittingSubModule.value = false;
    }
  }

  /// Deletes a sub-module from an existing module
  Future<bool> deleteSubModule(String moduleId, String subModuleCode) async {
    isSubmittingSubModule.value = true;
    try {
      final updatedModule = await _apiService.deleteSubModule(moduleId, subModuleCode);
      final index = modules.indexWhere((m) => m.id == moduleId);
      if (index != -1) {
        modules[index] = updatedModule;
      }
      final cacheIndex = _cachedModules.indexWhere((m) => m.id == moduleId);
      if (cacheIndex != -1) {
        _cachedModules[cacheIndex] = updatedModule;
      }

      CustomSnackbar.showSuccess(
        title: 'Sub-module Deleted',
        message: 'Sub-module "$subModuleCode" deleted successfully.',
      );
      return true;
    } catch (e) {
      return false;
    } finally {
      isSubmittingSubModule.value = false;
    }
  }

  /// Bulk import modules from JSON string
  Future<bool> bulkImportModules(String jsonString) async {
    final trimmed = jsonString.trim();
    if (trimmed.isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please paste a valid JSON array of modules.',
      );
      return false;
    }

    List<dynamic> parsedList;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        parsedList = decoded;
      } else if (decoded is Map && decoded['modules'] is List) {
        parsedList = decoded['modules'] as List;
      } else {
        CustomSnackbar.showError(
          title: 'Invalid JSON Structure',
          message: 'The JSON must be an array of module objects [ {...}, {...} ].',
        );
        return false;
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'JSON Parse Error',
        message: 'Could not parse JSON: ${e.toString()}',
      );
      return false;
    }

    if (parsedList.isEmpty) {
      CustomSnackbar.showError(
        title: 'Empty Array',
        message: 'The JSON array contains no module items.',
      );
      return false;
    }

    // Validate schema
    final List<Map<String, dynamic>> validatedModules = [];
    for (int i = 0; i < parsedList.length; i++) {
      final item = parsedList[i];
      if (item is! Map) {
        CustomSnackbar.showError(
          title: 'Validation Error',
          message: 'Item #${i + 1} is not a valid JSON object.',
        );
        return false;
      }

      final name = item['name']?.toString().trim() ?? '';
      final code = item['code']?.toString().trim().toUpperCase() ?? '';

      if (name.isEmpty || code.isEmpty) {
        CustomSnackbar.showError(
          title: 'Validation Error',
          message: 'Item #${i + 1} is missing a required "name" or "code" attribute.',
        );
        return false;
      }

      validatedModules.add(Map<String, dynamic>.from(item));
    }

    isBulkImporting.value = true;
    try {
      final result = await _apiService.bulkCreateModules(validatedModules);
      await fetchModules(showLoading: false);

      CustomSnackbar.showSuccess(
        title: 'Bulk Import Successful',
        message: result.isNotEmpty
            ? 'Successfully imported ${result.length} modules.'
            : 'Successfully processed ${validatedModules.length} modules.',
      );
      return true;
    } catch (e) {
      return false;
    } finally {
      isBulkImporting.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // DIALOGS & MODALS
  // ---------------------------------------------------------------------------

  /// Open Dialog to Add a New Module
  void openAddModuleDialog(BuildContext context) {
    _openModuleFormDialog(context: context);
  }

  /// Open Dialog to Edit an Existing Module
  void openEditModuleDialog(BuildContext context, ModuleModel module) {
    _openModuleFormDialog(context: context, existingModule: module);
  }

  void _openModuleFormDialog({
    required BuildContext context,
    ModuleModel? existingModule,
  }) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existingModule?.name ?? '');
    final codeController = TextEditingController(text: existingModule?.code ?? '');
    final descController = TextEditingController(text: existingModule?.description ?? '');
    final RxBool isActive = (existingModule?.isActive ?? true).obs;

    final isEdit = existingModule != null;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
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
                            child: Icon(
                              isEdit
                                  ? PhosphorIconsRegular.pencilSimple
                                  : PhosphorIconsRegular.squaresFour,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEdit ? 'Edit Module' : 'Add New Module',
                            style: const TextStyle(
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
                    isEdit
                        ? 'Update details for "${existingModule.name}".'
                        : 'Define a new system module to group features and permissions.',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: nameController,
                    label: 'Module Name',
                    hint: 'e.g. Feed & Fodder Management',
                    prefixIcon: const Icon(PhosphorIconsRegular.cards, size: 18),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Module name is required';
                      }
                      if (val.trim().length < 2) {
                        return 'Module name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: codeController,
                    label: 'Module Code',
                    hint: 'e.g. FEED_STOCK',
                    prefixIcon: const Icon(PhosphorIconsRegular.barcode, size: 18),
                    isUpperCase: true,
                    readOnly: isEdit, // Code is immutable in edit mode per backend schema
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Module code is required';
                      }
                      if (!RegExp(r'^[A-Z0-9_]+$').hasMatch(val.trim())) {
                        return 'Code must contain only uppercase letters, numbers, and underscores';
                      }
                      return null;
                    },
                  ),
                  if (isEdit)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0, left: 4.0),
                      child: Text(
                        'Module code serves as a unique system identifier and cannot be modified.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                      ),
                    ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: descController,
                    label: 'Description',
                    hint: 'Brief description of features and responsibilities under this module',
                    prefixIcon: const Icon(PhosphorIconsRegular.textT, size: 18),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Module Status',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Obx(
                              () => Text(
                                isActive.value
                                    ? 'Active - accessible to authorized users'
                                    : 'Inactive - hidden from navigation & operations',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isActive.value
                                      ? AppColors.success
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Obx(
                          () => Switch(
                            value: isActive.value,
                            activeThumbColor: AppColors.primary,
                            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                            onChanged: (val) => isActive.value = val,
                          ),
                        ),
                      ],
                    ),
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
                          text: isEdit ? 'Save Changes' : 'Create Module',
                          icon: isEdit ? Icons.check_rounded : Icons.add_rounded,
                          isLoading: isSubmitting.value,
                          width: 155,
                          height: 42,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final success = await saveModule(
                                existingModule: existingModule,
                                name: nameController.text,
                                code: codeController.text,
                                description: descController.text,
                                isActive: isActive.value,
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

  /// Open Dialog to Manage Sub-modules of a selected Module
  void openSubModulesDialog(BuildContext context, ModuleModel initialModule) {
    final subNameController = TextEditingController();
    final subCodeController = TextEditingController();
    final subDescController = TextEditingController();
    final subFormKey = GlobalKey<FormState>();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Obx(() {
            // Dynamically observe the latest state of this module
            final currentModule = modules.firstWhere(
              (m) => m.id == initialModule.id,
              orElse: () => initialModule,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
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
                              PhosphorIconsRegular.stack,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${currentModule.name} - Sub-modules',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  currentModule.code,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
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
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Sub-modules Table or Empty list
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Existing Sub-modules',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${currentModule.subModules.length} Sub-modules',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (currentModule.subModules.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        children: const [
                          Icon(PhosphorIconsRegular.fileDashed, size: 32, color: AppColors.textMutedLight),
                          SizedBox(height: 8),
                          Text(
                            'No sub-modules configured yet.',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Add the first sub-module using the form below.',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentModule.subModules.length,
                        separatorBuilder: (context, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final sub = currentModule.subModules[index];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                PhosphorIconsRegular.tag,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  sub.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    sub.code,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: sub.description.isNotEmpty
                                ? Text(
                                    sub.description,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  )
                                : null,
                            trailing: IconButton(
                              icon: const Icon(PhosphorIconsRegular.trash, size: 18, color: AppColors.error),
                              tooltip: 'Delete Sub-module',
                              onPressed: isSubmittingSubModule.value
                                  ? null
                                  : () => confirmDeleteSubModule(context, currentModule.id, sub),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Inline Form to Add New Sub-module
                  const Text(
                    'Add New Sub-module',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: subFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: CustomTextField(
                                controller: subNameController,
                                label: 'Sub-module Name',
                                hint: 'e.g. Feed Items',
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Name required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: CustomTextField(
                                controller: subCodeController,
                                label: 'Sub-module Code',
                                hint: 'e.g. FEED_ITEMS',
                                isUpperCase: true,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Code required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: subDescController,
                          label: 'Description',
                          hint: 'Brief description of this sub-module',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: CustomButton(
                            text: 'Add Sub-module',
                            icon: Icons.add_rounded,
                            isLoading: isSubmittingSubModule.value,
                            width: 160,
                            height: 38,
                            onPressed: () async {
                              if (subFormKey.currentState?.validate() ?? false) {
                                final success = await addSubModule(
                                  currentModule.id,
                                  subNameController.text,
                                  subCodeController.text,
                                  subDescController.text,
                                );
                                if (success) {
                                  subNameController.clear();
                                  subCodeController.clear();
                                  subDescController.clear();
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Open Dialog for Bulk Importing Modules via JSON
  void openBulkImportDialog(BuildContext context) {
    final jsonController = TextEditingController();

    const sampleJson = '''[
  {
    "name": "Feed & Fodder Management",
    "code": "FEED_STOCK",
    "description": "Manage cow chara/feed items and stock transactions",
    "isActive": true,
    "subModules": [
      { "name": "Feed Items", "code": "FEED_ITEMS", "description": "Manage feed items" },
      { "name": "Stock Transactions", "code": "FEED_TRANSACTIONS", "description": "Track stock transactions" }
    ]
  },
  {
    "name": "Medical & Health Management",
    "code": "MEDICAL",
    "description": "Veterinary medical inventory and cattle treatments",
    "isActive": true,
    "subModules": [
      { "name": "Medical Items", "code": "MED_ITEMS", "description": "Medicine inventory" },
      { "name": "Treatments", "code": "TREATMENTS", "description": "Cattle medical logs" }
    ]
  }
]''';

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
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
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            PhosphorIconsRegular.fileCode,
                            color: AppColors.accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Bulk Import Modules (JSON)',
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
                  'Paste a JSON array of module objects for bulk insert or synchronization.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'JSON Payload',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    TextButton.icon(
                      icon: const Icon(PhosphorIconsRegular.lightning, size: 14),
                      label: const Text('Load Sample Template', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        jsonController.text = sampleJson;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                TextField(
                  controller: jsonController,
                  maxLines: 12,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                  ),
                  decoration: InputDecoration(
                    hintText: '[\n  {\n    "name": "...",\n    "code": "...",\n    "description": "...",\n    "isActive": true\n  }\n]',
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
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
                        text: 'Validate & Import',
                        icon: PhosphorIconsRegular.fileArrowUp,
                        isLoading: isBulkImporting.value,
                        width: 175,
                        height: 42,
                        onPressed: () async {
                          final success = await bulkImportModules(jsonController.text);
                          if (success) {
                            if (Get.isDialogOpen ?? false) {
                              Get.back();
                            } else if (context.mounted) {
                              Navigator.of(context, rootNavigator: true).pop();
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
      barrierDismissible: false,
    );
  }

  /// Confirm Delete Module dialog
  void confirmDeleteModule(BuildContext context, ModuleModel module) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Delete Module'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete module "${module.name}" (${module.code})?',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone and will permanently remove this module and all its associated sub-modules.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
            ),
          ],
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
          Obx(
            () => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: isSubmitting.value
                  ? null
                  : () async {
                      final success = await deleteModule(module.id, moduleName: module.name);
                      if (success) {
                        if (Get.isDialogOpen ?? false) {
                          Get.back();
                        } else if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }
                      }
                    },
              child: isSubmitting.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Delete Module'),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirm Delete Sub-module dialog
  void confirmDeleteSubModule(
    BuildContext context,
    String moduleId,
    SubModuleModel subModule,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Delete Sub-module'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete sub-module "${subModule.name}" (${subModule.code})?',
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
          Obx(
            () => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: isSubmittingSubModule.value
                  ? null
                  : () async {
                      final success = await deleteSubModule(moduleId, subModule.code);
                      if (success) {
                        if (Get.isDialogOpen ?? false) {
                          Get.back();
                        } else if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }
                      }
                    },
              child: isSubmittingSubModule.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }
}
