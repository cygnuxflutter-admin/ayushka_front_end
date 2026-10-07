import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_dropdown_search.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/mobile_edit_scaffold.dart';
import '../../../data/models/feed_item_model.dart';
import '../../../data/models/gaushala_model.dart';
import '../feed_item_controller.dart';

/// Full-screen mobile edit page for Feed Items.
class EditFeedItemScreen extends StatefulWidget {
  final FeedItemModel item;

  const EditFeedItemScreen({super.key, required this.item});

  @override
  State<EditFeedItemScreen> createState() => _EditFeedItemScreenState();
}

class _EditFeedItemScreenState extends State<EditFeedItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _minStockController;
  late final TextEditingController _descController;

  late final Rx<FeedItemCategory> _selectedCat;
  late final Rx<FeedItemUnit> _selectedUnit;
  late final RxBool _isActive;
  late final Rxn<GaushalaModel> _selectedGaushala;

  final FeedItemController controller = Get.find<FeedItemController>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.itemName);
    _codeController = TextEditingController(text: widget.item.itemCode);
    _minStockController = TextEditingController(
      text: widget.item.minStockAlert.toStringAsFixed(
        widget.item.minStockAlert.truncateToDouble() == widget.item.minStockAlert ? 0 : 2,
      ),
    );
    _descController = TextEditingController(text: widget.item.description);

    _selectedCat = widget.item.categoryEnum.obs;
    _selectedUnit = widget.item.unitEnum.obs;
    _isActive = widget.item.isActive.obs;

    final targetGaushalaId = widget.item.gaushalaId ?? controller.selectedGaushalaFilter.value;
    _selectedGaushala = Rxn<GaushalaModel>(controller.findGaushala(targetGaushalaId));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _minStockController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final double minStock = double.tryParse(_minStockController.text.trim()) ?? 50.0;

    final success = await controller.updateFeedItem(
      widget.item.id,
      itemName: _nameController.text.trim(),
      itemCode: _codeController.text.trim(),
      category: _selectedCat.value.code,
      unit: _selectedUnit.value.code,
      minStockAlert: minStock,
      description: _descController.text.trim(),
      isActive: _isActive.value,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      CustomSnackbar.showSuccess(
        title: 'Item Updated',
        message: 'Feed item "${_nameController.text.trim()}" updated successfully.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(
      () => MobileEditScaffold(
        title: 'Edit Feed Item',
        icon: PhosphorIconsRegular.pencilSimple,
        headerIconColor: AppColors.primary,
        subtitle: 'Update item specifications, category, unit, and alert thresholds.',
        formKey: _formKey,
        isSaving: controller.isSubmitting.value,
        saveText: 'Update Feed Item',
        onSave: _handleSave,
        children: [
          // Gaushala Selector
          Obx(() {
            return CustomDropdownSearch<GaushalaModel>(
              label: 'Assigned Gaushala',
              enabled: controller.isSuperAdmin,
              hint: 'All Gaushalas',
              prefixIcon: Icons.storefront_outlined,
              selectedItem: _selectedGaushala.value,
              items: controller.gaushalas.toList(),
              itemAsString: (g) => g.gaushalaName,
              compareFn: (g1, g2) => g1.id == g2.id,
              searchable: true,
              searchHint: 'Search gaushala...',
              onChanged: (sel) => _selectedGaushala.value = sel,
            );
          }),
          const SizedBox(height: 16),

          // Item Name
          CustomTextField(
            label: 'Item Name *',
            hint: 'e.g. Green Maize Fodder',
            controller: _nameController,
            prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Item name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Item Code
          CustomTextField(
            label: 'Item Code',
            hint: 'e.g. GF-001',
            controller: _codeController,
            isUpperCase: true,
            prefixIcon: const Icon(Icons.tag_rounded, size: 20),
          ),
          const SizedBox(height: 16),

          // Category Dropdown
          Obx(() {
            return CustomDropdownSearch<FeedItemCategory>(
              label: 'Category *',
              hint: 'Select Category',
              prefixIcon: Icons.category_outlined,
              selectedItem: _selectedCat.value,
              items: FeedItemCategory.values,
              itemAsString: (cat) => cat.label,
              compareFn: (c1, c2) => c1 == c2,
              onChanged: (cat) {
                if (cat != null) _selectedCat.value = cat;
              },
            );
          }),
          const SizedBox(height: 16),

          // Unit Dropdown
          Obx(() {
            return CustomDropdownSearch<FeedItemUnit>(
              label: 'Unit of Measure *',
              hint: 'Select Unit',
              prefixIcon: Icons.straighten_rounded,
              selectedItem: _selectedUnit.value,
              items: FeedItemUnit.values,
              itemAsString: (u) => '${u.label} (${u.code})',
              compareFn: (u1, u2) => u1 == u2,
              onChanged: (u) {
                if (u != null) _selectedUnit.value = u;
              },
            );
          }),
          const SizedBox(height: 16),

          // Min Stock Alert
          CustomTextField(
            label: 'Min Stock Alert *',
            hint: '50',
            controller: _minStockController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            prefixIcon: const Icon(Icons.notification_important_outlined, size: 20),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Threshold is required';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description
          CustomTextField(
            label: 'Description',
            hint: 'Optional notes or specifications...',
            controller: _descController,
            maxLines: 2,
            prefixIcon: const Icon(Icons.notes_rounded, size: 20),
          ),
          const SizedBox(height: 16),

          // Active Status
          Obx(
            () => SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Active Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              subtitle: Text(
                _isActive.value ? 'Item is active and available for feeding' : 'Item is inactive / archived',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
              value: _isActive.value,
              activeTrackColor: AppColors.primary,
              onChanged: (val) => _isActive.value = val,
            ),
          ),
        ],
      ),
    );
  }
}
