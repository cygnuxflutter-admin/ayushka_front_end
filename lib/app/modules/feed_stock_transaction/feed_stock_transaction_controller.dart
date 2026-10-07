import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/utils/file_download_helper.dart';
import '../../core/values/app_colors.dart';
import '../../core/values/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dropdown_search.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../data/models/feed_item_model.dart';
import '../../data/models/feed_stock_transaction_model.dart';
import '../../data/models/gaushala_model.dart';
import '../../data/models/shed_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/gaushala_session_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';

/// Controller managing Feed Stock Transactions (Inward & Outward)
/// state, filters, recording actions, and receipt modals.
class FeedStockTransactionController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isSidebarCollapsed = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isSubmitting = false.obs;

  // Data lists
  final RxList<FeedStockTransactionModel> transactions = <FeedStockTransactionModel>[].obs;
  final RxList<FeedStockTransactionModel> mobileTransactions = <FeedStockTransactionModel>[].obs;
  final RxInt mobilePage = 1.obs;
  final RxBool isLoadingMoreTransactions = false.obs;
  bool get hasMoreMobileTransactions => mobileTransactions.length < totalRecords.value;

  final RxList<FeedItemModel> feedItems = <FeedItemModel>[].obs;
  final RxList<ShedModel> sheds = <ShedModel>[].obs;
  final RxList<GaushalaModel> gaushalas = <GaushalaModel>[].obs;

  // Filter states
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final Rxn<String> selectedGaushalaFilter = Rxn<String>();
  final RxString selectedTypeFilter = 'ALL'.obs; // ALL, INWARD, OUTWARD
  final RxString selectedReasonFilter = 'ALL'.obs; // ALL, PURCHASE, DONATION, DAILY_FEEDING, OTHER
  final Rxn<String> selectedItemFilter = Rxn<String>(); // itemId or null
  final Rxn<String> selectedShedFilter = Rxn<String>(); // shedId or null
  final Rxn<DateTimeRange> selectedDateRange = Rxn<DateTimeRange>();

  // Pagination states
  final RxInt currentPage = 1.obs;
  final RxInt rowsPerPage = 5.obs;
  final RxInt totalRecords = 0.obs;
  final RxInt totalPages = 1.obs;

  bool get canChangeGaushala => _gaushalaService.canChangeGaushala;

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

  // Summary Metrics computed from loaded transactions
  int get totalTransactionsCount => totalRecords.value > 0 ? totalRecords.value : transactions.length;

  int get inwardTransactionsCount => transactions.where((t) => t.isInward).length;
  double get totalInwardQuantity =>
      transactions.where((t) => t.isInward).fold(0.0, (sum, t) => sum + t.quantity);

  int get outwardTransactionsCount => transactions.where((t) => t.isOutward).length;
  double get totalOutwardQuantity =>
      transactions.where((t) => t.isOutward).fold(0.0, (sum, t) => sum + t.quantity);

  double get totalPurchaseSpend => transactions
      .where((t) => t.isInward && t.totalAmount > 0)
      .fold(0.0, (sum, t) => sum + t.totalAmount);

  List<FeedItemModel> get outOfStockItems =>
      feedItems.where((i) => i.currentStock <= 0.0).toList();

  List<FeedItemModel> get lowStockItems =>
      feedItems.where((i) => i.isLowStock && i.currentStock > 0.0).toList();

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    _bindGaushalaSession();
    loadInitialData();
  }

  void _loadUser() {
    currentUser.value = _storageService.getUser();
  }

  void _bindGaushalaSession() {
    selectedGaushalaFilter.value = _gaushalaService.selectedGaushalaId;
    ever(_gaushalaService.selectedGaushala, (GaushalaModel? g) {
      if (g != null && selectedGaushalaFilter.value != g.id) {
        selectedGaushalaFilter.value = g.id;
        currentPage.value = 1;
        fetchTransactions();
        loadFeedItems(g.id);
        loadSheds(g.id);
      }
    });
  }

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  Future<void> logout() async {
    _storageService.removeToken();
    _storageService.removeUser();
    Get.offAllNamed(AppRoutes.auth);
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        loadGaushalas(),
        loadFeedItems(selectedGaushalaFilter.value),
        loadSheds(selectedGaushalaFilter.value),
      ]);
      await fetchTransactions();
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to initialize feed stock transactions: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadGaushalas() async {
    try {
      final list = await _apiService.getGaushalas();
      gaushalas.assignAll(list);
    } catch (_) {}
  }

  Future<void> loadFeedItems(String? gId) async {
    try {
      final list = await _apiService.getFeedItems(gaushalaId: gId);
      feedItems.assignAll(list);
    } catch (_) {}
  }

  Future<void> loadSheds(String? gId) async {
    try {
      final list = await _apiService.getSheds(gaushalaId: gId);
      sheds.assignAll(list);
    } catch (_) {}
  }

  Future<void> fetchTransactions({bool showRefreshing = false, bool resetMobile = true}) async {
    if (showRefreshing) {
      isRefreshing.value = true;
    } else if (transactions.isEmpty) {
      isLoading.value = true;
    }

    try {
      final result = await _apiService.getFeedStockTransactions(
        gaushalaId: selectedGaushalaFilter.value,
        itemId: selectedItemFilter.value,
        type: selectedTypeFilter.value == 'ALL' ? null : selectedTypeFilter.value,
        shedId: selectedShedFilter.value,
        reason: selectedReasonFilter.value == 'ALL' ? null : selectedReasonFilter.value,
        page: currentPage.value,
        limit: rowsPerPage.value,
        search: searchQuery.value.trim().isEmpty ? null : searchQuery.value.trim(),
      );

      transactions.assignAll(result.items);
      totalRecords.value = result.total;
      totalPages.value = result.totalPages;
      if (resetMobile) {
        mobilePage.value = currentPage.value;
        mobileTransactions.assignAll(result.items);
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Could not fetch stock transactions: $e',
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> loadMoreMobileTransactions() async {
    if (isLoadingMoreTransactions.value || !hasMoreMobileTransactions) return;
    isLoadingMoreTransactions.value = true;
    try {
      final nextPage = mobilePage.value + 1;
      final result = await _apiService.getFeedStockTransactions(
        gaushalaId: selectedGaushalaFilter.value,
        itemId: selectedItemFilter.value,
        type: selectedTypeFilter.value == 'ALL' ? null : selectedTypeFilter.value,
        shedId: selectedShedFilter.value,
        reason: selectedReasonFilter.value == 'ALL' ? null : selectedReasonFilter.value,
        page: nextPage,
        limit: rowsPerPage.value,
        search: searchQuery.value.trim().isEmpty ? null : searchQuery.value.trim(),
      );
      mobileTransactions.addAll(result.items);
      mobilePage.value = nextPage;
      totalRecords.value = result.total;
    } catch (_) {
    } finally {
      isLoadingMoreTransactions.value = false;
    }
  }

  Future<void> refreshTransactions() async {
    await Future.wait([
      loadFeedItems(selectedGaushalaFilter.value),
      loadSheds(selectedGaushalaFilter.value),
      fetchTransactions(showRefreshing: true),
    ]);
  }

  void setGaushalaFilter(String? gId) {
    if (!canChangeGaushala) return;
    selectedGaushalaFilter.value = gId;
    currentPage.value = 1;
    loadFeedItems(gId);
    loadSheds(gId);
    fetchTransactions();
  }

  void setTypeFilter(String type) {
    selectedTypeFilter.value = type;
    currentPage.value = 1;
    fetchTransactions();
  }

  void setReasonFilter(String reason) {
    selectedReasonFilter.value = reason;
    currentPage.value = 1;
    fetchTransactions();
  }

  void setItemFilter(String? itemId) {
    selectedItemFilter.value = itemId;
    currentPage.value = 1;
    fetchTransactions();
  }

  void setShedFilter(String? shedId) {
    selectedShedFilter.value = shedId;
    currentPage.value = 1;
    fetchTransactions();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
    if (searchController.text != query) {
      searchController.text = query;
    }
    currentPage.value = 1;
    fetchTransactions();
  }

  void setPage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      fetchTransactions();
    }
  }

  void setRowsPerPage(int limit) {
    rowsPerPage.value = limit;
    currentPage.value = 1;
    fetchTransactions();
  }

  void clearFilters() {
    searchQuery.value = '';
    searchController.clear();
    selectedTypeFilter.value = 'ALL';
    selectedReasonFilter.value = 'ALL';
    selectedItemFilter.value = null;
    selectedShedFilter.value = null;
    selectedDateRange.value = null;
    currentPage.value = 1;
    fetchTransactions();
  }

  /// Unified Date & Time input field matching CustomTextField and CustomDropdownSearch
  /// styling with external bold label, red asterisk for required, 48px height, and rounded border.
  Widget _buildDateTimePickerField({
    required BuildContext context,
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
    bool isRequired = true,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
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
              initialDate: value,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 1)),
            );
            if (picked != null && context.mounted) {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(value),
              );
              onChanged(DateTime(
                picked.year,
                picked.month,
                picked.day,
                time?.hour ?? value.hour,
                time?.minute ?? value.minute,
              ));
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
                  PhosphorIconsRegular.calendarCheck,
                  size: 18,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(value),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                Icon(
                  PhosphorIconsRegular.caretDown,
                  size: 14,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // RECORD INWARD MODAL DIALOG
  // -------------------------------------------------------------
  void openInwardDialog(BuildContext context, {FeedItemModel? preselectedItem}) {
    final formKey = GlobalKey<FormState>();
    final qtyController = TextEditingController();
    final rateController = TextEditingController(
      text: preselectedItem != null && preselectedItem.unitPrice > 0
          ? preselectedItem.unitPrice.toStringAsFixed(2)
          : '',
    );
    final supplierController = TextEditingController();
    final billNoController = TextEditingController();
    final vehicleController = TextEditingController();
    final notesController = TextEditingController();

    final Rxn<FeedItemModel> selectedItem = Rxn<FeedItemModel>(preselectedItem);
    final Rx<FeedStockTransactionReason> selectedReason = FeedStockTransactionReason.purchase.obs;
    final Rx<DateTime> txDate = DateTime.now().obs;
    final RxDouble calculatedTotal = 0.0.obs;

    final targetGaushalaId = selectedGaushalaFilter.value ?? _gaushalaService.selectedGaushalaId;
    final Rxn<GaushalaModel> selectedGaushala = Rxn<GaushalaModel>(findGaushala(targetGaushalaId));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    void updateCalculation() {
      final q = double.tryParse(qtyController.text.trim()) ?? 0.0;
      final r = double.tryParse(rateController.text.trim()) ?? 0.0;
      calculatedTotal.value = q * r;
    }

    qtyController.addListener(updateCalculation);
    rateController.addListener(updateCalculation);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        elevation: 12,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 850),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.arrowDownLeft,
                          color: Color(0xFF10B981),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Record Inward Stock',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Receive fresh feed or fodder stock via purchase or donation',
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
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Gaushala & Item Selector
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Gaushala Selector
                              Expanded(
                                child: Obx(() {
                                  return CustomDropdownSearch<GaushalaModel>(
                                    label: 'Gaushala',
                                    isRequired: true,
                                    hint: 'Select Gaushala',
                                    prefixIcon: PhosphorIconsRegular.barn,
                                    selectedItem: selectedGaushala.value,
                                    items: gaushalas.toList(),
                                    itemAsString: (g) => g.gaushalaName,
                                    compareFn: (a, b) => a.id == b.id,
                                    enabled: canChangeGaushala,
                                    searchable: true,
                                    searchHint: 'Search Gaushala...',
                                    onChanged: (g) {
                                      selectedGaushala.value = g;
                                      selectedItem.value = null;
                                      if (g != null) {
                                        loadFeedItems(g.id);
                                      }
                                    },
                                    validator: (g) => g == null ? 'Please select gaushala' : null,
                                  );
                                }),
                              ),
                              const SizedBox(width: 14),

                              // Item Selector
                              Expanded(
                                child: Obx(() {
                                  final items = feedItems.where((i) {
                                    if (selectedGaushala.value == null) return true;
                                    return i.gaushalaId == selectedGaushala.value!.id;
                                  }).toList();

                                  return CustomDropdownSearch<FeedItemModel>(
                                    label: 'Feed Item',
                                    isRequired: true,
                                    hint: 'Select Feed Item',
                                    prefixIcon: PhosphorIconsRegular.grains,
                                    selectedItem: selectedItem.value,
                                    items: items,
                                    itemAsString: (item) => '${item.itemName} (${item.currentStock} ${item.unit})',
                                    compareFn: (a, b) => a.id == b.id,
                                    searchable: true,
                                    searchHint: 'Search feed item...',
                                    onChanged: (item) {
                                      selectedItem.value = item;
                                      if (item != null && item.unitPrice > 0 && rateController.text.isEmpty) {
                                        rateController.text = item.unitPrice.toStringAsFixed(2);
                                        updateCalculation();
                                      }
                                    },
                                    validator: (item) => item == null ? 'Please select an item' : null,
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 2. Reason & Date
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Reason dropdown
                              Expanded(
                                child: Obx(() {
                                  return CustomDropdownSearch<FeedStockTransactionReason>(
                                    label: 'Inward Reason',
                                    isRequired: true,
                                    hint: 'Select Reason',
                                    prefixIcon: PhosphorIconsRegular.tag,
                                    selectedItem: selectedReason.value,
                                    items: FeedStockTransactionReason.inwardReasons,
                                    itemAsString: (r) => r.label,
                                    compareFn: (a, b) => a == b,
                                    onChanged: (val) {
                                      if (val != null) selectedReason.value = val;
                                    },
                                  );
                                }),
                              ),
                              const SizedBox(width: 14),

                              // Date selector
                              Expanded(
                                child: Obx(() {
                                  return _buildDateTimePickerField(
                                    context: context,
                                    label: 'Date & Time',
                                    value: txDate.value,
                                    isRequired: true,
                                    onChanged: (newDt) => txDate.value = newDt,
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 3. Quantity & Rate per Unit
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Obx(() {
                                  final unitStr = selectedItem.value?.unit ?? 'KG';
                                  return CustomTextField(
                                    controller: qtyController,
                                    label: 'Quantity ($unitStr) *',
                                    hint: 'e.g. 500',
                                    prefixIcon: const Icon(PhosphorIconsRegular.scales, size: 18),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                    ],
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'Enter quantity';
                                      final n = double.tryParse(val.trim());
                                      if (n == null || n <= 0) return 'Must be > 0';
                                      return null;
                                    },
                                  );
                                }),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: CustomTextField(
                                  controller: rateController,
                                  label: 'Rate per Unit (₹)',
                                  hint: 'e.g. 15.00',
                                  prefixIcon: const Icon(PhosphorIconsRegular.currencyInr, size: 18),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Live Calculation & Stock Preview Card
                          Obx(() {
                            final item = selectedItem.value;
                            final qty = double.tryParse(qtyController.text.trim()) ?? 0.0;
                            final current = item?.currentStock ?? 0.0;
                            final after = current + qty;
                            final total = calculatedTotal.value;

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(PhosphorIconsRegular.chartLineUp, color: Color(0xFF10B981), size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Stock Preview: ${current.toStringAsFixed(1)} + ${qty.toStringAsFixed(1)} = ',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        '${after.toStringAsFixed(1)} ${item?.unit ?? 'KG'}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (total > 0)
                                    Text(
                                      'Total: ₹${NumberFormat('#,##,###.##').format(total)}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 14),

                          // 4. Supplier / Donor & Bill/Receipt No.
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: supplierController,
                                  label: 'Supplier / Donor Name',
                                  hint: 'e.g. Ram Agro Traders',
                                  prefixIcon: const Icon(PhosphorIconsRegular.user, size: 18),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: CustomTextField(
                                  controller: billNoController,
                                  label: 'Bill / Receipt No.',
                                  hint: 'e.g. INV-1024',
                                  prefixIcon: const Icon(PhosphorIconsRegular.receipt, size: 18),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 5. Vehicle Number & Notes
                          CustomTextField(
                            controller: vehicleController,
                            label: 'Vehicle Number',
                            hint: 'e.g. GJ-01-AB-1234',
                            prefixIcon: const Icon(PhosphorIconsRegular.truck, size: 18),
                          ),
                          const SizedBox(height: 14),

                          CustomTextField(
                            controller: notesController,
                            label: 'Notes / Remarks',
                            hint: 'e.g. Fresh green fodder cutting batch',
                            prefixIcon: const Icon(PhosphorIconsRegular.note, size: 18),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Actions
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      Obx(() {
                        return CustomButton(
                          text: 'Record Inward Stock',
                          icon: PhosphorIconsRegular.checkCircle,
                          isLoading: isSubmitting.value,
                          onPressed: isSubmitting.value
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  final gId = selectedGaushala.value?.id;
                                  final itm = selectedItem.value;
                                  if (gId == null || itm == null) return;

                                  final q = double.tryParse(qtyController.text.trim()) ?? 0.0;
                                  final r = double.tryParse(rateController.text.trim());

                                  isSubmitting.value = true;
                                  try {
                                    final req = FeedStockInwardRequest(
                                      gaushalaId: gId,
                                      itemId: itm.id,
                                      quantity: q,
                                      unit: itm.unit,
                                      reason: selectedReason.value.code,
                                      ratePerUnit: r,
                                      supplierOrDonorName: supplierController.text.trim(),
                                      billOrReceiptNo: billNoController.text.trim(),
                                      vehicleNumber: vehicleController.text.trim(),
                                      transactionDate: txDate.value,
                                      notes: notesController.text.trim(),
                                    );

                                    await _apiService.recordInwardStock(req);
                                    Get.back();
                                    CustomSnackbar.showSuccess(
                                      title: 'Stock Inward Recorded',
                                      message: 'Successfully recorded +$q ${itm.unit} of ${itm.itemName}',
                                    );
                                    refreshTransactions();
                                  } catch (e) {
                                    CustomSnackbar.showError(
                                      title: 'Failed',
                                      message: 'Failed to record inward transaction: $e',
                                    );
                                  } finally {
                                    isSubmitting.value = false;
                                  }
                                },
                        );
                      }),
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

  // -------------------------------------------------------------
  // RECORD OUTWARD MODAL DIALOG
  // -------------------------------------------------------------
  void openOutwardDialog(BuildContext context, {FeedItemModel? preselectedItem}) {
    final formKey = GlobalKey<FormState>();
    final qtyController = TextEditingController();
    final notesController = TextEditingController();

    final RxDouble enteredQty = 0.0.obs;
    final Rxn<FeedItemModel> selectedItem = Rxn<FeedItemModel>(preselectedItem);
    final Rx<FeedStockTransactionReason> selectedReason = FeedStockTransactionReason.dailyFeeding.obs;
    final Rxn<ShedModel> selectedShed = Rxn<ShedModel>();
    final Rx<DateTime> txDate = DateTime.now().obs;

    final targetGaushalaId = selectedGaushalaFilter.value ?? _gaushalaService.selectedGaushalaId;
    final Rxn<GaushalaModel> selectedGaushala = Rxn<GaushalaModel>(findGaushala(targetGaushalaId));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    void validateAndClampQuantity(String val) {
      if (val.trim().isEmpty) {
        enteredQty.value = 0.0;
        return;
      }
      final n = double.tryParse(val.trim());
      if (n == null) return;

      final item = selectedItem.value;
      if (item != null) {
        final maxStock = item.currentStock;
        if (n > maxStock) {
          final maxStockFormatted = (maxStock % 1 == 0)
              ? maxStock.toInt().toString()
              : maxStock.toString();

          qtyController.text = maxStockFormatted;
          qtyController.selection = TextSelection.fromPosition(
            TextPosition(offset: maxStockFormatted.length),
          );
          enteredQty.value = maxStock;

          CustomSnackbar.showWarning(
            title: 'Stock Limit Exceeded',
            message: 'Entered quantity cannot exceed available stock ($maxStockFormatted ${item.unit}).',
          );
          return;
        }
      }
      enteredQty.value = n;
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        elevation: 12,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 820),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.arrowUpRight,
                          color: Color(0xFFF59E0B),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Record Outward Stock',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Issue stock for cattle feeding or record other consumption',
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
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Gaushala & Item Selector
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Obx(() {
                                  return CustomDropdownSearch<GaushalaModel>(
                                    label: 'Gaushala',
                                    isRequired: true,
                                    hint: 'Select Gaushala',
                                    prefixIcon: PhosphorIconsRegular.barn,
                                    selectedItem: selectedGaushala.value,
                                    items: gaushalas.toList(),
                                    itemAsString: (g) => g.gaushalaName,
                                    compareFn: (a, b) => a.id == b.id,
                                    enabled: canChangeGaushala,
                                    searchable: true,
                                    searchHint: 'Search Gaushala...',
                                    onChanged: (g) {
                                      selectedGaushala.value = g;
                                      selectedItem.value = null;
                                      selectedShed.value = null;
                                      qtyController.clear();
                                      enteredQty.value = 0.0;
                                      if (g != null) {
                                        loadFeedItems(g.id);
                                        loadSheds(g.id);
                                      }
                                    },
                                    validator: (g) => g == null ? 'Please select gaushala' : null,
                                  );
                                }),
                              ),
                              const SizedBox(width: 14),

                              // Item Selector
                              Expanded(
                                child: Obx(() {
                                  final items = feedItems.where((i) {
                                    if (selectedGaushala.value == null) return true;
                                    return i.gaushalaId == selectedGaushala.value!.id;
                                  }).toList();

                                  return CustomDropdownSearch<FeedItemModel>(
                                    label: 'Feed Item',
                                    isRequired: true,
                                    hint: 'Select Feed Item',
                                    prefixIcon: PhosphorIconsRegular.grains,
                                    selectedItem: selectedItem.value,
                                    items: items,
                                    itemAsString: (item) => '${item.itemName} (${item.currentStock} ${item.unit})',
                                    compareFn: (a, b) => a.id == b.id,
                                    searchable: true,
                                    searchHint: 'Search feed item...',
                                    onChanged: (item) {
                                      selectedItem.value = item;
                                      if (item != null) {
                                        if (item.currentStock <= 0) {
                                          qtyController.clear();
                                          enteredQty.value = 0.0;
                                          CustomSnackbar.showWarning(
                                            title: 'Out of Stock',
                                            message: '${item.itemName} has 0 ${item.unit} available stock.',
                                          );
                                        } else if (qtyController.text.trim().isNotEmpty) {
                                          validateAndClampQuantity(qtyController.text.trim());
                                        }
                                      }
                                    },
                                    validator: (item) => item == null ? 'Please select an item' : null,
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 2. Reason & Shed Destination
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Reason dropdown
                              Expanded(
                                child: Obx(() {
                                  return CustomDropdownSearch<FeedStockTransactionReason>(
                                    label: 'Outward Reason',
                                    isRequired: true,
                                    hint: 'Select Reason',
                                    prefixIcon: PhosphorIconsRegular.tag,
                                    selectedItem: selectedReason.value,
                                    items: FeedStockTransactionReason.outwardReasons,
                                    itemAsString: (r) => r.label,
                                    compareFn: (a, b) => a == b,
                                    onChanged: (val) {
                                      if (val != null) selectedReason.value = val;
                                    },
                                  );
                                }),
                              ),
                              const SizedBox(width: 14),

                              // Shed Dropdown
                              Expanded(
                                child: Obx(() {
                                  final gId = selectedGaushala.value?.id;
                                  final shedList = sheds.where((s) {
                                    if (gId == null) return true;
                                    return s.gaushalaId == gId;
                                  }).toList();

                                  final isFeeding = selectedReason.value == FeedStockTransactionReason.dailyFeeding;

                                  return CustomDropdownSearch<ShedModel>(
                                    label: isFeeding ? 'Feeding Shed' : 'Destination Shed',
                                    isRequired: false,
                                    hint: 'Select Shed',
                                    prefixIcon: PhosphorIconsRegular.warehouse,
                                    selectedItem: selectedShed.value,
                                    items: shedList,
                                    itemAsString: (s) => '${s.shedName} (${s.shedNumber})',
                                    compareFn: (a, b) => a.id == b.id,
                                    searchable: true,
                                    searchHint: 'Search Shed...',
                                    onChanged: (s) => selectedShed.value = s,
                                    onClear: () => selectedShed.value = null,
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 3. Quantity & Date
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Obx(() {
                                  final item = selectedItem.value;
                                  final unitStr = item?.unit ?? 'KG';
                                  final maxStock = item?.currentStock ?? 0.0;
                                  final maxStockFormatted = (maxStock % 1 == 0)
                                      ? maxStock.toInt().toString()
                                      : maxStock.toString();
                                  final hasItem = item != null;
                                  final isOutOfStock = hasItem && maxStock <= 0;

                                  return CustomTextField(
                                    controller: qtyController,
                                    label: 'Outward Quantity ($unitStr) *',
                                    hint: !hasItem
                                        ? 'Select feed item first'
                                        : isOutOfStock
                                            ? 'Out of stock (0 $unitStr)'
                                            : 'e.g. 300 (Max: $maxStockFormatted)',
                                    prefixIcon: const Icon(PhosphorIconsRegular.scales, size: 18),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                    ],
                                    enabled: hasItem && !isOutOfStock,
                                    onChanged: validateAndClampQuantity,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'Enter quantity';
                                      final n = double.tryParse(val.trim());
                                      if (n == null || n <= 0) return 'Must be > 0';
                                      if (selectedItem.value != null && n > selectedItem.value!.currentStock) {
                                        return 'Exceeds available stock ($maxStockFormatted ${selectedItem.value!.unit})';
                                      }
                                      return null;
                                    },
                                  );
                                }),
                              ),
                              const SizedBox(width: 14),

                              Expanded(
                                child: Obx(() {
                                  return _buildDateTimePickerField(
                                    context: context,
                                    label: 'Date & Time',
                                    value: txDate.value,
                                    isRequired: true,
                                    onChanged: (newDt) => txDate.value = newDt,
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Live Stock Impact Card
                          Obx(() {
                            final item = selectedItem.value;
                            final qty = enteredQty.value;
                            final current = item?.currentStock ?? 0.0;
                            final remaining = current - qty;
                            final isExceeded = item != null && qty > current;
                            final isZeroStock = item != null && current <= 0;
                            final isWarning = isExceeded || isZeroStock;

                            final currentStr = (current % 1 == 0)
                                ? current.toInt().toString()
                                : current.toStringAsFixed(1);
                            final qtyStr = (qty % 1 == 0)
                                ? qty.toInt().toString()
                                : qty.toStringAsFixed(1);
                            final remVal = remaining < 0 ? 0.0 : remaining;
                            final remStr = (remVal % 1 == 0)
                                ? remVal.toInt().toString()
                                : remVal.toStringAsFixed(1);

                            String message;
                            if (item == null) {
                              message = 'Select an item to view live stock impact';
                            } else if (isZeroStock) {
                              message = 'Item is out of stock (0 ${item.unit}). Cannot record outward stock.';
                            } else if (isExceeded) {
                              message = 'Warning: Available stock is only $currentStr ${item.unit}. Cannot issue $qtyStr!';
                            } else {
                              message = 'Stock Impact: $currentStr - $qtyStr = $remStr ${item.unit} remaining';
                            }

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isWarning
                                    ? Colors.red.withValues(alpha: 0.08)
                                    : const Color(0xFFF59E0B).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isWarning
                                      ? Colors.red.withValues(alpha: 0.3)
                                      : const Color(0xFFF59E0B).withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isWarning ? Icons.warning_amber_rounded : PhosphorIconsRegular.chartLineDown,
                                    color: isWarning ? Colors.red : const Color(0xFFF59E0B),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      message,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isWarning ? Colors.red : (isDark ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 14),

                          // 4. Notes
                          CustomTextField(
                            controller: notesController,
                            label: 'Notes / Remarks',
                            hint: 'e.g. Morning green fodder feed for cattle shed',
                            prefixIcon: const Icon(PhosphorIconsRegular.note, size: 18),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Actions
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      Obx(() {
                        return CustomButton(
                          text: 'Record Outward Stock',
                          icon: PhosphorIconsRegular.checkCircle,
                          isLoading: isSubmitting.value,
                          onPressed: isSubmitting.value
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  final gId = selectedGaushala.value?.id;
                                  final itm = selectedItem.value;
                                  if (gId == null) {
                                    CustomSnackbar.showWarning(title: 'Required', message: 'Please select gaushala');
                                    return;
                                  }
                                  if (itm == null) {
                                    CustomSnackbar.showWarning(title: 'Required', message: 'Please select a feed item');
                                    return;
                                  }

                                  final q = double.tryParse(qtyController.text.trim()) ?? 0.0;
                                  if (q <= 0) {
                                    CustomSnackbar.showWarning(
                                      title: 'Invalid Quantity',
                                      message: 'Quantity must be greater than 0',
                                    );
                                    return;
                                  }

                                  if (q > itm.currentStock) {
                                    final maxStr = (itm.currentStock % 1 == 0)
                                        ? itm.currentStock.toInt().toString()
                                        : itm.currentStock.toString();
                                    CustomSnackbar.showError(
                                      title: 'Stock Limit Exceeded',
                                      message: 'Entered quantity ($q ${itm.unit}) exceeds available stock ($maxStr ${itm.unit}).',
                                    );
                                    return;
                                  }

                                  isSubmitting.value = true;
                                  try {
                                    final req = FeedStockOutwardRequest(
                                      gaushalaId: gId,
                                      itemId: itm.id,
                                      quantity: q,
                                      unit: itm.unit,
                                      shedId: selectedShed.value?.id,
                                      reason: selectedReason.value.code,
                                      transactionDate: txDate.value,
                                      notes: notesController.text.trim(),
                                    );

                                    await _apiService.recordOutwardStock(req);
                                    Get.back();
                                    CustomSnackbar.showSuccess(
                                      title: 'Stock Outward Recorded',
                                      message: 'Successfully issued -$q ${itm.unit} of ${itm.itemName}',
                                    );
                                    refreshTransactions();

                                    final remaining = itm.currentStock - q;
                                    if (remaining <= 0) {
                                      Future.delayed(const Duration(milliseconds: 600), () {
                                        CustomSnackbar.showWarning(
                                          title: '⚠️ Stock Depleted Alert (0 ${itm.unit})',
                                          message: 'Warning: "${itm.itemName}" is now completely OUT OF STOCK (0.0 ${itm.unit})! Restocking required.',
                                          duration: const Duration(seconds: 5),
                                        );
                                      });
                                    }
                                  } catch (e) {
                                    CustomSnackbar.showError(
                                      title: 'Failed',
                                      message: 'Failed to record outward transaction: $e',
                                    );
                                  } finally {
                                    isSubmitting.value = false;
                                  }
                                },
                        );
                      }),
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

  // -------------------------------------------------------------
  // TRANSACTION RECEIPT / DETAILS MODAL
  // -------------------------------------------------------------
  void openTransactionDetailsDialog(BuildContext context, FeedStockTransactionModel tx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        elevation: 12,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
                        color: tx.isInward
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        tx.isInward ? PhosphorIconsRegular.arrowDownLeft : PhosphorIconsRegular.arrowUpRight,
                        color: tx.isInward ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.isInward ? 'Inward Stock Receipt' : 'Outward Stock Voucher',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Voucher ID: ${tx.id}',
                            style: TextStyle(
                              fontSize: 11,
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

                // Body details
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Highlight Qty banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: tx.isInward
                                ? const Color(0xFF10B981).withValues(alpha: 0.08)
                                : const Color(0xFFF59E0B).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: tx.isInward
                                  ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                  : const Color(0xFFF59E0B).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.itemName,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Code: ${tx.itemCode.isNotEmpty ? tx.itemCode : 'N/A'} • ${tx.categoryEnum.label}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${tx.isInward ? '+' : '-'}${tx.quantity.toStringAsFixed(1)} ${tx.unit}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: tx.isInward ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Key-Value Grid
                        _buildDetailRow('Transaction Type', tx.typeEnum.label, isDark),
                        _buildDetailRow('Reason', tx.reasonEnum.label, isDark),
                        _buildDetailRow(
                          'Transaction Date',
                          tx.transactionDate != null
                              ? DateFormat('dd MMM yyyy, hh:mm a').format(tx.transactionDate!)
                              : 'N/A',
                          isDark,
                        ),
                        if (tx.gaushalaName != null && tx.gaushalaName!.isNotEmpty)
                          _buildDetailRow('Gaushala', tx.gaushalaName!, isDark),
                        if (tx.shedName != null && tx.shedName!.isNotEmpty)
                          _buildDetailRow(
                            'Shed Destination',
                            '${tx.shedName!} (${tx.shedNumber ?? ''})',
                            isDark,
                          ),
                        if (tx.ratePerUnit > 0)
                          _buildDetailRow('Rate per Unit', '₹${tx.ratePerUnit.toStringAsFixed(2)} / ${tx.unit}', isDark),
                        if (tx.totalAmount > 0)
                          _buildDetailRow('Total Cost', '₹${NumberFormat('#,##,###.##').format(tx.totalAmount)}', isDark),
                        if (tx.supplierOrDonorName.isNotEmpty)
                          _buildDetailRow('Supplier / Donor', tx.supplierOrDonorName, isDark),
                        if (tx.billOrReceiptNo.isNotEmpty)
                          _buildDetailRow('Bill / Receipt No.', tx.billOrReceiptNo, isDark),
                        if (tx.vehicleNumber.isNotEmpty)
                          _buildDetailRow('Vehicle Number', tx.vehicleNumber, isDark),

                        // Stock Audit Row
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : const Color(0xFFF4F6F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('Stock Before', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${tx.stockBefore.toStringAsFixed(1)} ${tx.unit}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Icon(
                                PhosphorIconsRegular.arrowRight,
                                size: 16,
                                color: tx.isInward ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              ),
                              Column(
                                children: [
                                  const Text('Stock After', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${tx.stockAfter.toStringAsFixed(1)} ${tx.unit}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: tx.stockAfter <= 0
                                          ? AppColors.error
                                          : (tx.isInward ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (tx.stockAfter <= 0) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Stock Depleted: Following this transaction, available stock dropped to 0.0 ${tx.unit} (Out of Stock).',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (tx.recordedByName != null && tx.recordedByName!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow('Recorded By', tx.recordedByName!, isDark),
                        ],
                        if (tx.notes.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow('Notes / Remarks', tx.notes, isDark),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // CSV EXPORT HELPER
  // -------------------------------------------------------------
  Future<void> exportToCsv() async {
    if (transactions.isEmpty) {
      CustomSnackbar.showWarning(
        title: 'No Data',
        message: 'There are no transactions to export.',
      );
      return;
    }

    try {
      final buffer = StringBuffer();
      // CSV Header
      buffer.writeln(
        'Transaction ID,Date,Gaushala,Item Name,Item Code,Category,Type,Reason,Quantity,Unit,Rate,Total Cost,Shed,Supplier/Donor,Bill No,Vehicle No,Stock Before,Stock After,Recorded By,Notes',
      );

      for (final t in transactions) {
        final dateStr = t.transactionDate != null
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(t.transactionDate!)
            : '';
        final row = [
          t.id,
          dateStr,
          t.gaushalaName ?? '',
          '"${t.itemName.replaceAll('"', '""')}"',
          t.itemCode,
          t.category,
          t.type,
          t.reason,
          t.quantity,
          t.unit,
          t.ratePerUnit,
          t.totalAmount,
          '"${(t.shedName ?? '').replaceAll('"', '""')}"',
          '"${t.supplierOrDonorName.replaceAll('"', '""')}"',
          t.billOrReceiptNo,
          t.vehicleNumber,
          t.stockBefore,
          t.stockAfter,
          '"${(t.recordedByName ?? '').replaceAll('"', '""')}"',
          '"${t.notes.replaceAll('"', '""')}"',
        ];
        buffer.writeln(row.join(','));
      }

      final bytes = utf8.encode(buffer.toString());
      final nowStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      await FileDownloadHelper.download(
        bytes: bytes,
        fileName: 'feed_stock_transactions_$nowStr.csv',
        mimeType: 'text/csv; charset=utf-8',
      );

      CustomSnackbar.showSuccess(
        title: 'Export Complete',
        message: 'Downloaded ${transactions.length} stock transaction records.',
      );
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Export Failed',
        message: 'Could not export CSV: $e',
      );
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
