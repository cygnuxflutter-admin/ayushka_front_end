import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/values/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/values/permission_constants.dart';
import '../../data/models/gaushala_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/gaushala_session_service.dart';
import '../../data/services/permission_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Controller managing Gaushalas Master state, operations, and navigation.
class GaushalaController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();
  final PermissionService? _permissionService =
      Get.isRegistered<PermissionService>() ? Get.find<PermissionService>() : null;

  bool get canAddGaushala =>
      _permissionService?.canAdd(PermissionModules.gaushala, PermissionSubModules.gaushalaList) ??
      (currentUser.value?.isAdmin ?? false);

  bool get canEditGaushala =>
      _permissionService?.canEdit(PermissionModules.gaushala, PermissionSubModules.gaushalaList) ??
      (currentUser.value?.isAdmin ?? false);

  bool get canDeleteGaushala =>
      _permissionService?.canDelete(PermissionModules.gaushala, PermissionSubModules.gaushalaList) ??
      (currentUser.value?.isAdmin ?? false);

  // Static in-memory cache to prevent flickering / repeated loading animations on navigation
  static final List<GaushalaModel> _cachedGaushalas = [];

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isSidebarCollapsed = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isSubmitting = false.obs;

  final RxList<GaushalaModel> gaushalas = <GaushalaModel>[].obs;
  final RxString searchQuery = ''.obs;

  // Pagination states
  final RxInt currentPage = 1.obs;
  final RxInt rowsPerPage = 5.obs;
  final RxInt mobileLimit = 10.obs;

  List<GaushalaModel> get mobileGaushalas => filteredGaushalas.take(mobileLimit.value).toList();
  bool get hasMoreMobile => mobileLimit.value < filteredGaushalas.length;

  void loadMoreMobile() {
    if (hasMoreMobile) {
      mobileLimit.value += 10;
    }
  }

  List<GaushalaModel> get filteredGaushalas {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return gaushalas;
    return gaushalas.where((g) {
      final nameMatches = g.gaushalaName.toLowerCase().contains(query);
      final idMatches = g.id.toLowerCase().contains(query);
      return nameMatches || idMatches;
    }).toList();
  }

  List<GaushalaModel> get paginatedGaushalas {
    final list = filteredGaushalas;
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

  int get totalPages => (filteredGaushalas.isEmpty)
      ? 1
      : (filteredGaushalas.length / rowsPerPage.value).ceil();

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
    debounce(searchQuery, (_) {
      currentPage.value = 1;
      mobileLimit.value = 10;
    }, time: const Duration(milliseconds: 100));
    // Instantly hydrate existing data from cache if present
    if (_cachedGaushalas.isNotEmpty) {
      gaushalas.assignAll(_cachedGaushalas);
    }
    // Only show full loader if cache is empty, otherwise refresh silently in background
    fetchGaushalas(showLoading: _cachedGaushalas.isEmpty);
  }

  void _loadUser() {
    currentUser.value = _storageService.getUser();
  }

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  Future<void> logout() async {
    _cachedGaushalas.clear();
    await _storageService.removeToken();
    await _storageService.removeUser();
    Get.offAllNamed(AppRoutes.auth);
  }

  /// Fetches all gaushalas from GET /api/v1/gaushalas
  Future<void> fetchGaushalas({
    bool showLoading = false,
    bool isManualRefresh = false,
  }) async {
    if (showLoading || gaushalas.isEmpty) {
      isLoading.value = true;
    }
    if (isManualRefresh) {
      isRefreshing.value = true;
    }
    try {
      final result = await _apiService.getGaushalas();
      _cachedGaushalas
        ..clear()
        ..addAll(result);
      gaushalas.assignAll(result);
      if (isManualRefresh) {
        CustomSnackbar.showSuccess(
          title: 'Refreshed',
          message: 'Gaushala list updated successfully.',
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
  Future<void> refreshGaushalas() async {
    if (isLoading.value || isRefreshing.value) return;
    await fetchGaushalas(showLoading: true, isManualRefresh: true);
  }

  /// Creates a new gaushala via POST /api/v1/gaushalas
  Future<bool> createGaushala(String gaushalaName) async {
    final trimmed = gaushalaName.trim();
    if (trimmed.isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please enter a valid gaushala name.',
      );
      return false;
    }

    isSubmitting.value = true;
    try {
      final newGaushala = await _apiService.createGaushala(trimmed);
      _cachedGaushalas.insert(0, newGaushala);
      gaushalas.insert(0, newGaushala);
      if (Get.isRegistered<GaushalaSessionService>()) {
        Get.find<GaushalaSessionService>().fetchGaushalas(forceReload: true);
      }
      CustomSnackbar.showSuccess(
        title: 'Gaushala Created',
        message: 'Gaushala "${newGaushala.gaushalaName}" was added successfully.',
      );
      return true;
    } catch (e) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Open Dialog to Add a New Gaushala
  void openAddGaushalaDialog(BuildContext context) {
    if (!canAddGaushala) {
      CustomSnackbar.showError(
        title: 'Access Denied',
        message: 'You do not have permission to add gaushalas.',
      );
      return;
    }
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
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
                              PhosphorIconsRegular.barn,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Add New Gaushala',
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
                    'Register a new farm or gaushala unit in the system.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: nameController,
                    label: 'Gaushala Name',
                    hint: 'e.g. north_farm, ayushka_navsari',
                    prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Gaushala name is required';
                      }
                      if (val.trim().length < 2) {
                        return 'Gaushala name must be at least 2 characters';
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
                          text: 'Create Gaushala',
                          icon: Icons.add_rounded,
                          isLoading: isSubmitting.value,
                          width: 165,
                          height: 42,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final success = await createGaushala(nameController.text);
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
}
