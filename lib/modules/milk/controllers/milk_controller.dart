import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:ayushka/app/core/widgets/custom_snackbar.dart';
import 'package:ayushka/app/data/models/cow_model.dart';
import 'package:ayushka/app/data/models/notification_model.dart';
import 'package:ayushka/app/data/models/user_model.dart';
import 'package:ayushka/app/data/models/worker_model.dart';
import 'package:ayushka/app/data/services/api_service.dart';
import 'package:ayushka/app/data/services/gaushala_session_service.dart';
import 'package:ayushka/app/data/services/storage_service.dart';
import 'package:ayushka/app/routes/app_routes.dart';
import '../models/fridge_stock_model.dart';
import '../models/milk_daily_summary_model.dart';
import '../models/milk_disposal_model.dart';
import '../models/milk_distribution_model.dart';
import '../models/milk_production_model.dart';
import '../services/milk_api_service.dart';

/// Main GetxController for Milk Production & Distribution Module
class MilkController extends GetxController {
  final MilkApiService _milkApiService = Get.find<MilkApiService>();
  final ApiService _apiService = Get.find<ApiService>();
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();
  final StorageService _storageService = Get.find<StorageService>();

  // ---------------------------------------------------------------------------
  // NAVIGATION & SHELL
  // ---------------------------------------------------------------------------
  final RxBool isSidebarCollapsed = false.obs;
  UserModel? get currentUser => _storageService.getUser();

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  void logout() async {
    await _storageService.clearAll();
    Get.offAllNamed(AppRoutes.auth);
  }

  // ---------------------------------------------------------------------------
  // ACTIVE GAUSHALA & LISTENERS
  // ---------------------------------------------------------------------------
  String get currentGaushalaId => _gaushalaService.selectedGaushalaId;
  String get selectedGaushalaName => _gaushalaService.selectedGaushalaName;

  final RxMap<String, WorkerModel> allWorkersMap = <String, WorkerModel>{}.obs;
  final RxMap<String, CowModel> allCowsMap = <String, CowModel>{}.obs;

  WorkerModel? findWorkerById(String? id) {
    if (id == null || id.isEmpty) return null;
    return allWorkersMap[id] ?? activeWorkers.firstWhereOrNull((w) => w.id == id);
  }

  CowModel? findCowById(String? id) {
    if (id == null || id.isEmpty) return null;
    return allCowsMap[id] ?? activeCows.firstWhereOrNull((c) => c.id == id);
  }

  // ---------------------------------------------------------------------------
  // DATE CONTROLS
  // ---------------------------------------------------------------------------
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  String get selectedDateFormatted => DateFormat('yyyy-MM-dd').format(selectedDate.value);
  String get selectedDateDisplay => DateFormat('dd MMM yyyy').format(selectedDate.value);

  bool get isSelectedDateToday {
    final now = DateTime.now();
    return selectedDate.value.year == now.year &&
        selectedDate.value.month == now.month &&
        selectedDate.value.day == now.day;
  }

  bool get isSelectedDatePast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel = DateTime(selectedDate.value.year, selectedDate.value.month, selectedDate.value.day);
    return sel.isBefore(today);
  }

  void setSelectedDate(DateTime date) {
    selectedDate.value = date;
    productionPage.value = 1;
    distributionPage.value = 1;
    refreshDateSensitiveData();
  }

  void previousDay() {
    setSelectedDate(selectedDate.value.subtract(const Duration(days: 1)));
  }

  void nextDay() {
    setSelectedDate(selectedDate.value.add(const Duration(days: 1)));
  }

  // ---------------------------------------------------------------------------
  // TABS STATE
  // ---------------------------------------------------------------------------
  // 0: Overview/Summary, 1: Production, 2: Distribution, 3: Fridge Stock & Disposal, 4: Monthly Variance
  final RxInt selectedTab = 0.obs;

  void changeTab(int index) {
    selectedTab.value = index;
    if (index == 0) {
      fetchDailySummary();
      fetchMilkNotifications();
    } else if (index == 1) {
      fetchProduction();
    } else if (index == 2) {
      fetchDistribution();
    } else if (index == 3) {
      fetchFridgeStock();
      fetchDisposals();
    } else if (index == 4) {
      fetchMilkNotifications();
    }
  }

  // ---------------------------------------------------------------------------
  // 1. DAILY BALANCE SHEET & SUMMARY STATE
  // ---------------------------------------------------------------------------
  final Rxn<MilkDailySummaryModel> dailySummary = Rxn<MilkDailySummaryModel>();
  final RxBool isLoadingSummary = false.obs;

  Future<void> fetchDailySummary({String? date}) async {
    if (currentGaushalaId.isEmpty) return;
    isLoadingSummary.value = true;
    try {
      final res = await _milkApiService.getDailySummary(
        gaushalaId: currentGaushalaId,
        date: date ?? selectedDateFormatted,
      );
      dailySummary.value = res;
    } catch (e) {
      // Quiet fail or snackbar if appropriate
      dailySummary.value = const MilkDailySummaryModel();
    } finally {
      isLoadingSummary.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // 2. PRODUCTION TAB STATE
  // ---------------------------------------------------------------------------
  final RxString productionShift = 'all'.obs;
  final RxInt productionPage = 1.obs;
  final RxInt productionLimit = 10.obs;
  final RxInt productionTotal = 0.obs;
  final RxInt productionTotalPages = 1.obs;
  final RxList<MilkProductionModel> productionList = <MilkProductionModel>[].obs;
  final RxBool isLoadingProduction = false.obs;

  void changeProductionShift(String shift) {
    if (productionShift.value == shift) return;
    productionShift.value = shift;
    productionPage.value = 1;
    fetchProduction();
  }

  void onProductionPageChanged(int page) {
    productionPage.value = page;
    fetchProduction();
  }

  void onProductionRowsPerPageChanged(int limit) {
    productionLimit.value = limit;
    productionPage.value = 1;
    fetchProduction();
  }

  Future<void> fetchProduction() async {
    if (currentGaushalaId.isEmpty) return;
    isLoadingProduction.value = true;
    try {
      if (allCowsMap.isEmpty || allWorkersMap.isEmpty) {
        unawaited(fetchAuxData());
      }
      final res = await _milkApiService.getProductionList(
        gaushalaId: currentGaushalaId,
        date: selectedDateFormatted,
        shift: productionShift.value == 'all' ? null : productionShift.value,
        page: productionPage.value,
        limit: productionLimit.value,
      );
      productionList.assignAll(res.items);
      productionTotal.value = res.total;
      productionTotalPages.value = res.totalPages;
      enrichProductionItemsWithAuxData();
    } catch (e) {
      productionList.clear();
      productionTotal.value = 0;
    } finally {
      isLoadingProduction.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // 3. DISTRIBUTION TAB STATE
  // ---------------------------------------------------------------------------
  final RxString distributionShift = 'all'.obs;
  final RxInt distributionPage = 1.obs;
  final RxInt distributionLimit = 10.obs;
  final RxInt distributionTotal = 0.obs;
  final RxInt distributionTotalPages = 1.obs;
  final RxList<MilkDistributionModel> distributionList = <MilkDistributionModel>[].obs;
  final RxBool isLoadingDistribution = false.obs;

  void changeDistributionShift(String shift) {
    if (distributionShift.value == shift) return;
    distributionShift.value = shift;
    distributionPage.value = 1;
    fetchDistribution();
  }

  void onDistributionPageChanged(int page) {
    distributionPage.value = page;
    fetchDistribution();
  }

  void onDistributionRowsPerPageChanged(int limit) {
    distributionLimit.value = limit;
    distributionPage.value = 1;
    fetchDistribution();
  }

  Future<void> fetchDistribution() async {
    if (currentGaushalaId.isEmpty) return;
    isLoadingDistribution.value = true;
    try {
      final res = await _milkApiService.getDistributionList(
        gaushalaId: currentGaushalaId,
        milkDate: selectedDateFormatted,
        shift: distributionShift.value == 'all' ? null : distributionShift.value,
        page: distributionPage.value,
        limit: distributionLimit.value,
      );
      distributionList.assignAll(res.items);
      distributionTotal.value = res.total;
      distributionTotalPages.value = res.totalPages;
      enrichDistributionItemsWithAuxData();
    } catch (e) {
      distributionList.clear();
      distributionTotal.value = 0;
    } finally {
      isLoadingDistribution.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // 4. FRIDGE / LEFTOVER STOCK & DISPOSAL STATE
  // ---------------------------------------------------------------------------
  final RxList<FridgeStockModel> fridgeStockList = <FridgeStockModel>[].obs;
  final RxBool isLoadingFridgeStock = false.obs;

  final RxList<MilkDisposalModel> disposalList = <MilkDisposalModel>[].obs;
  final RxInt disposalPage = 1.obs;
  final RxInt disposalLimit = 10.obs;
  final RxInt disposalTotal = 0.obs;
  final RxInt disposalTotalPages = 1.obs;
  final RxBool isLoadingDisposal = false.obs;

  Future<void> fetchFridgeStock() async {
    if (currentGaushalaId.isEmpty) return;
    isLoadingFridgeStock.value = true;
    try {
      final res = await _milkApiService.getFridgeStockList(gaushalaId: currentGaushalaId);
      fridgeStockList.assignAll(res);
    } catch (e) {
      fridgeStockList.clear();
    } finally {
      isLoadingFridgeStock.value = false;
    }
  }

  void onDisposalPageChanged(int page) {
    disposalPage.value = page;
    fetchDisposals();
  }

  void onDisposalRowsPerPageChanged(int limit) {
    disposalLimit.value = limit;
    disposalPage.value = 1;
    fetchDisposals();
  }

  Future<void> fetchDisposals() async {
    if (currentGaushalaId.isEmpty) return;
    isLoadingDisposal.value = true;
    try {
      if (allWorkersMap.isEmpty) {
        unawaited(fetchAuxData());
      }
      final res = await _milkApiService.getDisposalList(
        gaushalaId: currentGaushalaId,
        page: disposalPage.value,
        limit: disposalLimit.value,
      );
      disposalList.assignAll(res.items);
      disposalTotal.value = res.total;
      disposalTotalPages.value = res.totalPages;
      enrichDisposalItemsWithAuxData();
    } catch (e) {
      disposalList.clear();
      disposalTotal.value = 0;
    } finally {
      isLoadingDisposal.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // 5. MONTHLY VARIANCE & ALERTS STATE
  // ---------------------------------------------------------------------------
  final RxInt varianceYear = DateTime.now().year.obs;
  final RxInt varianceMonth = (DateTime.now().month == 1 ? 12 : DateTime.now().month - 1).obs;
  final RxBool isCheckingMonthlyAlerts = false.obs;
  final Rxn<Map<String, dynamic>> monthlyAlertResult = Rxn<Map<String, dynamic>>();

  final RxList<NotificationModel> milkNotifications = <NotificationModel>[].obs;
  final RxBool isLoadingNotifications = false.obs;

  Future<void> runMonthlyAnalysis({int? year, int? month}) async {
    if (currentGaushalaId.isEmpty) {
      CustomSnackbar.showWarning(title: 'Gaushala Required', message: 'Please select a gaushala first.');
      return;
    }
    final targetYear = year ?? varianceYear.value;
    final targetMonth = month ?? varianceMonth.value;

    isCheckingMonthlyAlerts.value = true;
    try {
      final res = await _milkApiService.checkMonthlyAlerts(
        gaushalaId: currentGaushalaId,
        year: targetYear,
        month: targetMonth,
      );
      monthlyAlertResult.value = res;
      CustomSnackbar.showSuccess(
        title: 'Monthly Analysis Complete',
        message: 'Variance analysis for $targetMonth/$targetYear evaluated successfully.',
      );
      await fetchMilkNotifications();
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Analysis Failed',
        message: e.toString().replaceAll('Exception:', '').trim(),
      );
    } finally {
      isCheckingMonthlyAlerts.value = false;
    }
  }

  Future<void> fetchMilkNotifications() async {
    isLoadingNotifications.value = true;
    try {
      final res = await _milkApiService.getMilkAlertNotifications(gaushalaId: currentGaushalaId);
      milkNotifications.assignAll(res);
    } catch (e) {
      milkNotifications.clear();
    } finally {
      isLoadingNotifications.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // AUXILIARY DATA (COWS & WORKERS)
  // ---------------------------------------------------------------------------
  final RxList<CowModel> activeCows = <CowModel>[].obs;
  final RxList<WorkerModel> activeWorkers = <WorkerModel>[].obs;
  final RxBool isLoadingAuxData = false.obs;

  Future<void> fetchAuxData() async {
    if (currentGaushalaId.isEmpty) return;
    isLoadingAuxData.value = true;
    try {
      final cowFuture = _apiService.getCows(gaushalaId: currentGaushalaId);
      final workerFuture = _apiService.getWorkers(gaushalaId: currentGaushalaId, limit: 300);

      final results = await Future.wait([cowFuture, workerFuture]);
      final cowResp = results[0] as CowListResponse;
      final workerResp = results[1] as WorkerPaginatedResult;

      final allCowsList = cowResp.allCows.isNotEmpty
          ? cowResp.allCows
          : (cowResp.female.isNotEmpty ? [...cowResp.female, ...cowResp.male] : <CowModel>[]);

      allCowsMap.clear();
      for (final cow in allCowsList) {
        allCowsMap[cow.id] = cow;
      }

      final nonDeletedCows = allCowsList.where((c) => !c.isDied && !c.isDeleted).toList();
      final femaleCows = nonDeletedCows.where((c) => c.isFemale).toList();
      activeCows.assignAll(femaleCows.isNotEmpty ? femaleCows : nonDeletedCows);

      allWorkersMap.clear();
      for (final w in workerResp.items) {
        allWorkersMap[w.id] = w;
      }
      activeWorkers.assignAll(workerResp.items);

      enrichProductionItemsWithAuxData();
      enrichDisposalItemsWithAuxData();
      enrichDistributionItemsWithAuxData();
    } catch (e) {
      // Non-critical, but helpful
    } finally {
      isLoadingAuxData.value = false;
    }
  }

  void enrichDistributionItemsWithAuxData() {
    if (distributionList.isEmpty) return;
    final List<MilkDistributionModel> updated = [];
    bool hasChange = false;

    for (final dist in distributionList) {
      String resolvedRecipient = dist.recipientName;
      if (dist.recipientType == 'staff') {
        final worker = findWorkerById(dist.customerId ?? dist.recipientName);
        if (worker != null) {
          resolvedRecipient = worker.name;
          hasChange = true;
        } else if (MilkDistributionModel.isMongoHexId(resolvedRecipient)) {
          resolvedRecipient = 'Staff Member';
          hasChange = true;
        }
      } else if (MilkDistributionModel.isMongoHexId(resolvedRecipient)) {
        resolvedRecipient = dist.recipientTypeEnum.label;
        hasChange = true;
      }

      updated.add(dist.copyWith(recipientName: resolvedRecipient));
    }

    if (hasChange) {
      distributionList.assignAll(updated);
    }
  }

  void enrichDisposalItemsWithAuxData() {
    if (disposalList.isEmpty) return;
    final List<MilkDisposalModel> updated = [];
    bool hasChange = false;

    for (final d in disposalList) {
      String? resolvedName = d.reportedByName;
      final worker = findWorkerById(d.reportedBy);
      if (worker != null) {
        if (resolvedName == null ||
            resolvedName.isEmpty ||
            resolvedName.startsWith('Worker #') ||
            MilkDisposalModel.isMongoHexId(resolvedName)) {
          resolvedName = worker.name;
          hasChange = true;
        }
      }

      updated.add(d.copyWith(reportedByName: resolvedName));
    }

    if (hasChange) {
      disposalList.assignAll(updated);
    }
  }

  void enrichProductionItemsWithAuxData() {
    if (productionList.isEmpty) return;
    final List<MilkProductionModel> updated = [];
    bool hasChange = false;

    for (final prod in productionList) {
      String resolvedTag = prod.cowTag;
      String? resolvedName = prod.cowName;
      String? resolvedWorker = prod.workerName;

      final cow = findCowById(prod.cowId);
      if (cow != null) {
        if (resolvedTag.isEmpty || MilkProductionModel.isMongoHexId(resolvedTag)) {
          resolvedTag = cow.tagId;
          hasChange = true;
        }
        if (resolvedName == null || resolvedName.isEmpty || MilkProductionModel.isMongoHexId(resolvedName)) {
          resolvedName = cow.calfName;
          hasChange = true;
        }
      }

      final worker = findWorkerById(prod.workerId);
      if (worker != null) {
        if (resolvedWorker == null ||
            resolvedWorker.isEmpty ||
            resolvedWorker.startsWith('Worker #') ||
            MilkProductionModel.isMongoHexId(resolvedWorker)) {
          resolvedWorker = worker.name;
          hasChange = true;
        }
      }

      updated.add(prod.copyWith(
        cowTag: resolvedTag,
        cowName: resolvedName,
        workerName: resolvedWorker,
      ));
    }

    if (hasChange) {
      productionList.assignAll(updated);
    }
  }

  // ---------------------------------------------------------------------------
  // MUTATION ACTIONS (SINGLE, BULK, DISTRIBUTION, DISPOSAL)
  // ---------------------------------------------------------------------------

  /// Submit Single Milk Production
  Future<bool> submitSingleProduction({
    required String date,
    required String shift,
    required String cowId,
    required String workerId,
    required double quantity,
    String? remarks,
  }) async {
    try {
      final body = {
        'gaushalaId': currentGaushalaId,
        'date': date,
        'shift': shift,
        'cowId': cowId,
        'workerId': workerId,
        'quantity': quantity,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      };

      final created = await _milkApiService.createSingleProduction(body);
      CustomSnackbar.showSuccess(
        title: 'Production Recorded',
        message: 'Successfully recorded ${created.quantity} L for Cow Tag ${created.cowTag}.',
      );
      if (created.alertGenerated || (created.variance != null && created.variance!.abs() >= 10)) {
        CustomSnackbar.showWarning(
          title: 'Production Variance Alert',
          message: 'Notice: Cow production deviated by ±10% from historical records.',
        );
      }

      await refreshAll();
      return true;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Save Failed',
        message: e.toString().replaceAll('Exception:', '').trim(),
      );
      return false;
    }
  }

  /// Submit Bulk Milk Production
  Future<bool> submitBulkProduction({
    required String date,
    required String shift,
    String? defaultWorkerId,
    required List<BulkProductionEntryItem> entries,
  }) async {
    try {
      final validEntries = entries.where((e) => e.quantity > 0).toList();
      if (validEntries.isEmpty) {
        CustomSnackbar.showWarning(
          title: 'No Valid Entries',
          message: 'Please enter milk quantity for at least one cow.',
        );
        return false;
      }

      final body = {
        'gaushalaId': currentGaushalaId,
        'date': date,
        'shift': shift,
        if (defaultWorkerId != null && defaultWorkerId.isNotEmpty) 'workerId': defaultWorkerId,
        'entries': validEntries.map((e) => e.toJson()).toList(),
      };

      final res = await _milkApiService.createBulkProduction(body);
      final count = validEntries.length;
      final totalQty = validEntries.fold<double>(0.0, (acc, item) => acc + item.quantity);

      CustomSnackbar.showSuccess(
        title: 'Bulk Production Saved',
        message: 'Successfully recorded $totalQty L across $count cows.',
      );

      // Check if backend warned of variances
      if (res['alerts'] != null || res['hasAlerts'] == true) {
        CustomSnackbar.showWarning(
          title: 'Variance Detected',
          message: 'One or more cows exhibited ±10% deviation. Alerts have been logged.',
        );
      }

      await refreshAll();
      return true;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Bulk Save Failed',
        message: e.toString().replaceAll('Exception:', '').trim(),
      );
      return false;
    }
  }

  /// Submit Milk Distribution with Live Stock Validation
  Future<bool> submitDistribution({
    required String milkDate,
    required String shift,
    required double quantity,
    required String recipientType,
    required String recipientName,
    String? customerId,
    required double ratePerLiter,
    String? remarks,
  }) async {
    try {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final isDateToday = milkDate == todayStr;

      // Real-time stock validation check
      if (dailySummary.value != null) {
        if (isDateToday) {
          final isMorn = shift.toLowerCase() == 'morning';
          final availableShift = isMorn
              ? dailySummary.value!.stockBalance.morningAvailable
              : dailySummary.value!.stockBalance.eveningAvailable;

          if (availableShift <= 0) {
            CustomSnackbar.showError(
              title: 'Out of Stock',
              message: 'Cannot distribute milk. No stock available in $shift shift.',
            );
            return false;
          }

          if (quantity > availableShift) {
            CustomSnackbar.showError(
              title: 'Insufficient Shift Stock',
              message: 'Cannot distribute $quantity L. Only $availableShift L available in $shift shift.',
            );
            return false;
          }
        } else {
          // Delayed past date distribution from fridge milk pool
          final fridgeStock = dailySummary.value!.stockBalance.remainingFridgeMilk;
          if (fridgeStock <= 0) {
            CustomSnackbar.showError(
              title: 'Out of Stock',
              message: 'Cannot distribute milk. No fridge leftover stock available.',
            );
            return false;
          }

          if (quantity > fridgeStock) {
            CustomSnackbar.showError(
              title: 'Insufficient Fridge Stock',
              message: 'Cannot distribute $quantity L. Only $fridgeStock L leftover available in fridge pool.',
            );
            return false;
          }
        }
      }

      final Map<String, dynamic> body = {
        'gaushalaId': currentGaushalaId,
        'milkDate': milkDate,
        'quantity': quantity,
        'recipientType': recipientType,
        'recipientName': recipientName,
        'ratePerLiter': ratePerLiter,
        if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      };

      // Backend requirement: shift is required only if milkDate == Today. If milkDate < Today, backend sets 'all'
      if (isDateToday) {
        body['shift'] = shift;
      }

      final res = await _milkApiService.createDistribution(body);
      CustomSnackbar.showSuccess(
        title: 'Distribution Recorded',
        message: 'Successfully distributed ${res.quantity} L to ${res.recipientName} (₹${res.totalAmount}).',
      );

      await refreshAll();
      return true;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Distribution Failed',
        message: e.toString().replaceAll('Exception:', '').trim(),
      );
      return false;
    }
  }

  /// Submit Milk Disposal
  Future<bool> submitDisposal({
    required String milkDate,
    String? disposalDate,
    required double quantity,
    required String reason,
    required String reportedBy,
    String? remarks,
  }) async {
    try {
      final dispDate = disposalDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

      final body = {
        'gaushalaId': currentGaushalaId,
        'milkDate': milkDate,
        'disposalDate': dispDate,
        'quantity': quantity,
        'reason': reason,
        'reportedBy': reportedBy,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      };

      final res = await _milkApiService.createDisposal(body);
      CustomSnackbar.showSuccess(
        title: 'Disposal Logged',
        message: 'Recorded disposal of ${res.quantity} L (${res.disposalReasonEnum.label}).',
      );

      await refreshAll();
      return true;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Disposal Failed',
        message: e.toString().replaceAll('Exception:', '').trim(),
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // REFRESH HELPERS
  // ---------------------------------------------------------------------------
  Future<void> refreshDateSensitiveData() async {
    await Future.wait([
      fetchDailySummary(),
      fetchProduction(),
      fetchDistribution(),
    ]);
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchDailySummary(),
      fetchProduction(),
      fetchDistribution(),
      fetchFridgeStock(),
      fetchDisposals(),
      fetchMilkNotifications(),
      fetchAuxData(),
    ]);
  }

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------
  @override
  void onInit() {
    super.onInit();

    // Listen to global active gaushala changes
    ever(_gaushalaService.selectedGaushala, (_) {
      productionPage.value = 1;
      distributionPage.value = 1;
      disposalPage.value = 1;
      refreshAll();
    });

    // Initial load
    if (currentGaushalaId.isNotEmpty) {
      refreshAll();
    }
  }
}
