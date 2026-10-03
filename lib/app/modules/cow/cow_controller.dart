import 'dart:math';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/utils/file_download_helper.dart';
import '../../core/values/app_colors.dart';
import '../../core/values/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../data/models/cow_model.dart';
import '../../data/models/gaushala_model.dart';
import '../../data/models/shed_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/gaushala_session_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'widgets/excel_import_dialog.dart';
import 'widgets/shed_transfer_dialog.dart';
import 'widgets/shed_transfer_history_dialog.dart';

/// Controller managing Herd & Cattle (Cow List) state, operations, and navigation.
class CowController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();

  // In-memory cache for fast transitions
  static final List<CowModel> _cachedCows = [];
  static CowCounts _cachedCounts = const CowCounts();
  static String? _cachedGaushalaId;

  /// Clears in-memory static cache (called on logout and fresh login)
  static void clearCache() {
    _cachedCows.clear();
    _cachedCounts = const CowCounts();
    _cachedGaushalaId = null;
  }

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isSidebarCollapsed = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isDeleting = false.obs;
  final RxBool isLoadingGaushalas = false.obs;
  final RxSet<String> updatingStatusCowIds = <String>{}.obs;
  final RxSet<String> updatingDiedCowIds = <String>{}.obs;
  final RxBool isTransferringShed = false.obs;

  // Download Template State
  final RxBool isDownloadingTemplate = false.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxInt downloadedBytes = 0.obs;
  final RxInt totalDownloadBytes = 0.obs;
  final RxString downloadStatusMessage = ''.obs;
  final RxBool showDownloadBanner = false.obs;
  final RxBool isDownloadSuccess = false.obs;

  // Excel Import / Upload State
  final RxBool isUploadingExcel = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxInt uploadedBytes = 0.obs;
  final RxInt totalUploadBytes = 0.obs;
  final RxBool isProcessingServer = false.obs;
  final RxBool isUploadSuccess = false.obs;
  final RxnString uploadError = RxnString();
  final RxString uploadingFileName = ''.obs;
  final RxInt importedCount = 0.obs;
  final RxString uploadSuccessMessage = ''.obs;

  // Master lists
  final RxList<CowModel> cows = <CowModel>[].obs;
  RxList<GaushalaModel> get gaushalas => _gaushalaService.gaushalas;
  final Rx<CowCounts> counts = const CowCounts().obs;

  // Filters
  final Rxn<String> selectedGaushalaId = Rxn<String>();
  final RxString selectedGenderFilter = 'all'.obs; // 'all' | 'female' | 'male'
  final RxString searchQuery = ''.obs;

  // Pagination states
  final RxInt currentPage = 1.obs;
  final RxInt rowsPerPage = 5.obs;

  /// Returns true if the logged-in user can change the active gaushala
  bool get canChangeGaushala => _gaushalaService.canChangeGaushala;

  /// Look up a Gaushala by ID, Name, or normalized slug
  GaushalaModel? findGaushala(String? query) => _gaushalaService.findGaushala(query);

  /// Returns the human-readable Gaushala Name for the currently filtered gaushala on this screen
  String get selectedGaushalaName {
    final gId = selectedGaushalaId.value;
    if (gId == null || gId.isEmpty) {
      return _gaushalaService.selectedGaushalaName;
    }
    final match = findGaushala(gId);
    return match?.gaushalaName ?? _gaushalaService.selectedGaushalaName;
  }

  /// Active gaushala name for the current herd list view
  String get activeGaushalaName => selectedGaushalaName;

  /// Global Gaushala ID from the top AppBar
  String get globalGaushalaId => _gaushalaService.selectedGaushalaId;

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    debounce(searchQuery, (_) => currentPage.value = 1, time: const Duration(milliseconds: 150));
    ever(_gaushalaService.selectedGaushala, (GaushalaModel? g) {
      if (g != null && g.id.isNotEmpty && selectedGaushalaId.value != g.id) {
        onGlobalGaushalaChanged(g);
      }
    });

    _initData();
  }

  void _loadUser() {
    currentUser.value = _storageService.getUser();
  }

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  Future<void> logout() async {
    clearCache();
    _gaushalaService.clearSession();
    await _storageService.removeToken();
    await _storageService.removeUser();
    Get.offAllNamed(AppRoutes.auth);
  }

  /// Initial load: fetch gaushalas, set initial gaushala based on user/admin, then fetch cows.
  Future<void> _initData() async {
    await _gaushalaService.initSession(user: currentUser.value);

    final targetGaushalaId = _gaushalaService.selectedGaushalaId;
    selectedGaushalaId.value = targetGaushalaId;

    if (_cachedCows.isNotEmpty && _cachedGaushalaId == targetGaushalaId) {
      cows.assignAll(_cachedCows);
      counts.value = _cachedCounts;
    }

    if (targetGaushalaId.isNotEmpty) {
      await fetchCows(
        gaushalaId: targetGaushalaId,
        gender: selectedGenderFilter.value,
        showLoading: cows.isEmpty,
      );
    }
  }

  /// Called when the active gaushala is switched globally from anywhere in the app
  void onGlobalGaushalaChanged(GaushalaModel gaushala) {
    if (selectedGaushalaId.value == gaushala.id) return;
    selectedGaushalaId.value = gaushala.id;
    currentPage.value = 1;
    fetchCows(gaushalaId: gaushala.id, showLoading: true);
  }

  /// Fetches gaushalas for dropdown filter.
  Future<void> fetchGaushalas() async {
    await _gaushalaService.fetchGaushalas(forceReload: true);
  }

  /// Fetches cows list via GET /api/v1/cows?gaushalaId=...
  Future<void> fetchCows({
    String? gaushalaId,
    String? gender,
    bool showLoading = false,
    bool isManualRefresh = false,
  }) async {
    final gId = gaushalaId ?? selectedGaushalaId.value;
    if (gId == null || gId.trim().isEmpty) {
      return;
    }

    if (showLoading || cows.isEmpty) {
      isLoading.value = true;
    }
    if (isManualRefresh) {
      isRefreshing.value = true;
    }

    try {
      final response = await _apiService.getCows(
        gaushalaId: gId.trim(),
        gender: null, // Fetch full gaushala dataset for smooth instantaneous gender filtering
      );

      cows.assignAll(response.allCows);
      counts.value = response.counts;

      // Update cache
      _cachedCows
        ..clear()
        ..addAll(response.allCows);
      _cachedCounts = response.counts;
      _cachedGaushalaId = gId;

      if (isManualRefresh) {
        CustomSnackbar.showSuccess(
          title: 'Refreshed',
          message: 'Herd list updated successfully.',
        );
      }
    } catch (_) {
      // Handled by Dio interceptor
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// User-initiated refresh
  Future<void> refreshCows() async {
    if (isLoading.value || isRefreshing.value) return;
    await Future.wait([
      fetchGaushalas(),
      fetchCows(
        gaushalaId: selectedGaushalaId.value,
        showLoading: true,
        isManualRefresh: true,
      ),
    ]);
  }

  /// Formats byte count to human-readable string (e.g. 13.9 KB, 1.2 MB)
  String formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    final clampedIndex = i.clamp(0, suffixes.length - 1);
    return '${(bytes / pow(1024, clampedIndex)).toStringAsFixed(decimals)} ${suffixes[clampedIndex]}';
  }

  /// Downloads the Excel import template with live progress and byte counter
  Future<void> downloadTemplate() async {
    if (isDownloadingTemplate.value) return;

    isDownloadingTemplate.value = true;
    downloadProgress.value = 0.0;
    downloadedBytes.value = 0;
    totalDownloadBytes.value = 0;
    downloadStatusMessage.value = 'Preparing template download...';
    showDownloadBanner.value = true;
    isDownloadSuccess.value = false;

    try {
      final bytes = await _apiService.downloadImportTemplate(
        onReceiveProgress: (received, total) {
          downloadedBytes.value = received;
          if (total > 0) {
            totalDownloadBytes.value = total;
            downloadProgress.value = (received / total).clamp(0.0, 1.0);
            downloadStatusMessage.value =
                'Downloading: ${formatBytes(received)} / ${formatBytes(total)} (${(downloadProgress.value * 100).toInt()}%)';
          } else {
            downloadStatusMessage.value = 'Downloading: ${formatBytes(received)}';
          }
        },
      );

      // Trigger platform-safe file save/download
      const fileName = 'cow_import_template.xlsx';
      await FileDownloadHelper.download(
        bytes: bytes,
        fileName: fileName,
      );

      downloadProgress.value = 1.0;
      isDownloadSuccess.value = true;
      downloadStatusMessage.value =
          'Downloaded ${formatBytes(bytes.length)} successfully ($fileName)';

      CustomSnackbar.showSuccess(
        title: 'Template Downloaded',
        message: 'Saved $fileName (${formatBytes(bytes.length)})',
      );

      // Automatically hide download notification after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (showDownloadBanner.value) {
          showDownloadBanner.value = false;
        }
      });
    } catch (e) {
      showDownloadBanner.value = false;
      CustomSnackbar.showError(
        title: 'Download Failed',
        message: 'Could not download template: ${e.toString()}',
      );
    } finally {
      isDownloadingTemplate.value = false;
    }
  }

  /// Opens file picker for Excel file (.xlsx, .xls) and displays animated import dialog
  Future<void> pickAndUploadExcel(BuildContext context) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (file == null) {
        return;
      }

      final fileBytes = await file.readAsBytes();
      if (fileBytes.isEmpty) {
        CustomSnackbar.showError(
          title: 'Empty File',
          message: 'The selected file is empty or could not be read.',
        );
        return;
      }

      if (!context.mounted) return;

      // Show animated import dialog
      ExcelImportDialog.show(
        context: context,
        fileName: file.name,
        fileBytes: fileBytes,
        controller: this,
      );
    } catch (e) {
      CustomSnackbar.showError(
        title: 'File Selection Error',
        message: 'Failed to select Excel file: ${e.toString()}',
      );
    }
  }

  /// Executes upload of Excel file to backend with live byte progress
  Future<void> executeUploadExcel({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    isUploadingExcel.value = true;
    uploadProgress.value = 0.0;
    uploadedBytes.value = 0;
    totalUploadBytes.value = fileBytes.length;
    isProcessingServer.value = false;
    isUploadSuccess.value = false;
    uploadError.value = null;
    uploadingFileName.value = fileName;
    importedCount.value = 0;
    uploadSuccessMessage.value = '';

    try {
      final response = await _apiService.uploadCowsExcel(
        fileBytes: fileBytes,
        fileName: fileName,
        onSendProgress: (sent, total) {
          uploadedBytes.value = sent;
          if (total > 0) {
            totalUploadBytes.value = total;
            uploadProgress.value = (sent / total).clamp(0.0, 1.0);
          }
          if (sent >= total && total > 0) {
            // All bytes sent to server, now backend is processing
            isProcessingServer.value = true;
          }
        },
      );

      isProcessingServer.value = false;
      isUploadSuccess.value = true;

      // Extract imported count from response
      int count = 0;
      final data = response['data'];
      if (data is Map) {
        final rawCount = data['count'] ??
            data['importedCount'] ??
            data['imported'] ??
            data['total'] ??
            data['successCount'] ??
            data['insertedCount'];
        if (rawCount != null) {
          count = int.tryParse(rawCount.toString()) ?? 0;
        }
      } else if (data is List) {
        count = data.length;
      } else if (data is int) {
        count = data;
      }

      final msg = response['message']?.toString() ?? 'Cattle imported successfully.';
      if (count == 0) {
        final match = RegExp(r'(\d+)\s*(?:records?|cows?|rows?|items?|cattle)?', caseSensitive: false).firstMatch(msg);
        if (match != null) {
          count = int.tryParse(match.group(1) ?? '0') ?? 0;
        }
      }

      importedCount.value = count;
      uploadSuccessMessage.value = msg;

      // Automatically refresh cow list
      await refreshCows();
    } catch (e) {
      isProcessingServer.value = false;
      isUploadSuccess.value = false;
      if (e is DioException) {
        uploadError.value = e.response?.data?['message']?.toString() ?? e.message ?? 'Upload failed.';
      } else {
        uploadError.value = e.toString();
      }
    } finally {
      isUploadingExcel.value = false;
    }
  }


  /// Change Gaushala filter on this screen (Allowed for Admins; restricted for regular users).
  /// Modifies only local screen filtering without altering the global AppBar gaushala selector.
  void setGaushala(String? gaushalaId) {
    if (gaushalaId == null || gaushalaId.isEmpty) {
      return;
    }

    // Role-based permission check: non-admins cannot switch to other gaushalas
    if (!canChangeGaushala) {
      final userGId = currentUser.value?.gaushalaId;
      final allowedMatch = findGaushala(userGId);
      final allowedId = allowedMatch?.id ?? userGId;
      if (allowedId != null && allowedId != gaushalaId) {
        CustomSnackbar.showWarning(
          title: 'Access Restricted',
          message: 'Only Administrators have permission to switch gaushala stations.',
        );
        return;
      }
    }

    if (selectedGaushalaId.value == gaushalaId) {
      return;
    }

    // Update screen-level filter only (does NOT modify global session gaushala in AppBar)
    selectedGaushalaId.value = gaushalaId;
    currentPage.value = 1;
    fetchCows(gaushalaId: gaushalaId, showLoading: cows.isEmpty);
  }

  /// Change Gender filter ('all', 'female', 'male') - instant smooth in-memory toggle
  void setGenderFilter(String gender) {
    if (selectedGenderFilter.value == gender) return;
    selectedGenderFilter.value = gender;
    currentPage.value = 1;
  }

  /// Clear text search, reset gender filter, and restore gaushala filter to main AppBar gaushala
  void clearFilters() {
    searchQuery.value = '';
    if (selectedGenderFilter.value != 'all') {
      selectedGenderFilter.value = 'all';
    }
    final globalGId = _gaushalaService.selectedGaushalaId;
    if (globalGId.isNotEmpty && selectedGaushalaId.value != globalGId) {
      selectedGaushalaId.value = globalGId;
      currentPage.value = 1;
      fetchCows(gaushalaId: globalGId, showLoading: true);
    } else {
      currentPage.value = 1;
    }
  }


  // -------------------------------------------------------------
  // FILTERED & PAGINATED LISTS
  // -------------------------------------------------------------
  List<CowModel> get filteredCows {
    final query = searchQuery.value.trim().toLowerCase();
    final gender = selectedGenderFilter.value;

    return cows.where((c) {
      // 1. Gender filter fallback (if backend didn't filter or for quick toggle)
      if (gender == 'female' && !c.isFemale) return false;
      if (gender == 'male' && c.isFemale) return false;

      // 2. Search query filter
      if (query.isEmpty) return true;
      final tagMatch = c.tagId.toLowerCase().contains(query);
      final calfMatch = c.calfName?.toLowerCase().contains(query) ?? false;
      final breedMatch = c.breed?.breedName.toLowerCase().contains(query) ?? false;
      final typeMatch = c.cowType?.typeName.toLowerCase().contains(query) ?? false;
      final shedNameMatch = c.shed?.shedName.toLowerCase().contains(query) ?? false;
      final shedNoMatch = c.shed?.shedNumber.toLowerCase().contains(query) ?? false;
      final remarkMatch = c.remark?.toLowerCase().contains(query) ?? false;
      final isCowDeleted = c.isDeleted || c.isDelete;
      final isCowDied = !isCowDeleted && (c.isDead || c.isDied);
      final isCowInactive = !isCowDeleted && !isCowDied && !c.isActive;
      final isCowActive = !isCowDeleted && !isCowDied && c.isActive;

      final statusMatch = (query == 'active' && isCowActive) ||
          ((query == 'inactive' || query == 'in_active') && isCowInactive) ||
          ((query == 'died' || query == 'death' || query == 'deceased') && isCowDied) ||
          ((query == 'delete' || query == 'deleted') && isCowDeleted);

      return tagMatch ||
          calfMatch ||
          breedMatch ||
          typeMatch ||
          shedNameMatch ||
          shedNoMatch ||
          remarkMatch ||
          statusMatch;
    }).toList();
  }

  List<CowModel> get paginatedCows {
    final list = filteredCows;
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

  int get totalPages => (filteredCows.isEmpty)
      ? 1
      : (filteredCows.length / rowsPerPage.value).ceil();

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      currentPage.value = page;
    }
  }

  void setRowsPerPage(int count) {
    rowsPerPage.value = count;
    currentPage.value = 1;
  }

  /// Navigate to Add Cow Screen
  Future<void> goToAddCow() async {
    final result = await Get.toNamed(
      AppRoutes.addCow,
      arguments: {'gaushalaId': selectedGaushalaId.value},
    );
    // If a cow was added, refresh the list
    if (result == true || selectedGaushalaId.value != null) {
      fetchCows(
        gaushalaId: selectedGaushalaId.value,
        gender: selectedGenderFilter.value,
        showLoading: false,
      );
    }
  }

  /// Navigate to Edit Cow Screen
  Future<void> goToEditCow(CowModel cow) async {
    if (!cow.canEdit) {
      CustomSnackbar.showWarning(
        title: 'Action Not Allowed',
        message: 'Cannot edit a ${cow.statusDisplay.toLowerCase()} cattle record.',
      );
      return;
    }
    final result = await Get.toNamed(
      AppRoutes.editCow,
      arguments: {
        'isEdit': true,
        'cow': cow,
        'gaushalaId': cow.gaushala?.id ?? selectedGaushalaId.value,
      },
    );
    // If a cow was updated, refresh the list
    if (result == true || selectedGaushalaId.value != null) {
      fetchCows(
        gaushalaId: selectedGaushalaId.value,
        gender: selectedGenderFilter.value,
        showLoading: false,
      );
    }
  }

  /// Delete a cow
  Future<void> confirmDeleteCow(BuildContext context, CowModel cow) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Delete Cattle Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete cattle with Tag ID "${cow.tagId}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Delete',
            icon: Icons.delete_outline_rounded,
            variant: ButtonVariant.danger,
            width: 110,
            height: 38,
            onPressed: () => Navigator.of(dialogCtx).pop(true),
          ),

        ],
      ),
    );

    if (confirmed == true) {
      try {
        isDeleting.value = true;
        final success = await _apiService.deleteCow(cow.id);
        if (success) {
          cows.removeWhere((c) => c.id == cow.id);
          _cachedCows.removeWhere((c) => c.id == cow.id);
          fetchCows(
            gaushalaId: selectedGaushalaId.value,
            showLoading: false,
            isManualRefresh: false,
          );
          CustomSnackbar.showSuccess(
            title: 'Deleted',
            message: 'Cattle ${cow.tagId} has been removed.',
          );
        }
      } catch (_) {
        // Handled by ApiService
      } finally {
        isDeleting.value = false;
      }
    }
  }

  /// Toggle cattle active/inactive status. POST /cows/:id/status
  Future<void> toggleCowStatus(CowModel cow) async {
    if (cow.isDeleted || cow.isDelete || cow.isDead || cow.isDied) return;
    if (updatingStatusCowIds.contains(cow.id)) return;

    final newStatus = !cow.isActive;
    updatingStatusCowIds.add(cow.id);

    try {
      final success = await _apiService.updateCowStatus(cow.id, newStatus);
      if (success) {
        // Optimistically update cow in memory
        final updatedCow = cow.copyWith(isActive: newStatus);
        final index = cows.indexWhere((c) => c.id == cow.id);
        if (index != -1) {
          cows[index] = updatedCow;
        }
        final cachedIndex = _cachedCows.indexWhere((c) => c.id == cow.id);
        if (cachedIndex != -1) {
          _cachedCows[cachedIndex] = updatedCow;
        }
        cows.refresh();

        CustomSnackbar.showSuccess(
          title: 'Status Updated',
          message: 'Tag ${cow.tagId} is now ${newStatus ? "Active" : "InActive"}.',
        );

        // Background sync to update counts
        fetchCows(
          gaushalaId: selectedGaushalaId.value,
          showLoading: false,
          isManualRefresh: false,
        );
      } else {
        CustomSnackbar.showError(
          title: 'Update Failed',
          message: 'Could not update status for Tag ${cow.tagId}.',
        );
      }
    } catch (_) {
      // Handled by ApiService
    } finally {
      updatingStatusCowIds.remove(cow.id);
    }
  }

  /// Mark a cow as deceased (died). POST /cows/:id/died
  Future<void> showMarkDiedDialog(BuildContext context, CowModel cow) async {
    if (cow.isDeleted || cow.isDelete) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime selectedDate = cow.sendDiedDate?.isNotEmpty == true
        ? (DateTime.tryParse(cow.sendDiedDate!) ?? DateTime.now())
        : DateTime.now();

    final result = await showDialog<DateTime?>(
      context: context,
      builder: (dialogCtx) {
        DateTime tempDate = selectedDate;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.heart_broken_rounded, color: Colors.red, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Record Cattle Death', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Record death or departure date for Tag ID "${cow.tagId}".',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Death Date',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => tempDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              DateFormat('yyyy-MM-dd').format(tempDate),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This will update the cattle record status to death with the specified date.',
                            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.red.shade200 : Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(null),
                  child: const Text('Cancel'),
                ),
                CustomButton(
                  text: 'Mark Death',
                  icon: Icons.heart_broken_rounded,
                  variant: ButtonVariant.danger,
                  width: 150,
                  height: 38,
                  onPressed: () => Navigator.of(dialogCtx).pop(tempDate),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(result);
      try {
        updatingDiedCowIds.add(cow.id);
        final success = await _apiService.markCowDied(cow.id, formattedDate);
        if (success) {
          final updatedCow = cow.copyWith(
            sendDiedDate: formattedDate,
            isDied: true,
            isActive: false,
          );
          final index = cows.indexWhere((c) => c.id == cow.id);
          if (index != -1) {
            cows[index] = updatedCow;
          }
          final cachedIndex = _cachedCows.indexWhere((c) => c.id == cow.id);
          if (cachedIndex != -1) {
            _cachedCows[cachedIndex] = updatedCow;
          }
          cows.refresh();

          CustomSnackbar.showSuccess(
            title: 'Recorded',
            message: 'Cattle ${cow.tagId} marked as died ($formattedDate).',
          );

          // Background sync counts
          fetchCows(
            gaushalaId: selectedGaushalaId.value,
            showLoading: false,
            isManualRefresh: false,
          );
        } else {
          CustomSnackbar.showError(
            title: 'Update Failed',
            message: 'Could not record death date for Tag ${cow.tagId}.',
          );
        }
      } catch (_) {
        // Handled by ApiService
      } finally {
        updatingDiedCowIds.remove(cow.id);
      }
    }
  }

  /// Executes cattle transfer to a new shed via POST /api/v1/cows/shed-transfer.
  Future<bool> executeShedTransfer({
    required String gaushalaId,
    required List<String> cowIds,
    required String toShedId,
    required String reason,
    required DateTime transferDate,
    ShedModel? targetShed,
  }) async {
    if (cowIds.isEmpty) {
      CustomSnackbar.showWarning(
        title: 'Selection Required',
        message: 'Please select at least one cattle to transfer.',
      );
      return false;
    }
    if (toShedId.isEmpty) {
      CustomSnackbar.showWarning(
        title: 'Target Shed Required',
        message: 'Please select a destination shed.',
      );
      return false;
    }

    isTransferringShed.value = true;
    try {
      final request = ShedTransferRequestModel(
        gaushalaId: gaushalaId,
        cowIds: cowIds,
        toShedId: toShedId,
        reason: reason.trim().isNotEmpty ? reason.trim() : 'Moved to shed',
        transferDate: transferDate.toUtc().toIso8601String(),
      );

      final res = await _apiService.transferCowShed(request);
      final msg = res['message']?.toString() ?? 'Cattle transferred to shed successfully.';

      // Immediately update local in-memory records
      if (targetShed != null) {
        final newShedRef = CowShedRef(
          id: targetShed.id,
          shedName: targetShed.shedName,
          shedNumber: targetShed.shedNumber,
        );
        for (final cowId in cowIds) {
          final idx = cows.indexWhere((c) => c.id == cowId);
          if (idx != -1) {
            cows[idx] = cows[idx].copyWith(shed: newShedRef);
          }
          final cIdx = _cachedCows.indexWhere((c) => c.id == cowId);
          if (cIdx != -1) {
            _cachedCows[cIdx] = _cachedCows[cIdx].copyWith(shed: newShedRef);
          }
        }
        cows.refresh();
      }

      // Re-fetch herd data silently in background to keep all attributes consistent
      fetchCows();

      CustomSnackbar.showSuccess(
        title: 'Transfer Complete',
        message: msg,
      );
      return true;
    } on DioException catch (dioErr) {
      final errMsg = dioErr.response?.data?['message']?.toString() ??
          dioErr.message ??
          'Failed to transfer cattle to shed.';
      CustomSnackbar.showError(
        title: 'Transfer Failed',
        message: errMsg,
      );
      return false;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: e.toString(),
      );
      return false;
    } finally {
      isTransferringShed.value = false;
    }
  }

  /// Opens the Cattle Shed Transfer dialog modal.
  Future<void> openShedTransferDialog(
    BuildContext context, {
    CowModel? cow,
    List<CowModel>? preselectedCows,
  }) async {
    if (cow != null && !cow.canTransferShed) {
      CustomSnackbar.showWarning(
        title: 'Action Not Allowed',
        message: 'Cannot transfer a ${cow.statusDisplay.toLowerCase()} cattle record.',
      );
      return;
    }
    await ShedTransferDialog.show(
      context: context,
      cow: cow,
      preselectedCows: preselectedCows,
      controller: this,
    );
  }

  /// Opens the Cattle Shed Transfer History dialog modal.
  Future<void> openShedTransferHistoryDialog(
    BuildContext context, {
    String? gaushalaId,
    String? cowId,
    CowModel? cow,
  }) async {
    await ShedTransferHistoryDialog.show(
      context: context,
      gaushalaId: gaushalaId ?? selectedGaushalaId.value ?? globalGaushalaId,
      gaushalaName: selectedGaushalaName,
      cowId: cowId ?? cow?.id,
      cow: cow,
    );
  }

  /// Open comprehensive Cow Details Modal with modern executive UI
  void openCowDetailsDialog(BuildContext context, CowModel cow) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth < 600 ? 14 : 24,
          vertical: screenHeight < 700 ? 16 : 28,
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 760,
            maxHeight: screenHeight * 0.90,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -------------------------------------------------------------
              // 1. EXECUTIVE HEADER BANNER
              // -------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.surfaceDark,
                            AppColors.cardDark,
                          ]
                        : [
                            AppColors.primary.withValues(alpha: 0.08),
                            AppColors.primaryLight.withValues(alpha: 0.03),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cattle Avatar Ring
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: cow.isFemale
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFE3F2FD),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cow.isFemale
                              ? AppColors.primary.withValues(alpha: 0.45)
                              : Colors.blue.withValues(alpha: 0.45),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (cow.isFemale ? AppColors.primary : Colors.blue)
                                .withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: cow.avatarUrl != null && cow.avatarUrl!.trim().isNotEmpty
                            ? Image.network(
                                cow.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(cow),
                              )
                            : _buildFallbackAvatar(cow),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Tag, Badges & Metadata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tag ID & Action & Badges
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Text(
                                cow.tagId,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              // Copy Tag Button
                              Tooltip(
                                message: 'Copy Tag ID',
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: cow.tagId));
                                    CustomSnackbar.showInfo(
                                      title: 'Copied',
                                      message: 'Tag ID ${cow.tagId} copied to clipboard',
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.surfaceDark
                                          : AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.borderDark
                                            : AppColors.borderLight,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.copy_rounded,
                                      size: 13,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                              ),

                              // Gender Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: cow.isFemale
                                      ? AppColors.primary.withValues(alpha: 0.12)
                                      : Colors.blue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: cow.isFemale
                                        ? AppColors.primary.withValues(alpha: 0.25)
                                        : Colors.blue.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      cow.isFemale
                                          ? PhosphorIconsRegular.genderFemale
                                          : PhosphorIconsRegular.genderMale,
                                      size: 12,
                                      color: cow.isFemale
                                          ? AppColors.primary
                                          : Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      cow.isFemale ? 'Female / Cow' : 'Male / Bull',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: cow.isFemale
                                            ? AppColors.primary
                                            : Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Breed Pill
                              if (cow.breed?.breedName.isNotEmpty == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.accent.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(PhosphorIconsRegular.dna, size: 12, color: AppColors.accent),
                                      const SizedBox(width: 4),
                                      Text(
                                        cow.breed!.breedName,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Status Pill
                              Builder(
                                builder: (context) {
                                  final isCowDeleted = cow.isDeleted || cow.isDelete;
                                  final isCowDied = !isCowDeleted && (cow.isDead || cow.isDied);
                                  final isCowInactive = !isCowDeleted && !isCowDied && !cow.isActive;

                                  final String pillText;
                                  final Color pillBg;
                                  final Color pillTextColor;

                                  if (isCowDeleted) {
                                    pillText = '● Deleted';
                                    pillBg = isDark ? Colors.red.withValues(alpha: 0.15) : AppColors.errorBg;
                                    pillTextColor = AppColors.error;
                                  } else if (isCowDied) {
                                    pillText = cow.sendDiedDate?.isNotEmpty == true
                                        ? '● Died (${cow.sendDiedDate})'
                                        : '● Died';
                                    pillBg = Colors.red.withValues(alpha: 0.12);
                                    pillTextColor = Colors.red.shade700;
                                  } else if (isCowInactive) {
                                    pillText = '● InActive';
                                    pillBg = isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.15);
                                    pillTextColor = isDark ? AppColors.textSecondaryDark : Colors.grey.shade700;
                                  } else {
                                    pillText = '● Active';
                                    pillBg = const Color(0xFFE8F5E9);
                                    pillTextColor = const Color(0xFF2E7D32);
                                  }

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: pillBg,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      pillText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: pillTextColor,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Subtitle Alias & Type
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              if (cow.calfName?.isNotEmpty == true)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(PhosphorIconsRegular.tag, size: 13, color: AppColors.textSecondaryLight),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Alias: "${cow.calfName}"',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                const Text(
                                  'No alias assigned',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMutedLight,
                                  ),
                                ),
                              if (cow.cowType?.typeName.isNotEmpty == true) ...[
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: AppColors.textMutedLight,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  'Stage: ${cow.cowType!.typeName}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Modern Close Button
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark.withValues(alpha: 0.8)
                              : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              // -------------------------------------------------------------
              // 2. SCROLLABLE DETAILS BODY
              // -------------------------------------------------------------
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 580;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // A. KPI Micro-Cards Ribbon
                          _buildKpiRibbon(context, isDark, cow, isWide),
                          const SizedBox(height: 20),

                          // B. Pedigree & Lineage Card
                          _buildSectionCard(
                            context: context,
                            isDark: isDark,
                            title: 'PEDIGREE & LINEAGE',
                            icon: PhosphorIconsRegular.gitFork,
                            child: isWide
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildLineageCard(
                                          context: context,
                                          isDark: isDark,
                                          role: 'Dam (Mother)',
                                          tagId: cow.dam?.tagId,
                                          isMother: true,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: _buildLineageCard(
                                          context: context,
                                          isDark: isDark,
                                          role: 'Sire (Father)',
                                          tagId: cow.sire?.tagId,
                                          isMother: false,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _buildLineageCard(
                                        context: context,
                                        isDark: isDark,
                                        role: 'Dam (Mother)',
                                        tagId: cow.dam?.tagId,
                                        isMother: true,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildLineageCard(
                                        context: context,
                                        isDark: isDark,
                                        role: 'Sire (Father)',
                                        tagId: cow.sire?.tagId,
                                        isMother: false,
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 18),

                          // C. Classification & Facility Card
                          _buildSectionCard(
                            context: context,
                            isDark: isDark,
                            title: 'CLASSIFICATION & FACILITY HOUSING',
                            icon: PhosphorIconsRegular.warehouse,
                            child: _buildDetailsGrid(
                              isWide: isWide,
                              items: [
                                _DetailGridItem(
                                  icon: PhosphorIconsRegular.dna,
                                  label: 'Breed',
                                  value: cow.breed?.breedName ?? 'N/A',
                                ),
                                _DetailGridItem(
                                  icon: PhosphorIconsRegular.tag,
                                  label: 'Cattle Stage / Type',
                                  value: cow.cowType?.typeName ?? 'N/A',
                                ),
                                _DetailGridItem(
                                  icon: PhosphorIconsRegular.buildings,
                                  label: 'Gaushala Unit',
                                  value: cow.gaushala?.gaushalaName ?? 'N/A',
                                ),
                                _DetailGridItem(
                                  icon: PhosphorIconsRegular.warehouse,
                                  label: 'Housing Shed',
                                  value: cow.shed?.shedName ?? 'Unassigned',
                                ),
                                _DetailGridItem(
                                  icon: PhosphorIconsRegular.hash,
                                  label: 'Shed Number',
                                  value: cow.shed?.shedNumber ?? 'N/A',
                                ),
                                _DetailGridItem(
                                  icon: PhosphorIconsRegular.user,
                                  label: 'Registered By',
                                  value: cow.addedBy?.name ?? cow.addedBy?.username ?? 'Ayushka Admin',
                                ),
                              ],
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // D. Lifecycle & Acquisition Timeline
                          _buildSectionCard(
                            context: context,
                            isDark: isDark,
                            title: 'LIFECYCLE & ACQUISITION TIMELINE',
                            icon: PhosphorIconsRegular.clock,
                            child: _buildDetailsGrid(
                              isWide: isWide,
                              items: [
                                _DetailGridItem(
                                  icon: PhosphorIconsRegular.calendarBlank,
                                  label: 'Date of Birth',
                                  value: _formatDate(cow.dob),
                                  badge: _calculateAge(cow.dob),
                                ),
                                _DetailGridItem(
                                  icon: PhosphorIconsRegular.shoppingCart,
                                  label: 'Purchase Date',
                                  value: _formatDate(cow.purchaseDate),
                                ),
                                _DetailGridItem(
                                  icon: PhosphorIconsRegular.clockAfternoon,
                                  label: 'Calving / Delivery Time',
                                  value: cow.deliveryTime?.isNotEmpty == true ? cow.deliveryTime! : 'Not recorded',
                                ),
                                _DetailGridItem(
                                  icon: PhosphorIconsRegular.notepad,
                                  label: 'Current Status',
                                  value: (cow.isDeleted || cow.isDelete)
                                      ? 'Deleted'
                                      : ((cow.isDead || cow.isDied)
                                          ? (cow.sendDiedDate?.isNotEmpty == true
                                              ? 'Died: ${_formatDate(cow.sendDiedDate)}'
                                              : 'Died')
                                          : (cow.isActive ? 'Active Gaushala Cattle' : 'InActive')),
                                ),
                              ],
                              isDark: isDark,
                            ),
                          ),

                          // E. Field Remarks & Observations (if present)
                          if (cow.remark?.isNotEmpty == true) ...[
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : const Color(0xFFF9FBF7),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      PhosphorIconsRegular.chatText,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'FIELD REMARKS & OBSERVATIONS',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          cow.remark!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1.5,
                                            color: isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),

              // -------------------------------------------------------------
              // 3. BOTTOM ACTION BAR & SYSTEM ID
              // -------------------------------------------------------------
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.6) : AppColors.backgroundLight,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // System Mongo ID & Creation date metadata strip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Tooltip(
                          message: 'Click to copy System ID (${cow.id})',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: cow.id));
                              CustomSnackbar.showInfo(
                                title: 'Copied',
                                message: 'Cattle System ID copied to clipboard',
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.tag_rounded, size: 12, color: AppColors.textSecondaryLight),
                                  const SizedBox(width: 4),
                                  Text(
                                    cow.id.length > 12 ? '${cow.id.substring(0, 10)}...' : cow.id,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.copy_rounded, size: 11, color: AppColors.textSecondaryLight),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (cow.createdAt != null)
                          Text(
                            'Added on ${_formatDate(cow.createdAt!.toIso8601String())}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Clean, modern horizontal action bar
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 620;

                        final moreActionsButton = (!cow.isDead && !cow.isDied && !cow.isDeleted && !cow.isDelete)
                            ? Theme(
                                data: Theme.of(context).copyWith(
                                  cardColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                                ),
                                child: PopupMenuButton<String>(
                                  tooltip: 'Status & dangerous actions',
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                    ),
                                  ),
                                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                                  elevation: 6,
                                  onSelected: (val) {
                                    if (val == 'status') {
                                      Navigator.of(ctx).pop();
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        toggleCowStatus(cow);
                                      });
                                    } else if (val == 'died') {
                                      Navigator.of(ctx).pop();
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        showMarkDiedDialog(context, cow);
                                      });
                                    }
                                  },
                                  itemBuilder: (menuCtx) => [
                                    PopupMenuItem(
                                      value: 'status',
                                      height: 38,
                                      child: Row(
                                        children: [
                                          Icon(
                                            cow.isActive
                                                ? Icons.power_settings_new_rounded
                                                : Icons.check_circle_outline_rounded,
                                            size: 16,
                                            color: cow.isActive ? Colors.orange : AppColors.primary,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            cow.isActive ? 'Deactivate Record' : 'Activate Record',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'died',
                                      height: 38,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.heart_broken_rounded,
                                            size: 16,
                                            color: Colors.red.shade700,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            (cow.isDead || cow.isDied) ? 'Update Death Date' : 'Mark as Died',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.red.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  child: Container(
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.cardDark : Colors.transparent,
                                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                                      border: Border.all(
                                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          PhosphorIconsRegular.dotsThreeCircle,
                                          size: 16,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'More Actions',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 16,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();

                        final actionButtons = <Widget>[
                          CustomButton(
                            text: 'Shed History',
                            icon: PhosphorIconsRegular.clockCounterClockwise,
                            variant: ButtonVariant.outlined,
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            onPressed: () {
                              openShedTransferHistoryDialog(context, cow: cow);
                            },
                          ),
                          if (cow.canTransferShed)
                            CustomButton(
                              text: 'Transfer Shed',
                              icon: PhosphorIconsRegular.arrowsLeftRight,
                              variant: ButtonVariant.outlined,
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  openShedTransferDialog(context, cow: cow);
                                });
                              },
                            ),
                          CustomButton(
                            text: 'Close',
                            variant: ButtonVariant.outlined,
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                          if (cow.canEdit)
                            CustomButton(
                              text: 'Edit Cattle',
                              icon: PhosphorIconsRegular.pencilSimple,
                              variant: ButtonVariant.primary,
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                goToEditCow(cow);
                              },
                            ),
                        ];

                        if (isCompact) {
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              moreActionsButton,
                              ...actionButtons,
                            ],
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            moreActionsButton,
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (int i = 0; i < actionButtons.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 8),
                                  actionButtons[i],
                                ],
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fallback Avatar Icon when network avatar is unavailable
  Widget _buildFallbackAvatar(CowModel cow) {
    return Center(
      child: Icon(
        cow.isFemale ? PhosphorIconsRegular.genderFemale : PhosphorIconsRegular.genderMale,
        color: cow.isFemale ? AppColors.primary : Colors.blue.shade700,
        size: 26,
      ),
    );
  }

  /// KPI Micro-Cards Ribbon (Weight, Age, Shed, Gaushala)
  Widget _buildKpiRibbon(BuildContext context, bool isDark, CowModel cow, bool isWide) {
    final weightCard = _buildKpiCard(
      isDark: isDark,
      icon: PhosphorIconsRegular.scales,
      color: const Color(0xFFE98324),
      label: 'WEIGHT',
      value: cow.calfWeight > 0 ? '${cow.calfWeight} kg' : 'Not recorded',
      subtitle: 'Recorded mass',
    );

    final ageText = _calculateAge(cow.dob);
    final ageCard = _buildKpiCard(
      isDark: isDark,
      icon: PhosphorIconsRegular.calendarBlank,
      color: AppColors.primary,
      label: 'AGE',
      value: ageText.isNotEmpty ? ageText : _formatDate(cow.dob),
      subtitle: cow.dob?.isNotEmpty == true ? 'Born: ${_formatDate(cow.dob)}' : 'DOB not specified',
    );

    final shedCard = _buildKpiCard(
      isDark: isDark,
      icon: PhosphorIconsRegular.warehouse,
      color: const Color(0xFF2E7D32),
      label: 'ASSIGNED SHED',
      value: cow.shed?.shedName ?? 'Unassigned',
      subtitle: (cow.shed?.shedNumber != null && cow.shed!.shedNumber.isNotEmpty)
          ? 'No: ${cow.shed!.shedNumber}'
          : 'No shed code',
    );

    final gaushalaCard = _buildKpiCard(
      isDark: isDark,
      icon: PhosphorIconsRegular.buildings,
      color: const Color(0xFF455A64),
      label: 'GAUSHALA STATION',
      value: cow.gaushala?.gaushalaName ?? 'N/A',
      subtitle: 'Primary station',
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(child: weightCard),
          const SizedBox(width: 10),
          Expanded(child: ageCard),
          const SizedBox(width: 10),
          Expanded(child: shedCard),
          const SizedBox(width: 10),
          Expanded(child: gaushalaCard),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: weightCard),
              const SizedBox(width: 10),
              Expanded(child: ageCard),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: shedCard),
              const SizedBox(width: 10),
              Expanded(child: gaushalaCard),
            ],
          ),
        ],
      );
    }
  }

  /// Individual KPI Micro-Card
  Widget _buildKpiCard({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icon, color: color, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMutedLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Visual Pedigree / Lineage Card (Dam & Sire)
  Widget _buildLineageCard({
    required BuildContext context,
    required bool isDark,
    required String role,
    required String? tagId,
    required bool isMother,
  }) {
    final hasParent = tagId != null &&
        tagId.trim().isNotEmpty &&
        !tagId.toLowerCase().contains('unknown') &&
        !tagId.toLowerCase().contains('not linked');
    final accentColor = isMother ? AppColors.primary : Colors.blue.shade700;
    final bgTint = isMother
        ? (isDark ? AppColors.primary.withValues(alpha: 0.12) : const Color(0xFFF2F7EF))
        : (isDark ? Colors.blue.withValues(alpha: 0.10) : const Color(0xFFF0F6FD));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    isMother ? PhosphorIconsRegular.genderFemale : PhosphorIconsRegular.genderMale,
                    color: accentColor,
                    size: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  role,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (hasParent ? accentColor : AppColors.textMutedLight).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasParent ? 'Linked' : 'Unlinked',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: hasParent ? accentColor : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasParent ? tagId : 'Unknown / Not Linked',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: hasParent ? 'monospace' : null,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hasParent
                ? (isMother ? 'Registered Dam Profile' : 'Registered Sire Profile')
                : (isMother ? 'External purchase or dam untracked' : 'Artificial Insemination / Sire untracked'),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  /// Section Card Wrapper
  Widget _buildSectionCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 15, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  /// Grid of Key-Value Items
  Widget _buildDetailsGrid({
    required bool isWide,
    required List<_DetailGridItem> items,
    required bool isDark,
  }) {
    return Wrap(
      spacing: 16,
      runSpacing: 14,
      children: items.map((item) {
        final itemWidth = isWide ? (760 - 44 - 32 - 16) / 2 : double.infinity;
        return SizedBox(
          width: itemWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.icon,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.value,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                        if (item.badge != null && item.badge!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.badge!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Helper date formatter
  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return 'Not recorded';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed != null) {
      return DateFormat('dd MMM yyyy').format(parsed);
    }
    return rawDate;
  }

  /// Helper age calculator
  String _calculateAge(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return '';
    final dob = DateTime.tryParse(rawDate);
    if (dob == null) return '';
    final now = DateTime.now();
    if (dob.isAfter(now)) return '';
    final difference = now.difference(dob);
    final days = difference.inDays;
    final years = days ~/ 365;
    final months = (days % 365) ~/ 30;
    if (years > 0 && months > 0) {
      return '$years yr${years > 1 ? 's' : ''}, $months mo${months > 1 ? 's' : ''}';
    } else if (years > 0) {
      return '$years yr${years > 1 ? 's' : ''}';
    } else if (months > 0) {
      return '$months mo${months > 1 ? 's' : ''}';
    } else {
      final weeks = days ~/ 7;
      if (weeks > 0) return '$weeks wk${weeks > 1 ? 's' : ''}';
      return '$days day${days > 1 ? 's' : ''}';
    }
  }
}

class _DetailGridItem {
  final IconData icon;
  final String label;
  final String value;
  final String? badge;

  const _DetailGridItem({
    required this.icon,
    required this.label,
    required this.value,
    this.badge,
  });
}

