import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../core/values/app_colors.dart';
import '../../core/values/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../data/models/gaushala_model.dart';
import '../../data/models/shed_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/gaushala_session_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Controller managing Sheds Master state, operations, and navigation.
class ShedController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();

  // Static in-memory cache to prevent flickering / repeated loading animations on navigation
  static final List<ShedModel> _cachedSheds = [];

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isSidebarCollapsed = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isSubmitting = false.obs;

  final RxList<ShedModel> sheds = <ShedModel>[].obs;
  final RxList<GaushalaModel> gaushalas = <GaushalaModel>[].obs;
  final RxBool isLoadingGaushalas = false.obs;
  final RxString searchQuery = ''.obs;
  final Rxn<String> selectedGaushalaFilter = Rxn<String>();

  // Pagination states
  final RxInt currentPage = 1.obs;
  final RxInt rowsPerPage = 5.obs;

  List<ShedModel> get filteredSheds {
    final query = searchQuery.value.trim().toLowerCase();
    final filterGId = selectedGaushalaFilter.value;

    return sheds.where((s) {
      // 1. Gaushala Filter
      if (filterGId != null && filterGId.isNotEmpty && filterGId != 'all') {
        final matchesId = s.gaushalaId == filterGId;
        final matchesName = s.gaushalaName != null &&
            gaushalas.any((g) => g.id == filterGId && g.gaushalaName.toLowerCase() == s.gaushalaName!.toLowerCase());
        if (!matchesId && !matchesName) {
          return false;
        }
      }

      // 2. Search Query Filter
      if (query.isEmpty) return true;
      final nameMatches = s.shedName.toLowerCase().contains(query);
      final numberMatches = s.shedNumber.toLowerCase().contains(query);
      final idMatches = s.id.toLowerCase().contains(query);
      final gaushalaMatches = (s.gaushalaName?.toLowerCase().contains(query) ?? false) ||
          gaushalas.any((g) => g.id == s.gaushalaId && g.gaushalaName.toLowerCase().contains(query));
      return nameMatches || numberMatches || idMatches || gaushalaMatches;
    }).toList();
  }

  List<ShedModel> get paginatedSheds {
    final list = filteredSheds;
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

  int get totalPages => (filteredSheds.isEmpty)
      ? 1
      : (filteredSheds.length / rowsPerPage.value).ceil();

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      currentPage.value = page;
    }
  }

  void setRowsPerPage(int count) {
    rowsPerPage.value = count;
    currentPage.value = 1;
  }

  void setGaushalaFilter(String? gaushalaId) {
    final cleanId = (gaushalaId == null || gaushalaId.isEmpty || gaushalaId == 'all')
        ? null
        : gaushalaId;
    if (selectedGaushalaFilter.value == cleanId) return;
    selectedGaushalaFilter.value = cleanId;
    currentPage.value = 1;
    fetchSheds(gaushalaId: cleanId, showLoading: true);
  }

  void clearFilters() {
    searchQuery.value = '';
    final hadGaushalaFilter = selectedGaushalaFilter.value != null;
    selectedGaushalaFilter.value = null;
    currentPage.value = 1;
    if (hadGaushalaFilter) {
      fetchSheds(gaushalaId: null, showLoading: true);
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    debounce(searchQuery, (_) => currentPage.value = 1, time: const Duration(milliseconds: 100));

    final initialGId = _gaushalaService.selectedGaushalaId;
    if (initialGId.isNotEmpty) {
      selectedGaushalaFilter.value = initialGId;
    }
    ever(_gaushalaService.selectedGaushala, (GaushalaModel? g) {
      if (g != null && g.id.isNotEmpty && selectedGaushalaFilter.value != g.id) {
        setGaushalaFilter(g.id);
      }
    });

    // Instantly hydrate existing data from cache if present
    if (_cachedSheds.isNotEmpty) {
      sheds.assignAll(_cachedSheds);
    }
    // Only show full loader if cache is empty, otherwise refresh silently in background
    fetchSheds(gaushalaId: initialGId.isNotEmpty ? initialGId : null, showLoading: _cachedSheds.isEmpty);
    fetchGaushalas();
  }

  void _loadUser() {
    currentUser.value = _storageService.getUser();
  }

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  Future<void> logout() async {
    _cachedSheds.clear();
    await _storageService.removeToken();
    await _storageService.removeUser();
    Get.offAllNamed(AppRoutes.auth);
  }

  /// Fetches sheds from GET /api/v1/sheds (supports filtering by gaushalaId)
  Future<void> fetchSheds({
    String? gaushalaId,
    bool showLoading = false,
    bool isManualRefresh = false,
  }) async {
    if (showLoading || sheds.isEmpty) {
      isLoading.value = true;
    }
    if (isManualRefresh) {
      isRefreshing.value = true;
    }
    try {
      final gId = gaushalaId ?? selectedGaushalaFilter.value;
      final result = await _apiService.getSheds(gaushalaId: gId);
      if (gId == null || gId.isEmpty || gId == 'all') {
        _cachedSheds
          ..clear()
          ..addAll(result);
      }
      sheds.assignAll(result);
      if (isManualRefresh) {
        CustomSnackbar.showSuccess(
          title: 'Refreshed',
          message: 'Sheds list updated successfully.',
        );
      }
    } catch (e) {
      // Handled by Dio interceptor
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// Fetches gaushalas for dropdown selection
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
  Future<void> refreshSheds() async {
    if (isLoading.value || isRefreshing.value) return;
    await Future.wait([
      fetchSheds(
        gaushalaId: selectedGaushalaFilter.value,
        showLoading: true,
        isManualRefresh: true,
      ),
      fetchGaushalas(),
    ]);
  }

  /// Creates a new shed via POST /api/v1/sheds
  Future<bool> createShed({
    required String shedName,
    required String shedNumber,
    String? gaushalaId,
  }) async {
    final trimmedName = shedName.trim();
    final trimmedNumber = shedNumber.trim().toUpperCase();

    if (trimmedName.isEmpty || trimmedNumber.isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please provide both Shed Name and Shed Number.',
      );
      return false;
    }

    if (gaushalaId == null || gaushalaId.trim().isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please select a Gaushala for this shed.',
      );
      return false;
    }

    isSubmitting.value = true;
    try {
      final newShed = await _apiService.createShed(
        shedName: trimmedName,
        shedNumber: trimmedNumber,
        gaushalaId: gaushalaId.trim(),
      );
      _cachedSheds.insert(0, newShed);
      sheds.insert(0, newShed);
      CustomSnackbar.showSuccess(
        title: 'Shed Created',
        message: 'Shed "${newShed.shedName}" ($trimmedNumber) was added successfully.',
      );
      fetchSheds(gaushalaId: selectedGaushalaFilter.value);
      return true;
    } catch (e) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Updates an existing shed via PUT /api/v1/sheds/:id
  Future<bool> updateShed(
    String id, {
    required String shedName,
    required String shedNumber,
    String? gaushalaId,
  }) async {
    final trimmedName = shedName.trim();
    final trimmedNumber = shedNumber.trim().toUpperCase();

    if (trimmedName.isEmpty || trimmedNumber.isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please provide both Shed Name and Shed Number.',
      );
      return false;
    }

    if (gaushalaId == null || gaushalaId.trim().isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please select a Gaushala for this shed.',
      );
      return false;
    }

    isSubmitting.value = true;
    try {
      final updated = await _apiService.updateShed(
        id,
        shedName: trimmedName,
        shedNumber: trimmedNumber,
        gaushalaId: gaushalaId.trim(),
      );
      final cacheIndex = _cachedSheds.indexWhere((s) => s.id == id);
      if (cacheIndex != -1) {
        _cachedSheds[cacheIndex] = updated;
      }
      final listIndex = sheds.indexWhere((s) => s.id == id);
      if (listIndex != -1) {
        sheds[listIndex] = updated;
      }
      CustomSnackbar.showSuccess(
        title: 'Shed Updated',
        message: 'Shed "${updated.shedName}" was updated successfully.',
      );
      return true;
    } catch (e) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Deletes a shed via DELETE /api/v1/sheds/:id
  Future<void> deleteShed(String id) async {
    isLoading.value = true;
    try {
      final success = await _apiService.deleteShed(id);
      if (success) {
        _cachedSheds.removeWhere((s) => s.id == id);
        sheds.removeWhere((s) => s.id == id);
        CustomSnackbar.showSuccess(
          title: 'Shed Deleted',
          message: 'Shed was removed successfully.',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      final list = gaushalas.toList();
      return DropdownSearch<GaushalaModel>(
        items: (filter, infiniteScrollProps) {
          if (filter.isEmpty) return list;
          return list
              .where((g) => g.gaushalaName.toLowerCase().contains(filter.toLowerCase()))
              .toList();
        },
        itemAsString: (g) => g.gaushalaName,
        compareFn: (g1, g2) => g1.id == g2.id,
        selectedItem: selectedGaushala.value,
        onSelected: (selected) {
          selectedGaushala.value = selected;
        },
        validator: (selected) {
          if (selected == null && selectedGaushala.value == null) {
            return 'Gaushala is required';
          }
          return null;
        },
        suffixProps: DropdownSuffixProps(
          dropdownButtonProps: DropdownButtonProps(
            iconClosed: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ),
        decoratorProps: DropDownDecoratorProps(
          baseStyle: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            labelText: 'Gaushala *',
            labelStyle: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            hintText: isLoadingGaushalas.value ? 'Loading gaushalas...' : 'Select Gaushala',
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            prefixIcon: const Icon(
              Icons.storefront_outlined,
              size: 20,
            ),
            filled: true,
            fillColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              borderSide: const BorderSide(
                color: AppColors.error,
              ),
            ),
          ),
        ),
        popupProps: PopupProps.menu(
          showSearchBox: list.length > 5,
          fit: FlexFit.loose,
          constraints: const BoxConstraints(maxHeight: 280),
          menuProps: MenuProps(
            backgroundColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            elevation: 4,
            barrierColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          searchFieldProps: TextFieldProps(
            autofocus: true,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: 'Search gaushala...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          itemBuilder: (ctx, item, isDisabled, isSelected) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
              child: Row(
                children: [
                  const Icon(Icons.storefront_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.gaushalaName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  /// Open Dialog to Add a New Shed
  void openAddShedDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final numberController = TextEditingController();

    if (gaushalas.isEmpty) {
      fetchGaushalas();
    }

    GaushalaModel? defaultGaushala;
    final userGId = currentUser.value?.gaushalaId;
    if (userGId != null && userGId.isNotEmpty) {
      defaultGaushala = gaushalas.firstWhereOrNull((g) => g.id == userGId);
    }
    if (defaultGaushala == null && gaushalas.length == 1) {
      defaultGaushala = gaushalas.first;
    }
    final Rxn<GaushalaModel> selectedGaushala = Rxn<GaushalaModel>(defaultGaushala);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
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
                              PhosphorIconsRegular.warehouse,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Add New Shed',
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
                    'Define a cattle housing shed or barn unit in the farm.',
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
                    label: 'Shed Name',
                    hint: 'e.g. North Shed, Milking Barn A',
                    prefixIcon: const Icon(Icons.warehouse_outlined, size: 20),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Shed name is required';
                      }
                      if (val.trim().length < 2) {
                        return 'Shed name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: numberController,
                    label: 'Shed Number / Code',
                    hint: 'e.g. SHED-001, SH-A1',
                    isUpperCase: true,
                    prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Shed number is required';
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
                          text: 'Create Shed',
                          icon: Icons.add_rounded,
                          isLoading: isSubmitting.value,
                          width: 145,
                          height: 42,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              if (selectedGaushala.value == null) {
                                CustomSnackbar.showError(
                                  title: 'Validation Error',
                                  message: 'Please select a Gaushala for this shed.',
                                );
                                return;
                              }
                              final success = await createShed(
                                shedName: nameController.text,
                                shedNumber: numberController.text,
                                gaushalaId: selectedGaushala.value!.id,
                              );
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

  /// Open Dialog to Edit Shed
  void openEditShedDialog(BuildContext context, ShedModel shed) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: shed.shedName);
    final numberController = TextEditingController(text: shed.shedNumber);

    if (gaushalas.isEmpty) {
      fetchGaushalas();
    }

    GaushalaModel? currentGaushala;
    if (shed.gaushalaId != null && shed.gaushalaId!.isNotEmpty) {
      currentGaushala = gaushalas.firstWhereOrNull((g) => g.id == shed.gaushalaId);
    }
    if (currentGaushala == null && shed.gaushalaName != null && shed.gaushalaName!.isNotEmpty) {
      currentGaushala = gaushalas.firstWhereOrNull((g) => g.gaushalaName.toLowerCase() == shed.gaushalaName!.toLowerCase());
    }
    final Rxn<GaushalaModel> selectedGaushala = Rxn<GaushalaModel>(currentGaushala);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
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
                            'Edit Shed',
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
                    'Update details for "${shed.shedName}".',
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
                    label: 'Shed Name',
                    hint: 'e.g. North Shed, Milking Barn A',
                    prefixIcon: const Icon(Icons.warehouse_outlined, size: 20),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Shed name is required';
                      }
                      if (val.trim().length < 2) {
                        return 'Shed name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: numberController,
                    label: 'Shed Number / Code',
                    hint: 'e.g. SHED-001, SH-A1',
                    isUpperCase: true,
                    prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Shed number is required';
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
                          width: 150,
                          height: 42,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              if (selectedGaushala.value == null) {
                                CustomSnackbar.showError(
                                  title: 'Validation Error',
                                  message: 'Please select a Gaushala for this shed.',
                                );
                                return;
                              }
                              final success = await updateShed(
                                shed.id,
                                shedName: nameController.text,
                                shedNumber: numberController.text,
                                gaushalaId: selectedGaushala.value!.id,
                              );
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

  /// Confirm Delete Shed
  void confirmDeleteShed(BuildContext context, ShedModel shed) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Delete Shed'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${shed.shedName}" (${shed.shedNumber})? This action cannot be undone.',
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
              deleteShed(shed.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
