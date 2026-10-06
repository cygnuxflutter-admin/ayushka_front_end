import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/mobile_edit_scaffold.dart';
import '../../../data/models/role_model.dart';
import '../role_controller.dart';

/// Full-screen mobile edit page for Roles.
class EditRoleScreen extends StatefulWidget {
  final RoleModel role;

  const EditRoleScreen({super.key, required this.role});

  @override
  State<EditRoleScreen> createState() => _EditRoleScreenState();
}

class _EditRoleScreenState extends State<EditRoleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final RoleController controller = Get.find<RoleController>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role.roleName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newName = _nameController.text.trim();
    final success = await controller.updateRole(widget.role.id, newName);
    if (success && mounted) {
      Navigator.of(context).pop();
      CustomSnackbar.showSuccess(
        title: 'Role Updated',
        message: 'Role updated to "$newName" successfully.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => MobileEditScaffold(
        title: 'Edit Role',
        icon: Icons.edit_rounded,
        headerIconColor: AppColors.info,
        subtitle: 'Update title and permissions for "${widget.role.roleName}"',
        formKey: _formKey,
        isSaving: controller.isSubmitting.value,
        saveText: 'Save Changes',
        onSave: _handleSave,
        children: [
          CustomTextField(
            controller: _nameController,
            label: 'Role Name *',
            hint: 'e.g. Manager, Doctor, Supervisor',
            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Role name is required';
              }
              if (val.trim().length < 2) {
                return 'Role name must be at least 2 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
