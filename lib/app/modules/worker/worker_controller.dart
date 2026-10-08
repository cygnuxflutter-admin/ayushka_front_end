import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/values/app_colors.dart';
import '../../core/values/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dropdown_search.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/values/permission_constants.dart';
import '../../data/models/department_model.dart';
import '../../data/models/department_summary_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/worker_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/gaushala_session_service.dart';
import '../../data/services/permission_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';
import 'department_controller.dart';
import 'views/edit_worker_screen.dart';

/// Controller managing Worker Operations, Filters, Summary Metrics, and Dialogs.
class WorkerController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();
  final PermissionService? _permissionService =
      Get.isRegistered<PermissionService>() ? Get.find<PermissionService>() : null;

  bool get canAddWorker =>
      _permissionService?.canAdd(PermissionModules.workerMgmt, PermissionSubModules.workerList) ??
      (currentUser.value?.isAdmin ?? false);

  bool get canEditWorker =>
      _permissionService?.canEdit(PermissionModules.workerMgmt, PermissionSubModules.workerList) ??
      (currentUser.value?.isAdmin ?? false);

  bool get canDeleteWorker =>
      _permissionService?.canDelete(PermissionModules.workerMgmt, PermissionSubModules.workerList) ??
      (currentUser.value?.isAdmin ?? false);

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isSidebarCollapsed = false.obs;

  // Data states
  final RxList<WorkerModel> workers = <WorkerModel>[].obs;
  final Rxn<DepartmentSummaryModel> summary = Rxn<DepartmentSummaryModel>();

  // Loading flags
  final RxBool isLoading = false.obs;
  final RxBool isLoadingSummary = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isSubmitting = false.obs;

  // Reactive Filters & Search
  final Rxn<String> selectedDepartmentFilter = Rxn<String>(); // null or 'all' = all
  final RxString selectedStatusFilter = 'all'.obs; // 'all', 'active', 'inactive'
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  // Pagination states
  final RxInt currentPage = 1.obs;
  final RxInt rowsPerPage = 5.obs;
  final RxInt totalWorkers = 0.obs;
  final RxInt totalPages = 1.obs;

  // Mobile infinite scroll state
  final RxList<WorkerModel> mobileWorkers = <WorkerModel>[].obs;
  final RxInt mobilePage = 1.obs;
  final RxBool isLoadingMore = false.obs;

  bool get hasMoreMobile => mobileWorkers.length < totalWorkers.value;

  Future<void> loadMoreWorkers() async {
    if (isLoadingMore.value || isLoading.value || !hasMoreMobile) return;
    final gId = currentGaushalaId;
    if (gId.isEmpty || gId == 'all') return;

    isLoadingMore.value = true;
    try {
      bool? activeParam;
      if (selectedStatusFilter.value == 'active') {
        activeParam = true;
      } else if (selectedStatusFilter.value == 'inactive') {
        activeParam = false;
      }

      final deptParam = selectedDepartmentFilter.value;
      final cleanDept = (deptParam != null && deptParam.isNotEmpty && deptParam != 'all') ? deptParam : null;

      final nextPage = mobilePage.value + 1;
      final res = await _apiService.getWorkers(
        gaushalaId: gId,
        departmentId: cleanDept,
        isActive: activeParam,
        search: searchQuery.value.trim().isNotEmpty ? searchQuery.value.trim() : null,
        page: nextPage,
        limit: rowsPerPage.value,
      );

      mobileWorkers.addAll(res.items);
      mobilePage.value = nextPage;
      totalWorkers.value = res.total;
      totalPages.value = res.totalPages;
    } catch (_) {
      // Handled silently
    } finally {
      isLoadingMore.value = false;
    }
  }

  String get currentGaushalaId => _gaushalaService.selectedGaushalaId;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _storageService.getUser();

    // Debounce search query to trigger remote API fetch smoothly
    debounce(
      searchQuery,
      (_) {
        currentPage.value = 1;
        fetchWorkers();
      },
      time: const Duration(milliseconds: 300),
    );

    // Initial load
    final gId = currentGaushalaId;
    if (gId.isNotEmpty) {
      loadInitialData(gId);
    }

    // Reactively refresh when Global Gaushala changes
    ever(_gaushalaService.selectedGaushala, (g) {
      if (g != null && g.id.isNotEmpty) {
        clearFilters(fetchAfter: false);
        loadInitialData(g.id);
      } else {
        workers.clear();
        summary.value = null;
      }
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  Future<void> logout() async {
    await _storageService.removeToken();
    await _storageService.removeUser();
    Get.offAllNamed(AppRoutes.auth);
  }

  Future<void> loadInitialData(String gaushalaId) async {
    await Future.wait([
      fetchDepartmentSummary(gaushalaId: gaushalaId, showLoading: true),
      fetchWorkers(showLoading: true),
    ]);
  }

  /// Refreshes both summary metrics and workers table
  Future<void> refreshAll() async {
    isRefreshing.value = true;
    try {
      await Future.wait([
        fetchDepartmentSummary(),
        fetchWorkers(),
      ]);
      if (Get.isRegistered<DepartmentController>()) {
        Get.find<DepartmentController>().fetchDepartments(showLoading: false);
      }
    } finally {
      isRefreshing.value = false;
    }
  }

  // -------------------------------------------------------------
  // SUMMARY METRICS
  // -------------------------------------------------------------

  Future<void> fetchDepartmentSummary({
    String? gaushalaId,
    bool showLoading = false,
  }) async {
    final gId = gaushalaId ?? currentGaushalaId;
    if (gId.isEmpty || gId == 'all') {
      summary.value = null;
      return;
    }

    if (showLoading) {
      isLoadingSummary.value = true;
    }
    try {
      final res = await _apiService.getWorkerDepartmentSummary(gaushalaId: gId);
      summary.value = res;
    } catch (e) {
      // Handled silently
    } finally {
      isLoadingSummary.value = false;
    }
  }

  // -------------------------------------------------------------
  // WORKERS LIST WITH PAGINATION & FILTERS
  // -------------------------------------------------------------

  Future<void> fetchWorkers({
    bool showLoading = false,
    bool isManualRefresh = false,
  }) async {
    final gId = currentGaushalaId;
    if (gId.isEmpty || gId == 'all') {
      workers.clear();
      mobileWorkers.clear();
      mobilePage.value = 1;
      totalWorkers.value = 0;
      totalPages.value = 1;
      return;
    }

    if (showLoading || workers.isEmpty) {
      isLoading.value = true;
    }
    if (isManualRefresh) {
      isRefreshing.value = true;
    }

    try {
      bool? activeParam;
      if (selectedStatusFilter.value == 'active') {
        activeParam = true;
      } else if (selectedStatusFilter.value == 'inactive') {
        activeParam = false;
      }

      final deptParam = selectedDepartmentFilter.value;
      final cleanDept = (deptParam != null && deptParam.isNotEmpty && deptParam != 'all') ? deptParam : null;

      final res = await _apiService.getWorkers(
        gaushalaId: gId,
        departmentId: cleanDept,
        isActive: activeParam,
        search: searchQuery.value.trim().isNotEmpty ? searchQuery.value.trim() : null,
        page: currentPage.value,
        limit: rowsPerPage.value,
      );

      workers.assignAll(res.items);
      if (currentPage.value == 1) {
        mobilePage.value = 1;
        mobileWorkers.assignAll(res.items);
      }
      totalWorkers.value = res.total;
      totalPages.value = res.totalPages;
    } catch (e) {
      if (e is DioException) {
        final msg = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to load workers.';
        CustomSnackbar.showError(title: 'Error', message: msg);
      }
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  void setDepartmentFilter(String? deptId) {
    final clean = (deptId == null || deptId.isEmpty || deptId == 'all') ? null : deptId;
    if (selectedDepartmentFilter.value == clean) return;
    selectedDepartmentFilter.value = clean;
    currentPage.value = 1;
    fetchWorkers(showLoading: true);
  }

  void setStatusFilter(String status) {
    if (selectedStatusFilter.value == status) return;
    selectedStatusFilter.value = status;
    currentPage.value = 1;
    fetchWorkers(showLoading: true);
  }

  void clearFilters({bool fetchAfter = true}) {
    searchQuery.value = '';
    searchController.clear();
    selectedDepartmentFilter.value = null;
    selectedStatusFilter.value = 'all';
    currentPage.value = 1;
    if (fetchAfter) {
      fetchWorkers(showLoading: true);
    }
  }

  void setPage(int page) {
    if (page >= 1 && page <= totalPages.value && page != currentPage.value) {
      currentPage.value = page;
      fetchWorkers(showLoading: true);
    }
  }

  void setRowsPerPage(int count) {
    if (rowsPerPage.value != count) {
      rowsPerPage.value = count;
      currentPage.value = 1;
      fetchWorkers(showLoading: true);
    }
  }

  // -------------------------------------------------------------
  // WORKER ACTIONS & CRUD
  // -------------------------------------------------------------

  /// Add Worker: POST /api/v1/workers
  Future<bool> createWorker({
    required String name,
    required String departmentId,
    required DateTime joiningDate,
  }) async {
    final gId = currentGaushalaId;
    if (gId.isEmpty) {
      CustomSnackbar.showError(title: 'Error', message: 'No active Gaushala selected.');
      return false;
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      CustomSnackbar.showError(title: 'Validation Error', message: 'Worker name is required.');
      return false;
    }
    if (departmentId.trim().isEmpty) {
      CustomSnackbar.showError(title: 'Validation Error', message: 'Please select a department.');
      return false;
    }

    isSubmitting.value = true;
    try {
      final newWorker = await _apiService.createWorker(
        gaushalaId: gId,
        departmentId: departmentId.trim(),
        name: trimmedName,
        joiningDate: joiningDate,
      );

      CustomSnackbar.showSuccess(
        title: 'Worker Added',
        message: 'Worker "${newWorker.name}" was added successfully.',
      );

      fetchWorkers();
      fetchDepartmentSummary();
      if (Get.isRegistered<DepartmentController>()) {
        Get.find<DepartmentController>().fetchDepartments();
      }
      return true;
    } catch (e) {
      String msg = 'Failed to add worker.';
      if (e is DioException) {
        msg = e.response?.data?['message']?.toString() ?? e.message ?? msg;
      }
      CustomSnackbar.showError(title: 'Error', message: msg);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Admin Edit: POST /api/v1/workers/{id}/update
  Future<bool> updateWorker(
    String id, {
    required String name,
    required String departmentId,
    required bool isActive,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      CustomSnackbar.showError(title: 'Validation Error', message: 'Worker name is required.');
      return false;
    }
    if (departmentId.trim().isEmpty) {
      CustomSnackbar.showError(title: 'Validation Error', message: 'Please select a department.');
      return false;
    }

    isSubmitting.value = true;
    try {
      final updated = await _apiService.updateWorker(
        id,
        name: trimmedName,
        departmentId: departmentId.trim(),
        isActive: isActive,
      );

      final index = workers.indexWhere((w) => w.id == id);
      if (index != -1) {
        workers[index] = updated;
      }

      CustomSnackbar.showSuccess(
        title: 'Worker Updated',
        message: 'Worker "${updated.name}" details updated successfully.',
      );

      fetchDepartmentSummary();
      if (Get.isRegistered<DepartmentController>()) {
        Get.find<DepartmentController>().fetchDepartments();
      }
      return true;
    } catch (e) {
      String msg = 'Failed to update worker.';
      if (e is DioException) {
        msg = e.response?.data?['message']?.toString() ?? e.message ?? msg;
      }
      CustomSnackbar.showError(title: 'Error', message: msg);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Toggle Active/Inactive Status: POST /api/v1/workers/{id}/status
  Future<void> toggleWorkerStatus(WorkerModel worker) async {
    final newStatus = !worker.isActive;
    isSubmitting.value = true;
    try {
      final updated = await _apiService.updateWorkerStatus(worker.id, isActive: newStatus);

      final index = workers.indexWhere((w) => w.id == worker.id);
      if (index != -1) {
        workers[index] = updated;
      }

      CustomSnackbar.showSuccess(
        title: 'Status Updated',
        message: 'Worker "${worker.name}" status changed to ${newStatus ? "Active" : "Inactive"}.',
      );

      fetchDepartmentSummary();
      if (Get.isRegistered<DepartmentController>()) {
        Get.find<DepartmentController>().fetchDepartments();
      }
    } catch (e) {
      String msg = 'Failed to toggle status.';
      if (e is DioException) {
        msg = e.response?.data?['message']?.toString() ?? e.message ?? msg;
      }
      CustomSnackbar.showError(title: 'Error', message: msg);
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Worker Leaving Gaushala: POST /api/v1/workers/{id}/leave
  Future<bool> markWorkerLeft(WorkerModel worker, DateTime leavingDate) async {
    isSubmitting.value = true;
    try {
      final updated = await _apiService.markWorkerLeft(worker.id, leavingDate: leavingDate);

      final index = workers.indexWhere((w) => w.id == worker.id);
      if (index != -1) {
        workers[index] = updated;
      }

      CustomSnackbar.showSuccess(
        title: 'Recorded Departure',
        message: 'Worker "${worker.name}" has been marked as left on ${DateFormat('dd MMM yyyy').format(leavingDate)}.',
      );

      fetchDepartmentSummary();
      if (Get.isRegistered<DepartmentController>()) {
        Get.find<DepartmentController>().fetchDepartments();
      }
      return true;
    } catch (e) {
      String msg = 'Failed to record worker departure.';
      if (e is DioException) {
        msg = e.response?.data?['message']?.toString() ?? e.message ?? msg;
      }
      CustomSnackbar.showError(title: 'Error', message: msg);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Soft Delete Worker: POST /api/v1/workers/{id}/delete
  Future<bool> deleteWorker(WorkerModel worker) async {
    isSubmitting.value = true;
    try {
      final success = await _apiService.deleteWorker(worker.id);
      if (success) {
        workers.removeWhere((w) => w.id == worker.id);
        totalWorkers.value = (totalWorkers.value - 1).clamp(0, 999999);
        CustomSnackbar.showSuccess(
          title: 'Worker Removed',
          message: 'Worker "${worker.name}" has been removed.',
        );

        fetchDepartmentSummary();
        if (Get.isRegistered<DepartmentController>()) {
          Get.find<DepartmentController>().fetchDepartments();
        }
        return true;
      } else {
        CustomSnackbar.showError(title: 'Error', message: 'Failed to delete worker.');
        return false;
      }
    } catch (e) {
      String msg = 'Failed to delete worker.';
      if (e is DioException) {
        msg = e.response?.data?['message']?.toString() ?? e.message ?? msg;
      }
      CustomSnackbar.showError(title: 'Error', message: msg);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // -------------------------------------------------------------
  // DIALOGS
  // -------------------------------------------------------------

  /// Add Worker Dialog
  void openAddWorkerDialog(BuildContext context) {
    if (!canAddWorker) {
      CustomSnackbar.showWarning(
        title: 'Access Denied',
        message: 'You do not have permission to add workers.',
      );
      return;
    }
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final Rx<DateTime> joiningDate = DateTime.now().obs;

    final deptCtrl = Get.find<DepartmentController>();
    if (deptCtrl.departments.isEmpty) {
      deptCtrl.fetchDepartments();
    }

    DepartmentModel? initialDept;
    if (selectedDepartmentFilter.value != null) {
      initialDept = deptCtrl.departments.firstWhereOrNull((d) => d.id == selectedDepartmentFilter.value);
    }
    if (initialDept == null && deptCtrl.departments.isNotEmpty) {
      initialDept = deptCtrl.departments.first;
    }
    final Rxn<DepartmentModel> selectedDept = Rxn<DepartmentModel>(initialDept);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
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
                              PhosphorIconsRegular.userPlus,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Add New Worker',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 6),
                  const Text(
                    'Register a new farm worker or labor staff in Gaushala operations.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 20),

                  // Worker Name
                  CustomTextField(
                    label: 'Worker Full Name *',
                    hint: 'e.g. Ramesh Patel',
                    controller: nameController,
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Worker name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Department Dropdown
                  Obx(() {
                    return CustomDropdownSearch<DepartmentModel>(
                      label: 'Department',
                      isRequired: true,
                      hint: 'Select Department',
                      prefixIcon: Icons.apartment_rounded,
                      selectedItem: selectedDept.value,
                      items: deptCtrl.departments.toList(),
                      itemAsString: (d) => '${d.departmentName} (${d.departmentCode})',
                      compareFn: (d1, d2) => d1.id == d2.id,
                      searchable: true,
                      searchHint: 'Search department...',
                      onChanged: (d) => selectedDept.value = d,
                      validator: (d) {
                        if (d == null && selectedDept.value == null) {
                          return 'Please select a department';
                        }
                        return null;
                      },
                    );
                  }),
                  const SizedBox(height: 16),

                  // Joining Date Picker
                  _buildDatePickerField(
                    context: context,
                    label: 'Joining Date',
                    selectedDate: joiningDate,
                    onDatePicked: (date) => joiningDate.value = date,
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomButton(
                        text: 'Cancel',
                        variant: ButtonVariant.outlined,
                        width: 100,
                        onPressed: () {
                          if (Get.isDialogOpen ?? false) {
                            Get.back();
                          } else if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      Obx(
                        () => CustomButton(
                          text: 'Add Worker',
                          variant: ButtonVariant.primary,
                          isLoading: isSubmitting.value,
                          width: 140,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              if (selectedDept.value == null) {
                                CustomSnackbar.showError(title: 'Validation Error', message: 'Please select a department');
                                return;
                              }

                              final ok = await createWorker(
                                name: nameController.text,
                                departmentId: selectedDept.value!.id,
                                joiningDate: joiningDate.value,
                              );
                              if (ok) {
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
    );
  }

  /// Edit Worker Dialog: Admin can update Name, Department, and Status (isActive).
  void openEditWorkerDialog(BuildContext context, WorkerModel worker) {
    if (!canEditWorker) {
      CustomSnackbar.showWarning(
        title: 'Access Denied',
        message: 'You do not have permission to edit workers.',
      );
      return;
    }
    if (ResponsiveLayout.isMobile(context)) {
      Get.to(() => EditWorkerScreen(worker: worker));
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: worker.name);
    final RxBool isActive = worker.isActive.obs;

    final deptCtrl = Get.find<DepartmentController>();
    if (deptCtrl.departments.isEmpty) {
      deptCtrl.fetchDepartments();
    }

    final initialDept = deptCtrl.departments.firstWhereOrNull((d) => d.id == worker.departmentId);
    final Rxn<DepartmentModel> selectedDept = Rxn<DepartmentModel>(initialDept);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
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
                              PhosphorIconsRegular.pencilSimple,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Edit Worker Details',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 6),
                  const Text(
                    'Update worker name, assigned department, and active status.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 20),

                  // Name
                  CustomTextField(
                    label: 'Worker Name *',
                    hint: 'e.g. Ramesh Patel',
                    controller: nameController,
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Worker name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Department Dropdown
                  Obx(() {
                    return CustomDropdownSearch<DepartmentModel>(
                      label: 'Assigned Department',
                      isRequired: true,
                      hint: 'Select Department',
                      prefixIcon: Icons.apartment_rounded,
                      selectedItem: selectedDept.value,
                      items: deptCtrl.departments.toList(),
                      itemAsString: (d) => '${d.departmentName} (${d.departmentCode})',
                      compareFn: (d1, d2) => d1.id == d2.id,
                      searchable: true,
                      searchHint: 'Search department...',
                      onChanged: (d) => selectedDept.value = d,
                      validator: (d) {
                        if (d == null && selectedDept.value == null) {
                          return 'Please select a department';
                        }
                        return null;
                      },
                    );
                  }),
                  const SizedBox(height: 16),

                  // Status Toggle
                  Obx(
                    () => SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Active Working Status',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        isActive.value ? 'Worker is currently active' : 'Worker is deactivated/inactive',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                      value: isActive.value,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) => isActive.value = val,
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomButton(
                        text: 'Cancel',
                        variant: ButtonVariant.outlined,
                        width: 100,
                        onPressed: () {
                          if (Get.isDialogOpen ?? false) {
                            Get.back();
                          } else if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      Obx(
                        () => CustomButton(
                          text: 'Save Changes',
                          variant: ButtonVariant.primary,
                          isLoading: isSubmitting.value,
                          width: 150,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              if (selectedDept.value == null) {
                                CustomSnackbar.showError(title: 'Validation Error', message: 'Please select a department');
                                return;
                              }

                              final ok = await updateWorker(
                                worker.id,
                                name: nameController.text,
                                departmentId: selectedDept.value!.id,
                                isActive: isActive.value,
                              );
                              if (ok) {
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
    );
  }

  /// Mark as Left Gaushala Dialog: Date picker for leavingDate.
  /// Backend rule: isActive = false, isDelete = false, and leavingDate is recorded.
  void openMarkLeftDialog(BuildContext context, WorkerModel worker) {
    final Rx<DateTime> leavingDate = (worker.leavingDate ?? DateTime.now()).obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
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
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            PhosphorIconsRegular.signpost,
                            color: AppColors.warning,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Mark as Left Gaushala',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  'Record departure date for "${worker.name}". Marking a worker as left will set their status to Inactive while preserving their records.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 20),

                // Leaving Date Picker
                _buildDatePickerField(
                  context: context,
                  label: 'Date of Departure / Leaving Date',
                  selectedDate: leavingDate,
                  onDatePicked: (date) => leavingDate.value = date,
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomButton(
                      text: 'Cancel',
                      variant: ButtonVariant.outlined,
                      width: 100,
                      onPressed: () {
                        if (Get.isDialogOpen ?? false) {
                          Get.back();
                        } else if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    Obx(
                      () => CustomButton(
                        text: 'Confirm Departure',
                        variant: ButtonVariant.secondary,
                        backgroundColor: AppColors.warning,
                        isLoading: isSubmitting.value,
                        width: 170,
                        onPressed: () async {
                          final ok = await markWorkerLeft(worker, leavingDate.value);
                          if (ok) {
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
    );
  }

  /// Confirm Delete Worker: Soft-delete (isDelete = true, isActive = false)
  void confirmDeleteWorker(BuildContext context, WorkerModel worker) {
    if (!canDeleteWorker) {
      CustomSnackbar.showWarning(
        title: 'Access Denied',
        message: 'You do not have permission to delete workers.',
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
            Text('Delete Worker'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove worker "${worker.name}"?\n\nThis will soft-delete their record from the active roster.',
          style: const TextStyle(fontSize: 14),
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
            onPressed: () async {
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
              } else {
                Get.back();
              }
              await deleteWorker(worker);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Reusable Date Picker input field styled to match CustomTextField aesthetics
  Widget _buildDatePickerField({
    required BuildContext context,
    required String label,
    required Rx<DateTime> selectedDate,
    required ValueChanged<DateTime> onDatePicked,
    bool isRequired = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate.value,
              firstDate: DateTime(1990),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              onDatePicked(picked);
            }
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIconsRegular.calendarBlank,
                  size: 18,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
                const SizedBox(width: 10),
                Obx(
                  () => Expanded(
                    child: Text(
                      DateFormat('dd MMM yyyy').format(selectedDate.value),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
