import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_dropdown_search.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/mobile_edit_scaffold.dart';
import '../../../data/models/medical_item_model.dart';
import '../medical_stock_controller.dart';

/// Full-screen mobile edit page for Medicine Master records.
class EditMedicineScreen extends StatefulWidget {
  final MedicalItemModel item;

  const EditMedicineScreen({super.key, required this.item});

  @override
  State<EditMedicineScreen> createState() => _EditMedicineScreenState();
}

class _EditMedicineScreenState extends State<EditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _minStockController;
  late final TextEditingController _manufacturerController;
  late final TextEditingController _descriptionController;

  late String _selectedCategory;
  late String _selectedUnit;

  final MedicalStockController controller = Get.find<MedicalStockController>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.itemName);
    _codeController = TextEditingController(text: widget.item.itemCode);
    _minStockController = TextEditingController(
      text: widget.item.minStockAlert.toStringAsFixed(0),
    );
    _manufacturerController = TextEditingController(text: widget.item.manufacturer);
    _descriptionController = TextEditingController(text: widget.item.description);

    _selectedCategory = widget.item.category.isNotEmpty
        ? widget.item.category
        : MedicalItemCategory.tablet.code;
    _selectedUnit = widget.item.unit.isNotEmpty
        ? widget.item.unit
        : MedicalItemUnit.piece.code;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _minStockController.dispose();
    _manufacturerController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    final minStock = double.tryParse(_minStockController.text.trim()) ?? 20.0;
    final manufacturer = _manufacturerController.text.trim();
    final description = _descriptionController.text.trim();

    final success = await controller.updateMedicine(widget.item.id, {
      'itemName': name,
      'itemCode': code,
      'category': _selectedCategory,
      'unit': _selectedUnit,
      'minStockAlert': minStock,
      'manufacturer': manufacturer,
      'description': description,
    });

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => MobileEditScaffold(
        title: 'Edit Medicine',
        icon: PhosphorIconsRegular.pill,
        headerIconColor: AppColors.primary,
        subtitle: 'Update medicine details, SKU code, category, and minimum threshold.',
        formKey: _formKey,
        isSaving: controller.isLoading.value,
        saveText: 'Save Changes',
        onSave: _handleSave,
        children: [
          // Medicine Name
          CustomTextField(
            controller: _nameController,
            label: 'Medicine Name *',
            hint: 'e.g. Oxytetracycline 200mg',
            prefixIcon: const Icon(PhosphorIconsRegular.pill, size: 20),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Medicine name is required';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Medicine SKU Code
          CustomTextField(
            controller: _codeController,
            label: 'Item / SKU Code *',
            hint: 'e.g. MED-OXY-01',
            isUpperCase: true,
            prefixIcon: const Icon(Icons.tag_rounded, size: 20),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Code is required';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Category Dropdown
          CustomDropdownSearch<MedicalItemCategory>(
            label: 'Dosage Form / Category *',
            hint: 'Select Category',
            prefixIcon: Icons.category_outlined,
            selectedItem: MedicalItemCategory.fromCode(_selectedCategory),
            items: MedicalItemCategory.values,
            itemAsString: (cat) => cat.label,
            compareFn: (c1, c2) => c1 == c2,
            onChanged: (cat) {
              if (cat != null) setState(() => _selectedCategory = cat.code);
            },
          ),
          const SizedBox(height: 16),

          // Unit Dropdown
          CustomDropdownSearch<MedicalItemUnit>(
            label: 'Unit of Measure *',
            hint: 'Select Unit',
            prefixIcon: Icons.straighten_rounded,
            selectedItem: MedicalItemUnit.fromCode(_selectedUnit),
            items: MedicalItemUnit.values,
            itemAsString: (u) => '${u.label} (${u.code})',
            compareFn: (u1, u2) => u1 == u2,
            onChanged: (u) {
              if (u != null) setState(() => _selectedUnit = u.code);
            },
          ),
          const SizedBox(height: 16),

          // Manufacturer
          CustomTextField(
            controller: _manufacturerController,
            label: 'Manufacturer / Brand',
            hint: 'e.g. Zydus Animal Health',
            prefixIcon: const Icon(Icons.business_outlined, size: 20),
          ),
          const SizedBox(height: 16),

          // Min Stock Threshold
          CustomTextField(
            controller: _minStockController,
            label: 'Min Stock Threshold *',
            hint: 'e.g. 20',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            prefixIcon: const Icon(Icons.notification_important_outlined, size: 20),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Threshold is required';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description
          CustomTextField(
            controller: _descriptionController,
            label: 'Description / Usage',
            hint: 'Antibiotic for bacterial infections...',
            maxLines: 2,
            prefixIcon: const Icon(Icons.notes_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
