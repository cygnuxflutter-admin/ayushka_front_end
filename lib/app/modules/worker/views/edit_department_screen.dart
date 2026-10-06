import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/mobile_edit_scaffold.dart';
import '../../../data/models/department_model.dart';
import '../department_controller.dart';

/// Full-screen mobile edit page for Departments.
class EditDepartmentScreen extends StatefulWidget {
  final DepartmentModel department;
  final VoidCallback? onSuccess;

  const EditDepartmentScreen({
    super.key,
    required this.department,
    this.onSuccess,
  });

  @override
  State<EditDepartmentScreen> createState() => _EditDepartmentScreenState();
}

class _EditDepartmentScreenState extends State<EditDepartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descController;
  late final RxBool _isActive;
  final DepartmentController controller = Get.find<DepartmentController>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.department.departmentName);
    _codeController = TextEditingController(text: widget.department.departmentCode);
    _descController = TextEditingController(text: widget.department.description);
    _isActive = widget.department.isActive.obs;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await controller.updateDepartment(
      widget.department.id,
      departmentName: _nameController.text.trim(),
      departmentCode: _codeController.text.trim().toUpperCase(),
      description: _descController.text.trim(),
      isActive: _isActive.value,
    );

    if (ok && mounted) {
      widget.onSuccess?.call();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(
      () => MobileEditScaffold(
        title: 'Edit Department',
        icon: PhosphorIconsRegular.pencilSimple,
        headerIconColor: AppColors.primary,
        subtitle: 'Modify department details, code, and operational status.',
        formKey: _formKey,
        isSaving: controller.isSubmitting.value,
        saveText: 'Save Changes',
        onSave: _handleSave,
        children: [
          // Department Name
          CustomTextField(
            label: 'Department Name *',
            hint: 'e.g. Dairy & Milking Operations',
            controller: _nameController,
            prefixIcon: const Icon(Icons.apartment_rounded, size: 18),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Department name is required' : null,
          ),
          const SizedBox(height: 16),

          // Department Code
          CustomTextField(
            label: 'Department Code *',
            hint: 'e.g. MILK, FEED',
            controller: _codeController,
            isUpperCase: true,
            prefixIcon: const Icon(Icons.tag_rounded, size: 18),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Department code is required' : null,
          ),
          const SizedBox(height: 16),

          // Description
          CustomTextField(
            label: 'Description',
            hint: 'Brief description...',
            controller: _descController,
            maxLines: 3,
            prefixIcon: const Icon(Icons.notes_rounded, size: 18),
          ),
          const SizedBox(height: 16),

          // Active Status Switch
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
                _isActive.value ? 'Department is active' : 'Department is deactivated',
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
