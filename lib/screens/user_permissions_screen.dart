import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/permission_model.dart';
import '../app/core/values/app_colors.dart';
import '../app/core/values/permission_constants.dart';
import '../app/core/widgets/custom_button.dart';
import '../app/core/widgets/custom_snackbar.dart';
import '../app/data/services/api_service.dart';
import '../app/data/services/permission_service.dart';
import '../app/data/services/storage_service.dart';

/// Screen and Dialog for Admin to manage granular Module & Sub-Module permissions for any user.
class UserPermissionsScreen extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String? userRole;
  final bool? isUserAdmin;
  final bool isDialog;

  const UserPermissionsScreen({
    super.key,
    this.userId,
    this.userName,
    this.userRole,
    this.isUserAdmin,
    this.isDialog = false,
  });

  /// Static helper to launch as an elegant modal dialog
  static Future<void> show(
    BuildContext context, {
    required String userId,
    String? userName,
    String? userRole,
    bool? isUserAdmin,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 1050,
          constraints: const BoxConstraints(maxHeight: 820),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: UserPermissionsScreen(
            userId: userId,
            userName: userName,
            userRole: userRole,
            isUserAdmin: isUserAdmin,
            isDialog: true,
          ),
        ),
      ),
    );
  }

  @override
  State<UserPermissionsScreen> createState() => _UserPermissionsScreenState();
}

class _UserPermissionsScreenState extends State<UserPermissionsScreen> {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  late String _effectiveUserId;
  String _displayName = 'User';
  String _roleName = 'User';
  bool _isAdminUser = false;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Local editable permissions list
  List<PermissionItemModel> _matrix = [];

  @override
  void initState() {
    super.initState();
    _extractParameters();
    _fetchPermissionMatrix();
  }

  void _extractParameters() {
    final routeArgs = Get.arguments;
    final queryParams = Get.parameters;

    if (widget.userId != null && widget.userId!.isNotEmpty) {
      _effectiveUserId = widget.userId!;
      _displayName = widget.userName ?? 'User';
      _roleName = widget.userRole ?? 'User';
      _isAdminUser = widget.isUserAdmin ?? false;
    } else if (routeArgs is Map<String, dynamic>) {
      _effectiveUserId = (routeArgs['userId'] ?? '').toString();
      _displayName = (routeArgs['userName'] ?? 'User').toString();
      _roleName = (routeArgs['userRole'] ?? 'User').toString();
      _isAdminUser = routeArgs['isAdmin'] == true;
    } else if (queryParams.containsKey('userId')) {
      _effectiveUserId = queryParams['userId'] ?? '';
      _displayName = queryParams['userName'] ?? 'User';
      _roleName = queryParams['userRole'] ?? 'User';
      _isAdminUser = queryParams['isAdmin'] == 'true';
    } else {
      _effectiveUserId = '';
    }
  }

  /// Complete list of system default modules and sub-modules to guarantee
  /// full coverage even when newly created user has an empty initial list.
  List<PermissionItemModel> _getDefaultSystemTemplate() {
    return [
      // Cow Management
      const PermissionItemModel(
        moduleId: '',
        moduleCode: PermissionModules.cow,
        moduleName: 'Cow Management',
        subModuleCode: PermissionSubModules.cowList,
        subModuleName: 'Cow Records',
      ),
      // Shed Management
      const PermissionItemModel(
        moduleId: '',
        moduleCode: PermissionModules.shed,
        moduleName: 'Shed Management',
        subModuleCode: PermissionSubModules.shedList,
        subModuleName: 'Shed Master',
      ),
      const PermissionItemModel(
        moduleId: '',
        moduleCode: PermissionModules.shed,
        moduleName: 'Shed Management',
        subModuleCode: PermissionSubModules.shedTransfer,
        subModuleName: 'Shed Transfers',
      ),
      // Gaushala Management
      const PermissionItemModel(
        moduleId: '',
        moduleCode: PermissionModules.gaushala,
        moduleName: 'Gaushala Management',
        subModuleCode: PermissionSubModules.gaushalaList,
        subModuleName: 'Gaushala Master',
      ),
      // User Management
      const PermissionItemModel(
        moduleId: '',
        moduleCode: PermissionModules.user,
        moduleName: 'User Management',
        subModuleCode: PermissionSubModules.userList,
        subModuleName: 'User Master',
      ),
      // Role Management
      const PermissionItemModel(
        moduleId: '',
        moduleCode: PermissionModules.role,
        moduleName: 'Role Management',
        subModuleCode: PermissionSubModules.roleList,
        subModuleName: 'Role Master',
      ),
      // Breed Types
      const PermissionItemModel(
        moduleId: '',
        moduleCode: PermissionModules.breedType,
        moduleName: 'Breed Types',
        subModuleCode: PermissionSubModules.breedTypeList,
        subModuleName: 'Breed Master',
      ),
      // Cattle Types
      const PermissionItemModel(
        moduleId: '',
        moduleCode: PermissionModules.type,
        moduleName: 'Cattle Types',
        subModuleCode: PermissionSubModules.typeList,
        subModuleName: 'Cattle Type Master',
      ),
      // Feed & Stock
      const PermissionItemModel(
        moduleId: '',
        moduleCode: PermissionModules.feedStock,
        moduleName: 'Feed & Stock Management',
        subModuleCode: PermissionSubModules.feedItems,
        subModuleName: 'Feed Item Master',
      ),
      const PermissionItemModel(
        moduleId: '',
        moduleCode: PermissionModules.feedStock,
        moduleName: 'Feed & Stock Management',
        subModuleCode: PermissionSubModules.stockTransaction,
        subModuleName: 'Stock Transactions',
      ),
      // Medical Stock
      const PermissionItemModel(
        moduleId: '',
        moduleCode: PermissionModules.medicalStock,
        moduleName: 'Medical Stock',
        subModuleCode: PermissionSubModules.medicalItems,
        subModuleName: 'Medical Stock & Items',
      ),
      // Treatments
      const PermissionItemModel(
        moduleId: '',
        moduleCode: PermissionModules.treatment,
        moduleName: 'Treatments & Health',
        subModuleCode: PermissionSubModules.treatmentList,
        subModuleName: 'Treatment Records',
      ),
      const PermissionItemModel(
        moduleId: '',
        moduleCode: PermissionModules.treatment,
        moduleName: 'Treatments & Health',
        subModuleCode: PermissionSubModules.doseSchedule,
        subModuleName: 'Dose Schedules',
      ),
      // Worker & Department
      const PermissionItemModel(
        moduleId: '',
        moduleCode: PermissionModules.workerMgmt,
        moduleName: 'Worker & Department',
        subModuleCode: PermissionSubModules.workerList,
        subModuleName: 'Worker Master',
      ),
      const PermissionItemModel(
        moduleId: '',
        moduleCode: PermissionModules.workerMgmt,
        moduleName: 'Worker & Department',
        subModuleCode: PermissionSubModules.departmentList,
        subModuleName: 'Department Master',
      ),
      // Milk Management
      const PermissionItemModel(
        moduleId: '',
        moduleCode: PermissionModules.milkMgmt,
        moduleName: 'Milk Management',
        subModuleCode: PermissionSubModules.milkProduction,
        subModuleName: 'Milk Production',
      ),
      const PermissionItemModel(
        moduleId: '',
        moduleCode: PermissionModules.milkMgmt,
        moduleName: 'Milk Management',
        subModuleCode: PermissionSubModules.milkDistribution,
        subModuleName: 'Milk Distribution',
      ),
    ];
  }

  Future<void> _fetchPermissionMatrix() async {
    if (_effectiveUserId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User ID is missing';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getUserPermissionMatrix(_effectiveUserId);

      // Merge backend items with standard template to ensure every submodule is available
      final template = _getDefaultSystemTemplate();
      final backendItems = response.permissionMatrix;

      // Extract user details if returned
      if (response.targetUser != null) {
        final u = response.targetUser!;
        final name = u['name'] ?? u['fullName'] ?? u['username'];
        if (name != null) _displayName = name.toString();
        final role = u['role'] ?? u['roleName'];
        if (role != null) _roleName = role.toString();
        if (u['isAdmin'] == true || _roleName.toLowerCase() == 'admin') {
          _isAdminUser = true;
        }
      }

      final Map<String, PermissionItemModel> combinedMap = {};

      for (var t in template) {
        final key = '${t.moduleCode}_${t.subModuleCode}'.toUpperCase();
        combinedMap[key] = t;
      }

      for (var b in backendItems) {
        final key = '${b.moduleCode}_${b.subModuleCode}'.toUpperCase();
        combinedMap[key] = b;
      }

      setState(() {
        _matrix = combinedMap.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load permissions: $e';
        // Fall back to template
        _matrix = _getDefaultSystemTemplate();
      });
    }
  }

  // -------------------------------------------------------------
  // PERMISSION MUTATIONS
  // -------------------------------------------------------------

  void _toggleSingle(int index, PermissionAction action, bool value) {
    if (_isAdminUser) return;
    setState(() {
      final item = _matrix[index];
      _matrix[index] = item.copyWith(
        canView: action == PermissionAction.view ? value : item.canView,
        canAdd: action == PermissionAction.add ? value : item.canAdd,
        canEdit: action == PermissionAction.edit ? value : item.canEdit,
        canDelete: action == PermissionAction.delete ? value : item.canDelete,
      );
    });
  }

  void _toggleRowAll(int index, bool value) {
    if (_isAdminUser) return;
    setState(() {
      final item = _matrix[index];
      _matrix[index] = item.copyWith(
        canView: value,
        canAdd: value,
        canEdit: value,
        canDelete: value,
      );
    });
  }

  void _toggleColumnAll(PermissionAction action, bool value) {
    if (_isAdminUser) return;
    setState(() {
      for (int i = 0; i < _matrix.length; i++) {
        final item = _matrix[i];
        _matrix[i] = item.copyWith(
          canView: action == PermissionAction.view ? value : item.canView,
          canAdd: action == PermissionAction.add ? value : item.canAdd,
          canEdit: action == PermissionAction.edit ? value : item.canEdit,
          canDelete: action == PermissionAction.delete ? value : item.canDelete,
        );
      }
    });
  }

  void _toggleGlobalAll(bool value) {
    if (_isAdminUser) return;
    setState(() {
      for (int i = 0; i < _matrix.length; i++) {
        _matrix[i] = _matrix[i].copyWith(
          canView: value,
          canAdd: value,
          canEdit: value,
          canDelete: value,
        );
      }
    });
  }

  bool _isColumnAllSelected(PermissionAction action) {
    if (_matrix.isEmpty) return false;
    return _matrix.every((item) => item.allows(action));
  }

  bool _isGlobalAllSelected() {
    if (_matrix.isEmpty) return false;
    return _matrix.every((item) => item.hasAllPermissions);
  }

  // -------------------------------------------------------------
  // SAVE PERMISSIONS
  // -------------------------------------------------------------
  Future<void> _savePermissions() async {
    if (_isSaving || _effectiveUserId.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final payload = _matrix.map((item) => item.toUpdatePayload()).toList();

      final success = await _apiService.updateUserPermissions(
        _effectiveUserId,
        payload,
      );

      if (success) {
        CustomSnackbar.showSuccess(
          title: 'Permissions Saved',
          message: 'Permission matrix for $_displayName updated successfully.',
        );

        // If the logged-in user updated their own permissions, refresh active session
        final currentUser = _storageService.getUser();
        if (currentUser != null && currentUser.id == _effectiveUserId) {
          if (Get.isRegistered<PermissionService>()) {
            await Get.find<PermissionService>().initPermissions(force: true);
          }
        }

        if (mounted && widget.isDialog) {
          Navigator.of(context).pop(true);
        }
      } else {
        CustomSnackbar.showError(
          title: 'Save Failed',
          message: 'Server could not update permissions.',
        );
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error Saving Permissions',
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // -------------------------------------------------------------
  // BUILD METHOD
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _buildHeader(context),
        if (_isAdminUser) _buildAdminBadgeBanner(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _errorMessage != null
                  ? _buildErrorView()
                  : _buildMatrixTable(),
        ),
        _buildFooter(context),
      ],
    );

    if (widget.isDialog) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        title: Text('Permissions: $_displayName'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D2939),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.all(24.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5ECE2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: content,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // HEADER
  // -------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEAECF0))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF5EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              PhosphorIconsRegular.shieldCheck,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Manage Permissions - $_displayName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D2939),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _roleName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475467),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Configure granular access permissions for system modules and operations.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
                ),
              ],
            ),
          ),
          if (widget.isDialog)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF667085)),
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // ADMIN BANNER
  // -------------------------------------------------------------
  Widget _buildAdminBadgeBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB2DDFF)),
      ),
      child: const Row(
        children: [
          Icon(PhosphorIconsFill.crown, size: 20, color: Color(0xFF175CD3)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Admin has full access: This user has administrator privileges and automatically possesses unrestricted access across all modules.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF175CD3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // ERROR VIEW
  // -------------------------------------------------------------
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An error occurred',
              style: const TextStyle(color: Color(0xFF344054), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPermissionMatrix,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // MATRIX TABLE
  // -------------------------------------------------------------
  Widget _buildMatrixTable() {
    // Group permissions by module
    final Map<String, List<int>> moduleGroups = {};
    for (int i = 0; i < _matrix.length; i++) {
      final mod = _matrix[i].moduleName.isNotEmpty ? _matrix[i].moduleName : _matrix[i].moduleCode;
      moduleGroups.putIfAbsent(mod, () => []).add(i);
    }

    return Column(
      children: [
        // Table Header
        _buildTableHeader(),
        const Divider(height: 1, color: Color(0xFFEAECF0)),

        // Table Rows
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: moduleGroups.keys.length,
            separatorBuilder: (context, _) => const Divider(height: 1, color: Color(0xFFF2F4F7)),
            itemBuilder: (context, groupIndex) {
              final moduleName = moduleGroups.keys.elementAt(groupIndex);
              final indices = moduleGroups[moduleName]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Header (Module Name)
                  Container(
                    color: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsRegular.folderSimple, size: 16, color: Color(0xFF475467)),
                        const SizedBox(width: 8),
                        Text(
                          moduleName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF344054),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Submodule rows
                  ...indices.map((idx) => _buildSubModuleRow(idx)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TABLE HEADER WITH SELECT ALL COLUMN TOGGLES
  // -------------------------------------------------------------
  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF8FBF8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // Sub-Module Column
          const Expanded(
            flex: 4,
            child: Text(
              'SUB-MODULE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475467),
                letterSpacing: 0.6,
              ),
            ),
          ),

          // View Column
          _buildColumnHeaderToggle(
            flex: 2,
            action: PermissionAction.view,
            label: 'View',
          ),

          // Add Column
          _buildColumnHeaderToggle(
            flex: 2,
            action: PermissionAction.add,
            label: 'Add',
          ),

          // Edit Column
          _buildColumnHeaderToggle(
            flex: 2,
            action: PermissionAction.edit,
            label: 'Edit',
          ),

          // Delete Column
          _buildColumnHeaderToggle(
            flex: 2,
            action: PermissionAction.delete,
            label: 'Delete',
          ),

          // Master Row Select All
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _isAdminUser || _isGlobalAllSelected(),
                  onChanged: _isAdminUser ? null : (v) => _toggleGlobalAll(v ?? false),
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
                const Text(
                  'ALL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475467),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeaderToggle({
    required int flex,
    required PermissionAction action,
    required String label,
  }) {
    final isAll = _isAdminUser || _isColumnAllSelected(action);

    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: _isAdminUser ? null : () => _toggleColumnAll(action, !isAll),
        borderRadius: BorderRadius.circular(6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: isAll,
              onChanged: _isAdminUser ? null : (v) => _toggleColumnAll(action, v ?? false),
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475467),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // SUBMODULE ROW
  // -------------------------------------------------------------
  Widget _buildSubModuleRow(int index) {
    final item = _matrix[index];
    final rowAll = _isAdminUser || item.hasAllPermissions;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          // Sub-Module Name & Code
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.subModuleName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D2939),
                  ),
                ),
                Text(
                  item.subModuleCode,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF98A2B3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // View Checkbox
          Expanded(
            flex: 2,
            child: Center(
              child: Checkbox(
                value: _isAdminUser || item.canView,
                onChanged: _isAdminUser ? null : (v) => _toggleSingle(index, PermissionAction.view, v ?? false),
                activeColor: AppColors.primary,
              ),
            ),
          ),

          // Add Checkbox
          Expanded(
            flex: 2,
            child: Center(
              child: Checkbox(
                value: _isAdminUser || item.canAdd,
                onChanged: _isAdminUser ? null : (v) => _toggleSingle(index, PermissionAction.add, v ?? false),
                activeColor: AppColors.primary,
              ),
            ),
          ),

          // Edit Checkbox
          Expanded(
            flex: 2,
            child: Center(
              child: Checkbox(
                value: _isAdminUser || item.canEdit,
                onChanged: _isAdminUser ? null : (v) => _toggleSingle(index, PermissionAction.edit, v ?? false),
                activeColor: AppColors.primary,
              ),
            ),
          ),

          // Delete Checkbox
          Expanded(
            flex: 2,
            child: Center(
              child: Checkbox(
                value: _isAdminUser || item.canDelete,
                onChanged: _isAdminUser ? null : (v) => _toggleSingle(index, PermissionAction.delete, v ?? false),
                activeColor: AppColors.primary,
              ),
            ),
          ),

          // Row Select All
          Expanded(
            flex: 2,
            child: Center(
              child: Checkbox(
                value: rowAll,
                onChanged: _isAdminUser ? null : (v) => _toggleRowAll(index, v ?? false),
                activeColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // FOOTER (SAVE / CANCEL ACTIONS)
  // -------------------------------------------------------------
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEAECF0))),
      ),
      child: Row(
        children: [
          Text(
            '${_matrix.length} Sub-modules mapped',
            style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
          ),
          const Spacer(),
          if (widget.isDialog)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF344054),
                side: const BorderSide(color: Color(0xFFD0D5DD)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          const SizedBox(width: 12),
          CustomButton(
            text: 'Save Permissions',
            isLoading: _isSaving,
            icon: PhosphorIconsRegular.floppyDisk,
            onPressed: _isAdminUser ? null : _savePermissions,
          ),
        ],
      ),
    );
  }
}
