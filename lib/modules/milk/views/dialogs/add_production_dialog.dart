import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/core/values/app_colors.dart';
import '../../../../app/core/widgets/custom_button.dart';
import '../../../../app/core/widgets/custom_dropdown_search.dart';
import '../../../../app/core/widgets/custom_snackbar.dart';
import '../../../../app/core/widgets/custom_text_field.dart';
import '../../../../app/data/models/cow_model.dart';
import '../../../../app/data/models/worker_model.dart';
import '../../controllers/milk_controller.dart';
import '../../models/milk_production_model.dart';

enum ProductionEntryMode { single, bulk }

/// Modal dialog for recording Milk Production (supports Single Cow Entry & Bulk Shift Entry)
class AddProductionDialog extends StatefulWidget {
  final ProductionEntryMode initialMode;
  final String? initialShift;

  const AddProductionDialog({super.key, this.initialMode = ProductionEntryMode.single, this.initialShift});

  static Future<void> show(BuildContext context, {ProductionEntryMode mode = ProductionEntryMode.single, String? shift}) async {
    await Get.dialog(AddProductionDialog(initialMode: mode, initialShift: shift), barrierDismissible: false);
  }

  @override
  State<AddProductionDialog> createState() => _AddProductionDialogState();
}

class _AddProductionDialogState extends State<AddProductionDialog> {
  final MilkController _controller = Get.find<MilkController>();
  late ProductionEntryMode _currentMode;

  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  late String _shift;

  // Single Entry Form Controllers
  CowModel? _selectedCow;
  WorkerModel? _selectedWorker;
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();

  // Bulk Entry State
  WorkerModel? _bulkDefaultWorker;
  final Map<String, BulkProductionEntryItem> _bulkItems = {};
  final Map<String, TextEditingController> _bulkQtyControllers = {};
  final TextEditingController _bulkSearchCtrl = TextEditingController();
  String _bulkSearchFilter = '';

  bool _isSubmitting = false;
  int _formResetKey = 0;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    _selectedDate = _controller.selectedDate.value;
    final shiftVal = widget.initialShift ?? _controller.productionShift.value;
    _shift = (shiftVal == 'all' || shiftVal.isEmpty) ? 'morning' : shiftVal;

    _initializeBulkEntries();

    _bulkSearchCtrl.addListener(() {
      setState(() {
        _bulkSearchFilter = _bulkSearchCtrl.text.trim().toLowerCase();
      });
    });
  }

  void _initializeBulkEntries() {
    for (final cow in _controller.activeCows) {
      if (!_bulkItems.containsKey(cow.id)) {
        _bulkItems[cow.id] = BulkProductionEntryItem(cowId: cow.id, cowTag: cow.tagId, cowName: cow.calfName, workerId: _bulkDefaultWorker?.id ?? '');
        _bulkQtyControllers[cow.id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _remarksCtrl.dispose();
    _bulkSearchCtrl.dispose();
    for (final c in _bulkQtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyDefaultWorkerToAll(WorkerModel? worker) {
    setState(() {
      _bulkDefaultWorker = worker;
      if (worker != null) {
        for (final item in _bulkItems.values) {
          item.workerId = worker.id;
        }
      }
    });
  }

  double get _bulkTotalQuantity {
    double sum = 0.0;
    for (final item in _bulkItems.values) {
      sum += item.quantity;
    }
    return sum;
  }

  int get _bulkFilledCowsCount {
    return _bulkItems.values.where((item) => item.quantity > 0).length;
  }

  Future<void> _submitSingle() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCow == null) {
      CustomSnackbar.showWarning(title: 'Missing Cow', message: 'Please select a cow to record production.');
      return;
    }
    if (_selectedWorker == null) {
      CustomSnackbar.showWarning(title: 'Missing Worker', message: 'Please select the milking worker.');
      return;
    }

    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0.0;

    setState(() => _isSubmitting = true);
    final success = await _controller.submitSingleProduction(
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      shift: _shift,
      cowId: _selectedCow!.id,
      workerId: _selectedWorker!.id,
      quantity: qty,
      remarks: _remarksCtrl.text.trim(),
    );
    setState(() => _isSubmitting = false);

    if (success) {
      _clearSingleForm();
    }
  }

  void _clearSingleForm() {
    setState(() {
      _selectedCow = null;
      _selectedWorker = null;
      _qtyCtrl.clear();
      _remarksCtrl.clear();
      _formResetKey++;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _submitBulk() async {
    final activeEntries = _bulkItems.values.where((e) => e.quantity > 0).toList();
    if (activeEntries.isEmpty) {
      CustomSnackbar.showWarning(title: 'No Quantities', message: 'Please enter milk quantity for at least one cow.');
      return;
    }

    // Ensure worker is assigned for every filled cow
    for (final entry in activeEntries) {
      if (entry.workerId.isEmpty && _bulkDefaultWorker != null) {
        entry.workerId = _bulkDefaultWorker!.id;
      }
      if (entry.workerId.isEmpty) {
        CustomSnackbar.showWarning(
          title: 'Missing Worker',
          message: 'Please assign a worker for Cow Tag ${entry.cowTag} or select a Default Worker.',
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    final success = await _controller.submitBulkProduction(
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      shift: _shift,
      defaultWorkerId: _bulkDefaultWorker?.id,
      entries: activeEntries,
    );
    setState(() => _isSubmitting = false);

    if (success) {
      _clearBulkForm();
    }
  }

  void _clearBulkForm() {
    setState(() {
      _bulkDefaultWorker = null;
      for (final ctrl in _bulkQtyControllers.values) {
        ctrl.clear();
      }
      for (final item in _bulkItems.values) {
        item.quantity = 0.0;
        item.workerId = '';
      }
      _bulkSearchCtrl.clear();
      _formResetKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBulk = _currentMode == ProductionEntryMode.bulk;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 500 ? 12 : 20, vertical: 20),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isBulk ? 960 : 580, maxHeight: isBulk ? 780 : 660),
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 500 ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -------------------------------------------------------------
              // HEADER & MODE TOGGLE
              // -------------------------------------------------------------
              _buildHeader(context, isDark),
              const SizedBox(height: 16),

              // Mode Tabs (Single vs Bulk)
              _buildModeSwitcher(isDark),
              const SizedBox(height: 16),

              // Date & Shift Shared Bar
              _buildDateAndShiftBar(isDark),
              const SizedBox(height: 16),

              const Divider(height: 1),
              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // BODY: SINGLE OR BULK
              // -------------------------------------------------------------
              Expanded(child: isBulk ? _buildBulkBody(isDark) : _buildSingleBody(isDark)),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // FOOTER ACTIONS
              // -------------------------------------------------------------
              _buildFooterActions(isBulk),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(PhosphorIconsRegular.drop, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentMode == ProductionEntryMode.bulk ? 'Bulk Milk Production' : 'Record Cow Milk Production',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gaushala: ${_controller.selectedGaushalaName}',
                  style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
              ],
            ),
          ],
        ),
        IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close_rounded), tooltip: 'Close'),
      ],
    );
  }

  Widget _buildModeSwitcher(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF263A1D) : const Color(0xFFEFF4EB), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() => _currentMode = ProductionEntryMode.single);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _currentMode == ProductionEntryMode.single ? (isDark ? AppColors.surfaceDark : Colors.white) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _currentMode == ProductionEntryMode.single
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_pin_rounded,
                      size: 16,
                      color: _currentMode == ProductionEntryMode.single
                          ? AppColors.primary
                          : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Single Cow Entry',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _currentMode == ProductionEntryMode.single ? FontWeight.bold : FontWeight.w500,
                        color: _currentMode == ProductionEntryMode.single
                            ? AppColors.primary
                            : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _currentMode = ProductionEntryMode.bulk;
                  _initializeBulkEntries();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _currentMode == ProductionEntryMode.bulk ? (isDark ? AppColors.surfaceDark : Colors.white) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _currentMode == ProductionEntryMode.bulk
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.groups_rounded,
                      size: 16,
                      color: _currentMode == ProductionEntryMode.bulk
                          ? AppColors.primary
                          : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bulk Shift Entry',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _currentMode == ProductionEntryMode.bulk ? FontWeight.bold : FontWeight.w500,
                        color: _currentMode == ProductionEntryMode.bulk
                            ? AppColors.primary
                            : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateAndShiftBar(bool isDark) {
    return Row(
      children: [
        // Date Selector Button
        Expanded(
          flex: 3,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsRegular.calendar, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Shift Selector Buttons (Morning / Evening)
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _shift = 'morning'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: _shift == 'morning' ? const Color(0xFFE98324).withValues(alpha: 0.15) : Colors.transparent,
                      border: Border.all(
                        color: _shift == 'morning' ? const Color(0xFFE98324) : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        width: _shift == 'morning' ? 1.5 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wb_sunny_rounded, size: 15, color: _shift == 'morning' ? const Color(0xFFE98324) : Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'Morning',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: _shift == 'morning' ? FontWeight.bold : FontWeight.w500,
                            color: _shift == 'morning' ? const Color(0xFFE98324) : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _shift = 'evening'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: _shift == 'evening' ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                      border: Border.all(
                        color: _shift == 'evening' ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        width: _shift == 'evening' ? 1.5 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.nights_stay_rounded, size: 15, color: _shift == 'evening' ? AppColors.primary : Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'Evening',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: _shift == 'evening' ? FontWeight.bold : FontWeight.w500,
                            color: _shift == 'evening' ? AppColors.primary : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SINGLE COW FORM BODY
  // ---------------------------------------------------------------------------
  Widget _buildSingleBody(bool isDark) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cow Dropdown
            CustomDropdownSearch<CowModel>(
              key: ValueKey('cow_select_$_formResetKey'),
              label: 'Select Cow',
              isRequired: true,
              hint: 'Search cow tag or name...',
              searchable: true,
              items: _controller.activeCows,
              selectedItem: _selectedCow,
              itemAsString: (c) => c.tagId.isNotEmpty ? '${c.tagId}${c.calfName != null ? " (${c.calfName})" : ""}' : c.id,
              onChanged: (c) => setState(() => _selectedCow = c),
              prefixIcon: Icons.pets_rounded,
            ),
            const SizedBox(height: 14),

            // Worker Dropdown
            CustomDropdownSearch<WorkerModel>(
              key: ValueKey('worker_select_$_formResetKey'),
              label: 'Milking Worker / Reported By',
              isRequired: true,
              hint: 'Select farm worker...',
              searchable: true,
              items: _controller.activeWorkers,
              selectedItem: _selectedWorker,
              itemAsString: (w) => w.name,
              onChanged: (w) => setState(() => _selectedWorker = w),
              prefixIcon: Icons.badge_rounded,
            ),
            const SizedBox(height: 14),

            // Quantity (L)
            CustomTextField(
              label: 'Milk Quantity (Liters)',
              hint: 'e.g. 12.5',
              controller: _qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              prefixIcon: const Icon(PhosphorIconsRegular.drop, size: 18),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Enter milk quantity';
                final n = double.tryParse(val.trim());
                if (n == null || n <= 0) return 'Enter valid quantity greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Remarks
            CustomTextField(
              label: 'Remarks (Optional)',
              hint: 'Any notes regarding milking, yield or health...',
              controller: _remarksCtrl,
              maxLines: 2,
              prefixIcon: const Icon(Icons.notes_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BULK COW SHIFT BODY
  // ---------------------------------------------------------------------------
  Widget _buildBulkBody(bool isDark) {
    final filteredCows = _controller.activeCows.where((c) {
      if (_bulkSearchFilter.isEmpty) return true;
      final tag = c.tagId.toLowerCase();
      final name = (c.calfName ?? '').toLowerCase();
      return tag.contains(_bulkSearchFilter) || name.contains(_bulkSearchFilter);
    }).toList();

    return Column(
      children: [
        // Default Worker & Search Bar
        Row(
          children: [
            Expanded(
              flex: 4,
              child: CustomDropdownSearch<WorkerModel>(
                key: ValueKey('bulk_worker_$_formResetKey'),
                label: 'Default Worker (Applies to all cows)',
                hint: 'Select default worker...',
                items: _controller.activeWorkers,
                selectedItem: _bulkDefaultWorker,
                itemAsString: (w) => w.name,
                onChanged: _applyDefaultWorkerToAll,
                prefixIcon: Icons.badge_rounded,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 3,
              child: CustomTextField(
                label: 'Search Active Cows',
                hint: 'Filter by Tag or Name...',
                controller: _bulkSearchCtrl,
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Live stats pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${filteredCows.length} cows (${_controller.activeCows.length} active in Gaushala)',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  children: [
                    const TextSpan(text: 'Entered: '),
                    TextSpan(
                      text: '$_bulkFilledCowsCount cows',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const TextSpan(text: '  •  Total: '),
                    TextSpan(
                      text: '${_bulkTotalQuantity.toStringAsFixed(1)} Liters',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE98324)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Cows Grid/Table
        Expanded(
          child: filteredCows.isEmpty
              ? Center(
                  child: Text(
                    _bulkSearchFilter.isEmpty ? 'No active cows found for this gaushala.' : 'No cows match "$_bulkSearchFilter".',
                    style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      itemCount: filteredCows.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      itemBuilder: (context, index) {
                        final cow = filteredCows[index];
                        final item = _bulkItems[cow.id]!;
                        final qtyCtrl = _bulkQtyControllers[cow.id]!;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          color: item.quantity > 0 ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
                          child: Row(
                            children: [
                              // Cow Tag & Name
                              SizedBox(
                                width: 140,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(cow.tagId, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                                    if (cow.calfName != null && cow.calfName!.isNotEmpty)
                                      Text(
                                        cow.calfName!,
                                        style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                      ),
                                  ],
                                ),
                              ),

                              // Worker selector
                              Expanded(
                                flex: 3,
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: item.workerId.isNotEmpty ? item.workerId : (_bulkDefaultWorker?.id ?? ''),
                                    isExpanded: true,
                                    hint: const Text('Worker', style: TextStyle(fontSize: 12)),
                                    items: [
                                      const DropdownMenuItem(
                                        value: '',
                                        child: Text('Default Worker', style: TextStyle(fontSize: 12)),
                                      ),
                                      ..._controller.activeWorkers.map(
                                        (w) => DropdownMenuItem(
                                          value: w.id,
                                          child: Text(w.name, style: const TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        item.workerId = val ?? '';
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Quantity (L)
                              SizedBox(
                                width: 130,
                                child: TextField(
                                  controller: qtyCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    labelText: 'Qty (L)',
                                    labelStyle: const TextStyle(fontSize: 11),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      item.quantity = double.tryParse(val.trim()) ?? 0.0;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FOOTER ACTIONS
  // ---------------------------------------------------------------------------
  Widget _buildFooterActions(bool isBulk) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 500;

    if (isCompact) {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: CustomButton(text: 'Cancel', variant: ButtonVariant.outlined, height: 42, onPressed: _isSubmitting ? null : () => Get.back()),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: isBulk ? 'Save Bulk ($_bulkFilledCowsCount)' : 'Save Entry',
              icon: isBulk ? Icons.cloud_upload_rounded : Icons.check_rounded,
              isLoading: _isSubmitting,
              height: 42,
              onPressed: isBulk ? _submitBulk : _submitSingle,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CustomButton(text: 'Cancel', variant: ButtonVariant.outlined, onPressed: _isSubmitting ? null : () => Get.back()),
        const SizedBox(width: 12),
        CustomButton(
          text: isBulk ? 'Save Bulk Entries ($_bulkFilledCowsCount)' : 'Save Production Entry',
          icon: isBulk ? Icons.cloud_upload_rounded : Icons.check_rounded,
          isLoading: _isSubmitting,
          onPressed: isBulk ? _submitBulk : _submitSingle,
        ),
      ],
    );
  }
}
