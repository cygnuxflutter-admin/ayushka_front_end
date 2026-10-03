import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/permission_model.dart';
import '../app/data/services/permission_service.dart';

/// Reusable UI Guard widget that conditionally renders [child]
/// only when the user possesses the required permission action.
///
/// If unauthorized, renders [fallback] (defaults to [SizedBox.shrink]).
///
/// Example:
/// ```dart
/// PermissionGuard(
///   moduleCode: 'COW',
///   subModuleCode: 'COW_LIST',
///   action: PermissionAction.add,
///   child: ElevatedButton.icon(
///     onPressed: () => _openAddCowDialog(),
///     icon: const Icon(Icons.add),
///     label: const Text('Add Cow'),
///   ),
/// )
/// ```
class PermissionGuard extends StatelessWidget {
  final String moduleCode;
  final String subModuleCode;
  final PermissionAction action;
  final Widget child;
  final Widget fallback;

  const PermissionGuard({
    super.key,
    required this.moduleCode,
    required this.subModuleCode,
    required this.action,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PermissionService>()) {
      return child;
    }

    final permissionService = Get.find<PermissionService>();

    return Obx(() {
      final allowed = permissionService.hasPermission(
        module: moduleCode,
        subModule: subModuleCode,
        action: action,
      );

      if (allowed) {
        return child;
      }
      return fallback;
    });
  }
}

/// Dynamic permission builder supplying granular boolean flags to children.
class PermissionBuilder extends StatelessWidget {
  final String moduleCode;
  final String subModuleCode;
  final Widget Function(
    BuildContext context,
    bool canView,
    bool canAdd,
    bool canEdit,
    bool canDelete,
  ) builder;

  const PermissionBuilder({
    super.key,
    required this.moduleCode,
    required this.subModuleCode,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PermissionService>()) {
      return builder(context, true, true, true, true);
    }

    final permissionService = Get.find<PermissionService>();

    return Obx(() {
      final canView = permissionService.canView(moduleCode, subModuleCode);
      final canAdd = permissionService.canAdd(moduleCode, subModuleCode);
      final canEdit = permissionService.canEdit(moduleCode, subModuleCode);
      final canDelete = permissionService.canDelete(moduleCode, subModuleCode);

      return builder(context, canView, canAdd, canEdit, canDelete);
    });
  }
}

/// Helpful BuildContext extensions for rapid inline permission checks.
extension PermissionContextExtensions on BuildContext {
  /// Reference to registered PermissionService
  PermissionService? get _permissionService {
    if (Get.isRegistered<PermissionService>()) {
      return Get.find<PermissionService>();
    }
    return null;
  }

  /// Whether current user is an Admin
  bool get isAdmin => _permissionService?.isAdmin ?? false;

  /// Check granular permission for a module, submodule, and action
  bool hasPermission({
    required String module,
    required String subModule,
    required PermissionAction action,
  }) {
    return _permissionService?.hasPermission(
          module: module,
          subModule: subModule,
          action: action,
        ) ??
        false;
  }

  /// Check View permission
  bool canView(String module, String subModule) =>
      _permissionService?.canView(module, subModule) ?? false;

  /// Check Add permission
  bool canAdd(String module, String subModule) =>
      _permissionService?.canAdd(module, subModule) ?? false;

  /// Check Edit permission
  bool canEdit(String module, String subModule) =>
      _permissionService?.canEdit(module, subModule) ?? false;

  /// Check Delete permission
  bool canDelete(String module, String subModule) =>
      _permissionService?.canDelete(module, subModule) ?? false;

  /// Check if whole module is visible
  bool isModuleVisible(String module) =>
      _permissionService?.isModuleVisible(module) ?? false;
}
