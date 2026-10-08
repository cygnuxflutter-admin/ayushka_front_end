import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/values/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dropdown_search.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../data/models/feed_item_model.dart';
import '../../data/models/gaushala_model.dart';
import '../../data/models/user_model.dart';
import '../../core/values/permission_constants.dart';
import '../../data/services/api_service.dart';
import '../../data/services/gaushala_session_service.dart';
import '../../data/services/permission_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';
import 'views/edit_feed_item_screen.dart';

/// Controller managing Feed Stock Items Master state, operations, and dialogs.
class FeedItemController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();
  final PermissionService? _permissionService =
      Get.isRegistered<PermissionService>() ? Get.find<PermissionService>() : null;

  bool get canAddFeedItem =>
      _permissionService?.canAdd(PermissionModules.feedStock, PermissionSubModules.feedItems) ??
      (currentUser.value?.isAdmin ?? false);

  bool get canEditFeedItem =>
      _permissionService?.canEdit(PermissionModules.feedStock, PermissionSubModules.feedItems) ??
      (currentUser.value?.isAdmin ?? false);

  bool get canDeleteFeedItem =>
      _permissionService?.canDelete(PermissionModules.feedStock, PermissionSubModules.feedItems) ??
      (currentUser.value?.isAdmin ?? false);

  // Static in-memory cache to prevent flickering on repeated navigation
  static final List<FeedItemModel> _cachedFeedItems = [];
  static String? _cachedGaushalaId;

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isSidebarCollapsed = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isSubmitting = false.obs;

  final RxList<FeedItemModel> feedItems = <FeedItemModel>[].obs;
  final RxList<GaushalaModel> gaushalas = <GaushalaModel>[].obs;
  final RxBool isLoadingGaushalas = false.obs;

  // Filter states
  final RxString searchQuery = ''.obs;
  final Rxn<String> selectedGaushalaFilter = Rxn<String>();
  final RxString selectedCategoryFilter = 'ALL'.obs;
  final RxString selectedStockFilter = 'ALL'.obs; // ALL, LOW_STOCK, IN_STOCK, OUT_OF_STOCK
  final RxString selectedStatusFilter = 'ALL'.obs; // ALL, ACTIVE, INACTIVE

  bool get canChangeGaushala => _gaushalaService.canChangeGaushala;
  bool get isSuperAdmin => _gaushalaService.isSuperAdmin;

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

  // Mobile infinite scroll state
  final RxInt mobileLimit = 10.obs;

  List<FeedItemModel> get mobileFeedItems {
    final list = filteredFeedItems;
    return list.take(mobileLimit.value).toList();
  }

  bool get hasMoreMobile => mobileLimit.value < filteredFeedItems.length;

  void loadMoreMobile() {
    if (hasMoreMobile) {
      mobileLimit.value += 10;
    }
  }

  void resetMobileLimit() {
    mobileLimit.value = 10;
  }

  // Metrics
  int get totalItemsCount => feedItems.length;
  int get lowStockCount => feedItems.where((i) => i.isLowStock).length;
  int get activeItemsCount => feedItems.where((i) => i.isActive).length;

  List<FeedItemModel> get filteredFeedItems {
    final query = searchQuery.value.trim().toLowerCase();
    final filterGId = selectedGaushalaFilter.value;
    final categoryFilter = selectedCategoryFilter.value;
    final stockFilter = selectedStockFilter.value;
    final statusFilter = selectedStatusFilter.value;

    return feedItems.where((item) {
      // 1. Gaushala Filter
      if (filterGId != null && filterGId.isNotEmpty && filterGId != 'all') {
        final matchesId = item.gaushalaId == filterGId;
        final matchesName = item.gaushalaName != null &&
            gaushalas.any((g) => g.id == filterGId && g.gaushalaName.toLowerCase() == item.gaushalaName!.toLowerCase());
        if (!matchesId && !matchesName) {
          return false;
        }
      }

      // 2. Category Filter
      if (categoryFilter != 'ALL' && item.category != categoryFilter) {
        return false;
      }

      // 3. Stock Level Filter
      if (stockFilter == 'LOW_STOCK' && !item.isLowStock) {
        return false;
      } else if (stockFilter == 'OUT_OF_STOCK' && !item.isOutOfStock) {
        return false;
      } else if (stockFilter == 'IN_STOCK' && item.isOutOfStock) {
        return false;
      }

      // 4. Status Filter
      if (statusFilter == 'ACTIVE' && !item.isActive) {
        return false;
      } else if (statusFilter == 'INACTIVE' && item.isActive) {
        return false;
      }

      // 5. Search Query Filter
      if (query.isNotEmpty) {
        final nameMatches = item.itemName.toLowerCase().contains(query);
        final codeMatches = item.itemCode.toLowerCase().contains(query);
        final idMatches = item.id.toLowerCase().contains(query);
        final categoryMatches = item.category.toLowerCase().contains(query) ||
            item.categoryEnum.label.toLowerCase().contains(query);
        final descMatches = item.description.toLowerCase().contains(query);
        final gaushalaMatches = (item.gaushalaName?.toLowerCase().contains(query) ?? false) ||
            gaushalas.any((g) => g.id == item.gaushalaId && g.gaushalaName.toLowerCase() == query);

        if (!nameMatches && !codeMatches && !idMatches && !categoryMatches && !descMatches && !gaushalaMatches) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<FeedItemModel> get paginatedFeedItems {
    final list = filteredFeedItems;
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

  int get totalPages => (filteredFeedItems.isEmpty)
      ? 1
      : (filteredFeedItems.length / rowsPerPage.value).ceil();

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
    if (!isSuperAdmin) return;
    if (gaushalaId == null || gaushalaId.isEmpty || gaushalaId == 'all') return;
    if (selectedGaushalaFilter.value == gaushalaId) return;

    selectedGaushalaFilter.value = gaushalaId;
    currentPage.value = 1;
    resetMobileLimit();

    final match = findGaushala(gaushalaId);
    if (match != null && _gaushalaService.canChangeGaushala && _gaushalaService.selectedGaushalaId != gaushalaId) {
      _gaushalaService.setGaushala(match);
    }

    fetchFeedItems(gaushalaId: gaushalaId, showLoading: true);
  }

  void setCategoryFilter(String category) {
    selectedCategoryFilter.value = category;
    currentPage.value = 1;
    resetMobileLimit();
  }

  void setStockFilter(String stockStatus) {
    selectedStockFilter.value = stockStatus;
    currentPage.value = 1;
    resetMobileLimit();
  }

  void setStatusFilter(String status) {
    selectedStatusFilter.value = status;
    currentPage.value = 1;
    resetMobileLimit();
  }

  void clearFilters() {
    searchQuery.value = '';
    selectedCategoryFilter.value = 'ALL';
    selectedStockFilter.value = 'ALL';
    selectedStatusFilter.value = 'ALL';
    currentPage.value = 1;
    resetMobileLimit();
  }

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    debounce(searchQuery, (_) {
      currentPage.value = 1;
      resetMobileLimit();
    }, time: const Duration(milliseconds: 100));

    // Listen to global AppBar gaushala switch
    ever(_gaushalaService.selectedGaushala, (GaushalaModel? g) {
      if (g != null && g.id.isNotEmpty && selectedGaushalaFilter.value != g.id) {
        selectedGaushalaFilter.value = g.id;
        currentPage.value = 1;
        resetMobileLimit();
        fetchFeedItems(gaushalaId: g.id, showLoading: true);
      }
    });

    _initData();
  }

  Future<void> _initData() async {
    if (_gaushalaService.gaushalas.isEmpty) {
      await _gaushalaService.initSession(user: currentUser.value);
    }
    await fetchGaushalas();

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

    if (_cachedFeedItems.isNotEmpty && _cachedGaushalaId == targetGId) {
      feedItems.assignAll(_cachedFeedItems);
    }

    if (targetGId.isNotEmpty) {
      await fetchFeedItems(gaushalaId: targetGId, showLoading: feedItems.isEmpty);
    }
  }

  void _loadUser() {
    currentUser.value = _storageService.getUser();
  }

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  Future<void> logout() async {
    _cachedFeedItems.clear();
    _cachedGaushalaId = null;
    await _storageService.removeToken();
    await _storageService.removeUser();
    Get.offAllNamed(AppRoutes.auth);
  }

  /// Fetches feed items from GET /api/v1/feed-stock/items
  Future<void> fetchFeedItems({
    String? gaushalaId,
    bool showLoading = false,
    bool isManualRefresh = false,
  }) async {
    final gId = gaushalaId ?? selectedGaushalaFilter.value ?? _gaushalaService.selectedGaushalaId;

    if (showLoading || feedItems.isEmpty) {
      isLoading.value = true;
    }
    if (isManualRefresh) {
      isRefreshing.value = true;
    }

    try {
      final result = await _apiService.getFeedItems(
        gaushalaId: (gId.isNotEmpty && gId != 'all') ? gId : null,
      );
      _cachedGaushalaId = gId;
      _cachedFeedItems
        ..clear()
        ..addAll(result);
      feedItems.assignAll(result);

      if (isManualRefresh) {
        CustomSnackbar.showSuccess(
          title: 'Refreshed',
          message: 'Feed items list updated successfully.',
        );
      }
    } catch (e) {
      // Handled by Dio interceptor
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

  /// User-initiated refresh action
  Future<void> refreshFeedItems() async {
    if (isLoading.value || isRefreshing.value) return;
    await Future.wait([
      fetchFeedItems(
        gaushalaId: selectedGaushalaFilter.value,
        showLoading: true,
        isManualRefresh: true,
      ),
      fetchGaushalas(),
    ]);
  }

  /// Creates a new feed item via POST /api/v1/feed-stock/items
  Future<bool> createFeedItem({
    required String gaushalaId,
    required String itemName,
    String? itemCode,
    required String category,
    required String unit,
    double initialStock = 0.0,
    double minStockAlert = 50.0,
    double unitPrice = 0.0,
    String? description,
    bool isActive = true,
  }) async {
    final trimmedName = itemName.trim();
    if (trimmedName.isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please enter a valid item name.',
      );
      return false;
    }

    final targetGaushalaId = gaushalaId.trim().isNotEmpty
        ? gaushalaId.trim()
        : (selectedGaushalaFilter.value ?? _gaushalaService.selectedGaushalaId);

    if (targetGaushalaId.isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please select a Gaushala for this feed item.',
      );
      return false;
    }

    isSubmitting.value = true;
    try {
      final newItem = await _apiService.createFeedItem(
        gaushalaId: targetGaushalaId,
        itemName: trimmedName,
        itemCode: itemCode?.trim(),
        category: category,
        unit: unit,
        initialStock: initialStock,
        minStockAlert: minStockAlert,
        unitPrice: unitPrice,
        description: description?.trim(),
        isActive: isActive,
      );

      _cachedFeedItems.insert(0, newItem);
      feedItems.insert(0, newItem);
      feedItems.refresh();
      return true;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Creation Failed',
        message: e is DioException
            ? (e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to create feed item.')
            : e.toString(),
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Updates an existing feed item via POST /api/v1/feed-stock/items/:id/update (supports partial updates)
  Future<bool> updateFeedItem(
    String id, {
    String? itemName,
    String? itemCode,
    String? category,
    String? unit,
    double? minStockAlert,
    double? unitPrice,
    String? description,
    bool? isActive,
    String? gaushalaId,
  }) async {
    final trimmedName = itemName?.trim();
    if (trimmedName != null && trimmedName.isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please enter a valid item name.',
      );
      return false;
    }

    isSubmitting.value = true;
    try {
      final updated = await _apiService.updateFeedItem(
        id,
        itemName: trimmedName,
        itemCode: itemCode?.trim(),
        category: category,
        unit: unit,
        minStockAlert: minStockAlert,
        unitPrice: unitPrice,
        description: description?.trim(),
        isActive: isActive,
        gaushalaId: gaushalaId,
      );

      final index = feedItems.indexWhere((i) => i.id == id);
      if (index != -1) {
        feedItems[index] = updated;
      }
      final cacheIndex = _cachedFeedItems.indexWhere((i) => i.id == id);
      if (cacheIndex != -1) {
        _cachedFeedItems[cacheIndex] = updated;
      }
      feedItems.refresh();

      return true;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Update Failed',
        message: e is DioException
            ? (e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to update feed item.')
            : e.toString(),
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Quick toggle active status for a feed item (Partial update {"isActive": bool})
  Future<bool> toggleFeedItemStatus(FeedItemModel item) async {
    try {
      final updated = await _apiService.updateFeedItem(
        item.id,
        isActive: !item.isActive,
      );

      final index = feedItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        feedItems[index] = updated;
      }
      final cacheIndex = _cachedFeedItems.indexWhere((i) => i.id == item.id);
      if (cacheIndex != -1) {
        _cachedFeedItems[cacheIndex] = updated;
      }
      feedItems.refresh();

      CustomSnackbar.showSuccess(
        title: 'Status Updated',
        message: 'Feed item "${updated.itemName}" is now ${updated.isActive ? "Active" : "Inactive"}.',
      );
      return true;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Status Update Failed',
        message: e is DioException
            ? (e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to update status.')
            : e.toString(),
      );
      return false;
    }
  }

  /// Deletes a feed item via DELETE /api/v1/feed-stock/items/:id
  Future<void> deleteFeedItem(String id) async {
    if (!canDeleteFeedItem) {
      CustomSnackbar.showError(
        title: 'Access Denied',
        message: 'You do not have permission to delete feed items.',
      );
      return;
    }
    isLoading.value = true;
    try {
      final success = await _apiService.deleteFeedItem(id);
      if (success) {
        feedItems.removeWhere((i) => i.id == id);
        _cachedFeedItems.removeWhere((i) => i.id == id);
        CustomSnackbar.showSuccess(
          title: 'Item Deleted',
          message: 'Feed item removed successfully.',
        );
      }
    } catch (e) {
      // Handled by Dio interceptor
    } finally {
      isLoading.value = false;
    }
  }

  // -------------------------------------------------------------
  // DIALOGS: ADD / EDIT / DELETE / VIEW
  // -------------------------------------------------------------

  /// Opens the Add Feed Item modal dialog
  void openAddFeedItemDialog(BuildContext context) {
    if (!canAddFeedItem) {
      CustomSnackbar.showError(
        title: 'Access Denied',
        message: 'You do not have permission to add feed items.',
      );
      return;
    }
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final initialStockController = TextEditingController(text: '0');
    final minStockController = TextEditingController(text: '100');
    final descController = TextEditingController();

    final Rx<FeedItemCategory> selectedCat = FeedItemCategory.greenFodder.obs;
    final Rx<FeedItemUnit> selectedUnit = FeedItemUnit.kg.obs;
    final RxBool isActive = true.obs;

    final defaultG = _gaushalaService.getUserDefaultGaushala() ?? _gaushalaService.selectedGaushala.value;
    final targetGaushalaId = (isSuperAdmin ? selectedGaushalaFilter.value : null) ?? defaultG?.id ?? _gaushalaService.selectedGaushalaId;
    final Rxn<GaushalaModel> selectedGaushala = Rxn<GaushalaModel>(findGaushala(targetGaushalaId) ?? defaultG);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        elevation: 12,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 820),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.grains,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Feed Item',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Create a new feed, fodder, or supplement item master record',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        tooltip: 'Close',
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 18),

                  // Form Fields (Scrollable)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Gaushala Dropdown
                          _buildGaushalaDropdown(isDark, selectedGaushala),
                          const SizedBox(height: 16),

                          // 2. Item Name & Item Code
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: CustomTextField(
                                  label: 'Item Name *',
                                  hint: 'e.g. Green Maize Fodder',
                                  controller: nameController,
                                  prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Item name is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 4,
                                child: CustomTextField(
                                  label: 'Item Code',
                                  hint: 'e.g. GF-001',
                                  controller: codeController,
                                  isUpperCase: true,
                                  prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 3. Category & Unit Selection
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Obx(() => _buildCategoryDropdown(isDark, selectedCat)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Obx(() => _buildUnitDropdown(isDark, selectedUnit)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 4. Stock Settings (Initial Stock, Min Stock Alert)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  label: 'Initial Stock',
                                  hint: '0',
                                  controller: initialStockController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                  prefixIcon: const Icon(Icons.warehouse_outlined, size: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomTextField(
                                  label: 'Min Stock Alert *',
                                  hint: '50',
                                  controller: minStockController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                  prefixIcon: const Icon(Icons.notification_important_outlined, size: 20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 5. Description
                          CustomTextField(
                            label: 'Description',
                            hint: 'Optional notes or specifications...',
                            controller: descController,
                            maxLines: 2,
                            prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                          ),
                          const SizedBox(height: 12),

                          // 6. Active Toggle
                          Obx(
                            () => SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Active Status',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                              subtitle: Text(
                                isActive.value ? 'Item is active and available for feeding' : 'Item is inactive / archived',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              value: isActive.value,
                              activeTrackColor: AppColors.primary,
                              onChanged: (val) => isActive.value = val,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      Obx(
                        () => CustomButton(
                          text: 'Save Feed Item',
                          icon: Icons.check_rounded,
                          isLoading: isSubmitting.value,
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final gId = selectedGaushala.value?.id ?? targetGaushalaId;
                            if (gId.isEmpty) {
                              CustomSnackbar.showError(
                                title: 'Validation Error',
                                message: 'Please select a Gaushala.',
                              );
                              return;
                            }

                            final double initialStock = double.tryParse(initialStockController.text.trim()) ?? 0.0;
                            final double minStock = double.tryParse(minStockController.text.trim()) ?? 50.0;

                            final success = await createFeedItem(
                              gaushalaId: gId,
                              itemName: nameController.text.trim(),
                              itemCode: codeController.text.trim(),
                              category: selectedCat.value.code,
                              unit: selectedUnit.value.code,
                              initialStock: initialStock,
                              minStockAlert: minStock,
                              unitPrice: 0.0,
                              description: descController.text.trim(),
                              isActive: isActive.value,
                            );

                            if (success) {
                              if (Get.isDialogOpen ?? false) {
                                Get.back();
                              } else if (context.mounted) {
                                Navigator.of(context, rootNavigator: true).pop();
                              }
                              CustomSnackbar.showSuccess(
                                title: 'Item Created',
                                message: 'Feed item "${nameController.text.trim()}" was created successfully.',
                              );
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

  /// Opens the Edit Feed Item modal dialog
  void openEditFeedItemDialog(BuildContext context, FeedItemModel item) {
    if (!canEditFeedItem) {
      CustomSnackbar.showError(
        title: 'Access Denied',
        message: 'You do not have permission to edit feed items.',
      );
      return;
    }
    if (ResponsiveLayout.isMobile(context)) {
      Get.to(() => EditFeedItemScreen(item: item));
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item.itemName);
    final codeController = TextEditingController(text: item.itemCode);
    final minStockController = TextEditingController(text: item.minStockAlert.toStringAsFixed(item.minStockAlert.truncateToDouble() == item.minStockAlert ? 0 : 2));
    final descController = TextEditingController(text: item.description);

    final Rx<FeedItemCategory> selectedCat = item.categoryEnum.obs;
    final Rx<FeedItemUnit> selectedUnit = item.unitEnum.obs;
    final RxBool isActive = item.isActive.obs;

    final targetGaushalaId = item.gaushalaId ?? selectedGaushalaFilter.value ?? _gaushalaService.selectedGaushalaId;
    final Rxn<GaushalaModel> selectedGaushala = Rxn<GaushalaModel>(findGaushala(targetGaushalaId));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        elevation: 12,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 780),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.pencilSimple,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Feed Item',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Update item details, category, alerts, and pricing',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        tooltip: 'Close',
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 18),

                  // Form Fields (Scrollable)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Gaushala Dropdown
                          _buildGaushalaDropdown(isDark, selectedGaushala),
                          const SizedBox(height: 16),

                          // 2. Item Name & Item Code
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: CustomTextField(
                                  label: 'Item Name *',
                                  hint: 'e.g. Green Maize Fodder',
                                  controller: nameController,
                                  prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Item name is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 4,
                                child: CustomTextField(
                                  label: 'Item Code',
                                  hint: 'e.g. GF-001',
                                  controller: codeController,
                                  isUpperCase: true,
                                  prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 3. Category & Unit Selection
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Obx(() => _buildCategoryDropdown(isDark, selectedCat)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Obx(() => _buildUnitDropdown(isDark, selectedUnit)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 4. Stock Alert
                          CustomTextField(
                            label: 'Min Stock Alert *',
                            hint: '50',
                            controller: minStockController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            prefixIcon: const Icon(Icons.notification_important_outlined, size: 20),
                          ),
                          const SizedBox(height: 16),

                          // 5. Description
                          CustomTextField(
                            label: 'Description',
                            hint: 'Optional notes or specifications...',
                            controller: descController,
                            maxLines: 2,
                            prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                          ),
                          const SizedBox(height: 12),

                          // 6. Active Toggle
                          Obx(
                            () => SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Active Status',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                              subtitle: Text(
                                isActive.value ? 'Item is active and available for feeding' : 'Item is inactive / archived',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              value: isActive.value,
                              activeTrackColor: AppColors.primary,
                              onChanged: (val) => isActive.value = val,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      Obx(
                        () => CustomButton(
                          text: 'Update Feed Item',
                          icon: Icons.check_rounded,
                          isLoading: isSubmitting.value,
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final double minStock = double.tryParse(minStockController.text.trim()) ?? 50.0;

                            final success = await updateFeedItem(
                              item.id,
                              itemName: nameController.text.trim(),
                              itemCode: codeController.text.trim(),
                              category: selectedCat.value.code,
                              unit: selectedUnit.value.code,
                              minStockAlert: minStock,
                              description: descController.text.trim(),
                              isActive: isActive.value,
                            );

                            if (success) {
                              if (Get.isDialogOpen ?? false) {
                                Get.back();
                              } else if (context.mounted) {
                                Navigator.of(context, rootNavigator: true).pop();
                              }
                              CustomSnackbar.showSuccess(
                                title: 'Item Updated',
                                message: 'Feed item "${nameController.text.trim()}" updated successfully.',
                              );
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

  /// Confirmation dialog before deleting a feed item
  void confirmDeleteFeedItem(BuildContext context, FeedItemModel item) {
    if (!canDeleteFeedItem) {
      CustomSnackbar.showError(
        title: 'Access Denied',
        message: 'You do not have permission to delete feed items.',
      );
      return;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Delete Feed Item?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to delete "${item.itemName}" (${item.itemCode.isNotEmpty ? item.itemCode : item.categoryEnum.label})? This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    CustomButton(
                      text: 'Delete',
                      variant: ButtonVariant.danger,
                      icon: Icons.delete_outline_rounded,
                      onPressed: () {
                        Get.back();
                        deleteFeedItem(item.id);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Details dialog to view complete feed item record
  void showFeedItemDetailsDialog(BuildContext context, FeedItemModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: item.categoryEnum.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        PhosphorIconsRegular.grains,
                        color: item.categoryEnum.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          if (item.itemCode.isNotEmpty)
                            Text(
                              'Code: ${item.itemCode}',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      tooltip: 'Close',
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                _buildDetailRow('Category', item.categoryEnum.label, isDark, tagColor: item.categoryEnum.color),
                _buildDetailRow('Gaushala', item.gaushalaName ?? '-', isDark),
                _buildDetailRow('Current Stock', '${item.currentStock} ${item.unitEnum.shortLabel}', isDark,
                    isAlert: item.isLowStock),
                _buildDetailRow('Min Stock Alert', '${item.minStockAlert} ${item.unitEnum.shortLabel}', isDark),
                _buildDetailRow('Status', item.isActive ? 'Active' : 'Inactive', isDark,
                    tagColor: item.isActive ? AppColors.success : AppColors.error),
                if (item.description.isNotEmpty) _buildDetailRow('Description', item.description, isDark),
                _buildDetailRow('System ID', item.id, isDark, isMonospace: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark,
      {Color? tagColor, bool isAlert = false, bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: tagColor != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tagColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tagColor,
                        ),
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: isMonospace ? 'monospace' : null,
                      fontWeight: isAlert ? FontWeight.bold : FontWeight.normal,
                      color: isAlert
                          ? AppColors.error
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaushalaDropdown(bool isDark, Rxn<GaushalaModel> selectedGaushala, {bool? enabled}) {
    return Obx(() {
      return CustomDropdownSearch<GaushalaModel>(
        label: 'Gaushala',
        isRequired: true,
        enabled: enabled ?? isSuperAdmin,
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

  Widget _buildCategoryDropdown(bool isDark, Rx<FeedItemCategory> selectedCat) {
    return CustomDropdownSearch<FeedItemCategory>(
      label: 'Category',
      isRequired: true,
      hint: 'Select Category',
      prefixIcon: PhosphorIconsRegular.tag,
      selectedItem: selectedCat.value,
      items: FeedItemCategory.values,
      itemAsString: (c) => c.label,
      compareFn: (c1, c2) => c1 == c2,
      onChanged: (selected) {
        if (selected != null) selectedCat.value = selected;
      },
    );
  }

  Widget _buildUnitDropdown(bool isDark, Rx<FeedItemUnit> selectedUnit) {
    return CustomDropdownSearch<FeedItemUnit>(
      label: 'Unit',
      isRequired: true,
      hint: 'Select Unit',
      prefixIcon: Icons.scale_rounded,
      selectedItem: selectedUnit.value,
      items: FeedItemUnit.values,
      itemAsString: (u) => u.label,
      compareFn: (u1, u2) => u1 == u2,
      onChanged: (selected) {
        if (selected != null) selectedUnit.value = selected;
      },
    );
  }
}
