import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/values/permission_constants.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../data/models/cow_heat_model.dart';
import '../../data/models/gaushala_model.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/heat_provider.dart';
import '../../data/services/gaushala_session_service.dart';
import '../../data/services/permission_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';

/// Centralized Controller for Cow Heat Management & Estrus Monitoring.
class HeatController extends GetxController {
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();
  final StorageService _storageService = Get.find<StorageService>();
  final HeatProvider _heatProvider = HeatProvider();

  PermissionService? get _permissionService =>
      Get.isRegistered<PermissionService>() ? Get.find<PermissionService>() : null;

  bool get canAddHeat =>
      _permissionService?.canAdd(PermissionModules.cowHeat, PermissionSubModules.heatList) ??
      (currentUser.value?.isAdmin ?? true);

  bool get canEditHeat =>
      _permissionService?.canEdit(PermissionModules.cowHeat, PermissionSubModules.heatList) ??
      (currentUser.value?.isAdmin ?? true);

  bool get canDeleteHeat =>
      _permissionService?.canDelete(PermissionModules.cowHeat, PermissionSubModules.heatList) ??
      (currentUser.value?.isAdmin ?? true);

  // Layout & Sidebar
  final RxBool isSidebarCollapsed = false.obs;
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  // Data Observables
  final RxList<CowHeatModel> heats = <CowHeatModel>[].obs;
  final RxList<CowHeatModel> mobileHeats = <CowHeatModel>[].obs;
  final RxList<CowHeatModel> activeHeatAlerts = <CowHeatModel>[].obs;
  final RxList<CowHeatModel> repeatHeatAlerts = <CowHeatModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isLoadingAlerts = false.obs;
  final RxBool isActionLoading = false.obs;
  final RxBool isLoadingMore = false.obs;

  // Search & Filter State
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString statusFilter = 'ALL'.obs; // ALL, OBSERVED, READY_FOR_MATING, MATED, MISSED, EXPIRED
  final RxString stageFilter = 'ALL'.obs; // ALL, EARLY, STANDING, LATE
  final RxString intensityFilter = 'ALL'.obs; // ALL, MILD, MODERATE, STRONG
  final RxBool isRepeatFilter = false.obs;
  final Rxn<DateTime> startDateFilter = Rxn<DateTime>();
  final Rxn<DateTime> endDateFilter = Rxn<DateTime>();
  final RxString cowIdFilter = ''.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt rowsPerPage = 5.obs;
  final RxInt totalItems = 0.obs;
  final RxInt totalPages = 1.obs;
  final RxInt mobilePage = 1.obs;

  bool get hasMoreMobileItems => (mobilePage.value * rowsPerPage.value) < filteredHeats.length;

  /// Client-side filtered list of heat records (instantly respects search query, status, stage, etc.)
  List<CowHeatModel> get filteredHeats {
    final query = searchQuery.value.trim().toLowerCase();
    final status = statusFilter.value;
    final stage = stageFilter.value;
    final intensity = intensityFilter.value;
    final isRepeat = isRepeatFilter.value;
    final start = startDateFilter.value;
    final end = endDateFilter.value;

    return heats.where((h) {
      // 1. Status Filter
      if (status != 'ALL' && h.status.code != status) {
        return false;
      }

      // 2. Stage Filter
      if (stage != 'ALL' && h.heatStage.code != stage) {
        return false;
      }

      // 3. Intensity Filter
      if (intensity != 'ALL' && h.intensity.code != intensity) {
        return false;
      }

      // 4. Repeat Filter
      if (isRepeat && !h.isHighAlert) {
        return false;
      }

      // 5. Date Range Filter
      if (start != null && h.heatDate != null && h.heatDate!.isBefore(start)) {
        return false;
      }
      if (end != null && h.heatDate != null && h.heatDate!.isAfter(end.add(const Duration(days: 1)))) {
        return false;
      }

      // 6. Search Query (Cow Tag, Calf Name, Shed, Breed, Worker, Remarks, Status, Stage)
      if (query.isNotEmpty) {
        final matchesTag = h.cowTagId.toLowerCase().contains(query);
        final matchesName = (h.cowCalfName?.toLowerCase().contains(query)) ?? false;
        final matchesShed = (h.cowShedName?.toLowerCase().contains(query)) ?? false;
        final matchesBreed = (h.cowBreedName?.toLowerCase().contains(query)) ?? false;
        final matchesWorker = (h.observedByWorkerName?.toLowerCase().contains(query)) ?? false;
        final matchesRemarks = (h.remarks?.toLowerCase().contains(query)) ?? false;
        final matchesStatus = h.status.label.toLowerCase().contains(query) ||
            h.status.code.toLowerCase().contains(query);
        final matchesStage = h.heatStage.label.toLowerCase().contains(query) ||
            h.heatStage.code.toLowerCase().contains(query);

        if (!matchesTag &&
            !matchesName &&
            !matchesShed &&
            !matchesBreed &&
            !matchesWorker &&
            !matchesRemarks &&
            !matchesStatus &&
            !matchesStage) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Paginated heat records for current desktop page
  List<CowHeatModel> get paginatedHeats {
    final list = filteredHeats;
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
      return list.isEmpty ? [] : list.take(rowsPerPage.value).toList();
    }
    return list.skip(start).take(rowsPerPage.value).toList();
  }

  /// Mobile view list of heat records
  List<CowHeatModel> get mobileDisplayHeats {
    return filteredHeats.take(mobilePage.value * rowsPerPage.value).toList();
  }

  int get displayTotalItems => filteredHeats.length;
  int get displayTotalPages => (filteredHeats.isEmpty)
      ? 1
      : (filteredHeats.length / rowsPerPage.value).ceil();

  Timer? _debounceTimer;

  // Gaushala Session Helpers
  String get currentGaushalaId => _gaushalaService.selectedGaushalaId;
  RxList<GaushalaModel> get gaushalas => _gaushalaService.gaushalas;
  bool get canChangeGaushala => _gaushalaService.canChangeGaushala;
  String get selectedGaushalaName => _gaushalaService.selectedGaushalaName;
  GaushalaModel? findGaushala(String? query) => _gaushalaService.findGaushala(query);

  void setGaushala(String? gaushalaId) {
    if (!canChangeGaushala) return;
    if (gaushalaId == null || gaushalaId.isEmpty) return;
    final match = findGaushala(gaushalaId);
    if (match != null) {
      _gaushalaService.setGaushala(match);
    }
  }

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _storageService.getUser();
    fetchAllData();

    // Re-fetch when gaushala context changes
    ever(_gaushalaService.selectedGaushala, (_) {
      currentPage.value = 1;
      mobilePage.value = 1;
      fetchAllData();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    _debounceTimer?.cancel();
    super.onClose();
  }

  void toggleSidebar() {
    isSidebarCollapsed.toggle();
  }

  void logout() {
    _storageService.clearAll();
    Get.offAllNamed(AppRoutes.auth);
  }

  // ---------------------------------------------------------------------------
  // Data Fetching
  // ---------------------------------------------------------------------------

  Future<void> fetchAllData() async {
    final gId = currentGaushalaId;
    if (gId.isEmpty) return;

    await Future.wait([
      fetchHeats(),
      fetchAlerts(),
    ]);
  }

  Future<void> fetchAlerts() async {
    final gId = currentGaushalaId;
    if (gId.isEmpty) return;

    try {
      isLoadingAlerts.value = true;
      final active = await _heatProvider.getActiveHeatAlerts(gaushalaId: gId);
      final repeat = await _heatProvider.getRepeatHeatAlerts(gaushalaId: gId);
      activeHeatAlerts.assignAll(active);
      repeatHeatAlerts.assignAll(repeat);
    } catch (e) {
      // Fallback
    } finally {
      isLoadingAlerts.value = false;
    }
  }

  Future<void> fetchHeats({bool isPageChange = false}) async {
    final gId = currentGaushalaId;
    if (gId.isEmpty) return;

    try {
      if (!isPageChange && heats.isEmpty) {
        isLoading.value = true;
      }

      final result = await _heatProvider.getHeats(
        gaushalaId: gId,
        cowId: cowIdFilter.value.isNotEmpty ? cowIdFilter.value : null,
        status: statusFilter.value != 'ALL' ? statusFilter.value : null,
        heatStage: stageFilter.value != 'ALL' ? stageFilter.value : null,
        intensity: intensityFilter.value != 'ALL' ? intensityFilter.value : null,
        isRepeatHeatAlert: isRepeatFilter.value ? true : null,
        startDate: startDateFilter.value,
        endDate: endDateFilter.value,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        page: 1,
        limit: 500, // Load full dataset for instant reactive filtering and responsive search
      );

      heats.assignAll(result.items);
      totalItems.value = displayTotalItems;
      totalPages.value = displayTotalPages;

      if (!isPageChange || currentPage.value == 1) {
        mobileHeats.assignAll(mobileDisplayHeats);
        mobilePage.value = 1;
      }
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: 'Failed to load cow heat records: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  void loadMoreMobileHeats() {
    if (hasMoreMobileItems) {
      mobilePage.value += 1;
      mobileHeats.assignAll(mobileDisplayHeats);
    }
  }

  Future<void> refreshData() async {
    isRefreshing.value = true;
    currentPage.value = 1;
    mobilePage.value = 1;
    await fetchAllData();
  }

  // ---------------------------------------------------------------------------
  // Filters & Search
  // ---------------------------------------------------------------------------

  void onSearchChanged(String val) {
    searchQuery.value = val.trim();
    currentPage.value = 1;
    mobilePage.value = 1;
    totalItems.value = displayTotalItems;
    totalPages.value = displayTotalPages;
    mobileHeats.assignAll(mobileDisplayHeats);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      fetchHeats(isPageChange: true);
    });
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    currentPage.value = 1;
    mobilePage.value = 1;
    totalItems.value = displayTotalItems;
    totalPages.value = displayTotalPages;
    mobileHeats.assignAll(mobileDisplayHeats);
    fetchHeats(isPageChange: true);
  }

  void setStatusFilter(String val) {
    statusFilter.value = val;
    currentPage.value = 1;
    mobilePage.value = 1;
    totalItems.value = displayTotalItems;
    totalPages.value = displayTotalPages;
    mobileHeats.assignAll(mobileDisplayHeats);
    fetchHeats(isPageChange: true);
  }

  void setStageFilter(String val) {
    stageFilter.value = val;
    currentPage.value = 1;
    mobilePage.value = 1;
    totalItems.value = displayTotalItems;
    totalPages.value = displayTotalPages;
    mobileHeats.assignAll(mobileDisplayHeats);
    fetchHeats(isPageChange: true);
  }

  void setIntensityFilter(String val) {
    intensityFilter.value = val;
    currentPage.value = 1;
    mobilePage.value = 1;
    totalItems.value = displayTotalItems;
    totalPages.value = displayTotalPages;
    mobileHeats.assignAll(mobileDisplayHeats);
    fetchHeats(isPageChange: true);
  }

  void toggleRepeatFilter() {
    isRepeatFilter.toggle();
    currentPage.value = 1;
    mobilePage.value = 1;
    totalItems.value = displayTotalItems;
    totalPages.value = displayTotalPages;
    mobileHeats.assignAll(mobileDisplayHeats);
    fetchHeats(isPageChange: true);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    startDateFilter.value = start;
    endDateFilter.value = end;
    currentPage.value = 1;
    mobilePage.value = 1;
    totalItems.value = displayTotalItems;
    totalPages.value = displayTotalPages;
    mobileHeats.assignAll(mobileDisplayHeats);
    fetchHeats(isPageChange: true);
  }

  void resetFilters() {
    searchController.clear();
    searchQuery.value = '';
    statusFilter.value = 'ALL';
    stageFilter.value = 'ALL';
    intensityFilter.value = 'ALL';
    isRepeatFilter.value = false;
    startDateFilter.value = null;
    endDateFilter.value = null;
    cowIdFilter.value = '';
    currentPage.value = 1;
    mobilePage.value = 1;
    totalItems.value = displayTotalItems;
    totalPages.value = displayTotalPages;
    mobileHeats.assignAll(mobileDisplayHeats);
    fetchHeats(isPageChange: true);
  }

  void onPageChanged(int page) {
    if (page < 1 || page > displayTotalPages) return;
    currentPage.value = page;
  }

  void onRowsPerPageChanged(int rows) {
    rowsPerPage.value = rows;
    currentPage.value = 1;
    totalItems.value = displayTotalItems;
    totalPages.value = displayTotalPages;
    mobileHeats.assignAll(mobileDisplayHeats);
  }

  // ---------------------------------------------------------------------------
  // CRUD Actions
  // ---------------------------------------------------------------------------

  Future<bool> createHeat(Map<String, dynamic> data) async {
    try {
      isActionLoading.value = true;
      final newRecord = await _heatProvider.createHeat(data);
      CustomSnackbar.showSuccess(
        title: 'Success',
        message: 'Heat cycle recorded for ${newRecord.cowTagId}',
      );
      await fetchAllData();
      return true;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to record heat: $e',
      );
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> updateHeat(String id, Map<String, dynamic> data) async {
    try {
      isActionLoading.value = true;
      final updated = await _heatProvider.updateHeat(id, data);
      CustomSnackbar.showSuccess(
        title: 'Success',
        message: 'Heat record updated for ${updated.cowTagId}',
      );
      await fetchAllData();
      return true;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to update heat record: $e',
      );
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> deleteHeat(CowHeatModel heat) async {
    try {
      isActionLoading.value = true;
      final success = await _heatProvider.deleteHeat(heat.id);
      if (success) {
        CustomSnackbar.showSuccess(
          title: 'Success',
          message: 'Heat record removed for ${heat.cowTagId}',
        );
        await fetchAllData();
        return true;
      }
      return false;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to delete heat record: $e',
      );
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }
}
