import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/values/permission_constants.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../data/models/cow_mating_model.dart';
import '../../data/models/gaushala_model.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/mating_provider.dart';
import '../../data/services/gaushala_session_service.dart';
import '../../data/services/permission_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';

/// Centralized Controller for Cow Mating & Breeding Management.
class MatingController extends GetxController {
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();
  final StorageService _storageService = Get.find<StorageService>();
  final MatingProvider _matingProvider = MatingProvider();

  PermissionService? get _permissionService =>
      Get.isRegistered<PermissionService>() ? Get.find<PermissionService>() : null;

  bool get canAddMating =>
      _permissionService?.canAdd(PermissionModules.cowMating, PermissionSubModules.matingList) ??
      (currentUser.value?.isAdmin ?? true);

  bool get canEditMating =>
      _permissionService?.canEdit(PermissionModules.cowMating, PermissionSubModules.matingList) ??
      (currentUser.value?.isAdmin ?? true);

  bool get canDeleteMating =>
      _permissionService?.canDelete(PermissionModules.cowMating, PermissionSubModules.matingList) ??
      (currentUser.value?.isAdmin ?? true);

  // Layout & Sidebar
  final RxBool isSidebarCollapsed = false.obs;
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  // Data Observables
  final RxList<CowMatingModel> matings = <CowMatingModel>[].obs;
  final RxList<CowMatingModel> mobileMatings = <CowMatingModel>[].obs;
  final RxList<CowMatingModel> repeatBreederAlerts = <CowMatingModel>[].obs;
  final RxList<CowMatingModel> pendingPDAlerts = <CowMatingModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isLoadingAlerts = false.obs;
  final RxBool isActionLoading = false.obs;
  final RxBool isLoadingMore = false.obs;

  // Search & Filter State
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString statusFilter = 'ALL'.obs; // ALL, PENDING_PD, PREGNANT, FAILED, CALVED, ABORTED
  final RxString typeFilter = 'ALL'.obs; // ALL, NATURAL, ARTIFICIAL
  final RxBool isRepeatBreederFilter = false.obs;
  final Rxn<DateTime> startDateFilter = Rxn<DateTime>();
  final Rxn<DateTime> endDateFilter = Rxn<DateTime>();
  final RxString cowIdFilter = ''.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt rowsPerPage = 5.obs;
  final RxInt totalItems = 0.obs;
  final RxInt totalPages = 1.obs;
  final RxInt mobilePage = 1.obs;

  bool get hasMoreMobileItems => (mobilePage.value * rowsPerPage.value) < filteredMatings.length;

  /// Client-side filtered list of matings (instantly respects search query, status, type, etc.)
  List<CowMatingModel> get filteredMatings {
    final query = searchQuery.value.trim().toLowerCase();
    final status = statusFilter.value;
    final type = typeFilter.value;
    final isRepeatOnly = isRepeatBreederFilter.value;
    final start = startDateFilter.value;
    final end = endDateFilter.value;

    return matings.where((m) {
      // 1. Status Filter
      if (status != 'ALL' && m.status.code != status) {
        return false;
      }

      // 2. Type Filter
      if (type != 'ALL' && m.matingType.code != type) {
        return false;
      }

      // 3. Repeat Breeder Filter
      if (isRepeatOnly && !m.isHighAlert) {
        return false;
      }

      // 4. Date Range Filter
      if (start != null && m.matingDate != null && m.matingDate!.isBefore(start)) {
        return false;
      }
      if (end != null && m.matingDate != null && m.matingDate!.isAfter(end.add(const Duration(days: 1)))) {
        return false;
      }

      // 5. Search Query (Cow Tag, Cow Name, Bull Tag/Name, Straw Code, Inseminator, Status, Remarks, Breed, Shed)
      if (query.isNotEmpty) {
        final matchesCowTag = m.cowTagId.toLowerCase().contains(query);
        final matchesCowName = (m.cowCalfName?.toLowerCase().contains(query)) ?? false;
        final matchesBull = (m.bullNameOrTag?.toLowerCase().contains(query)) ?? false;
        final matchesStraw = (m.semenStrawCode?.toLowerCase().contains(query)) ?? false;
        final matchesInseminator = (m.inseminatorName?.toLowerCase().contains(query)) ?? false;
        final matchesStatus = m.status.label.toLowerCase().contains(query) ||
            m.status.code.toLowerCase().contains(query);
        final matchesRemarks = (m.remarks?.toLowerCase().contains(query)) ?? false;
        final matchesBreed = (m.cowBreedName?.toLowerCase().contains(query)) ??
            (m.semenBreedName?.toLowerCase().contains(query)) ??
            false;
        final matchesShed = (m.cowShedName?.toLowerCase().contains(query)) ?? false;

        if (!matchesCowTag &&
            !matchesCowName &&
            !matchesBull &&
            !matchesStraw &&
            !matchesInseminator &&
            !matchesStatus &&
            !matchesRemarks &&
            !matchesBreed &&
            !matchesShed) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Paginated matings for the current page
  List<CowMatingModel> get paginatedMatings {
    final list = filteredMatings;
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

  /// Mobile view list of matings
  List<CowMatingModel> get mobileDisplayMatings {
    return filteredMatings.take(mobilePage.value * rowsPerPage.value).toList();
  }

  int get displayTotalItems => filteredMatings.length;
  int get displayTotalPages => (filteredMatings.isEmpty)
      ? 1
      : (filteredMatings.length / rowsPerPage.value).ceil();

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

    // Re-fetch on gaushala change
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
      fetchMatings(),
      fetchAlerts(),
    ]);
  }

  Future<void> fetchAlerts() async {
    final gId = currentGaushalaId;
    if (gId.isEmpty) return;

    try {
      isLoadingAlerts.value = true;
      final repeat = await _matingProvider.getRepeatBreederAlerts(gaushalaId: gId);
      final pending = await _matingProvider.getPendingPDAlerts(gaushalaId: gId);
      repeatBreederAlerts.assignAll(repeat);
      pendingPDAlerts.assignAll(pending);
    } catch (e) {
      // Fallback
    } finally {
      isLoadingAlerts.value = false;
    }
  }

  Future<void> fetchMatings({bool isPageChange = false}) async {
    final gId = currentGaushalaId;
    if (gId.isEmpty) return;

    try {
      if (!isPageChange && matings.isEmpty) {
        isLoading.value = true;
      }

      final result = await _matingProvider.getMatings(
        gaushalaId: gId,
        cowId: cowIdFilter.value.isNotEmpty ? cowIdFilter.value : null,
        status: statusFilter.value != 'ALL' ? statusFilter.value : null,
        matingType: typeFilter.value != 'ALL' ? typeFilter.value : null,
        isRepeatBreederAlert: isRepeatBreederFilter.value ? true : null,
        startDate: startDateFilter.value,
        endDate: endDateFilter.value,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        page: 1,
        limit: 500, // Load full dataset for instant reactive filtering and responsive search
      );

      matings.assignAll(result.items);
      totalItems.value = displayTotalItems;
      totalPages.value = displayTotalPages;

      if (!isPageChange || currentPage.value == 1) {
        mobileMatings.assignAll(mobileDisplayMatings);
        mobilePage.value = 1;
      }
    } catch (e) {
      CustomSnackbar.showError(title: 'Error', message: 'Failed to load cow mating records: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  void loadMoreMobileMatings() {
    if (hasMoreMobileItems) {
      mobilePage.value += 1;
      mobileMatings.assignAll(mobileDisplayMatings);
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
    mobileMatings.assignAll(mobileDisplayMatings);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      fetchMatings(isPageChange: true);
    });
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    currentPage.value = 1;
    mobilePage.value = 1;
    totalItems.value = displayTotalItems;
    totalPages.value = displayTotalPages;
    mobileMatings.assignAll(mobileDisplayMatings);
    fetchMatings(isPageChange: true);
  }

  void setStatusFilter(String val) {
    statusFilter.value = val;
    currentPage.value = 1;
    mobilePage.value = 1;
    totalItems.value = displayTotalItems;
    totalPages.value = displayTotalPages;
    mobileMatings.assignAll(mobileDisplayMatings);
    fetchMatings(isPageChange: true);
  }

  void setTypeFilter(String val) {
    typeFilter.value = val;
    currentPage.value = 1;
    mobilePage.value = 1;
    totalItems.value = displayTotalItems;
    totalPages.value = displayTotalPages;
    mobileMatings.assignAll(mobileDisplayMatings);
    fetchMatings(isPageChange: true);
  }

  void toggleRepeatBreederFilter() {
    isRepeatBreederFilter.toggle();
    currentPage.value = 1;
    mobilePage.value = 1;
    totalItems.value = displayTotalItems;
    totalPages.value = displayTotalPages;
    mobileMatings.assignAll(mobileDisplayMatings);
    fetchMatings(isPageChange: true);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    startDateFilter.value = start;
    endDateFilter.value = end;
    currentPage.value = 1;
    mobilePage.value = 1;
    totalItems.value = displayTotalItems;
    totalPages.value = displayTotalPages;
    mobileMatings.assignAll(mobileDisplayMatings);
    fetchMatings(isPageChange: true);
  }

  void resetFilters() {
    searchController.clear();
    searchQuery.value = '';
    statusFilter.value = 'ALL';
    typeFilter.value = 'ALL';
    isRepeatBreederFilter.value = false;
    startDateFilter.value = null;
    endDateFilter.value = null;
    cowIdFilter.value = '';
    currentPage.value = 1;
    mobilePage.value = 1;
    totalItems.value = displayTotalItems;
    totalPages.value = displayTotalPages;
    mobileMatings.assignAll(mobileDisplayMatings);
    fetchMatings(isPageChange: true);
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
    mobileMatings.assignAll(mobileDisplayMatings);
  }

  // ---------------------------------------------------------------------------
  // CRUD & Workflow Actions
  // ---------------------------------------------------------------------------

  Future<bool> createMating(Map<String, dynamic> data) async {
    try {
      isActionLoading.value = true;
      final newRecord = await _matingProvider.createMating(data);
      CustomSnackbar.showSuccess(
        title: 'Success',
        message: 'Mating record created for ${newRecord.cowTagId}',
      );
      await fetchAllData();
      return true;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to record mating: $e',
      );
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> updateMating(String id, Map<String, dynamic> data) async {
    try {
      isActionLoading.value = true;
      final updated = await _matingProvider.updateMating(id, data);
      CustomSnackbar.showSuccess(
        title: 'Success',
        message: 'Mating details updated for ${updated.cowTagId}',
      );
      await fetchAllData();
      return true;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to update mating: $e',
      );
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> updatePDStatus(
    String id, {
    required String pdResult,
    required String pdDate,
    String? pdPerformedBy,
    String? remarks,
  }) async {
    try {
      isActionLoading.value = true;
      final updated = await _matingProvider.updatePDStatus(
        id,
        pdResult: pdResult,
        pdDate: pdDate,
        pdPerformedBy: pdPerformedBy,
        remarks: remarks,
      );
      final isPreg = pdResult.toUpperCase() == 'POSITIVE';
      CustomSnackbar.showSuccess(
        title: 'Success',
        message: isPreg
            ? 'Pregnancy confirmed! Expected calving date calculated.'
            : 'PD result recorded as Negative for ${updated.cowTagId}.',
      );
      await fetchAllData();
      return true;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to record PD status: $e',
      );
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> recordCalving(
    String id, {
    required String actualCalvingDate,
    String? remarks,
  }) async {
    try {
      isActionLoading.value = true;
      final updated = await _matingProvider.recordCalving(
        id,
        actualCalvingDate: actualCalvingDate,
        remarks: remarks,
      );
      CustomSnackbar.showSuccess(
        title: 'Success',
        message: 'Calving successfully recorded for ${updated.cowTagId}!',
      );
      await fetchAllData();
      return true;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to record calving: $e',
      );
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> deleteMating(CowMatingModel mating) async {
    try {
      isActionLoading.value = true;
      final success = await _matingProvider.deleteMating(mating.id);
      if (success) {
        CustomSnackbar.showSuccess(
          title: 'Success',
          message: 'Mating record removed for ${mating.cowTagId}',
        );
        await fetchAllData();
        return true;
      }
      return false;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to delete mating record: $e',
      );
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }
}
