import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/values/permission_constants.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../data/models/cow_model.dart';
import '../../data/models/gaushala_model.dart';
import '../../data/models/medical_item_model.dart';
import '../../data/models/shed_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/gaushala_session_service.dart';
import '../../data/services/permission_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';

/// Dynamic row representation for Multi-Batch Stock Inward entry
class MedicalInwardBatchRow {
  final TextEditingController batchNumberController = TextEditingController();
  final Rxn<DateTime> expiryDate = Rxn<DateTime>();
  final Rxn<DateTime> mfgDate = Rxn<DateTime>();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController mrpController = TextEditingController();
  final RxDouble lineTotal = 0.0.obs;
  final RxDouble rowQuantity = 0.0.obs;

  MedicalInwardBatchRow({
    String initialBatchNo = '',
    DateTime? initialExpiry,
    DateTime? initialMfg,
    double initialQty = 0,
    double initialUnitPrice = 0,
    double initialMrp = 0,
  }) {
    if (initialBatchNo.isNotEmpty) batchNumberController.text = initialBatchNo;
    if (initialExpiry != null) expiryDate.value = initialExpiry;
    if (initialMfg != null) mfgDate.value = initialMfg;
    if (initialQty > 0) quantityController.text = initialQty.toStringAsFixed(0);
    if (initialUnitPrice > 0) unitPriceController.text = initialUnitPrice.toStringAsFixed(2);
    if (initialMrp > 0) mrpController.text = initialMrp.toStringAsFixed(2);

    _updateLineTotal();
    quantityController.addListener(_updateLineTotal);
    unitPriceController.addListener(_updateLineTotal);
  }

  void _updateLineTotal() {
    final qty = double.tryParse(quantityController.text.trim()) ?? 0.0;
    final rate = double.tryParse(unitPriceController.text.trim()) ?? 0.0;
    rowQuantity.value = qty;
    lineTotal.value = qty * rate;
  }

  void dispose() {
    batchNumberController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
    mrpController.dispose();
  }

  double get quantity => double.tryParse(quantityController.text.trim()) ?? 0.0;
  double get unitPrice => double.tryParse(unitPriceController.text.trim()) ?? 0.0;
  double get mrp => double.tryParse(mrpController.text.trim()) ?? unitPrice;
  String get batchNumber => batchNumberController.text.trim().toUpperCase();
}

/// Dynamic deduction preview for FEFO Outward Simulation
class FefoBatchPreview {
  final MedicalBatchModel batch;
  final double deductedQuantity;
  final double remainingQuantity;
  final bool isFullyConsumed;
  final bool isPartiallyConsumed;

  const FefoBatchPreview({
    required this.batch,
    required this.deductedQuantity,
    required this.remainingQuantity,
    required this.isFullyConsumed,
    required this.isPartiallyConsumed,
  });
}

/// Centralized Controller for Veterinary / Medical Stock Management
class MedicalStockController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();
  final PermissionService? _permissionService =
      Get.isRegistered<PermissionService>() ? Get.find<PermissionService>() : null;

  bool get canAddMedicine =>
      _permissionService?.canAdd(PermissionModules.medicalStock, PermissionSubModules.medicalItems) ??
      (currentUser.value?.isAdmin ?? false);

  bool get canEditMedicine =>
      _permissionService?.canEdit(PermissionModules.medicalStock, PermissionSubModules.medicalItems) ??
      (currentUser.value?.isAdmin ?? false);

  bool get canDeleteMedicine =>
      _permissionService?.canDelete(PermissionModules.medicalStock, PermissionSubModules.medicalItems) ??
      (currentUser.value?.isAdmin ?? false);

  bool get canAddTransaction =>
      _permissionService?.canAdd(PermissionModules.medicalStock, PermissionSubModules.stockTransaction) ??
      (currentUser.value?.isAdmin ?? false);

  // Navigation & Layout
  final RxInt selectedTab = 0.obs; // 0: Dashboard, 1: Master, 2: Inward, 3: Outward, 4: Batches, 5: Ledger
  final RxBool isSidebarCollapsed = false.obs;
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  // Global states
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isSubmitting = false.obs;

  // Master Data collections
  final Rx<MedicalSummaryModel> summary = const MedicalSummaryModel().obs;
  final RxList<MedicalItemModel> items = <MedicalItemModel>[].obs;
  final RxList<MedicalBatchModel> allBatches = <MedicalBatchModel>[].obs;
  final RxList<MedicalTransactionModel> transactions = <MedicalTransactionModel>[].obs;
  final RxList<CowModel> cows = <CowModel>[].obs;
  final RxList<ShedModel> sheds = <ShedModel>[].obs;
  final RxList<GaushalaModel> gaushalas = <GaushalaModel>[].obs;

  // -------------------------------------------------------------
  // TAB 0: DASHBOARD & SUMMARY
  // -------------------------------------------------------------
  final RxInt dashboardActiveSubTab = 0.obs; // 0: Low stock items, 1: Expiring batches
  final RxInt expiringDaysThreshold = 30.obs; // 30 or 60 days

  // -------------------------------------------------------------
  // TAB 1: MEDICINE MASTER (INVENTORY LIST)
  // -------------------------------------------------------------
  final RxString itemSearchQuery = ''.obs;
  final RxString selectedCategoryFilter = 'ALL'.obs;
  final RxString selectedUnitFilter = 'ALL'.obs;
  final RxBool lowStockOnlyFilter = false.obs;
  final RxString selectedStockFilter = 'all'.obs; // 'all', 'in_stock', 'low', 'out'
  final RxInt itemsCurrentPage = 1.obs;
  final RxInt itemsPerPage = 5.obs;

  // Mobile infinite scroll for items
  final RxInt mobileItemsLimit = 10.obs;

  List<MedicalItemModel> get mobileItems {
    final list = filteredItems;
    return list.take(mobileItemsLimit.value).toList();
  }

  bool get hasMoreMobileItems => mobileItemsLimit.value < filteredItems.length;

  void loadMoreMobileItems() {
    if (hasMoreMobileItems) {
      mobileItemsLimit.value += 10;
    }
  }

  void resetMobileItemsLimit() {
    mobileItemsLimit.value = 10;
  }

  void setStockFilter(String filter) {
    selectedStockFilter.value = filter;
    lowStockOnlyFilter.value = (filter == 'low');
    itemsCurrentPage.value = 1;
    resetMobileItemsLimit();
  }

  void clearMedicineFilters() {
    itemSearchQuery.value = '';
    selectedCategoryFilter.value = 'ALL';
    selectedUnitFilter.value = 'ALL';
    selectedStockFilter.value = 'all';
    lowStockOnlyFilter.value = false;
    itemsCurrentPage.value = 1;
    resetMobileItemsLimit();
  }

  // -------------------------------------------------------------
  // TAB 2: STOCK INWARD (MULTI-BATCH PURCHASE ENTRY)
  // -------------------------------------------------------------
  final Rxn<MedicalItemModel> inwardSelectedItem = Rxn<MedicalItemModel>();
  final Rx<MedicalTransactionReason> inwardReason = MedicalTransactionReason.purchase.obs;
  final TextEditingController inwardSupplierController = TextEditingController();
  final TextEditingController inwardBillNoController = TextEditingController();
  final Rx<DateTime> inwardDate = DateTime.now().obs;
  final RxList<MedicalInwardBatchRow> inwardBatchRows = <MedicalInwardBatchRow>[].obs;

  // -------------------------------------------------------------
  // TAB 3: STOCK OUTWARD / DISPENSING (FEFO SMART UI)
  // -------------------------------------------------------------
  final Rxn<MedicalItemModel> outwardSelectedItem = Rxn<MedicalItemModel>();
  final TextEditingController outwardQuantityController = TextEditingController();
  final Rx<MedicalTransactionReason> outwardReason = MedicalTransactionReason.treatment.obs;
  final Rxn<CowModel> outwardSelectedCow = Rxn<CowModel>();
  final Rxn<ShedModel> outwardSelectedShed = Rxn<ShedModel>();
  final TextEditingController outwardDoctorController = TextEditingController();
  final TextEditingController outwardPrescribedForController = TextEditingController();
  final TextEditingController outwardNotesController = TextEditingController();
  final Rx<DateTime> outwardDate = DateTime.now().obs;
  final RxList<FefoBatchPreview> outwardFefoPreviews = <FefoBatchPreview>[].obs;
  final RxDouble outwardRequestedQuantity = 0.0.obs;
  final RxBool outwardHasExcessStockError = false.obs;

  // -------------------------------------------------------------
  // TAB 4: BATCHES & EXPIRY TRACKER
  // -------------------------------------------------------------
  final RxString batchExpiryFilter = 'ALL'.obs; // ALL, ACTIVE, EXPIRING_30, EXPIRING_60, EXPIRED
  final Rxn<String> batchMedicineFilter = Rxn<String>();
  final RxString batchSearchQuery = ''.obs;
  final RxInt batchesCurrentPage = 1.obs;
  final RxInt batchesPerPage = 5.obs;

  // Mobile infinite scroll for batches
  final RxInt mobileBatchesLimit = 10.obs;

  List<MedicalBatchModel> get mobileBatches {
    final list = filteredBatches;
    return list.take(mobileBatchesLimit.value).toList();
  }

  bool get hasMoreMobileBatches => mobileBatchesLimit.value < filteredBatches.length;

  void loadMoreMobileBatches() {
    if (hasMoreMobileBatches) {
      mobileBatchesLimit.value += 10;
    }
  }

  void resetMobileBatchesLimit() {
    mobileBatchesLimit.value = 10;
  }

  // -------------------------------------------------------------
  // TAB 5: STOCK LEDGER / TRANSACTION AUDIT LOG
  // -------------------------------------------------------------
  final RxString ledgerTypeFilter = 'ALL'.obs; // ALL, INWARD, OUTWARD, EXPIRED_DISPOSAL, ADJUSTMENT
  final Rxn<String> ledgerMedicineFilter = Rxn<String>();
  final RxString ledgerReasonFilter = 'ALL'.obs;
  final Rxn<DateTime> ledgerStartDate = Rxn<DateTime>();
  final Rxn<DateTime> ledgerEndDate = Rxn<DateTime>();
  final RxInt ledgerPage = 1.obs;
  final RxInt ledgerLimit = 5.obs;

  // Mobile infinite scroll for ledger
  final RxInt mobileLedgerLimit = 10.obs;

  List<MedicalTransactionModel> get mobileTransactions {
    final list = filteredTransactions;
    return list.take(mobileLedgerLimit.value).toList();
  }

  bool get hasMoreMobileLedger => mobileLedgerLimit.value < filteredTransactions.length;

  void loadMoreMobileLedger() {
    if (hasMoreMobileLedger) {
      mobileLedgerLimit.value += 10;
    }
  }

  void resetMobileLedgerLimit() {
    mobileLedgerLimit.value = 10;
  }

  // Getters for Gaushala
  String get activeGaushalaId => _gaushalaService.selectedGaushalaId;
  String get activeGaushalaName => _gaushalaService.selectedGaushalaName;
  bool get canChangeGaushala => _gaushalaService.canChangeGaushala;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _storageService.getUser();
    gaushalas.assignAll(_gaushalaService.gaushalas);

    // Default first batch row for inward entry
    addInwardBatchRow();

    // Listen to outward quantity text changes for real-time FEFO calculation
    outwardQuantityController.addListener(_onOutwardQuantityChanged);

    // Reload when active gaushala changes
    ever(_gaushalaService.selectedGaushala, (_) {
      batchesCurrentPage.value = 1;
      refreshAllData();
    });

    // Reset batches pagination on filter changes
    ever(batchExpiryFilter, (_) => batchesCurrentPage.value = 1);
    ever(batchMedicineFilter, (_) => batchesCurrentPage.value = 1);
    debounce(batchSearchQuery, (_) => batchesCurrentPage.value = 1, time: const Duration(milliseconds: 150));

    // Initial load
    fetchInitialData();
  }

  @override
  void onClose() {
    for (final row in inwardBatchRows) {
      row.dispose();
    }
    inwardSupplierController.dispose();
    inwardBillNoController.dispose();
    outwardQuantityController.dispose();
    outwardDoctorController.dispose();
    outwardPrescribedForController.dispose();
    outwardNotesController.dispose();
    super.onClose();
  }

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  void switchTab(int tabIndex) {
    if (selectedTab.value == tabIndex) return;
    selectedTab.value = tabIndex;
  }

  void logout() {
    _storageService.clearAll();
    Get.offAllNamed(AppRoutes.auth);
  }

  // -------------------------------------------------------------
  // DATA FETCHING & SYNCHRONIZATION
  // -------------------------------------------------------------
  Future<void> fetchInitialData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadCowsAndSheds(),
        refreshAllData(showLoader: false),
      ]);
    } catch (e) {
      if (kDebugMode) print('[MedicalStockController] fetchInitialData error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshAllData({bool showLoader = true}) async {
    if (showLoader) isRefreshing.value = true;
    try {
      final gId = activeGaushalaId;
      await Future.wait([
        _fetchSummary(gId),
        _fetchItemsBatchesAndTransactions(gId),
      ]);
    } catch (e) {
      if (kDebugMode) print('[MedicalStockController] refreshAllData error: $e');
    } finally {
      if (showLoader) isRefreshing.value = false;
    }
  }

  Future<void> _fetchSummary(String gId) async {
    try {
      final res = await _apiService.getMedicalStockSummary(gaushalaId: gId);
      summary.value = res;
    } catch (e) {
      if (kDebugMode) print('[MedicalStockController] _fetchSummary error: $e');
      _recalculateSummaryFromLocal();
    }
  }

  Future<void> _fetchItemsBatchesAndTransactions(String gId) async {
    try {
      final itemsFuture = _apiService.getMedicalItems(
        gaushalaId: gId,
        page: 1,
        limit: 100,
      );
      final batchesFuture = _apiService.getMedicalBatches(
        gaushalaId: gId,
        status: 'ALL',
      );
      final txnFuture = _apiService.getMedicalTransactions(
        gaushalaId: gId,
        page: 1,
        limit: 100,
      );

      final results = await Future.wait([itemsFuture, batchesFuture, txnFuture]);
      final itemsRes = results[0] as MedicalItemPaginatedResult;
      final rawBatches = results[1] as List<MedicalBatchModel>;
      final txnRes = results[2] as MedicalTransactionPaginatedResult;

      transactions.assignAll(txnRes.items);
      _syncAllInventory(itemsRes.items, rawBatches, txnRes.items);
    } catch (e) {
      if (kDebugMode) print('[MedicalStockController] _fetchItemsBatchesAndTransactions error: $e');
      await _fetchItemsBatchesAndTransactionsFallback(gId);
    }
  }

  Future<void> _fetchItemsBatchesAndTransactionsFallback(String gId) async {
    List<MedicalItemModel> fetchedItems = items.toList();
    List<MedicalBatchModel> fetchedBatches = allBatches.toList();
    List<MedicalTransactionModel> fetchedTxns = transactions.toList();

    try {
      final res = await _apiService.getMedicalItems(gaushalaId: gId, page: 1, limit: 100);
      fetchedItems = res.items;
    } catch (_) {}

    try {
      final bRes = await _apiService.getMedicalBatches(gaushalaId: gId, status: 'ALL');
      if (bRes.isNotEmpty) {
        fetchedBatches = bRes;
      }
    } catch (_) {}

    try {
      final tRes = await _apiService.getMedicalTransactions(gaushalaId: gId, page: 1, limit: 100);
      fetchedTxns = tRes.items;
      transactions.assignAll(fetchedTxns);
    } catch (_) {}

    _syncAllInventory(fetchedItems, fetchedBatches, fetchedTxns);
  }

  MedicalItemModel? _findMatchingItem(Iterable<MedicalItemModel> list, String? code, String? name) {
    for (final i in list) {
      if (code != null && code.isNotEmpty && i.itemCode.isNotEmpty && i.itemCode.toUpperCase() == code.toUpperCase()) {
        return i;
      }
      if (name != null && name.isNotEmpty && i.itemName.toLowerCase() == name.toLowerCase()) {
        return i;
      }
    }
    return null;
  }

  List<MedicalBatchModel> _extractBatchesFromTransactions(
    List<MedicalTransactionModel> txns,
    Map<String, MedicalItemModel> itemMap,
  ) {
    if (txns.isEmpty) return [];

    final Map<String, MedicalBatchModel> batchMap = {};

    // Sort transactions chronologically (oldest first) to reconstruct batch lifecycle
    final sortedTxns = List<MedicalTransactionModel>.from(txns)
      ..sort((a, b) {
        final dateA = a.transactionDate ?? a.createdAt ?? DateTime(2020);
        final dateB = b.transactionDate ?? b.createdAt ?? DateTime(2020);
        return dateA.compareTo(dateB);
      });

    for (final txn in sortedTxns) {
      MedicalItemModel? parentItem = itemMap[txn.itemId];
      parentItem ??= _findMatchingItem(itemMap.values, txn.itemCode, txn.itemName);

      final resolvedItemId = parentItem?.id.isNotEmpty == true ? parentItem!.id : txn.itemId;
      final resolvedItemName = parentItem?.itemName.isNotEmpty == true ? parentItem!.itemName : txn.itemName;
      final resolvedItemCode = parentItem?.itemCode.isNotEmpty == true ? parentItem!.itemCode : txn.itemCode;

      if (txn.isInward) {
        for (final b in txn.batches) {
          final bNo = b.batchNumber.trim().toUpperCase();
          if (bNo.isEmpty) continue;
          final key = '${resolvedItemId}_$bNo';
          final existing = batchMap[key];

          if (existing != null) {
            final newQty = existing.quantity + b.quantity;
            final newAvail = existing.availableQuantity + b.quantity;
            batchMap[key] = existing.copyWith(
              quantity: newQty,
              availableQuantity: newAvail,
              expiryDate: b.expiryDate ?? existing.expiryDate,
              mfgDate: b.mfgDate ?? existing.mfgDate,
              unitPrice: b.unitPrice > 0 ? b.unitPrice : existing.unitPrice,
            );
          } else {
            batchMap[key] = MedicalBatchModel(
              id: b.batchId?.isNotEmpty == true ? b.batchId! : key,
              itemId: resolvedItemId,
              itemName: resolvedItemName,
              itemCode: resolvedItemCode,
              batchNumber: bNo,
              expiryDate: b.expiryDate ?? DateTime.now().add(const Duration(days: 365)),
              mfgDate: b.mfgDate,
              quantity: b.quantity,
              availableQuantity: b.quantity,
              unitPrice: b.unitPrice,
              mrp: b.unitPrice > 0 ? b.unitPrice * 1.15 : 0.0,
              status: 'ACTIVE',
              gaushalaId: txn.gaushalaId,
              supplierOrDonorName: txn.supplierOrDonorName,
              createdAt: txn.transactionDate ?? txn.createdAt,
            );
          }
        }
      } else if (txn.isOutward || txn.isDisposal) {
        for (final b in txn.batches) {
          final bNo = b.batchNumber.trim().toUpperCase();
          if (bNo.isEmpty) continue;
          final key = '${resolvedItemId}_$bNo';
          final existing = batchMap[key];

          if (existing != null) {
            final newAvail = (existing.availableQuantity - b.quantity).clamp(0.0, double.infinity);
            batchMap[key] = existing.copyWith(
              availableQuantity: newAvail,
              status: newAvail == 0 ? 'DEPLETED' : existing.status,
            );
          }
        }
      }
    }

    return batchMap.values.toList();
  }

  void _syncAllInventory(
    List<MedicalItemModel> rawItems,
    List<MedicalBatchModel> rawBatches,
    List<MedicalTransactionModel> txns,
  ) {
    // 1. Map items by ID
    final Map<String, MedicalItemModel> itemMap = {for (final it in rawItems) it.id: it};

    // Helper to resolve parent medicine info for any batch
    MedicalBatchModel resolveParent(MedicalBatchModel b) {
      MedicalItemModel? parent = itemMap[b.itemId];
      parent ??= _findMatchingItem(rawItems, b.itemCode, b.itemName);
      if (parent != null) {
        return b.copyWith(
          itemId: parent.id,
          itemName: b.itemName.isNotEmpty ? b.itemName : parent.itemName,
          itemCode: b.itemCode.isNotEmpty ? b.itemCode : parent.itemCode,
        );
      }
      return b;
    }

    // 2. Extract active batches directly from transactions history (API inward/outward records)
    final txnBatches = _extractBatchesFromTransactions(txns, itemMap);

    // 3. Consolidated master batch map with dual-key (DB id + business key) deduplication
    final Map<String, MedicalBatchModel> masterBatchMap = {};
    final Map<String, String> idToKeyMap = {}; // b.id -> canonical businessKey

    void upsertBatch(MedicalBatchModel incoming) {
      final b = resolveParent(incoming);
      final bNo = b.batchNumber.trim().toUpperCase();
      if (bNo.isEmpty) return;

      final businessKey = '${b.itemId}_$bNo';
      String? existingKey;

      if (b.id.isNotEmpty && idToKeyMap.containsKey(b.id)) {
        existingKey = idToKeyMap[b.id];
      } else if (masterBatchMap.containsKey(businessKey)) {
        existingKey = businessKey;
      }

      if (existingKey != null && masterBatchMap.containsKey(existingKey)) {
        final existing = masterBatchMap[existingKey]!;
        final merged = existing.copyWith(
          id: b.id.isNotEmpty ? b.id : existing.id,
          itemId: b.itemId.isNotEmpty ? b.itemId : existing.itemId,
          itemName: b.itemName.isNotEmpty ? b.itemName : existing.itemName,
          itemCode: b.itemCode.isNotEmpty ? b.itemCode : existing.itemCode,
          availableQuantity: b.availableQuantity > 0 ? b.availableQuantity : existing.availableQuantity,
          quantity: b.quantity > 0 ? b.quantity : existing.quantity,
          expiryDate: b.expiryDate,
          mfgDate: b.mfgDate ?? existing.mfgDate,
          unitPrice: b.unitPrice > 0 ? b.unitPrice : existing.unitPrice,
          status: b.status.isNotEmpty ? b.status : existing.status,
          gaushalaId: b.gaushalaId ?? existing.gaushalaId,
          supplierOrDonorName: b.supplierOrDonorName ?? existing.supplierOrDonorName,
        );
        masterBatchMap[existingKey] = merged;
        if (merged.id.isNotEmpty) {
          idToKeyMap[merged.id] = existingKey;
        }
      } else {
        masterBatchMap[businessKey] = b;
        if (b.id.isNotEmpty) {
          idToKeyMap[b.id] = businessKey;
        }
      }
    }

    // Merge transactions, raw API batches, and item-embedded batches
    for (final b in txnBatches) {
      upsertBatch(b);
    }
    for (final b in rawBatches) {
      upsertBatch(b);
    }
    for (final it in rawItems) {
      for (final ib in it.batches) {
        upsertBatch(ib.copyWith(
          itemId: ib.itemId.isNotEmpty ? ib.itemId : it.id,
          itemName: ib.itemName.isNotEmpty ? ib.itemName : it.itemName,
          itemCode: ib.itemCode.isNotEmpty ? ib.itemCode : it.itemCode,
        ));
      }
    }

    // Secondary strict deduplication to ensure 100% uniqueness by id and by (itemId_batchNumber)
    final Map<String, MedicalBatchModel> finalDedupedMap = {};
    final Set<String> seenIds = {};

    for (final b in masterBatchMap.values) {
      if (b.id.isNotEmpty && seenIds.contains(b.id)) {
        continue;
      }
      final key = '${b.itemId}_${b.batchNumber.trim().toUpperCase()}';
      if (finalDedupedMap.containsKey(key)) {
        continue;
      }
      if (b.id.isNotEmpty) seenIds.add(b.id);
      finalDedupedMap[key] = b;
    }

    final List<MedicalBatchModel> consolidatedBatches = finalDedupedMap.values.toList();
    consolidatedBatches.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    allBatches.assignAll(consolidatedBatches);

    // 7. Group batches by itemId
    final Map<String, List<MedicalBatchModel>> batchesByItem = {};
    for (final b in consolidatedBatches) {
      if (b.itemId.isNotEmpty) {
        batchesByItem.putIfAbsent(b.itemId, () => []).add(b);
      }
    }

    // 8. Update each item with its active batches, totalStock, and activeBatchesCount
    final List<MedicalItemModel> updatedItems = [];
    for (final it in rawItems) {
      final itemBatches = batchesByItem[it.id] ??
          consolidatedBatches.where((b) =>
              (it.itemCode.isNotEmpty && b.itemCode.isNotEmpty && it.itemCode.toUpperCase() == b.itemCode.toUpperCase()) ||
              (b.itemName.toLowerCase() == it.itemName.toLowerCase())).toList();

      final sorted = List<MedicalBatchModel>.from(itemBatches)
        ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

      final double computedStock = sorted.isNotEmpty
          ? sorted.fold<double>(0.0, (sum, b) => sum + b.availableQuantity)
          : it.totalStock;

      final int activeCount = sorted.isNotEmpty
          ? sorted.where((b) => b.availableQuantity > 0 && !b.isExpired).length
          : (it.activeBatchesCount > 0 ? it.activeBatchesCount : 0);

      updatedItems.add(it.copyWith(
        batches: sorted,
        totalStock: computedStock,
        activeBatchesCount: activeCount,
      ));
    }

    items.assignAll(updatedItems);

    // 9. Update outward selected item if it was already selected
    if (outwardSelectedItem.value != null) {
      final updated = items.firstWhereOrNull((i) => i.id == outwardSelectedItem.value!.id);
      if (updated != null) {
        outwardSelectedItem.value = updated;
        _computeFefoPreview();
      }
    }

    _recalculateSummaryFromLocal();
  }

  List<MedicalBatchModel> getBatchesForItem(String itemId) {
    if (itemId.isEmpty) return [];

    // 1. Try from allBatches by itemId
    var fromAll = allBatches.where((b) => b.itemId == itemId).toList();
    if (fromAll.isNotEmpty) {
      fromAll.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      return fromAll;
    }

    // 2. Try from items
    final item = items.firstWhereOrNull((i) => i.id == itemId);
    if (item != null && item.batches.isNotEmpty) {
      return item.sortedBatches;
    }

    // 3. Try matching allBatches by itemCode or itemName
    if (item != null) {
      fromAll = allBatches.where((b) =>
          (item.itemCode.isNotEmpty && b.itemCode.isNotEmpty && b.itemCode.toUpperCase() == item.itemCode.toUpperCase()) ||
          (b.itemName.toLowerCase() == item.itemName.toLowerCase())).toList();
      if (fromAll.isNotEmpty) {
        fromAll.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        return fromAll;
      }
    }

    // 4. Try extracting from transactions directly
    final matchingTxns = transactions.where((t) =>
        t.itemId == itemId ||
        (item != null && item.itemCode.isNotEmpty && t.itemCode.toUpperCase() == item.itemCode.toUpperCase()) ||
        (item != null && t.itemName.toLowerCase() == item.itemName.toLowerCase())).toList();
    if (matchingTxns.isNotEmpty) {
      final itemMap = {for (final it in items) it.id: it};
      final fromTxns = _extractBatchesFromTransactions(matchingTxns, itemMap);
      if (fromTxns.isNotEmpty) {
        fromTxns.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        return fromTxns;
      }
    }

    return [];
  }

  Future<List<MedicalBatchModel>> fetchBatchesForItem(String itemId) async {
    if (itemId.isEmpty) return [];
    try {
      final batches = await _apiService.getMedicalBatches(
        gaushalaId: activeGaushalaId,
        itemId: itemId,
        status: 'ALL',
      );
      if (batches.isNotEmpty) {
        for (final b in batches) {
          final resolvedB = b.copyWith(
            itemId: b.itemId.isNotEmpty ? b.itemId : itemId,
          );
          final idx = allBatches.indexWhere((x) =>
              (x.id.isNotEmpty && resolvedB.id.isNotEmpty && x.id == resolvedB.id) ||
              (x.batchNumber.trim().toUpperCase() == resolvedB.batchNumber.trim().toUpperCase() &&
                  (x.itemId == itemId || resolvedB.itemId == itemId)));
          if (idx != -1) {
            allBatches[idx] = resolvedB;
          } else {
            allBatches.add(resolvedB);
          }
        }
        final seen = <String>{};
        allBatches.retainWhere((x) {
          final key = x.id.isNotEmpty ? x.id : '${x.itemId}_${x.batchNumber.trim().toUpperCase()}';
          return seen.add(key);
        });
        allBatches.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

        final itemIndex = items.indexWhere((i) => i.id == itemId);
        if (itemIndex != -1) {
          final it = items[itemIndex];
          final itemBatches = getBatchesForItem(itemId);
          final double computedStock = itemBatches.fold<double>(0.0, (s, b) => s + b.availableQuantity);
          final int activeCount = itemBatches.where((b) => b.availableQuantity > 0 && !b.isExpired).length;
          items[itemIndex] = it.copyWith(
            batches: itemBatches,
            totalStock: computedStock > 0 ? computedStock : it.totalStock,
            activeBatchesCount: activeCount > 0 ? activeCount : it.activeBatchesCount,
          );
        }

        if (outwardSelectedItem.value?.id == itemId) {
          final updated = items.firstWhereOrNull((i) => i.id == itemId);
          if (updated != null) {
            outwardSelectedItem.value = updated;
            _computeFefoPreview();
          }
        }
      }
      return getBatchesForItem(itemId);
    } catch (e) {
      if (kDebugMode) print('[MedicalStockController] fetchBatchesForItem error: $e');
      return getBatchesForItem(itemId);
    }
  }


  Future<void> _loadCowsAndSheds() async {
    try {
      final gId = activeGaushalaId;
      final shedsList = await _apiService.getSheds(gaushalaId: gId);
      sheds.assignAll(shedsList);

      final cowsList = await _apiService.getCows(gaushalaId: gId);
      cows.assignAll(cowsList.allCows);
    } catch (e) {
      if (kDebugMode) print('[MedicalStockController] _loadCowsAndSheds error: $e');
    }
  }

  void _extractBatchesFromItems() {
    if (allBatches.isEmpty) {
      final List<MedicalBatchModel> extracted = [];
      final seen = <String>{};
      for (final it in items) {
        for (final b in it.batches) {
          final key = b.id.isNotEmpty ? b.id : '${it.id}_${b.batchNumber.trim().toUpperCase()}';
          if (seen.add(key)) {
            extracted.add(b.copyWith(
              itemId: b.itemId.isNotEmpty ? b.itemId : it.id,
              itemName: b.itemName.isNotEmpty ? b.itemName : it.itemName,
              itemCode: b.itemCode.isNotEmpty ? b.itemCode : it.itemCode,
            ));
          }
        }
      }
      extracted.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      allBatches.assignAll(extracted);
    }
    _recalculateSummaryFromLocal();
  }

  void _recalculateSummaryFromLocal() {
    final totalSkus = items.length;
    final lowStock = items.where((i) => i.isLowStock).length;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int expired = 0;
    int expiringSoon = 0;
    double totalVal = 0.0;

    for (final b in allBatches) {
      final exp = DateTime(b.expiryDate.year, b.expiryDate.month, b.expiryDate.day);
      if (exp.isBefore(today)) {
        if (b.availableQuantity > 0) expired++;
      } else if (exp.difference(today).inDays <= expiringDaysThreshold.value) {
        if (b.availableQuantity > 0) expiringSoon++;
      }
      totalVal += b.availableQuantity * (b.unitPrice > 0 ? b.unitPrice : b.mrp);
    }

    summary.value = MedicalSummaryModel(
      totalItems: totalSkus,
      lowStockItemsCount: lowStock,
      expiringSoonBatchesCount: expiringSoon,
      expiredBatchesCount: expired,
      totalBatchesCount: allBatches.length,
      totalStockValue: totalVal,
    );
  }

  // -------------------------------------------------------------
  // TAB 1: MEDICINE MASTER CRUD & FILTERING
  // -------------------------------------------------------------
  List<MedicalItemModel> get filteredItems {
    final query = itemSearchQuery.value.trim().toLowerCase();
    final cat = selectedCategoryFilter.value;
    final unit = selectedUnitFilter.value;
    final lowOnly = lowStockOnlyFilter.value;
    final stockFilter = selectedStockFilter.value;

    return items.where((item) {
      if (query.isNotEmpty) {
        final matchName = item.itemName.toLowerCase().contains(query);
        final matchCode = item.itemCode.toLowerCase().contains(query);
        final matchMfr = item.manufacturer.toLowerCase().contains(query);
        if (!matchName && !matchCode && !matchMfr) return false;
      }
      if (cat != 'ALL' && item.category != cat) return false;
      if (unit != 'ALL' && item.unit != unit) return false;
      if (lowOnly && !item.isLowStock) return false;

      // Status filters
      if (stockFilter == 'in_stock' && (item.isLowStock || item.isOutOfStock)) return false;
      if (stockFilter == 'low' && (!item.isLowStock || item.isOutOfStock)) return false;
      if (stockFilter == 'out' && !item.isOutOfStock) return false;

      return true;
    }).toList();
  }

  List<MedicalItemModel> get paginatedItems {
    final list = filteredItems;
    final start = (itemsCurrentPage.value - 1) * itemsPerPage.value;
    if (start >= list.length) {
      return [];
    }
    final end = min(start + itemsPerPage.value, list.length);
    return list.sublist(start, end);
  }

  int get itemsTotalPages {
    final len = filteredItems.length;
    if (len == 0) return 1;
    return (len / itemsPerPage.value).ceil();
  }

  String _extractErrorMessage(dynamic error, {String defaultMessage = 'An unexpected error occurred.'}) {
    if (error is DioException) {
      final resData = error.response?.data;
      if (resData is Map) {
        if (resData['message'] != null && resData['message'].toString().trim().isNotEmpty) {
          return resData['message'].toString().trim();
        }
        if (resData['error'] != null && resData['error'].toString().trim().isNotEmpty) {
          return resData['error'].toString().trim();
        }
      } else if (resData is String && resData.trim().isNotEmpty && !resData.contains('<html')) {
        return resData.trim();
      }
      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!.trim();
      }
    }
    final str = error.toString();
    return str.replaceFirst('Exception: ', '');
  }

  Future<bool> createMedicine({
    required String itemName,
    required String itemCode,
    required String category,
    required String unit,
    required double minStockAlert,
    required String manufacturer,
    required String description,
    List<MedicalInwardBatchDto>? initialBatches,
  }) async {
    final gId = activeGaushalaId;
    if (gId.isEmpty) {
      CustomSnackbar.showError(
        title: 'Gaushala Required',
        message: 'Please select an active Gaushala before creating a medicine.',
      );
      return false;
    }

    isSubmitting.value = true;
    try {
      final createdItem = await _apiService.createMedicalItem(
        gaushalaId: gId,
        itemName: itemName,
        itemCode: itemCode,
        category: category,
        unit: unit,
        minStockAlert: minStockAlert,
        manufacturer: manufacturer,
        description: description,
        initialBatches: initialBatches,
      );

      // If initial batches were provided, ensure they are recorded in database
      if (initialBatches != null && initialBatches.isNotEmpty) {
        if (createdItem.totalStock == 0 && createdItem.batches.isEmpty) {
          try {
            await _apiService.recordMedicalStockInward(
              MedicalStockInwardRequest(
                gaushalaId: gId,
                itemId: createdItem.id,
                reason: MedicalTransactionReason.openingStock.code,
                supplierOrDonorName: manufacturer.isNotEmpty ? manufacturer : 'Opening Stock',
                billOrReceiptNo: 'INIT-${createdItem.itemCode.isNotEmpty ? createdItem.itemCode : (DateTime.now().millisecondsSinceEpoch % 100000).toString()}',
                transactionDate: DateTime.now(),
                batches: initialBatches,
              ),
            );
          } catch (inwardErr) {
            if (kDebugMode) print('[createMedicine] Initial inward record fallback error: $inwardErr');
          }
        }
      }

      await refreshAllData(showLoader: false);
      CustomSnackbar.showSuccess(
        title: 'Medicine Added',
        message: '${createdItem.itemName} has been created successfully.',
      );
      return true;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error Adding Medicine',
        message: _extractErrorMessage(e, defaultMessage: 'Failed to create medicine.'),
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateMedicine(String id, Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      final updated = await _apiService.updateMedicalItem(id, data);
      final index = items.indexWhere((i) => i.id == id);
      if (index != -1) {
        items[index] = updated;
      }
      _extractBatchesFromItems();
      await refreshAllData(showLoader: false);
      CustomSnackbar.showSuccess(
        title: 'Medicine Updated',
        message: '${updated.itemName} was updated successfully.',
      );
      return true;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Update Failed',
        message: _extractErrorMessage(e, defaultMessage: 'Failed to update medicine.'),
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deleteMedicine(String id) async {
    if (!canDeleteMedicine) {
      CustomSnackbar.showWarning(
        title: 'Access Denied',
        message: 'You do not have permission to delete medicine records.',
      );
      return;
    }
    isSubmitting.value = true;
    try {
      await _apiService.deleteMedicalItem(id);
      items.removeWhere((i) => i.id == id);
      allBatches.removeWhere((b) => b.itemId == id);
      await refreshAllData(showLoader: false);
      CustomSnackbar.showSuccess(
        title: 'Medicine Removed',
        message: 'Medicine record has been deleted.',
      );
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Delete Failed',
        message: _extractErrorMessage(e, defaultMessage: 'Failed to delete medicine.'),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  // -------------------------------------------------------------
  // TAB 2: STOCK INWARD (DYNAMIC MULTI-BATCH ENTRY)
  // -------------------------------------------------------------
  void addInwardBatchRow() {
    inwardBatchRows.add(
      MedicalInwardBatchRow(
        initialBatchNo: 'B-${DateTime.now().year}-${Random().nextInt(900) + 100}',
        initialExpiry: DateTime.now().add(const Duration(days: 365)),
        initialMfg: DateTime.now().subtract(const Duration(days: 30)),
      ),
    );
  }

  void removeInwardBatchRow(int index) {
    if (inwardBatchRows.length <= 1) {
      CustomSnackbar.showWarning(
        title: 'Action Denied',
        message: 'At least one batch row is required for stock inward.',
      );
      return;
    }
    final row = inwardBatchRows.removeAt(index);
    row.dispose();
  }

  double get inwardTotalQuantity {
    return inwardBatchRows.fold<double>(0.0, (sum, row) => sum + row.rowQuantity.value);
  }

  double get inwardTotalValue {
    return inwardBatchRows.fold<double>(0.0, (sum, row) => sum + row.lineTotal.value);
  }

  void clearInwardForm() {
    inwardSelectedItem.value = null;
    inwardSupplierController.clear();
    inwardBillNoController.clear();
    inwardDate.value = DateTime.now();
    for (final row in inwardBatchRows) {
      row.dispose();
    }
    inwardBatchRows.clear();
    addInwardBatchRow();
  }

  Future<void> submitStockInward() async {
    // 1. Validations
    final item = inwardSelectedItem.value;
    if (item == null) {
      CustomSnackbar.showWarning(
        title: 'Medicine Required',
        message: 'Please search and select a medicine SKU for stock inward.',
      );
      return;
    }

    if (inwardBatchRows.isEmpty) {
      CustomSnackbar.showWarning(
        title: 'Batches Required',
        message: 'Please enter at least one batch to record inward stock.',
      );
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<MedicalInwardBatchDto> batchDtos = [];
    for (int i = 0; i < inwardBatchRows.length; i++) {
      final row = inwardBatchRows[i];
      final bNo = row.batchNumber;
      final exp = row.expiryDate.value;
      final qty = row.quantity;
      final price = row.unitPrice;

      if (bNo.isEmpty) {
        CustomSnackbar.showWarning(
          title: 'Batch Number Missing',
          message: 'Row #${i + 1}: Batch number cannot be empty.',
        );
        return;
      }

      if (exp == null) {
        CustomSnackbar.showWarning(
          title: 'Expiry Date Required',
          message: 'Row #${i + 1} ($bNo): Please pick a valid expiry date.',
        );
        return;
      }

      final expDateOnly = DateTime(exp.year, exp.month, exp.day);
      if (expDateOnly.isBefore(today)) {
        CustomSnackbar.showError(
          title: 'Invalid Expiry Date',
          message: 'Row #${i + 1} ($bNo): Expiry date cannot be in the past for stock inward!',
        );
        return;
      }

      if (qty <= 0) {
        CustomSnackbar.showWarning(
          title: 'Positive Quantity Required',
          message: 'Row #${i + 1} ($bNo): Quantity must be greater than zero.',
        );
        return;
      }

      if (price < 0) {
        CustomSnackbar.showWarning(
          title: 'Invalid Unit Price',
          message: 'Row #${i + 1} ($bNo): Unit price cannot be negative.',
        );
        return;
      }

      batchDtos.add(
        MedicalInwardBatchDto(
          batchNumber: bNo,
          expiryDate: exp,
          mfgDate: row.mfgDate.value,
          quantity: qty,
          unitPrice: price,
          mrp: row.mrp,
        ),
      );
    }

    isSubmitting.value = true;
    try {
      final request = MedicalStockInwardRequest(
        gaushalaId: activeGaushalaId,
        itemId: item.id,
        reason: inwardReason.value.code,
        supplierOrDonorName: inwardSupplierController.text.trim(),
        billOrReceiptNo: inwardBillNoController.text.trim(),
        transactionDate: inwardDate.value,
        batches: batchDtos,
      );

      final transaction = await _apiService.recordMedicalStockInward(request);
      transactions.insert(0, transaction);
      await refreshAllData(showLoader: false);

      CustomSnackbar.showSuccess(
        title: 'Stock Inward Recorded',
        message: 'Successfully received ${inwardTotalQuantity.toStringAsFixed(0)} ${item.unit} (${batchDtos.length} batches) for ${item.itemName}.',
      );

      clearInwardForm();
      switchTab(1); // Navigate to inventory list to see updated stock
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Stock Inward Failed',
        message: _extractErrorMessage(e, defaultMessage: 'Failed to record stock inward.'),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  // -------------------------------------------------------------
  // TAB 3: STOCK OUTWARD / DISPENSING (REAL-TIME FEFO ENGINE)
  // -------------------------------------------------------------
  void onOutwardItemChanged(MedicalItemModel? newItem) {
    if (newItem != null) {
      final itemBatches = getBatchesForItem(newItem.id);
      if (itemBatches.isNotEmpty) {
        newItem = newItem.copyWith(batches: itemBatches);
      } else {
        fetchBatchesForItem(newItem.id);
      }
    }
    outwardSelectedItem.value = newItem;
    _computeFefoPreview();
  }

  void _onOutwardQuantityChanged() {
    final qty = double.tryParse(outwardQuantityController.text.trim()) ?? 0.0;
    outwardRequestedQuantity.value = qty;
    _computeFefoPreview();
  }

  double get outwardItemAvailableStock {
    final it = outwardSelectedItem.value;
    if (it == null) return 0.0;
    final batches = it.fefoBatches.isNotEmpty
        ? it.fefoBatches
        : getBatchesForItem(it.id).where((b) => b.availableQuantity > 0 && !b.isExpired).toList();
    return batches.fold<double>(0.0, (sum, b) => sum + b.availableQuantity);
  }

  /// Calculates real-time FEFO allocation
  void _computeFefoPreview() {
    final item = outwardSelectedItem.value;
    final reqQty = outwardRequestedQuantity.value;

    if (item == null || reqQty <= 0) {
      outwardFefoPreviews.clear();
      outwardHasExcessStockError.value = false;
      return;
    }

    final activeBatches = item.fefoBatches.isNotEmpty
        ? item.fefoBatches
        : getBatchesForItem(item.id).where((b) => b.availableQuantity > 0 && !b.isExpired).toList();
    final totalAvail = activeBatches.fold<double>(0.0, (s, b) => s + b.availableQuantity);

    if (reqQty > totalAvail) {
      outwardHasExcessStockError.value = true;
    } else {
      outwardHasExcessStockError.value = false;
    }

    double remainingToDeduct = reqQty;
    final List<FefoBatchPreview> previews = [];

    for (final batch in activeBatches) {
      if (remainingToDeduct <= 0) {
        previews.add(
          FefoBatchPreview(
            batch: batch,
            deductedQuantity: 0.0,
            remainingQuantity: batch.availableQuantity,
            isFullyConsumed: false,
            isPartiallyConsumed: false,
          ),
        );
      } else {
        final deduct = min(batch.availableQuantity, remainingToDeduct);
        remainingToDeduct -= deduct;
        final rem = batch.availableQuantity - deduct;
        previews.add(
          FefoBatchPreview(
            batch: batch,
            deductedQuantity: deduct,
            remainingQuantity: rem,
            isFullyConsumed: rem == 0,
            isPartiallyConsumed: rem > 0 && deduct > 0,
          ),
        );
      }
    }

    outwardFefoPreviews.assignAll(previews);
  }

  void clearOutwardForm() {
    outwardSelectedItem.value = null;
    outwardQuantityController.clear();
    outwardRequestedQuantity.value = 0.0;
    outwardSelectedCow.value = null;
    outwardSelectedShed.value = null;
    outwardDoctorController.clear();
    outwardPrescribedForController.clear();
    outwardNotesController.clear();
    outwardDate.value = DateTime.now();
    outwardFefoPreviews.clear();
    outwardHasExcessStockError.value = false;
  }

  Future<MedicalStockOutwardResponse?> submitStockOutward() async {
    final item = outwardSelectedItem.value;
    if (item == null) {
      CustomSnackbar.showWarning(
        title: 'Medicine Required',
        message: 'Please search and select a medicine for outward dispensing.',
      );
      return null;
    }

    final reqQty = outwardRequestedQuantity.value;
    if (reqQty <= 0) {
      CustomSnackbar.showWarning(
        title: 'Invalid Quantity',
        message: 'Please enter a positive quantity to dispense.',
      );
      return null;
    }

    final availStock = outwardItemAvailableStock;
    if (reqQty > availStock) {
      CustomSnackbar.showError(
        title: 'Insufficient Stock',
        message: 'Requested quantity ($reqQty ${item.unit}) exceeds available safe stock ($availStock ${item.unit}).',
      );
      return null;
    }

    isSubmitting.value = true;
    try {
      final request = MedicalStockOutwardRequest(
        gaushalaId: activeGaushalaId,
        itemId: item.id,
        quantity: reqQty,
        reason: outwardReason.value.code,
        cowId: outwardSelectedCow.value?.id,
        shedId: outwardSelectedShed.value?.id,
        doctorName: outwardDoctorController.text.trim(),
        prescribedFor: outwardPrescribedForController.text.trim(),
        notes: outwardNotesController.text.trim(),
        transactionDate: outwardDate.value,
      );

      final response = await _apiService.recordMedicalStockOutward(request);
      await refreshAllData(showLoader: false);
      clearOutwardForm();
      return response;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Stock Outward Failed',
        message: _extractErrorMessage(e, defaultMessage: 'Failed to record stock outward.'),
      );
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  // -------------------------------------------------------------
  // TAB 4: BATCHES & EXPIRY TRACKER & DISPOSAL
  // -------------------------------------------------------------
  List<MedicalBatchModel> get filteredBatches {
    final statusFilter = batchExpiryFilter.value;
    final medId = batchMedicineFilter.value;
    final query = batchSearchQuery.value.trim().toLowerCase();

    final seenKeys = <String>{};
    return allBatches.where((b) {
      final dedupKey = b.id.isNotEmpty ? b.id : '${b.itemId}_${b.batchNumber.trim().toUpperCase()}';
      if (!seenKeys.add(dedupKey)) {
        return false;
      }

      if (query.isNotEmpty) {
        final matchBatch = b.batchNumber.toLowerCase().contains(query);
        final matchName = b.itemName.toLowerCase().contains(query);
        if (!matchBatch && !matchName) return false;
      }

      if (medId != null && medId.isNotEmpty && medId != 'all') {
        if (b.itemId != medId) return false;
      }

      if (statusFilter == 'ACTIVE') {
        if (b.availableQuantity <= 0 || b.isExpired) return false;
      } else if (statusFilter == 'EXPIRING_30') {
        if (!b.isExpiringSoon || b.availableQuantity <= 0) return false;
      } else if (statusFilter == 'EXPIRING_60') {
        if (!b.isExpiringWarning || b.availableQuantity <= 0) return false;
      } else if (statusFilter == 'EXPIRED') {
        if (!b.isExpired) return false;
      }

      return true;
    }).toList();
  }

  List<MedicalBatchModel> get paginatedBatches {
    final list = filteredBatches;
    final int start = (batchesCurrentPage.value - 1) * batchesPerPage.value;
    if (start >= list.length) {
      if (list.isNotEmpty && batchesCurrentPage.value > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final maxPage = (list.length / batchesPerPage.value).ceil().clamp(1, 999999);
          if (batchesCurrentPage.value > maxPage) {
            batchesCurrentPage.value = maxPage;
          }
        });
      }
      return list.take(batchesPerPage.value).toList();
    }
    final end = min(start + batchesPerPage.value, list.length);
    return list.sublist(start, end);
  }

  int get batchesTotalPages {
    final len = filteredBatches.length;
    if (len == 0) return 1;
    return (len / batchesPerPage.value).ceil();
  }

  void setBatchesPage(int page) {
    if (page >= 1 && page <= batchesTotalPages) {
      batchesCurrentPage.value = page;
    }
  }

  void setBatchesPerPage(int count) {
    batchesPerPage.value = count;
    batchesCurrentPage.value = 1;
  }

  Future<bool> disposeExpiredBatch({
    required MedicalBatchModel batch,
    required double quantity,
    required String reason,
    String? notes,
  }) async {
    isSubmitting.value = true;
    try {
      final request = MedicalStockAdjustmentRequest(
        gaushalaId: activeGaushalaId,
        itemId: batch.itemId,
        batchId: batch.id,
        batchNumber: batch.batchNumber,
        quantity: quantity,
        reason: reason,
        notes: notes,
      );

      final txn = await _apiService.recordMedicalStockAdjustment(request);
      transactions.insert(0, txn);
      await refreshAllData(showLoader: false);

      CustomSnackbar.showSuccess(
        title: 'Batch Disposed',
        message: 'Successfully disposed ${quantity.toStringAsFixed(0)} units from batch ${batch.batchNumber}.',
      );
      return true;
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Disposal Failed',
        message: _extractErrorMessage(e, defaultMessage: 'Failed to dispose expired stock.'),
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // -------------------------------------------------------------
  // TAB 5: STOCK LEDGER / TRANSACTION AUDIT LOG
  // -------------------------------------------------------------
  List<MedicalTransactionModel> get filteredTransactions {
    final type = ledgerTypeFilter.value;
    final medId = ledgerMedicineFilter.value;
    final rsn = ledgerReasonFilter.value;
    final start = ledgerStartDate.value;
    final end = ledgerEndDate.value;

    return transactions.where((t) {
      if (type != 'ALL' && t.type != type) return false;
      if (medId != null && medId.isNotEmpty && medId != 'all') {
        if (t.itemId != medId) return false;
      }
      if (rsn != 'ALL' && t.reason != rsn) return false;
      if (start != null && t.transactionDate != null) {
        if (t.transactionDate!.isBefore(start)) return false;
      }
      if (end != null && t.transactionDate != null) {
        final endInclusive = DateTime(end.year, end.month, end.day, 23, 59, 59);
        if (t.transactionDate!.isAfter(endInclusive)) return false;
      }
      return true;
    }).toList();
  }

  List<MedicalTransactionModel> get paginatedTransactions {
    final list = filteredTransactions;
    final start = (ledgerPage.value - 1) * ledgerLimit.value;
    if (start >= list.length) return [];
    final end = min(start + ledgerLimit.value, list.length);
    return list.sublist(start, end);
  }

  int get ledgerTotalPages {
    final len = filteredTransactions.length;
    if (len == 0) return 1;
    return (len / ledgerLimit.value).ceil();
  }

}

