import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../models/permission_model.dart';
import '../core/values/permission_constants.dart';
import '../data/services/permission_service.dart';
import '../data/services/storage_service.dart';
import 'app_routes.dart';

/// Route guard middleware verifying user authentication and granular
/// Module & Sub-Module permissions for route destinations in Flutter Web.
class PermissionGuardMiddleware extends GetMiddleware {
  final String? requiredModule;
  final String? requiredSubModule;
  final PermissionAction requiredAction;
  final bool adminOnly;
  final bool superAdminOnly;

  PermissionGuardMiddleware({
    this.requiredModule,
    this.requiredSubModule,
    this.requiredAction = PermissionAction.view,
    this.adminOnly = false,
    this.superAdminOnly = false,
    int? priority,
  }) : super(priority: priority ?? 1);

  @override
  RouteSettings? redirect(String? route) {
    // 1. Authenticated check
    if (!Get.isRegistered<StorageService>()) {
      return null;
    }
    final storageService = Get.find<StorageService>();
    if (!storageService.hasToken) {
      return const RouteSettings(name: AppRoutes.auth);
    }

    // 2. Permission check
    if (!Get.isRegistered<PermissionService>()) {
      return null;
    }
    final permissionService = Get.find<PermissionService>();

    // SuperAdmin only route check
    if (superAdminOnly) {
      if (!permissionService.isSuperAdmin) {
        return RouteSettings(
          name: '${AppRoutes.forbidden}?route=${Uri.encodeComponent(route ?? '')}',
        );
      }
      return null;
    }

    // Admins bypass normal module permission restrictions
    if (permissionService.isAdmin) {
      return null;
    }

    if (adminOnly) {
      return RouteSettings(
        name: '${AppRoutes.forbidden}?route=${Uri.encodeComponent(route ?? '')}',
      );
    }

    if (requiredModule != null && requiredSubModule != null) {
      final allowed = permissionService.hasPermission(
        module: requiredModule!,
        subModule: requiredSubModule!,
        action: requiredAction,
      );

      if (!allowed) {
        return RouteSettings(
          name: '${AppRoutes.forbidden}?route=${Uri.encodeComponent(route ?? '')}',
        );
      }
    }

    return null;
  }
}

/// Helper mapping standard AppRoutes to their corresponding permission requirements
class RoutePermissionRegistry {
  RoutePermissionRegistry._();

  static PermissionGuardMiddleware forRoute(String route) {
    switch (route) {
      case AppRoutes.cows:
        return PermissionGuardMiddleware(
          requiredModule: PermissionModules.cow,
          requiredSubModule: PermissionSubModules.cowList,
          requiredAction: PermissionAction.view,
        );
      case AppRoutes.addCow:
        return PermissionGuardMiddleware(
          requiredModule: PermissionModules.cow,
          requiredSubModule: PermissionSubModules.cowList,
          requiredAction: PermissionAction.add,
        );
      case AppRoutes.editCow:
        return PermissionGuardMiddleware(
          requiredModule: PermissionModules.cow,
          requiredSubModule: PermissionSubModules.cowList,
          requiredAction: PermissionAction.edit,
        );
      case AppRoutes.sheds:
        return PermissionGuardMiddleware(
          requiredModule: PermissionModules.shed,
          requiredSubModule: PermissionSubModules.shedList,
          requiredAction: PermissionAction.view,
        );
      case AppRoutes.gaushalas:
        return PermissionGuardMiddleware(
          requiredModule: PermissionModules.gaushala,
          requiredSubModule: PermissionSubModules.gaushalaList,
          requiredAction: PermissionAction.view,
          superAdminOnly: true,
        );
      case AppRoutes.roles:
        return PermissionGuardMiddleware(
          requiredModule: PermissionModules.role,
          requiredSubModule: PermissionSubModules.roleList,
          requiredAction: PermissionAction.view,
        );
      case AppRoutes.users:
        return PermissionGuardMiddleware(
          requiredModule: PermissionModules.user,
          requiredSubModule: PermissionSubModules.userList,
          requiredAction: PermissionAction.view,
        );
      case AppRoutes.userPermissions:
      case AppRoutes.moduleManagement:
        return PermissionGuardMiddleware(
          adminOnly: true,
        );
      case AppRoutes.breeds:
        return PermissionGuardMiddleware(
          requiredModule: PermissionModules.breedType,
          requiredSubModule: PermissionSubModules.breedTypeList,
          requiredAction: PermissionAction.view,
        );
      case AppRoutes.types:
        return PermissionGuardMiddleware(
          requiredModule: PermissionModules.type,
          requiredSubModule: PermissionSubModules.typeList,
          requiredAction: PermissionAction.view,
        );
      case AppRoutes.feedItems:
        return PermissionGuardMiddleware(
          requiredModule: PermissionModules.feedStock,
          requiredSubModule: PermissionSubModules.feedItems,
          requiredAction: PermissionAction.view,
        );
      case AppRoutes.feedTransactions:
        return PermissionGuardMiddleware(
          requiredModule: PermissionModules.feedStock,
          requiredSubModule: PermissionSubModules.stockTransaction,
          requiredAction: PermissionAction.view,
        );
      case AppRoutes.medicalStock:
        return PermissionGuardMiddleware(
          requiredModule: PermissionModules.medicalStock,
          requiredSubModule: PermissionSubModules.medicalItems,
          requiredAction: PermissionAction.view,
        );
      case AppRoutes.treatments:
      case AppRoutes.treatmentDetails:
        return PermissionGuardMiddleware(
          requiredModule: PermissionModules.treatment,
          requiredSubModule: PermissionSubModules.treatmentList,
          requiredAction: PermissionAction.view,
        );
      case AppRoutes.workers:
        return PermissionGuardMiddleware(
          requiredModule: PermissionModules.workerMgmt,
          requiredSubModule: PermissionSubModules.workerList,
          requiredAction: PermissionAction.view,
        );
      case AppRoutes.departments:
        return PermissionGuardMiddleware(
          requiredModule: PermissionModules.workerMgmt,
          requiredSubModule: PermissionSubModules.departmentList,
          requiredAction: PermissionAction.view,
        );
      case AppRoutes.milk:
        return PermissionGuardMiddleware(
          requiredModule: PermissionModules.milkMgmt,
          requiredSubModule: PermissionSubModules.milkProduction,
          requiredAction: PermissionAction.view,
        );
      default:
        return PermissionGuardMiddleware();
    }
  }
}
