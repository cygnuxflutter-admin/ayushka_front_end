import '../app/core/values/permission_constants.dart';

/// Supported granular actions for Role and Permission-Based Access Control.
enum PermissionAction {
  view,
  add,
  edit,
  delete;

  /// String representation for API payloads and serialization
  String get value {
    switch (this) {
      case PermissionAction.view:
        return 'view';
      case PermissionAction.add:
        return 'add';
      case PermissionAction.edit:
        return 'edit';
      case PermissionAction.delete:
        return 'delete';
    }
  }

  /// Capitalized title label for UI rendering
  String get displayName {
    switch (this) {
      case PermissionAction.view:
        return 'View';
      case PermissionAction.add:
        return 'Add';
      case PermissionAction.edit:
        return 'Edit';
      case PermissionAction.delete:
        return 'Delete';
    }
  }

  static PermissionAction fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'add':
        return PermissionAction.add;
      case 'edit':
        return PermissionAction.edit;
      case 'delete':
        return PermissionAction.delete;
      case 'view':
      default:
        return PermissionAction.view;
    }
  }
}

/// Strongly-typed immutable model representing a granular sub-module permission entry.
class PermissionItemModel {
  final String moduleId;
  final String moduleCode;
  final String moduleName;
  final String subModuleCode;
  final String subModuleName;
  final bool canView;
  final bool canAdd;
  final bool canEdit;
  final bool canDelete;

  const PermissionItemModel({
    required this.moduleId,
    required this.moduleCode,
    required this.moduleName,
    required this.subModuleCode,
    required this.subModuleName,
    this.canView = false,
    this.canAdd = false,
    this.canEdit = false,
    this.canDelete = false,
  });

  /// True if all 4 action flags are granted
  bool get hasAllPermissions => canView && canAdd && canEdit && canDelete;

  /// True if any action flag is granted
  bool get hasAnyPermission => canView || canAdd || canEdit || canDelete;

  /// Check permission for a specific action
  bool allows(PermissionAction action) {
    switch (action) {
      case PermissionAction.view:
        return canView;
      case PermissionAction.add:
        return canAdd;
      case PermissionAction.edit:
        return canEdit;
      case PermissionAction.delete:
        return canDelete;
    }
  }

  PermissionItemModel copyWith({
    String? moduleId,
    String? moduleCode,
    String? moduleName,
    String? subModuleCode,
    String? subModuleName,
    bool? canView,
    bool? canAdd,
    bool? canEdit,
    bool? canDelete,
  }) {
    return PermissionItemModel(
      moduleId: moduleId ?? this.moduleId,
      moduleCode: moduleCode ?? this.moduleCode,
      moduleName: moduleName ?? this.moduleName,
      subModuleCode: subModuleCode ?? this.subModuleCode,
      subModuleName: subModuleName ?? this.subModuleName,
      canView: canView ?? this.canView,
      canAdd: canAdd ?? this.canAdd,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
    );
  }

  factory PermissionItemModel.fromJson(Map<String, dynamic> json) {
    final subCode = (json['subModuleCode'] ?? json['sub_module_code'] ?? '').toString().toUpperCase();
    String modCode = (json['moduleCode'] ?? json['module_code'] ?? '').toString().toUpperCase();
    if (modCode.isEmpty && subCode.isNotEmpty) {
      modCode = PermissionSubModules.getParentModule(subCode);
    }

    final modName = (json['moduleName'] ?? json['module_name'] ?? '').toString();
    final subName = (json['subModuleName'] ?? json['sub_module_name'] ?? '').toString();

    return PermissionItemModel(
      moduleId: (json['moduleId'] ?? json['module_id'] ?? json['_id'] ?? json['id'] ?? '').toString(),
      moduleCode: modCode,
      moduleName: modName.isNotEmpty ? modName : PermissionModules.getLabel(modCode),
      subModuleCode: subCode,
      subModuleName: subName.isNotEmpty ? subName : PermissionSubModules.getLabel(subCode),
      canView: json['canView'] == true || json['can_view'] == true,
      canAdd: json['canAdd'] == true || json['can_add'] == true,
      canEdit: json['canEdit'] == true || json['can_edit'] == true,
      canDelete: json['canDelete'] == true || json['can_delete'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleId': moduleId,
      'moduleCode': moduleCode,
      'moduleName': moduleName,
      'subModuleCode': subModuleCode,
      'subModuleName': subModuleName,
      'canView': canView,
      'canAdd': canAdd,
      'canEdit': canEdit,
      'canDelete': canDelete,
    };
  }

  /// Compact payload structure expected by Admin Update permissions API:
  /// POST /api/v1/permissions/users/:userId
  Map<String, dynamic> toUpdatePayload() {
    final map = <String, dynamic>{
      'moduleCode': moduleCode,
      'subModuleCode': subModuleCode,
      'canView': canView,
      'canAdd': canAdd,
      'canEdit': canEdit,
      'canDelete': canDelete,
    };
    if (moduleId.isNotEmpty) {
      map['moduleId'] = moduleId;
    }
    return map;
  }
}

/// Response model for GET /api/v1/permissions/my-permissions
class UserPermissionsResponse {
  final String userId;
  final String role;
  final bool isAdmin;
  final List<PermissionItemModel> permissions;

  const UserPermissionsResponse({
    required this.userId,
    required this.role,
    this.isAdmin = false,
    this.permissions = const [],
  });

  factory UserPermissionsResponse.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;

    final rawList = dataMap['permissions'] ?? json['permissions'];
    List<PermissionItemModel> list = [];
    if (rawList is List) {
      list = rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => PermissionItemModel.fromJson(e))
          .toList();
    }

    final roleVal = (dataMap['role'] ?? json['role'] ?? '').toString();
    final bool rawIsAdmin = dataMap['isAdmin'] == true ||
        dataMap['is_admin'] == true ||
        json['isAdmin'] == true ||
        json['is_admin'] == true ||
        roleVal.toLowerCase() == 'admin' ||
        roleVal.toLowerCase() == 'superadmin';

    return UserPermissionsResponse(
      userId: (dataMap['userId'] ?? dataMap['user_id'] ?? dataMap['id'] ?? dataMap['_id'] ?? '').toString(),
      role: roleVal,
      isAdmin: rawIsAdmin,
      permissions: list,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role,
      'isAdmin': isAdmin,
      'permissions': permissions.map((e) => e.toJson()).toList(),
    };
  }
}

/// Single item within the permission matrix returned for an admin's user query
typedef PermissionMatrixItem = PermissionItemModel;

/// Response model for Admin: GET /api/v1/permissions/users/:userId
class UserPermissionMatrixResponse {
  final Map<String, dynamic>? targetUser;
  final List<PermissionItemModel> permissionMatrix;

  const UserPermissionMatrixResponse({
    this.targetUser,
    this.permissionMatrix = const [],
  });

  factory UserPermissionMatrixResponse.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;

    final rawMatrix = dataMap['permissionMatrix'] ?? dataMap['permissions'] ?? [];
    List<PermissionItemModel> matrix = [];
    if (rawMatrix is List) {
      matrix = rawMatrix
          .whereType<Map<String, dynamic>>()
          .map((e) => PermissionItemModel.fromJson(e))
          .toList();
    }

    final userMap = dataMap['user'] is Map<String, dynamic>
        ? dataMap['user'] as Map<String, dynamic>
        : (dataMap['targetUser'] is Map<String, dynamic> ? dataMap['targetUser'] as Map<String, dynamic> : null);

    return UserPermissionMatrixResponse(
      targetUser: userMap,
      permissionMatrix: matrix,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': targetUser,
      'permissionMatrix': permissionMatrix.map((e) => e.toJson()).toList(),
    };
  }
}
