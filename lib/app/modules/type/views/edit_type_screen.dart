import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_dropdown_search.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/mobile_edit_scaffold.dart';
import '../../../data/models/gaushala_model.dart';
import '../../../data/models/type_model.dart';
import '../../../data/services/gaushala_session_service.dart';
import '../type_controller.dart';

/// Full-screen mobile edit page for Cattle Types.
class EditTypeScreen extends StatefulWidget {
  final TypeModel type;

  const EditTypeScreen({super.key, required this.type});

  @override
  State<EditTypeScreen> createState() => _EditTypeScreenState();
}

class _EditTypeScreenState extends State<EditTypeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final TypeController controller = Get.find<TypeController>();
  late final Rxn<GaushalaModel> _selectedGaushala;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.type.typeName);

    if (controller.gaushalas.isEmpty) {
      controller.fetchGaushalas();
    }

    GaushalaModel? initialGaushala;
    if (widget.type.gaushalaId != null && widget.type.gaushalaId!.isNotEmpty) {
      initialGaushala = controller.gaushalas.firstWhereOrNull((g) => g.id == widget.type.gaushalaId);
    }
    try {
      initialGaushala ??= Get.find<GaushalaSessionService>().selectedGaushala.value;
    } catch (_) {}
    _selectedGaushala = Rxn<GaushalaModel>(initialGaushala);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await controller.updateType(
      widget.type.id,
      _nameController.text,
      gaushalaId: _selectedGaushala.value?.id,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => MobileEditScaffold(
        title: 'Edit Type',
        icon: Icons.edit_rounded,
        headerIconColor: AppColors.info,
        subtitle: 'Update classification name for "${widget.type.typeName}"',
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
              enabled: controller.isSuperAdmin,
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

          // Type Name
          CustomTextField(
            controller: _nameController,
            label: 'Type Name *',
            hint: 'e.g. Milking, Dry, Pregnant',
            prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Type name is required';
              }
              if (val.trim().length < 2) {
                return 'Type name must be at least 2 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
