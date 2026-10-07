import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_dropdown_search.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/mobile_edit_scaffold.dart';
import '../../../data/models/gaushala_model.dart';
import '../../../data/models/role_model.dart';
import '../../../data/models/user_model.dart';
import '../user_controller.dart';

/// Full-screen mobile edit page for Users.
class EditUserScreen extends StatefulWidget {
  final UserModel user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final UserController controller = Get.find<UserController>();

  late final Rxn<RoleModel> _selectedRole;
  late final Rxn<GaushalaModel> _selectedGaushala;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _usernameController = TextEditingController(text: widget.user.username ?? '');
    _emailController = TextEditingController(text: widget.user.email);
    _passwordController = TextEditingController();

    final initialRole = controller.roles.firstWhereOrNull(
      (r) => r.id == widget.user.roleId || r.roleName.toLowerCase() == widget.user.role.toLowerCase(),
    );
    final initialGaushala = controller.gaushalas.firstWhereOrNull(
      (g) => g.id == widget.user.gaushalaId || (widget.user.gaushalaName != null && g.gaushalaName.toLowerCase() == widget.user.gaushalaName!.toLowerCase()),
    );

    _selectedRole = Rxn<RoleModel>(initialRole);
    _selectedGaushala = Rxn<GaushalaModel>(initialGaushala);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedGaushala.value == null) {
      CustomSnackbar.showError(
        title: 'Gaushala Required',
        message: 'Please select a gaushala for this user.',
      );
      return;
    }
    if (_selectedRole.value == null) {
      CustomSnackbar.showError(
        title: 'Role Required',
        message: 'Please assign a role to this user.',
      );
      return;
    }

    final success = await controller.updateUser(
      id: widget.user.id,
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      emailId: _emailController.text.trim(),
      password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
      roleId: _selectedRole.value!.id,
      gaushalaId: _selectedGaushala.value!.id,
      isActive: widget.user.isActive,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => MobileEditScaffold(
        title: 'Edit User',
        icon: Icons.edit_rounded,
        headerIconColor: AppColors.info,
        subtitle: 'Modify profile details and permissions for "${widget.user.name}"',
        formKey: _formKey,
        isSaving: controller.isSubmitting.value,
        saveText: 'Save Changes',
        onSave: _handleSave,
        children: [
          // Full Name
          CustomTextField(
            controller: _nameController,
            label: 'Full Name *',
            hint: 'e.g. Ravi Sharma',
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Full name is required';
              if (val.trim().length < 2) return 'Name must be at least 2 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Username
          CustomTextField(
            controller: _usernameController,
            label: 'Username *',
            hint: 'e.g. ravi_sharma',
            prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Username is required';
              if (val.trim().length < 3) return 'Min 3 chars';
              if (val.trim().contains(' ')) return 'No spaces allowed';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email
          CustomTextField(
            controller: _emailController,
            label: 'Email ID *',
            hint: 'e.g. ravi@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Email is required';
              if (!GetUtils.isEmail(val.trim())) return 'Invalid email format';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Gaushala Dropdown
          Obx(() {
            return CustomDropdownSearch<GaushalaModel>(
              label: 'Gaushala',
              isRequired: true,
              hint: 'Select Gaushala',
              prefixIcon: Icons.storefront_outlined,
              selectedItem: _selectedGaushala.value,
              items: controller.gaushalas.toList(),
              itemAsString: (g) => g.gaushalaName,
              compareFn: (g1, g2) => g1.id == g2.id,
              searchable: true,
              searchHint: 'Search gaushala...',
              enabled: controller.isSuperAdmin,
              onChanged: controller.isSuperAdmin ? (sel) => _selectedGaushala.value = sel : null,
              validator: (sel) => sel == null ? 'Gaushala is required' : null,
            );
          }),
          const SizedBox(height: 16),

          // Role Dropdown
          Obx(() {
            return CustomDropdownSearch<RoleModel>(
              label: 'Role',
              isRequired: true,
              hint: 'Select Role',
              prefixIcon: PhosphorIconsRegular.shieldCheck,
              selectedItem: _selectedRole.value,
              items: controller.roles.toList(),
              itemAsString: (r) => r.roleName,
              compareFn: (r1, r2) => r1.id == r2.id,
              searchable: true,
              searchHint: 'Search role...',
              onChanged: (sel) => _selectedRole.value = sel,
              validator: (sel) => sel == null ? 'Role is required' : null,
            );
          }),
          const SizedBox(height: 16),

          // Password Field (Optional on Edit)
          CustomTextField(
            controller: _passwordController,
            label: 'New Password',
            hint: 'Leave empty to keep current password',
            isPassword: true,
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            validator: (val) {
              if (val != null && val.isNotEmpty && val.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
