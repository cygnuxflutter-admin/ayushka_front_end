import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_dropdown_search.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/mobile_edit_scaffold.dart';
import '../../../data/models/gaushala_model.dart';
import '../../../data/models/shed_model.dart';
import '../shed_controller.dart';

/// Full-screen mobile edit page for Sheds.
class EditShedScreen extends StatefulWidget {
  final ShedModel shed;

  const EditShedScreen({super.key, required this.shed});

  @override
  State<EditShedScreen> createState() => _EditShedScreenState();
}

class _EditShedScreenState extends State<EditShedScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _numberController;
  final ShedController controller = Get.find<ShedController>();
  late final Rxn<GaushalaModel> _selectedGaushala;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shed.shedName);
    _numberController = TextEditingController(text: widget.shed.shedNumber);

    if (controller.gaushalas.isEmpty) {
      controller.fetchGaushalas();
    }

    GaushalaModel? currentGaushala;
    if (widget.shed.gaushalaId != null && widget.shed.gaushalaId!.isNotEmpty) {
      currentGaushala = controller.gaushalas.firstWhereOrNull((g) => g.id == widget.shed.gaushalaId);
    }
    if (currentGaushala == null && widget.shed.gaushalaName != null && widget.shed.gaushalaName!.isNotEmpty) {
      currentGaushala = controller.gaushalas.firstWhereOrNull(
        (g) => g.gaushalaName.toLowerCase() == widget.shed.gaushalaName!.toLowerCase(),
      );
    }
    _selectedGaushala = Rxn<GaushalaModel>(currentGaushala);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedGaushala.value == null) {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please select a Gaushala for this shed.',
      );
      return;
    }

    final success = await controller.updateShed(
      widget.shed.id,
      shedName: _nameController.text,
      shedNumber: _numberController.text,
      gaushalaId: _selectedGaushala.value!.id,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => MobileEditScaffold(
        title: 'Edit Shed',
        icon: Icons.edit_rounded,
        headerIconColor: AppColors.info,
        subtitle: 'Update details for "${widget.shed.shedName}"',
        formKey: _formKey,
        isSaving: controller.isSubmitting.value,
        saveText: 'Save Changes',
        onSave: _handleSave,
        children: [
          // Gaushala Selector
          Obx(() {
            return CustomDropdownSearch<GaushalaModel>(
              label: 'Assigned Gaushala',
              isRequired: true,
              hint: 'Select Gaushala',
              prefixIcon: Icons.storefront_outlined,
              selectedItem: _selectedGaushala.value,
              items: controller.gaushalas.toList(),
              itemAsString: (g) => g.gaushalaName,
              compareFn: (g1, g2) => g1.id == g2.id,
              searchable: true,
              searchHint: 'Search gaushala...',
              onChanged: (sel) => _selectedGaushala.value = sel,
              validator: (sel) => sel == null ? 'Gaushala is required' : null,
            );
          }),
          const SizedBox(height: 16),

          // Shed Name
          CustomTextField(
            controller: _nameController,
            label: 'Shed Name *',
            hint: 'e.g. North Shed, Milking Barn A',
            prefixIcon: const Icon(Icons.warehouse_outlined, size: 20),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Shed name is required';
              }
              if (val.trim().length < 2) {
                return 'Shed name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Shed Number / Code
          CustomTextField(
            controller: _numberController,
            label: 'Shed Number / Code *',
            hint: 'e.g. SHED-001, SH-A1',
            isUpperCase: true,
            prefixIcon: const Icon(Icons.tag_rounded, size: 20),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Shed number is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
