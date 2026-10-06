import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/utils/responsive_layout.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dropdown_search.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/medical_item_model.dart';
import '../medical_stock_controller.dart';
import '../views/edit_medicine_screen.dart';

/// Modal dialog for adding or editing a Medicine SKU in the Medicine Master.
/// Uses the Herd & Cattle form design system (AddCowScreen) with executive header,
/// section headers with dividers, responsive field grid, date field styling,
/// animated custom textfields, dropdowns, and buttons.
class AddEditMedicineDialog extends StatefulWidget {
  final MedicalItemModel? existingItem;

  const AddEditMedicineDialog({super.key, this.existingItem});

  static Future<void> show(BuildContext context, {MedicalItemModel? existingItem}) async {
    if (existingItem != null && ResponsiveLayout.isMobile(context)) {
      await Get.to(() => EditMedicineScreen(item: existingItem));
      return;
    }
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddEditMedicineDialog(existingItem: existingItem),
    );
  }

  @override
  State<AddEditMedicineDialog> createState() => _AddEditMedicineDialogState();
}

class _AddEditMedicineDialogState extends State<AddEditMedicineDialog> {
  final _formKey = GlobalKey<FormState>();
  final MedicalStockController controller = Get.find<MedicalStockController>();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _minStockController;
  late final TextEditingController _manufacturerController;
  late final TextEditingController _descriptionController;

  // Initial batch fields (for new item creation)
  bool _includeInitialBatch = false;
  late final TextEditingController _initialBatchNoController;
  late final TextEditingController _initialQtyController;
  late final TextEditingController _initialUnitPriceController;
  DateTime? _initialExpiryDate;
  DateTime? _initialMfgDate;

  late String _selectedCategory;
  late String _selectedUnit;

  bool get isEdit => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameController = TextEditingController(text: item?.itemName ?? '');
    _codeController = TextEditingController(text: item?.itemCode ?? '');
    _minStockController = TextEditingController(text: (item?.minStockAlert ?? 20.0).toStringAsFixed(0));
    _manufacturerController = TextEditingController(text: item?.manufacturer ?? '');
    _descriptionController = TextEditingController(text: item?.description ?? '');

    _selectedCategory = item?.category ?? MedicalItemCategory.tablet.code;
    _selectedUnit = item?.unit ?? MedicalItemUnit.piece.code;

    _initialBatchNoController = TextEditingController(
      text: 'B-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 1000}',
    );
    _initialQtyController = TextEditingController(text: '100');
    _initialUnitPriceController = TextEditingController(text: '50.0');
    _initialExpiryDate = DateTime.now().add(const Duration(days: 365));
    _initialMfgDate = DateTime.now().subtract(const Duration(days: 30));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _minStockController.dispose();
    _manufacturerController.dispose();
    _descriptionController.dispose();
    _initialBatchNoController.dispose();
    _initialQtyController.dispose();
    _initialUnitPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isExpiry}) async {
    final now = DateTime.now();
    final initial = isExpiry
        ? (_initialExpiryDate ?? now.add(const Duration(days: 365)))
        : (_initialMfgDate ?? now.subtract(const Duration(days: 30)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isExpiry ? now : DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimaryLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _initialExpiryDate = picked;
        } else {
          _initialMfgDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    final minStock = double.tryParse(_minStockController.text.trim()) ?? 20.0;
    final manufacturer = _manufacturerController.text.trim();
    final description = _descriptionController.text.trim();

    if (isEdit) {
      final success = await controller.updateMedicine(widget.existingItem!.id, {
        'itemName': name,
        'itemCode': code,
        'category': _selectedCategory,
        'unit': _selectedUnit,
        'minStockAlert': minStock,
        'manufacturer': manufacturer,
        'description': description,
      });
      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
        } else if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      }
    } else {
      List<MedicalInwardBatchDto>? initialBatches;
      if (_includeInitialBatch) {
        final bNo = _initialBatchNoController.text.trim();
        final qty = double.tryParse(_initialQtyController.text.trim()) ?? 0.0;
        final price = double.tryParse(_initialUnitPriceController.text.trim()) ?? 0.0;

        if (bNo.isEmpty || _initialExpiryDate == null || qty <= 0) {
          CustomSnackbar.showWarning(
            title: 'Batch Details Incomplete',
            message: 'Please provide valid batch number, positive quantity, and future expiry date.',
          );
          return;
        }

        initialBatches = [
          MedicalInwardBatchDto(
            batchNumber: bNo,
            expiryDate: _initialExpiryDate,
            mfgDate: _initialMfgDate,
            quantity: qty,
            unitPrice: price,
            mrp: price * 1.15,
          ),
        ];
      }

      final success = await controller.createMedicine(
        itemName: name,
        itemCode: code,
        category: _selectedCategory,
        unit: _selectedUnit,
        minStockAlert: minStock,
        manufacturer: manufacturer,
        description: description,
        initialBatches: initialBatches,
      );
      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
        } else if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSingleColumn = screenWidth < 680;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Dialog(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 600 ? 14 : 24,
        vertical: screenHeight < 700 ? 16 : 24,
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: screenHeight * 0.90,
        ),
        child: Column(
          children: [
            // -------------------------------------------------------------
            // EXECUTIVE HEADER BANNER (Herd & Cattle Style)
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
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isEdit ? PhosphorIconsRegular.pencilSimple : PhosphorIconsRegular.pill,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Medicine SKU' : 'New Medicine Master Registration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEdit
                              ? 'Update medicine specifications, category, unit, and alert threshold.'
                              : 'Register veterinary medicine, formulation, packaging, and initial stock.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).pop(),
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
            // FORM BODY (Herd & Cattle AddCowScreen Grid & Section Pattern)
            // -------------------------------------------------------------
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION 1: Basic Specifications
                      _buildSectionHeader(context, 'Basic Specifications', PhosphorIconsRegular.identificationCard),
                      const SizedBox(height: 16),
                      _buildFieldGrid(
                        isSingleColumn: isSingleColumn,
                        children: [
                          CustomTextField(
                            label: 'Medicine Name *',
                            hint: 'e.g. Oxytetracycline 20% LA',
                            controller: _nameController,
                            prefixIcon: const Icon(PhosphorIconsRegular.pill, size: 18),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Medicine name is required';
                              }
                              return null;
                            },
                          ),
                          CustomTextField(
                            label: 'Item Code / SKU',
                            hint: 'e.g. MED-OXY-100',
                            controller: _codeController,
                            isUpperCase: true,
                            prefixIcon: const Icon(PhosphorIconsRegular.barcode, size: 18),
                          ),
                          CustomTextField(
                            label: 'Manufacturer / Brand',
                            hint: 'e.g. Zydus, Virbac, Intas',
                            controller: _manufacturerController,
                            prefixIcon: const Icon(PhosphorIconsRegular.buildings, size: 18),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // SECTION 2: Formulation & Packaging
                      _buildSectionHeader(context, 'Formulation & Packaging', PhosphorIconsRegular.listDashes),
                      const SizedBox(height: 16),
                      _buildFieldGrid(
                        isSingleColumn: isSingleColumn,
                        children: [
                          CustomDropdownSearch<MedicalItemCategory>(
                            label: 'Formulation / Category *',
                            isRequired: true,
                            prefixIcon: PhosphorIconsRegular.tag,
                            hint: 'Select formulation',
                            selectedItem: MedicalItemCategory.fromCode(_selectedCategory),
                            items: MedicalItemCategory.values,
                            itemAsString: (cat) => cat.label,
                            showClearButton: false,
                            onChanged: (cat) {
                              if (cat != null) setState(() => _selectedCategory = cat.code);
                            },
                            customItemBuilder: (ctx, item, isDisabled, isSelected) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                child: Row(
                                  children: [
                                    Icon(item.icon, size: 16, color: item.color),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                                  ],
                                ),
                              );
                            },
                          ),
                          CustomDropdownSearch<MedicalItemUnit>(
                            label: 'Packaging Unit *',
                            isRequired: true,
                            prefixIcon: PhosphorIconsRegular.scales,
                            hint: 'Select measurement unit',
                            selectedItem: MedicalItemUnit.fromCode(_selectedUnit),
                            items: MedicalItemUnit.values,
                            itemAsString: (u) => '${u.label} (${u.shortLabel})',
                            showClearButton: false,
                            onChanged: (u) {
                              if (u != null) setState(() => _selectedUnit = u.code);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // SECTION 3: Inventory Controls & Indications
                      _buildSectionHeader(context, 'Inventory Controls & Clinical Notes', PhosphorIconsRegular.slidersHorizontal),
                      const SizedBox(height: 16),
                      _buildFieldGrid(
                        isSingleColumn: isSingleColumn,
                        children: [
                          CustomTextField(
                            label: 'Min Stock Reorder Alert *',
                            hint: 'e.g. 25',
                            controller: _minStockController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            prefixIcon: const Icon(PhosphorIconsRegular.warningCircle, size: 18),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Alert threshold is required';
                              if (double.tryParse(val.trim()) == null) return 'Enter a valid number';
                              return null;
                            },
                          ),
                          CustomTextField(
                            label: 'Clinical Notes / Indications',
                            hint: 'Usage indications, recommended dosage, storage temperature...',
                            controller: _descriptionController,
                            maxLines: 1,
                            prefixIcon: const Icon(PhosphorIconsRegular.notepad, size: 18),
                          ),
                        ],
                      ),

                      // SECTION 4: Initial Batch Record (New creation only)
                      if (!isEdit) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader(context, 'Initial Inward Batch Record', PhosphorIconsRegular.stack),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _includeInitialBatch
                                ? (isDark ? AppColors.surfaceDark : const Color(0xFFF9FDF7))
                                : (isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : const Color(0xFFFAFAFA)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _includeInitialBatch
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _includeInitialBatch,
                                    activeColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) => setState(() => _includeInitialBatch = val ?? false),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Record Initial Inward Batch Now (Optional)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Enter initial stock quantity and expiry right now, or add later via Stock Inward.',
                                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_includeInitialBatch) ...[
                                const Divider(height: 24),
                                _buildFieldGrid(
                                  isSingleColumn: isSingleColumn,
                                  children: [
                                    CustomTextField(
                                      label: 'Batch No *',
                                      controller: _initialBatchNoController,
                                      isUpperCase: true,
                                      prefixIcon: const Icon(PhosphorIconsRegular.tag, size: 18),
                                    ),
                                    _buildDateField(
                                      context,
                                      label: 'Expiry Date *',
                                      displayValue: () => _initialExpiryDate != null ? dateFormat.format(_initialExpiryDate!) : '',
                                      hint: 'Select Expiry Date',
                                      icon: PhosphorIconsRegular.calendarBlank,
                                      isRequired: true,
                                      onTap: () => _pickDate(isExpiry: true),
                                      onClear: () => setState(() => _initialExpiryDate = null),
                                    ),
                                    CustomTextField(
                                      label: 'Quantity *',
                                      controller: _initialQtyController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                      prefixIcon: const Icon(PhosphorIconsRegular.scales, size: 18),
                                    ),
                                    CustomTextField(
                                      label: 'Unit Purchase Rate (₹)',
                                      controller: _initialUnitPriceController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                      prefixIcon: const Icon(PhosphorIconsRegular.currencyInr, size: 18),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // -------------------------------------------------------------
            // FOOTER ACTION BUTTONS (Herd & Cattle Style)
            // -------------------------------------------------------------
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSingleColumn ? 16 : 24,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.6) : AppColors.backgroundLight,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: isSingleColumn ? MainAxisAlignment.center : MainAxisAlignment.end,
                children: [
                  if (isSingleColumn) ...[
                    Expanded(
                      flex: 1,
                      child: CustomButton(
                        text: 'Cancel',
                        variant: ButtonVariant.outlined,
                        height: 44,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Obx(
                        () => CustomButton(
                          text: isEdit ? 'Save Changes' : 'Create Medicine',
                          variant: ButtonVariant.primary,
                          icon: isEdit ? PhosphorIconsRegular.check : PhosphorIconsRegular.plus,
                          isLoading: controller.isSubmitting.value,
                          height: 44,
                          onPressed: controller.isSubmitting.value ? null : _submit,
                        ),
                      ),
                    ),
                  ] else ...[
                    CustomButton(
                      text: 'Cancel',
                      variant: ButtonVariant.outlined,
                      width: 120,
                      height: 44,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 14),
                    Obx(
                      () => CustomButton(
                        text: isEdit ? 'Save Changes' : 'Create Medicine',
                        variant: ButtonVariant.primary,
                        icon: isEdit ? PhosphorIconsRegular.check : PhosphorIconsRegular.plus,
                        isLoading: controller.isSubmitting.value,
                        width: 170,
                        height: 44,
                        onPressed: controller.isSubmitting.value ? null : _submit,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // HERD & CATTLE REUSABLE SECTION HEADER
  // -------------------------------------------------------------------
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // HERD & CATTLE RESPONSIVE FIELD GRID (2-column on desktop, 1 on mobile)
  // -------------------------------------------------------------------
  Widget _buildFieldGrid({
    required bool isSingleColumn,
    required List<Widget> children,
  }) {
    if (isSingleColumn) {
      return Column(
        children: children.map((child) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: child,
          );
        }).toList(),
      );
    }

    final List<Widget> rows = [];
    for (int i = 0; i < children.length; i += 2) {
      final Widget left = children[i];
      final Widget? right = (i + 1 < children.length) ? children[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 20),
              Expanded(child: right ?? const SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  // -------------------------------------------------------------------
  // HERD & CATTLE DATE FIELD (Matching AddCowScreen date field design)
  // -------------------------------------------------------------------
  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required String Function() displayValue,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onClear,
    bool isRequired = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FormField<String>(
      validator: isRequired
          ? (_) {
              if (displayValue().isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
      builder: (fieldState) {
        final hasError = fieldState.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRequired && !label.endsWith('*') ? '$label *' : label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 6),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  onTap();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    fieldState.didChange(displayValue());
                  });
                },
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    border: Border.all(
                      color: hasError
                          ? (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626))
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: hasError ? 1.2 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          displayValue().isNotEmpty ? displayValue() : hint,
                          style: TextStyle(
                            fontSize: 14,
                            color: displayValue().isNotEmpty
                                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                          ),
                        ),
                      ),
                      if (displayValue().isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            onClear();
                            fieldState.didChange('');
                          },
                          child: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMutedLight),
                        )
                      else
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textMutedLight),
                    ],
                  ),
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: Text(
                  fieldState.errorText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
