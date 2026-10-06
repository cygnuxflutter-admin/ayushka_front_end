import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_dropdown_search.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/mobile_edit_scaffold.dart';
import '../../../data/models/department_model.dart';
import '../../../data/models/worker_model.dart';
import '../department_controller.dart';
import '../worker_controller.dart';

/// Full-screen mobile edit page for Workers.
class EditWorkerScreen extends StatefulWidget {
  final WorkerModel worker;

  const EditWorkerScreen({super.key, required this.worker});

  @override
  State<EditWorkerScreen> createState() => _EditWorkerScreenState();
}

class _EditWorkerScreenState extends State<EditWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final RxBool _isActive;
  final WorkerController controller = Get.find<WorkerController>();
  late final DepartmentController deptCtrl;
  late final Rxn<DepartmentModel> _selectedDept;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.worker.name);
    _isActive = widget.worker.isActive.obs;

    deptCtrl = Get.find<DepartmentController>();
    if (deptCtrl.departments.isEmpty) {
      deptCtrl.fetchDepartments();
    }

    final initialDept = deptCtrl.departments.firstWhereOrNull((d) => d.id == widget.worker.departmentId);
    _selectedDept = Rxn<DepartmentModel>(initialDept);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedDept.value == null) {
      CustomSnackbar.showError(title: 'Validation Error', message: 'Please select a department');
      return;
    }

    final ok = await controller.updateWorker(
      widget.worker.id,
      name: _nameController.text.trim(),
      departmentId: _selectedDept.value!.id,
      isActive: _isActive.value,
    );

    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(
      () => MobileEditScaffold(
        title: 'Edit Worker Details',
        icon: PhosphorIconsRegular.pencilSimple,
        headerIconColor: AppColors.primary,
        subtitle: 'Update worker name, assigned department, and active status.',
        formKey: _formKey,
        isSaving: controller.isSubmitting.value,
        saveText: 'Save Changes',
        onSave: _handleSave,
        children: [
          // Name
          CustomTextField(
            label: 'Worker Name *',
            hint: 'e.g. Ramesh Patel',
            controller: _nameController,
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Worker name is required' : null,
          ),
          const SizedBox(height: 16),

          // Department Dropdown
          Obx(() {
            return CustomDropdownSearch<DepartmentModel>(
              label: 'Assigned Department',
              isRequired: true,
              hint: 'Select Department',
              prefixIcon: Icons.apartment_rounded,
              selectedItem: _selectedDept.value,
              items: deptCtrl.departments.toList(),
              itemAsString: (d) => '${d.departmentName} (${d.departmentCode})',
              compareFn: (d1, d2) => d1.id == d2.id,
              searchable: true,
              searchHint: 'Search department...',
              onChanged: (d) => _selectedDept.value = d,
              validator: (d) {
                if (d == null && _selectedDept.value == null) {
                  return 'Please select a department';
                }
                return null;
              },
            );
          }),
          const SizedBox(height: 16),

          // Status Toggle
          Obx(
            () => SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Active Working Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              subtitle: Text(
                _isActive.value ? 'Worker is currently active' : 'Worker is deactivated / inactive',
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
