import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../data/models/gaushala_model.dart';
import '../../data/models/treatment_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/gaushala_session_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';
import '../notification/notification_controller.dart';
import 'dialogs/add_treatment_dialog.dart';
import 'dialogs/administer_dose_dialog.dart';
import 'dialogs/change_status_dialog.dart';
import 'dialogs/treatment_details_dialog.dart';

/// Centralized Controller for Cow Treatment & Multi-Dose Veterinary Schedules
class TreatmentController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();
  final StorageService _storageService = Get.find<StorageService>();

  // Layout & Sidebar
  final RxBool isSidebarCollapsed = false.obs;
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  // Metrics & Today Due
  final Rx<TreatmentSummaryModel> summary = const TreatmentSummaryModel().obs;
  final RxList<CowTreatmentModel> todayDueTreatments = <CowTreatmentModel>[].obs;
  final RxBool isSummaryLoading = false.obs;
  final RxBool isDueDosesLoading = false.obs;

  // Treatment Data List
  final RxList<CowTreatmentModel> treatments = <CowTreatmentModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;

  // Search & Filter state
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString statusFilter = 'ALL'.obs; // ALL, UNDER_TREATMENT, RECOVERED, CRITICAL, CLOSED, DECEASED
  final RxString severityFilter = 'ALL'.obs; // ALL, MILD, MODERATE, CRITICAL
  final RxBool filterOnlyDueToday = false.obs;
  final Rxn<DateTime> startDateFilter = Rxn<DateTime>();
  final Rxn<DateTime> endDateFilter = Rxn<DateTime>();

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt rowsPerPage = 5.obs;
  final RxInt totalItems = 0.obs;
  final RxInt totalPages = 1.obs;

  // Action states
  final RxBool isDeleting = false.obs;

  Timer? _debounceTimer;

  String get currentGaushalaId => _gaushalaService.selectedGaushalaId;
  RxList<GaushalaModel> get gaushalas => _gaushalaService.gaushalas;
  bool get canChangeGaushala => _gaushalaService.canChangeGaushala;
  String get selectedGaushalaName => _gaushalaService.selectedGaushalaName;
  GaushalaModel? findGaushala(String? query) => _gaushalaService.findGaushala(query);

  void setGaushala(String? gaushalaId) {
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

    // Listen for search changes with debounce
    searchController.addListener(_onSearchChanged);

    // Initial load
    loadAll();

    // Reload when active gaushala changes
    ever(_gaushalaService.selectedGaushala, (_) {
      currentPage.value = 1;
      loadAll();
    });
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    searchController.dispose();
    super.onClose();
  }

  void toggleSidebar() {
    isSidebarCollapsed.toggle();
  }

  void logout() {
    _storageService.removeToken();
    _storageService.removeUser();
    Get.offAllNamed(AppRoutes.auth);
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      final text = searchController.text.trim();
      if (searchQuery.value != text) {
        searchQuery.value = text;
        currentPage.value = 1;
        fetchTreatments();
      }
    });
  }

  /// Reload all dashboard components
  Future<void> loadAll() async {
    await Future.wait([
      fetchSummary(),
      fetchTodayDueDoses(),
      fetchTreatments(),
    ]);
  }

  /// Pull-to-refresh or refresh button action
  Future<void> refreshData() async {
    isRefreshing.value = true;
    try {
      await loadAll();
      // Also refresh notifications
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().fetchUnreadCount();
      }
      CustomSnackbar.showSuccess(
        title: 'Refreshed',
        message: 'Treatment data updated successfully',
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Fetches top summary metrics
  Future<void> fetchSummary() async {
    final gId = currentGaushalaId;
    if (gId.isEmpty) return;

    isSummaryLoading.value = true;
    try {
      final res = await _apiService.getTreatmentSummary(gaushalaId: gId);
      summary.value = res;
    } catch (_) {
    } finally {
      isSummaryLoading.value = false;
    }
  }

  /// Fetches cases with doses scheduled on or before today
  Future<void> fetchTodayDueDoses() async {
    final gId = currentGaushalaId;
    if (gId.isEmpty) return;

    isDueDosesLoading.value = true;
    try {
      final list = await _apiService.getTodayDueDoses(gaushalaId: gId);
      todayDueTreatments.assignAll(list);
    } catch (_) {
    } finally {
      isDueDosesLoading.value = false;
    }
  }

  /// Fetches paginated treatments list with all active filters
  Future<void> fetchTreatments({bool isSilent = false}) async {
    final gId = currentGaushalaId;
    if (gId.isEmpty) return;

    if (!isSilent) isLoading.value = true;

    try {
      // If user toggled 'Only Due Today', we can filter either client-side or use today-due list
      if (filterOnlyDueToday.value) {
        final dueList = await _apiService.getTodayDueDoses(gaushalaId: gId);
        treatments.assignAll(dueList);
        totalItems.value = dueList.length;
        totalPages.value = 1;
        return;
      }

      final result = await _apiService.getTreatments(
        gaushalaId: gId,
        status: statusFilter.value == 'ALL' ? null : statusFilter.value,
        severity: severityFilter.value == 'ALL' ? null : severityFilter.value,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        page: currentPage.value,
        limit: rowsPerPage.value,
        startDate: startDateFilter.value,
        endDate: endDateFilter.value,
      );

      treatments.assignAll(result.items);
      totalItems.value = result.total;
      totalPages.value = result.totalPages;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to load treatments list',
      );
    } finally {
      if (!isSilent) isLoading.value = false;
    }
  }

  // Filter setters
  void setStatusFilter(String? status) {
    statusFilter.value = status ?? 'ALL';
    currentPage.value = 1;
    fetchTreatments();
  }

  void setSeverityFilter(String? severity) {
    severityFilter.value = severity ?? 'ALL';
    currentPage.value = 1;
    fetchTreatments();
  }

  void toggleDueTodayFilter([bool? val]) {
    filterOnlyDueToday.value = val ?? !filterOnlyDueToday.value;
    currentPage.value = 1;
    fetchTreatments();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    startDateFilter.value = start;
    endDateFilter.value = end;
    currentPage.value = 1;
    fetchTreatments();
  }

  void clearFilters() {
    searchController.clear();
    searchQuery.value = '';
    statusFilter.value = 'ALL';
    severityFilter.value = 'ALL';
    filterOnlyDueToday.value = false;
    startDateFilter.value = null;
    endDateFilter.value = null;
    currentPage.value = 1;
    fetchTreatments();
  }

  // Pagination handlers
  void onPageChanged(int page) {
    currentPage.value = page;
    fetchTreatments();
  }

  void onRowsPerPageChanged(int rows) {
    rowsPerPage.value = rows;
    currentPage.value = 1;
    fetchTreatments();
  }

  // Dialog & Navigation openers
  Future<void> openAddTreatmentDialog(BuildContext context) async {
    final created = await AddTreatmentDialog.show(context);
    if (created == true) {
      loadAll();
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().fetchUnreadCount();
      }
    }
  }

  Future<void> openAdministerDoseDialog(
    BuildContext context,
    CowTreatmentModel treatment, [
    int? specificDoseNumber,
  ]) async {
    final nextDose = specificDoseNumber ?? treatment.nextDoseNumber ?? (treatment.completedDoses + 1);
    final administered = await AdministerDoseDialog.show(
      context,
      treatment: treatment,
      doseNumber: nextDose,
    );

    if (administered == true) {
      loadAll();
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().fetchUnreadCount();
      }
    }
  }

  Future<void> openChangeStatusDialog(
    BuildContext context,
    CowTreatmentModel treatment,
  ) async {
    final updated = await ChangeStatusDialog.show(
      context,
      treatment: treatment,
    );

    if (updated == true) {
      loadAll();
    }
  }

  Future<void> goToTreatmentDetails(
    CowTreatmentModel treatment, [
    BuildContext? context,
  ]) async {
    final ctx = context ?? Get.context;
    if (ctx != null) {
      final updated = await TreatmentDetailsDialog.show(
        ctx,
        treatment: treatment,
      );
      if (updated == true) {
        loadAll();
      }
    } else {
      Get.toNamed(
        AppRoutes.treatmentDetails,
        arguments: {'treatmentId': treatment.id, 'treatment': treatment},
      );
    }
  }

  /// Deletes a treatment record
  Future<void> deleteTreatment(BuildContext context, CowTreatmentModel treatment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Treatment Record?'),
        content: Text(
          'Are you sure you want to delete treatment case #${treatment.treatmentNumber.isNotEmpty ? treatment.treatmentNumber : treatment.id} for Cow ${treatment.displayCowTag}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    isDeleting.value = true;
    try {
      final success = await _apiService.deleteTreatment(treatment.id);
      if (success) {
        CustomSnackbar.showSuccess(
          title: 'Deleted',
          message: 'Treatment case deleted successfully',
        );
        loadAll();
      } else {
        CustomSnackbar.showError(
          title: 'Error',
          message: 'Failed to delete treatment case',
        );
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'An error occurred while deleting treatment case',
      );
    } finally {
      isDeleting.value = false;
    }
  }
}
