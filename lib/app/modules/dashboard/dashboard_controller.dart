import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../data/models/dashboard_alerts_model.dart';
import '../../data/models/feed_item_model.dart';
import '../../data/models/medical_item_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/treatment_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/gaushala_session_service.dart';
import '../../data/services/storage_service.dart';
import '../cow/cow_controller.dart';
import '../../routes/app_routes.dart';

/// Controller managing Cattle Farm dashboard state, real-time alerts, and inline quick actions.
class DashboardController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final ApiService _apiService = Get.find<ApiService>();

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isLoading = false.obs;
  final RxBool isLoadingAlerts = false.obs;
  final RxBool isActionLoading = false.obs;
  final RxBool isSidebarCollapsed = false.obs;

  // Live Cattle herd metrics
  final RxInt registeredCattleCount = 0.obs;
  final RxInt femaleCattleCount = 0.obs;
  final RxInt maleCattleCount = 0.obs;
  final RxBool isCattleLoaded = false.obs;

  // Live Milking Telemetry Observables
  final RxDouble todayMilkProduced = 0.0.obs;
  final RxDouble todayMorningProduced = 0.0.obs;
  final RxDouble todayEveningProduced = 0.0.obs;
  final RxDouble fridgeMilkAvailable = 0.0.obs;
  final RxDouble totalMilkDistributed = 0.0.obs;
  final RxBool isMilkTelemetryLoaded = false.obs;

  // Legacy compatibility property
  RxInt get totalCattle => registeredCattleCount;

  // Smart Alerts Center Observables
  final Rx<DashboardAlertCounts> alertCounts = const DashboardAlertCounts().obs;
  final RxList<TreatmentAlertItem> treatmentAlerts = <TreatmentAlertItem>[].obs;
  final RxList<MilkAlertItem> milkAlerts = <MilkAlertItem>[].obs;
  final RxList<MedicalLowStockAlertItem> medicalLowStock = <MedicalLowStockAlertItem>[].obs;
  final RxList<MedicalExpiringAlertItem> medicalExpiring = <MedicalExpiringAlertItem>[].obs;
  final RxList<FeedStockAlertItem> feedAlerts = <FeedStockAlertItem>[].obs;

  // Active Tab Index (0: Treatments, 1: Milk, 2: Medical, 3: Feed)
  final RxInt selectedTabIndex = 0.obs;

  String? get _currentGaushalaId {
    if (Get.isRegistered<GaushalaSessionService>()) {
      return Get.find<GaushalaSessionService>().selectedGaushalaId;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    _fetchLiveCattleStats();
    fetchAlertsSummary();
    final gId = _currentGaushalaId;
    if (gId != null && gId.isNotEmpty) {
      _fetchLiveMilkingTelemetry(gId);
    }

    if (Get.isRegistered<GaushalaSessionService>()) {
      ever(Get.find<GaushalaSessionService>().selectedGaushala, (_) {
        _fetchLiveCattleStats();
        fetchAlertsSummary();
        final id = _currentGaushalaId;
        if (id != null && id.isNotEmpty) {
          _fetchLiveMilkingTelemetry(id);
        }
      });
    }
  }

  void _loadUser() {
    currentUser.value = _storageService.getUser();
  }

  void changeTab(int index) {
    selectedTabIndex.value = index;
  }

  /// Fetches consolidated alerts with automatic fallback to individual APIs if aggregated endpoint is not available.
  Future<void> fetchAlertsSummary() async {
    final gId = _currentGaushalaId;
    if (gId == null || gId.isEmpty) return;

    try {
      isLoadingAlerts.value = true;

      // 1. Attempt Aggregated Endpoint
      final summary = await _apiService.getDashboardAlertsSummary(gaushalaId: gId);
      if (summary != null) {
        alertCounts.value = summary.counts;
        treatmentAlerts.assignAll(summary.treatmentAlerts);
        milkAlerts.assignAll(summary.milkAlerts);
        medicalLowStock.assignAll(summary.medicalLowStock);
        medicalExpiring.assignAll(summary.medicalExpiring);
        feedAlerts.assignAll(summary.feedAlerts);
        return;
      }

      // 2. Fallback: Aggregate live data from individual endpoints
      await _fetchAlertsFallback(gId);
    } catch (e) {
      if (kDebugMode) print('[DashboardController] fetchAlertsSummary error: $e');
      await _fetchAlertsFallback(gId);
    } finally {
      isLoadingAlerts.value = false;
    }
  }

  /// Resilient fallback calling individual existing APIs
  Future<void> _fetchAlertsFallback(String gId) async {
    try {
      List<CowTreatmentModel> dueDoses = [];
      TreatmentPaginatedResult? criticalResult;
      NotificationPaginatedResult? notifResult;
      List<MedicalItemModel> lowMeds = [];
      List<MedicalBatchModel> expBatches = [];
      List<FeedItemModel> lowFeed = [];

      await Future.wait([
        () async {
          try {
            dueDoses = await _apiService.getTodayDueDoses(gaushalaId: gId);
          } catch (_) {}
        }(),
        () async {
          try {
            criticalResult = await _apiService.getTreatments(
              gaushalaId: gId,
              status: 'UNDER_TREATMENT',
              severity: 'CRITICAL',
              limit: 20,
            );
          } catch (_) {}
        }(),
        () async {
          try {
            notifResult = await _apiService.getNotifications(
              gaushalaId: gId,
              isRead: false,
              limit: 30,
            );
          } catch (_) {}
        }(),
        () async {
          try {
            lowMeds = await _apiService.getLowStockMedicalItems(gaushalaId: gId);
          } catch (_) {}
        }(),
        () async {
          try {
            expBatches = await _apiService.getExpiringMedicalBatches(gaushalaId: gId, days: 30);
          } catch (_) {}
        }(),
        () async {
          try {
            lowFeed = await _apiService.getLowStockFeedItems(gaushalaId: gId);
          } catch (_) {}
        }(),
      ]);

      // 1. Process Treatments
      final List<TreatmentAlertItem> mappedTreatments = [];
      final Set<String> seenTreatmentIds = {};

      for (final item in dueDoses) {
        final id = item.id.trim();
        if (id.isNotEmpty) seenTreatmentIds.add(id);
        mappedTreatments.add(TreatmentAlertItem(
          treatmentId: id,
          cowTag: item.cowTagId ?? 'Cattle',
          calfName: item.cowCalfName,
          shedNumber: item.cowShedName,
          diseaseName: item.diseaseName.isNotEmpty ? item.diseaseName : 'General Care',
          severity: item.severity.code,
          dueDoseNumber: item.nextDoseNumber ?? 1,
          totalDoses: item.totalDoses,
          nextDoseDate: item.nextDoseDate,
          status: item.status.code,
        ));
      }

      if (criticalResult != null) {
        for (final item in criticalResult!.items) {
          final id = item.id.trim();
          if (id.isNotEmpty && !seenTreatmentIds.contains(id)) {
            seenTreatmentIds.add(id);
            mappedTreatments.add(TreatmentAlertItem(
              treatmentId: id,
              cowTag: item.cowTagId ?? 'Cattle',
              calfName: item.cowCalfName,
              shedNumber: item.cowShedName,
              diseaseName: item.diseaseName.isNotEmpty ? item.diseaseName : 'Critical Case',
              severity: 'CRITICAL',
              dueDoseNumber: item.nextDoseNumber ?? 1,
              totalDoses: item.totalDoses,
              nextDoseDate: item.nextDoseDate,
              status: item.status.code,
            ));
          }
        }
      }
      treatmentAlerts.assignAll(mappedTreatments);

      // 2. Process Milk Alerts from Notifications
      final List<MilkAlertItem> mappedMilk = [];
      if (notifResult != null) {
        for (final n in notifResult!.items) {
          final isMilk = (n.type?.contains('MILK') == true) ||
              (n.title.toLowerCase().contains('milk')) ||
              (n.message.toLowerCase().contains('milk')) ||
              (n.message.toLowerCase().contains('drop')) ||
              (n.message.toLowerCase().contains('variance'));

          if (isMilk) {
            mappedMilk.add(MilkAlertItem(
              notificationId: n.id,
              cowTag: n.cowTagId ?? 'Yield Alert',
              message: n.message.isNotEmpty ? n.message : n.title,
              title: n.title,
              createdAt: n.createdAt,
              isRead: n.isRead,
            ));
          }
        }
      }
      milkAlerts.assignAll(mappedMilk);

      // 3. Process Medical Alerts
      final List<MedicalLowStockAlertItem> mappedLowMeds = [];
      for (final m in lowMeds) {
        mappedLowMeds.add(MedicalLowStockAlertItem(
          itemId: m.id,
          itemName: m.itemName,
          category: m.category,
          totalStock: m.totalStock,
          minStockAlert: m.minStockAlert,
          unit: m.unit,
        ));
      }
      medicalLowStock.assignAll(mappedLowMeds);

      final List<MedicalExpiringAlertItem> mappedExpMeds = [];
      for (final b in expBatches) {
        mappedExpMeds.add(MedicalExpiringAlertItem(
          itemId: b.itemId,
          itemName: b.itemName.isNotEmpty ? b.itemName : 'Batch ${b.batchNumber}',
          batchNumber: b.batchNumber,
          expiryDate: b.expiryDate,
          daysRemaining: b.daysUntilExpiry,
          quantity: b.availableQuantity,
        ));
      }
      medicalExpiring.assignAll(mappedExpMeds);

      // 4. Process Feed Alerts
      final List<FeedStockAlertItem> mappedFeed = [];
      for (final f in lowFeed) {
        mappedFeed.add(FeedStockAlertItem(
          itemId: f.id,
          itemName: f.itemName,
          currentStock: f.currentStock,
          minStockAlert: f.minStockAlert,
          unit: f.unit,
          category: f.category,
        ));
      }
      feedAlerts.assignAll(mappedFeed);

      // 5. Compute Consolidated Counts
      final criticalCount = mappedTreatments.where((t) => t.isCritical).length;
      final total = mappedTreatments.length +
          mappedMilk.length +
          mappedLowMeds.length +
          mappedExpMeds.length +
          mappedFeed.length;

      alertCounts.value = DashboardAlertCounts(
        treatmentDueDoses: mappedTreatments.length,
        criticalCases: criticalCount,
        milkVariances: mappedMilk.length,
        lowMedicalStock: mappedLowMeds.length,
        expiringMedicines: mappedExpMeds.length,
        lowFeedStock: mappedFeed.length,
        totalAlerts: total,
      );
    } catch (e) {
      if (kDebugMode) print('[DashboardController] _fetchAlertsFallback error: $e');
    }
  }

  // --------------------------------------------------------------------------
  // QUICK ACTIONS (Direct Inline Modals)
  // --------------------------------------------------------------------------

  /// Administers treatment dose and immediately refreshes alerts
  Future<void> administerTreatmentDose({
    required String treatmentId,
    required int doseNumber,
    required String administeredBy,
    required DateTime administeredDate,
    required String notes,
  }) async {
    try {
      isActionLoading.value = true;
      final res = await _apiService.administerDose(
        treatmentId: treatmentId,
        doseNumber: doseNumber,
        data: {
          'administeredBy': administeredBy,
          'administeredDate': administeredDate.toIso8601String(),
          'notes': notes,
        },
      );

      if (res != null) {
        CustomSnackbar.showSuccess(
          title: 'Dose Administered',
          message: 'Dose #$doseNumber recorded successfully for this animal.',
        );
        await fetchAlertsSummary();
      } else {
        CustomSnackbar.showError(
          title: 'Failed',
          message: 'Unable to administer dose. Please verify treatment record.',
        );
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    } finally {
      isActionLoading.value = false;
    }
  }

  /// Marks milk variance alert as read / dismissed
  Future<void> dismissMilkAlert(String notificationId) async {
    if (notificationId.isEmpty) return;
    try {
      // Optimistic UI removal
      milkAlerts.removeWhere((m) => m.notificationId == notificationId);
      final currentCounts = alertCounts.value;
      alertCounts.value = DashboardAlertCounts(
        treatmentDueDoses: currentCounts.treatmentDueDoses,
        criticalCases: currentCounts.criticalCases,
        milkVariances: (currentCounts.milkVariances - 1).clamp(0, 9999),
        lowMedicalStock: currentCounts.lowMedicalStock,
        expiringMedicines: currentCounts.expiringMedicines,
        lowFeedStock: currentCounts.lowFeedStock,
        totalAlerts: (currentCounts.totalAlerts - 1).clamp(0, 9999),
      );

      final success = await _apiService.markNotificationAsRead(notificationId);
      if (success) {
        CustomSnackbar.showSuccess(
          title: 'Alert Acknowledged',
          message: 'Milk alert marked as read.',
        );
      }
    } catch (_) {
      // Re-sync on failure
      fetchAlertsSummary();
    }
  }

  /// Records quick inward stock for low or expiring medical items
  Future<void> quickMedicalInward({
    required String itemId,
    required String batchNumber,
    required DateTime expiryDate,
    required double quantity,
  }) async {
    final gId = _currentGaushalaId;
    if (gId == null || gId.isEmpty) {
      CustomSnackbar.showError(
        title: 'Action Error',
        message: 'No active Gaushala selected.',
      );
      return;
    }

    try {
      isActionLoading.value = true;
      final success = await _apiService.recordQuickMedicalStockInward(
        gaushalaId: gId,
        itemId: itemId,
        batchNumber: batchNumber,
        expiryDate: expiryDate,
        quantity: quantity,
      );

      if (success) {
        CustomSnackbar.showSuccess(
          title: 'Stock Inward Saved',
          message: 'Added $quantity units into pharmacy inventory.',
        );
        await fetchAlertsSummary();
      } else {
        CustomSnackbar.showError(
          title: 'Failed',
          message: 'Unable to record inward transaction.',
        );
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    } finally {
      isActionLoading.value = false;
    }
  }

  /// Records quick inward for low feed supplies
  Future<void> quickFeedInward({
    required String itemId,
    required double quantity,
    required String unit,
    required String reason,
  }) async {
    final gId = _currentGaushalaId;
    if (gId == null || gId.isEmpty) {
      CustomSnackbar.showError(
        title: 'Action Error',
        message: 'No active Gaushala selected.',
      );
      return;
    }

    try {
      isActionLoading.value = true;
      final success = await _apiService.recordQuickFeedStockInward(
        gaushalaId: gId,
        itemId: itemId,
        quantity: quantity,
        unit: unit,
        reason: reason,
      );

      if (success) {
        CustomSnackbar.showSuccess(
          title: 'Feed Restocked',
          message: 'Received $quantity $unit of feed into barn storage.',
        );
        await fetchAlertsSummary();
      } else {
        CustomSnackbar.showError(
          title: 'Failed',
          message: 'Unable to record feed inward transaction.',
        );
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> _fetchLiveCattleStats() async {
    try {
      isLoading.value = true;
      final gId = _currentGaushalaId;
      final res = await _apiService.getCows(gaushalaId: gId);
      registeredCattleCount.value = res.total;
      femaleCattleCount.value = res.femaleCount;
      maleCattleCount.value = res.maleCount;
      isCattleLoaded.value = true;
    } catch (_) {
      // Graceful fallback
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchLiveMilkingTelemetry(String gId) async {
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final response = await _apiService.get(
        '/milk/daily-summary',
        queryParameters: {
          'gaushalaId': gId,
          'date': todayStr,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data is Map ? response.data as Map : {};
        final data = raw['data'] is Map ? raw['data'] as Map : raw;

        final prod = data['production'] is Map ? data['production'] as Map : {};
        final dist = data['distribution'] is Map ? data['distribution'] as Map : {};
        final stock = data['stockBalance'] is Map ? data['stockBalance'] as Map : {};

        double parseNum(dynamic val) {
          if (val is num) return val.toDouble();
          return double.tryParse(val?.toString() ?? '') ?? 0.0;
        }

        todayMilkProduced.value = parseNum(prod['totalProduced']);
        todayMorningProduced.value = parseNum(prod['morningProduced']);
        todayEveningProduced.value = parseNum(prod['eveningProduced']);
        totalMilkDistributed.value = parseNum(dist['totalDistributed']);
        fridgeMilkAvailable.value = parseNum(stock['remainingFridgeMilk']);
        isMilkTelemetryLoaded.value = true;
      }
    } catch (_) {
      // Graceful fallback
    }
  }

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  Future<void> refreshFarmData() async {
    _loadUser();
    final gId = _currentGaushalaId;
    await Future.wait([
      _fetchLiveCattleStats(),
      fetchAlertsSummary(),
      if (gId != null && gId.isNotEmpty) _fetchLiveMilkingTelemetry(gId),
    ]);
  }

  // --------------------------------------------------------------------------
  // TEST ALERT GENERATOR (Live Backend API Data for Verification)
  // --------------------------------------------------------------------------

  /// Creates a real Critical Treatment Alert with today's dose due via POST /treatments
  Future<bool> generateTestTreatmentAlert() async {
    final gId = _currentGaushalaId;
    if (gId == null || gId.isEmpty) {
      CustomSnackbar.showError(
        title: 'Action Error',
        message: 'No active Gaushala selected.',
      );
      return false;
    }

    try {
      isActionLoading.value = true;
      final cowsRes = await _apiService.getCows(gaushalaId: gId);
      String cowId = '';
      String cowTag = 'COW-DEMO-01';
      String? calfName;
      if (cowsRes.allCows.isNotEmpty) {
        final cow = cowsRes.allCows.first;
        cowId = cow.id;
        cowTag = cow.tagId.isNotEmpty ? cow.tagId : 'CATTLE';
        calfName = cow.calfName;
      }

      final yesterdayIso = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      final nowIso = DateTime.now().toIso8601String();

      final payload = {
        'gaushalaId': gId,
        if (cowId.isNotEmpty) 'cowId': cowId,
        'cowTagId': cowTag,
        if (calfName != null && calfName.isNotEmpty) 'cowCalfName': calfName,
        'diseaseName': 'Acute Mastitis & High Fever',
        'severity': 'CRITICAL',
        'status': 'UNDER_TREATMENT',
        'doctorName': 'Dr. Sharma (Veterinary Specialist)',
        'doctorContact': '9876543210',
        'doctorType': 'IN_HOUSE',
        'treatmentStartDate': yesterdayIso,
        'totalDoses': 3,
        'doseIntervalDays': 1,
        'nextDoseDate': nowIso,
        'nextDoseNumber': 2,
        'symptoms': ['High temperature', 'Loss of appetite', 'Udder inflammation'],
        'diagnosisNotes': 'Simulated critical case for live alert testing and dose verification.',
      };

      final created = await _apiService.createTreatment(payload);
      if (created != null) {
        CustomSnackbar.showSuccess(
          title: 'Treatment Alert Created',
          message: 'Created critical treatment case for $cowTag with dose due today.',
        );
        await fetchAlertsSummary();
        return true;
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Simulation Error',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isActionLoading.value = false;
    }
    return false;
  }

  /// Creates a real Milk Production Variance Alert via POST /milk/production
  Future<bool> generateTestMilkAlert() async {
    final gId = _currentGaushalaId;
    if (gId == null || gId.isEmpty) {
      CustomSnackbar.showError(
        title: 'Action Error',
        message: 'No active Gaushala selected.',
      );
      return false;
    }

    try {
      isActionLoading.value = true;
      final cowsRes = await _apiService.getCows(gaushalaId: gId);
      String cowId = '';
      String cowTag = 'CATTLE';
      if (cowsRes.allCows.isNotEmpty) {
        final cow = cowsRes.allCows.first;
        cowId = cow.id;
        cowTag = cow.tagId.isNotEmpty ? cow.tagId : 'CATTLE';
      }

      String workerId = '';
      try {
        final workers = await _apiService.getWorkers(gaushalaId: gId);
        if (workers.items.isNotEmpty) {
          workerId = workers.items.first.id;
        }
      } catch (_) {}

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final shift = DateTime.now().hour < 12 ? 'morning' : 'evening';

      final response = await _apiService.post(
        '/milk/production',
        data: {
          'gaushalaId': gId,
          'date': todayStr,
          'shift': shift,
          if (cowId.isNotEmpty) 'cowId': cowId,
          if (workerId.isNotEmpty) 'workerId': workerId,
          'quantity': 4.5,
          'remarks': 'Simulated milk yield drop (-30% variance alert).',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomSnackbar.showSuccess(
          title: 'Milk Alert Created',
          message: 'Recorded low milk yield for $cowTag ($shift shift). Production drop variance alert triggered.',
        );
        await fetchAlertsSummary();
        return true;
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Simulation Error',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isActionLoading.value = false;
    }
    return false;
  }

  /// Creates a real Low Medical Stock & Expiring Medicine Alert via POST /medical-stock/items
  Future<bool> generateTestMedicalAlert() async {
    final gId = _currentGaushalaId;
    if (gId == null || gId.isEmpty) {
      CustomSnackbar.showError(
        title: 'Action Error',
        message: 'No active Gaushala selected.',
      );
      return false;
    }

    try {
      isActionLoading.value = true;
      final randSuffix = DateTime.now().millisecondsSinceEpoch % 10000;
      final item = await _apiService.createMedicalItem(
        gaushalaId: gId,
        itemName: 'Amoxicillin Trihydrate ($randSuffix)',
        itemCode: 'AMX-$randSuffix',
        category: 'ANTIBIOTIC',
        unit: 'VIAL',
        minStockAlert: 50.0,
        initialBatches: [
          MedicalInwardBatchDto(
            batchNumber: 'BAT-$randSuffix',
            expiryDate: DateTime.now().add(const Duration(days: 18)),
            quantity: 5.0,
          ),
        ],
      );

      if (item.id.isNotEmpty) {
        CustomSnackbar.showSuccess(
          title: 'Medical Alert Created',
          message: 'Created low-stock and expiring antibiotic item: ${item.itemName} (5 vials).',
        );
        await fetchAlertsSummary();
        return true;
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Simulation Error',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isActionLoading.value = false;
    }
    return false;
  }

  /// Creates a real Low Feed Stock Alert via POST /feed-stock/items
  Future<bool> generateTestFeedAlert() async {
    final gId = _currentGaushalaId;
    if (gId == null || gId.isEmpty) {
      CustomSnackbar.showError(
        title: 'Action Error',
        message: 'No active Gaushala selected.',
      );
      return false;
    }

    try {
      isActionLoading.value = true;
      final randSuffix = DateTime.now().millisecondsSinceEpoch % 10000;
      final item = await _apiService.createFeedItem(
        gaushalaId: gId,
        itemName: 'Green Hybrid Fodder ($randSuffix)',
        itemCode: 'FOD-$randSuffix',
        category: 'GREEN_FODDER',
        unit: 'KG',
        initialStock: 35.0,
        minStockAlert: 500.0,
      );

      if (item.id.isNotEmpty) {
        CustomSnackbar.showSuccess(
          title: 'Feed Alert Created',
          message: 'Created low inventory feed item: ${item.itemName} (35 KG / 500 KG buffer).',
        );
        await fetchAlertsSummary();
        return true;
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Simulation Error',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isActionLoading.value = false;
    }
    return false;
  }

  /// Concurrently generates test alerts across all 4 operational domains
  Future<void> generateAllTestAlerts() async {
    isActionLoading.value = true;
    try {
      await Future.wait([
        generateTestTreatmentAlert(),
        generateTestMilkAlert(),
        generateTestMedicalAlert(),
        generateTestFeedAlert(),
      ]);
      await fetchAlertsSummary();
      CustomSnackbar.showSuccess(
        title: 'All Alerts Simulated',
        message: 'Live test records created across treatments, milk, medicines, and feed.',
      );
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> logout() async {
    CowController.clearCache();
    if (Get.isRegistered<GaushalaSessionService>()) {
      Get.find<GaushalaSessionService>().clearSession();
    }
    await _storageService.removeSelectedGaushalaId();
    await _storageService.removeToken();
    await _storageService.removeUser();
    Get.offAllNamed(AppRoutes.auth);
  }
}
