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
import '../../../../app/data/models/worker_model.dart';
import '../../controllers/milk_controller.dart';
import '../../models/milk_distribution_model.dart';

/// Enhanced modal dialog for recording Milk Distribution (Milk Out)
/// Enforces real-time stock limits, dynamic limit indicators, quick-fill chips,
/// and prevents over-distribution.
class AddDistributionDialog extends StatefulWidget {
  final DateTime? initialMilkDate;
  final String? initialShift;

  const AddDistributionDialog({
    super.key,
    this.initialMilkDate,
    this.initialShift,
  });

  static Future<void> show(
    BuildContext context, {
    DateTime? milkDate,
    String? shift,
  }) async {
    if (Get.isRegistered<MilkController>()) {
      final controller = Get.find<MilkController>();
      if (!controller.canAddDistribution) {
        CustomSnackbar.showError(
          title: 'Access Denied',
          message: 'You do not have permission to add milk distribution.',
        );
        return;
      }
    }
    await Get.dialog(
      AddDistributionDialog(
        initialMilkDate: milkDate,
        initialShift: shift,
      ),
      barrierDismissible: false,
    );
  }

  @override
  State<AddDistributionDialog> createState() => _AddDistributionDialogState();
}

class _AddDistributionDialogState extends State<AddDistributionDialog> {
  final MilkController _controller = Get.find<MilkController>();
  final _formKey = GlobalKey<FormState>();

  late DateTime _milkDate;
  String _shift = 'morning';

  RecipientType _recipientType = RecipientType.customer;
  WorkerModel? _selectedWorker;
  final TextEditingController _recipientNameCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _rateCtrl = TextEditingController(text: '60.0');
  final TextEditingController _remarksCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _milkDate = widget.initialMilkDate ?? _controller.selectedDate.value;
    final s = widget.initialShift ?? 'morning';
    _shift = (s == 'all' || s.isEmpty) ? 'morning' : s;

    // Refresh daily summary for the selected date if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dateStr = DateFormat('yyyy-MM-dd').format(_milkDate);
      if (_controller.dailySummary.value == null ||
          _controller.dailySummary.value!.date != dateStr) {
        _controller.fetchDailySummary(date: dateStr);
      }
    });
  }

  @override
  void dispose() {
    _recipientNameCtrl.dispose();
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  bool get _isToday {
    final now = DateTime.now();
    return _milkDate.year == now.year &&
        _milkDate.month == now.month &&
        _milkDate.day == now.day;
  }

  double get _morningStock =>
      _controller.dailySummary.value?.stockBalance.morningAvailable ?? 0.0;
  double get _eveningStock =>
      _controller.dailySummary.value?.stockBalance.eveningAvailable ?? 0.0;
  double get _fridgeStock =>
      _controller.dailySummary.value?.stockBalance.remainingFridgeMilk ?? 0.0;

  double get _availableStock {
    final summary = _controller.dailySummary.value;
    if (summary == null) return 0.0;

    if (_isToday) {
      if (_shift == 'morning') {
        return summary.stockBalance.morningAvailable;
      } else {
        return summary.stockBalance.eveningAvailable;
      }
    } else {
      // Past date: distributing from Fridge Milk Pool
      return summary.stockBalance.remainingFridgeMilk;
    }
  }

  double get _enteredQty => double.tryParse(_qtyCtrl.text.trim()) ?? 0.0;
  double get _rate => double.tryParse(_rateCtrl.text.trim()) ?? 0.0;
  double get _calculatedTotal => _enteredQty * _rate;

  double get _remainingStock => _availableStock - _enteredQty;
  bool get _isOutOfStock => _availableStock <= 0.0001;
  bool get _isExceeded => _enteredQty > _availableStock;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = _enteredQty;
    final rate = _rate;
    final available = _availableStock;

    // Strict validation against available stock limit
    if (available <= 0) {
      CustomSnackbar.showError(
        title: 'Out of Stock',
        message: _isToday
            ? 'Cannot distribute milk. No stock available in $_shift shift.'
            : 'Cannot distribute milk. No fridge leftover stock available.',
      );
      return;
    }

    if (qty > available) {
      CustomSnackbar.showError(
        title: 'Stock Limit Exceeded',
        message: _isToday
            ? 'Cannot distribute $qty L. Maximum available is ${available.toStringAsFixed(1)} L in $_shift shift.'
            : 'Cannot distribute $qty L. Maximum available is ${available.toStringAsFixed(1)} L in fridge pool.',
      );
      return;
    }

    if (qty <= 0) {
      CustomSnackbar.showError(
        title: 'Invalid Quantity',
        message: 'Distribution quantity must be greater than 0 Liters.',
      );
      return;
    }

    final String recipientName = _recipientType == RecipientType.staff && _selectedWorker != null
        ? _selectedWorker!.name
        : _recipientNameCtrl.text.trim();

    if (recipientName.isEmpty) {
      CustomSnackbar.showError(
        title: 'Missing Recipient',
        message: 'Please enter or select recipient name.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await _controller.submitDistribution(
      milkDate: DateFormat('yyyy-MM-dd').format(_milkDate),
      shift: _shift,
      quantity: qty,
      recipientType: _recipientType.value,
      recipientName: recipientName,
      customerId: _selectedWorker?.id,
      ratePerLiter: rate,
      remarks: _remarksCtrl.text.trim(),
    );
    setState(() => _isSubmitting = false);

    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -------------------------------------------------------------
              // HEADER
              // -------------------------------------------------------------
              _buildHeader(isDark),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // FORM BODY (REACTIVE)
              // -------------------------------------------------------------
              Expanded(
                child: Obx(() {
                  final availableStock = _availableStock;

                  return SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Milk Date Picker Row
                          _buildDatePickerRow(isDark),
                          const SizedBox(height: 14),

                          // Shift Selection (for same day) or Delayed banner (for past day)
                          if (_isToday) ...[
                            _buildShiftSelector(isDark),
                            const SizedBox(height: 12),
                          ] else ...[
                            _buildDelayedPoolBanner(),
                            const SizedBox(height: 12),
                          ],

                          // -------------------------------------------------
                          // STOCK LIMIT & MONITOR CARD
                          // -------------------------------------------------
                          _buildStockLimitCard(isDark, availableStock),
                          const SizedBox(height: 16),

                          // Recipient Type Selector
                          CustomDropdownSearch<RecipientType>(
                            label: 'Recipient Type',
                            isRequired: true,
                            items: RecipientType.values,
                            selectedItem: _recipientType,
                            itemAsString: (r) => r.label,
                            onChanged: (r) {
                              if (r != null) {
                                setState(() {
                                  _recipientType = r;
                                  if (r == RecipientType.calfFeeding) {
                                    _rateCtrl.text = '0.0';
                                    if (_recipientNameCtrl.text.trim().isEmpty) {
                                      _recipientNameCtrl.text = 'Gaushala Calves';
                                    }
                                  } else if (r == RecipientType.staff) {
                                    if (_selectedWorker != null) {
                                      _recipientNameCtrl.text = _selectedWorker!.name;
                                    }
                                    if (_rateCtrl.text == '0.0') {
                                      _rateCtrl.text = '60.0';
                                    }
                                  } else {
                                    if (_rateCtrl.text == '0.0') {
                                      _rateCtrl.text = '60.0';
                                    }
                                    if (_recipientNameCtrl.text == 'Gaushala Calves') {
                                      _recipientNameCtrl.clear();
                                    }
                                  }
                                });
                              }
                            },
                            prefixIcon: Icons.category_rounded,
                          ),
                          const SizedBox(height: 14),

                          // Recipient / Customer Name or Staff Selector
                          if (_recipientType == RecipientType.staff &&
                              _controller.activeWorkers.isNotEmpty) ...[
                            CustomDropdownSearch<WorkerModel>(
                              label: 'Staff Member / Worker *',
                              isRequired: true,
                              hint: 'Select staff member...',
                              items: _controller.activeWorkers,
                              selectedItem: _selectedWorker,
                              itemAsString: (w) =>
                                  '${w.name}${w.departmentName != null && w.departmentName!.isNotEmpty ? ' (${w.departmentName})' : ''}',
                              onChanged: (w) {
                                setState(() {
                                  _selectedWorker = w;
                                  if (w != null) {
                                    _recipientNameCtrl.text = w.name;
                                  }
                                });
                              },
                              prefixIcon: Icons.badge_rounded,
                              validator: (w) {
                                if (w == null && _recipientNameCtrl.text.trim().isEmpty) {
                                  return 'Please select a staff member';
                                }
                                return null;
                              },
                            ),
                          ] else ...[
                            CustomTextField(
                              label: _recipientType == RecipientType.customer
                                  ? 'Recipient / Customer Name *'
                                  : (_recipientType == RecipientType.dairyPlant
                                      ? 'Dairy Plant / Center Name *'
                                      : 'Recipient Name *'),
                              hint: _recipientType == RecipientType.dairyPlant
                                  ? 'e.g. Amul Dairy Chilling Center, Sumul, etc.'
                                  : 'e.g. Ramesh Patel, Shanti Ben, etc.',
                              controller: _recipientNameCtrl,
                              prefixIcon: Icon(_recipientType.icon, size: 18),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter recipient name';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 14),

                          // -------------------------------------------------
                          // QUANTITY & RATE ROW (WITH LIMIT & MAX ACTION)
                          // -------------------------------------------------
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quantity Field with Limit Protection
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomTextField(
                                      label: 'Quantity (Liters) *',
                                      hint: 'e.g. 25.0',
                                      controller: _qtyCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                      prefixIcon: const Icon(PhosphorIconsRegular.drop, size: 18),
                                      suffixIcon: availableStock > 0
                                          ? Padding(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              child: UnconstrainedBox(
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(6),
                                                  onTap: () {
                                                    _qtyCtrl.text = availableStock.toStringAsFixed(1);
                                                    setState(() {});
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(
                                                        color: AppColors.primary.withValues(alpha: 0.3),
                                                      ),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.bolt_rounded, size: 13, color: AppColors.primary),
                                                        SizedBox(width: 2),
                                                        Text(
                                                          'MAX',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppColors.primary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : null,
                                      onChanged: (_) => setState(() {}),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) return 'Enter quantity';
                                        final n = double.tryParse(val.trim());
                                        if (n == null || n <= 0) return 'Enter valid quantity (> 0)';
                                        if (availableStock <= 0) return 'No milk available in this shift';
                                        if (n > availableStock) {
                                          return 'Limit exceeded! Max available is ${availableStock.toStringAsFixed(1)} L';
                                        }
                                        return null;
                                      },
                                    ),
                                    _buildQuickQtyChips(availableStock),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Rate Field with Presets
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomTextField(
                                      label: 'Rate / Liter (₹) *',
                                      hint: 'e.g. 60.0',
                                      controller: _rateCtrl,
                                      readOnly: _recipientType == RecipientType.calfFeeding,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                      prefixIcon: const Icon(PhosphorIconsRegular.currencyInr, size: 18),
                                      onChanged: (_) => setState(() {}),
                                      validator: (val) {
                                        if (_recipientType == RecipientType.calfFeeding) return null;
                                        if (val == null || val.trim().isEmpty) return 'Enter rate';
                                        final n = double.tryParse(val.trim());
                                        if (n == null || n < 0) return 'Enter valid rate';
                                        return null;
                                      },
                                    ),
                                    _buildQuickRateChips(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // -------------------------------------------------
                          // ESTIMATED TOTAL REVENUE CARD
                          // -------------------------------------------------
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF22351B) : const Color(0xFFF1F5EE),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334B28) : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(PhosphorIconsRegular.receipt, size: 20, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Estimated Total Amount',
                                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                                      ),
                                      if (_enteredQty > 0 && _rate > 0)
                                        Text(
                                          '${_enteredQty.toStringAsFixed(1)} L × ₹ ${_rate.toStringAsFixed(1)}/L',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹ ${_calculatedTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Remarks
                          CustomTextField(
                            label: 'Remarks (Optional)',
                            hint: 'Delivery notes, bill reference, invoice no...',
                            controller: _remarksCtrl,
                            maxLines: 2,
                            prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // FOOTER ACTIONS
              // -------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    text: 'Cancel',
                    variant: ButtonVariant.outlined,
                    onPressed: _isSubmitting ? null : () => Get.back(),
                  ),
                  const SizedBox(width: 12),
                  Obx(() {
                    final isExceeded = _isExceeded;
                    final isOutOfStock = _isOutOfStock;
                    final isBlocked = isExceeded || isOutOfStock;

                    return CustomButton(
                      text: isExceeded
                          ? 'Limit Exceeded'
                          : (isOutOfStock ? 'Out of Stock' : 'Record Distribution'),
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _isSubmitting,
                      onPressed: isBlocked || _isSubmitting ? null : _submit,
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE98324).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                PhosphorIconsRegular.truck,
                color: Color(0xFFE98324),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record Milk Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gaushala: ${_controller.selectedGaushalaName}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // DATE PICKER ROW
  // ---------------------------------------------------------------------------
  Widget _buildDatePickerRow(bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _milkDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            _milkDate = picked;
          });
          final dateStr = DateFormat('yyyy-MM-dd').format(picked);
          _controller.fetchDailySummary(date: dateStr);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(PhosphorIconsRegular.calendar, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Milk Date',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(_milkDate),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            if (_isToday)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHIFT SELECTOR (SAME DAY)
  // ---------------------------------------------------------------------------
  Widget _buildShiftSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shift (Required for Today\'s Milk)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildShiftButton(
                shiftKey: 'morning',
                label: 'Morning Shift',
                stock: _morningStock,
                icon: Icons.wb_sunny_rounded,
                accentColor: const Color(0xFFE98324),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildShiftButton(
                shiftKey: 'evening',
                label: 'Evening Shift',
                stock: _eveningStock,
                icon: Icons.nights_stay_rounded,
                accentColor: AppColors.primary,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShiftButton({
    required String shiftKey,
    required String label,
    required double stock,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
  }) {
    final bool isSelected = _shift == shiftKey;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _shift = shiftKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.14)
              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 1.8 : 1.0,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? accentColor : Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? accentColor : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stock > 0 ? '${stock.toStringAsFixed(1)} L avail.' : '0.0 L (No Stock)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: stock > 0
                          ? (isSelected ? accentColor : Colors.grey.shade600)
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: 16, color: accentColor),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DELAYED POOL BANNER (PAST DATES)
  // ---------------------------------------------------------------------------
  Widget _buildDelayedPoolBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF3E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE98324).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE98324),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Delayed Entry',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Distributing from Fridge Milk Pool',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9A4C00),
                  ),
                ),
                Text(
                  'Available Pool Stock: ${_fridgeStock.toStringAsFixed(1)} Liters',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE98324),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STOCK LIMIT MONITOR CARD (LIVE USAGE & EXCEEDED ALERT)
  // ---------------------------------------------------------------------------
  Widget _buildStockLimitCard(bool isDark, double availableStock) {
    final entered = _enteredQty;
    final remaining = _remainingStock;
    final isExceeded = _isExceeded;
    final isOut = _isOutOfStock;
    final percent = availableStock > 0 ? (entered / availableStock).clamp(0.0, 1.0) : 0.0;

    final cardBg = isOut || isExceeded
        ? (isDark ? const Color(0xFF331A1A) : const Color(0xFFFEF2F2))
        : (isDark ? const Color(0xFF1E2818) : const Color(0xFFF4F7F1));

    final cardBorder = isOut || isExceeded
        ? AppColors.error.withValues(alpha: 0.6)
        : AppColors.primary.withValues(alpha: 0.25);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: isExceeded ? 1.5 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with Status Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isOut || isExceeded
                      ? AppColors.error.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isOut || isExceeded ? Icons.warning_amber_rounded : PhosphorIconsRegular.shieldCheck,
                  size: 16,
                  color: isOut || isExceeded ? AppColors.error : AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isToday
                          ? '${_shift.capitalizeFirst} Shift Stock Limit'
                          : 'Fridge Leftover Pool Limit',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isOut || isExceeded
                            ? AppColors.error
                            : (isDark ? Colors.white : AppColors.textPrimaryLight),
                      ),
                    ),
                    Text(
                      isOut
                          ? 'Zero milk stock available in this shift'
                          : (isExceeded
                              ? 'Entered quantity exceeds shift stock limit!'
                              : 'Limit: ${availableStock.toStringAsFixed(1)} L max distribution'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isOut || isExceeded
                            ? AppColors.error
                            : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOut
                      ? AppColors.error
                      : (isExceeded
                          ? AppColors.error
                          : (entered >= availableStock && availableStock > 0
                              ? const Color(0xFFE98324)
                              : (entered > 0 ? AppColors.primary : Colors.grey.shade600))),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isOut
                      ? 'OUT OF STOCK'
                      : (isExceeded
                          ? 'LIMIT EXCEEDED'
                          : (entered >= availableStock && availableStock > 0
                              ? '100% USED'
                              : (entered > 0
                                  ? '${(percent * 100).toStringAsFixed(0)}% ALLOCATED'
                                  : 'READY'))),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3 Metric Stat Columns: Limit | Out (Entered) | Remaining Balance
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStockStatItem(
                    label: 'Available Limit',
                    value: '${availableStock.toStringAsFixed(1)} L',
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Container(width: 1, height: 26, color: Colors.grey.withValues(alpha: 0.2)),
                Expanded(
                  child: _buildStockStatItem(
                    label: 'Out Quantity',
                    value: '${entered.toStringAsFixed(1)} L',
                    color: isExceeded ? AppColors.error : AppColors.primary,
                  ),
                ),
                Container(width: 1, height: 26, color: Colors.grey.withValues(alpha: 0.2)),
                Expanded(
                  child: _buildStockStatItem(
                    label: 'Remaining Stock',
                    value: isExceeded
                        ? '-${(entered - availableStock).toStringAsFixed(1)} L'
                        : '${remaining.clamp(0.0, double.infinity).toStringAsFixed(1)} L',
                    color: isExceeded
                        ? AppColors.error
                        : (remaining <= 0 && entered > 0
                            ? const Color(0xFFE98324)
                            : const Color(0xFF16A34A)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                isExceeded
                    ? AppColors.error
                    : (entered >= availableStock && availableStock > 0
                        ? const Color(0xFFE98324)
                        : AppColors.primary),
              ),
            ),
          ),

          // Warning messages
          if (isExceeded) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Entered quantity exceeds shift limit by ${(entered - availableStock).toStringAsFixed(1)} L! You cannot distribute more than available stock.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isOut) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'No milk available for ${_isToday ? '$_shift shift' : 'fridge pool'}. Record milk production first before recording distribution.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStockStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // QUICK QUANTITY CHIPS (25%, 50%, 75%, MAX)
  // ---------------------------------------------------------------------------
  Widget _buildQuickQtyChips(double availableStock) {
    if (availableStock <= 0) return const SizedBox.shrink();

    final presets = <Map<String, dynamic>>[
      {'label': '25%', 'fraction': 0.25},
      {'label': '50%', 'fraction': 0.50},
      {'label': '75%', 'fraction': 0.75},
      {'label': 'MAX', 'fraction': 1.0},
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Text(
            'Quick Limit:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: presets.map((p) {
                  final double fraction = p['fraction'] as double;
                  final double qty = double.parse((availableStock * fraction).toStringAsFixed(1));
                  final String qtyStr = qty.toStringAsFixed(1);
                  final bool isSelected = _qtyCtrl.text.trim() == qtyStr;

                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        _qtyCtrl.text = qtyStr;
                        setState(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          '${p['label']} (${qtyStr}L)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // QUICK RATE CHIPS (₹50, ₹55, ₹60, ₹65, ₹70)
  // ---------------------------------------------------------------------------
  Widget _buildQuickRateChips() {
    if (_recipientType == RecipientType.calfFeeding) return const SizedBox.shrink();

    final rates = [50.0, 55.0, 60.0, 65.0, 70.0];

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Text(
            'Rates:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: rates.map((r) {
                  final str = r.toStringAsFixed(1);
                  final isSelected = _rateCtrl.text.trim() == str ||
                      _rateCtrl.text.trim() == r.toStringAsFixed(0);

                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        _rateCtrl.text = str;
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF384C28)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF384C28) : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          '₹${r.toInt()}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
