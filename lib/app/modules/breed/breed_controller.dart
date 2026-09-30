import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/values/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../data/models/breed_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Controller managing Breed Master state, operations, and navigation.
class BreedController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  // Static in-memory cache to prevent flickering / repeated loading animations on navigation
  static final List<BreedModel> _cachedBreeds = [];

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isSidebarCollapsed = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isSubmitting = false.obs;

  final RxList<BreedModel> breeds = <BreedModel>[].obs;
  final RxString searchQuery = ''.obs;

  // Pagination states
  final RxInt currentPage = 1.obs;
  final RxInt rowsPerPage = 5.obs;

  List<BreedModel> get filteredBreeds {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return breeds;
    return breeds.where((b) {
      final nameMatches = b.breedName.toLowerCase().contains(query);
      final idMatches = b.id.toLowerCase().contains(query);
      return nameMatches || idMatches;
    }).toList();
  }

  List<BreedModel> get paginatedBreeds {
    final list = filteredBreeds;
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

  int get totalPages => (filteredBreeds.isEmpty)
      ? 1
      : (filteredBreeds.length / rowsPerPage.value).ceil();

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
    if (_cachedBreeds.isNotEmpty) {
      breeds.assignAll(_cachedBreeds);
    }
    // Only show full loader if cache is empty, otherwise refresh silently in background
    fetchBreeds(showLoading: _cachedBreeds.isEmpty);
  }

  void _loadUser() {
    currentUser.value = _storageService.getUser();
  }

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  Future<void> logout() async {
    _cachedBreeds.clear();
    await _storageService.removeToken();
    await _storageService.removeUser();
    Get.offAllNamed(AppRoutes.auth);
  }

  /// Fetches all breeds from GET /api/v1/breed-types
  Future<void> fetchBreeds({
    bool showLoading = false,
    bool isManualRefresh = false,
  }) async {
    if (showLoading || breeds.isEmpty) {
      isLoading.value = true;
    }
    if (isManualRefresh) {
      isRefreshing.value = true;
    }
    try {
      final result = await _apiService.getBreedTypes();
      _cachedBreeds
        ..clear()
        ..addAll(result);
      breeds.assignAll(result);
      if (isManualRefresh) {
        CustomSnackbar.showSuccess(
          title: 'Refreshed',
          message: 'Breeds list updated successfully.',
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
  Future<void> refreshBreeds() async {
    if (isLoading.value || isRefreshing.value) return;
    await fetchBreeds(showLoading: true, isManualRefresh: true);
  }

  /// Creates a new breed via POST /api/v1/breed-types
  Future<bool> createBreed(String breedName) async {
    final trimmed = breedName.trim();
    if (trimmed.isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please enter a valid breed name.',
      );
      return false;
    }

    isSubmitting.value = true;
    try {
      final newBreed = await _apiService.createBreedType(trimmed);
      _cachedBreeds.insert(0, newBreed);
      breeds.insert(0, newBreed);
      CustomSnackbar.showSuccess(
        title: 'Breed Created',
        message: 'Breed "${newBreed.breedName}" was added successfully.',
      );
      return true;
    } catch (e) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Open Dialog to Add a New Breed
  void openAddBreedDialog(BuildContext context) {
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
                              PhosphorIconsRegular.dna,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Add New Breed',
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
                    'Register a new cattle breed type in the system.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: nameController,
                    label: 'Breed Name',
                    hint: 'e.g. Gir, Kankrej, Sahiwal, Red Sindhi',
                    prefixIcon: const Icon(Icons.pets_outlined, size: 20),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Breed name is required';
                      }
                      if (val.trim().length < 2) {
                        return 'Breed name must be at least 2 characters';
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
                          text: 'Create Breed',
                          icon: Icons.add_rounded,
                          isLoading: isSubmitting.value,
                          width: 155,
                          height: 42,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final success = await createBreed(nameController.text);
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
}
