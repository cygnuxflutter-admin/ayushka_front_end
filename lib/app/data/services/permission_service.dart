import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/permission_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Production-ready Role & Permission-Based Access Control (RBAC) Service.
/// Manages logged-in user permissions, caching, and evaluation methods.
/// Extends [GetxService] and implements [ChangeNotifier] for broad framework compatibility.
class PermissionService extends GetxService with ChangeNotifier {
  late final ApiService _apiService;
  late final StorageService _storageService;

  final RxList<PermissionItemModel> _permissions = <PermissionItemModel>[].obs;
  final RxBool _isAdmin = false.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isInitialized = false.obs;
  final RxInt _version = 0.obs;

  RxList<PermissionItemModel> get rxPermissions => _permissions;
  RxBool get rxIsAdmin => _isAdmin;
  RxBool get rxIsLoading => _isLoading;
  RxBool get rxIsInitialized => _isInitialized;
  RxInt get rxVersion => _version;

  List<PermissionItemModel> get permissions => _permissions.toList();
  bool get isLoading => _isLoading.value;
  bool get isInitialized => _isInitialized.value;

  /// Returns true if the user is a Super Administrator
  bool get isSuperAdmin {
    final user = _storageService.getUser();
    return user?.isSuperAdmin ?? false;
  }

  /// Returns true if the user has Administrator privileges
  bool get isAdmin {
    if (_isInitialized.value) {
      return _isAdmin.value;
    }
    final cachedAdmin = _storageService.getIsAdminPermission();
    if (cachedAdmin != null) {
      return cachedAdmin;
    }
    final user = _storageService.getUser();
    if (user != null) {
      return user.isAdmin;
    }
    return _isAdmin.value;
  }

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _storageService = Get.find<StorageService>();
    loadFromCache();
  }

  /// Load cached permissions immediately to avoid flicker on page load / reload
  void loadFromCache() {
    final cached = _storageService.getUserPermissions();
    final cachedAdmin = _storageService.getIsAdminPermission();
    if (cached != null && cached.isNotEmpty) {
      _permissions.assignAll(cached);
      _isInitialized.value = true;
    }
    if (cachedAdmin != null) {
      _isAdmin.value = cachedAdmin;
    }
  }

  /// Initialize and refresh permissions from the server.
  /// Called upon login, application start, and web refresh.
  Future<void> initPermissions({bool force = false}) async {
    if (!_storageService.hasToken) {
      clearPermissions();
      return;
    }

    loadFromCache();

    try {
      _isLoading.value = true;
      notifyListeners();

      final response = await _apiService.getMyPermissions();

      _permissions.assignAll(response.permissions);
      _isAdmin.value = response.isAdmin;
      _isInitialized.value = true;
      _version.value++;

      // Save to local cache
      await _storageService.saveUserPermissions(response.permissions, response.isAdmin);

      // Keep stored user profile in sync with confirmed role
      final user = _storageService.getUser();
      if (user != null && response.role.isNotEmpty && user.role != response.role) {
        await _storageService.saveUser(user.copyWith(role: response.role));
      }

      if (kDebugMode) {
        print('[RBAC] Loaded ${response.permissions.length} permissions. Role: ${response.role}, IsAdmin: ${response.isAdmin}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[RBAC Error] Failed to fetch permissions: $e');
      }
      // On error, fall back to cached data or user admin flag
      final user = _storageService.getUser();
      if (user != null && user.isAdmin) {
        _isAdmin.value = true;
      }
    } finally {
      _isLoading.value = false;
      notifyListeners();
    }
  }

  /// Reset permissions on user sign out
  Future<void> clearPermissions() async {
    _permissions.clear();
    _isAdmin.value = false;
    _isInitialized.value = false;
    _version.value++;
    await _storageService.removeUserPermissions();
    notifyListeners();
  }

  // -------------------------------------------------------------
  // PERMISSION EVALUATION HELPERS
  // -------------------------------------------------------------

  /// Generic permission evaluator checking module, subModule, and action
  bool hasPermission({
    required String module,
    required String subModule,
    required PermissionAction action,
  }) {
    // 1. Admins have unrestricted access to everything
    if (isAdmin) return true;

    final targetModule = module.trim().toUpperCase();
    final targetSubModule = subModule.trim().toUpperCase();

    // 2. Find permission entry (exact module+submodule first, fallback to unique submodule)
    var item = _permissions.firstWhereOrNull(
      (p) =>
          p.moduleCode.trim().toUpperCase() == targetModule &&
          p.subModuleCode.trim().toUpperCase() == targetSubModule,
    );
    item ??= _permissions.firstWhereOrNull(
      (p) => p.subModuleCode.trim().toUpperCase() == targetSubModule,
    );

    if (item == null) return false;

    // 3. Check requested action
    switch (action) {
      case PermissionAction.view:
        return item.canView;
      case PermissionAction.add:
        return item.canAdd;
      case PermissionAction.edit:
        return item.canEdit;
      case PermissionAction.delete:
        return item.canDelete;
    }
  }

  /// Can user view the specific sub-module?
  bool canView(String module, String subModule) =>
      hasPermission(module: module, subModule: subModule, action: PermissionAction.view);

  /// Can user add/create in the specific sub-module?
  bool canAdd(String module, String subModule) =>
      hasPermission(module: module, subModule: subModule, action: PermissionAction.add);

  /// Can user edit/update in the specific sub-module?
  bool canEdit(String module, String subModule) =>
      hasPermission(module: module, subModule: subModule, action: PermissionAction.edit);

  /// Can user delete in the specific sub-module?
  bool canDelete(String module, String subModule) =>
      hasPermission(module: module, subModule: subModule, action: PermissionAction.delete);

  /// Returns true if user has ANY permission (view, add, edit, or delete) on the submodule.
  /// If the user has none of these rights (or has no entry), returns false.
  bool hasAnySubModulePermission(String module, String subModule) {
    if (isAdmin) return true;
    final targetModule = module.trim().toUpperCase();
    final targetSubModule = subModule.trim().toUpperCase();

    var item = _permissions.firstWhereOrNull(
      (p) =>
          p.moduleCode.trim().toUpperCase() == targetModule &&
          p.subModuleCode.trim().toUpperCase() == targetSubModule,
    );
    item ??= _permissions.firstWhereOrNull(
      (p) => p.subModuleCode.trim().toUpperCase() == targetSubModule,
    );

    if (item == null) return false;
    return item.canView || item.canAdd || item.canEdit || item.canDelete;
  }

  /// Determines if a menu item should be visible in navigation menus.
  /// Strictly requires user to be Admin OR possess at least one active permission
  /// (view, add, edit, or delete) for this submodule.
  bool hasMenuAccess(String module, String subModule) =>
      hasAnySubModulePermission(module, subModule);

  /// Determines if user has menu access to at least one of the given submodules.
  bool hasAnyMenuAccess(String module, List<String> subModules) {
    if (isAdmin) return true;
    return subModules.any((s) => hasMenuAccess(module, s));
  }

  /// Determines if a parent module should be visible in navigation menus.
  /// Returns true if user is Admin OR has at least one active permission (view, add, edit, delete)
  /// on ANY submodule belonging to that module.
  bool isModuleVisible(String module) {
    if (isAdmin) return true;
    final targetModule = module.trim().toUpperCase();
    return _permissions.any(
      (p) =>
          p.moduleCode.trim().toUpperCase() == targetModule &&
          (p.canView || p.canAdd || p.canEdit || p.canDelete),
    );
  }

  /// Determines if a sub-module should be visible.
  /// Honors user requirement: must have at least one permission flag (view/add/edit/delete).
  bool isSubModuleVisible(String module, String subModule) {
    return hasMenuAccess(module, subModule);
  }
}
