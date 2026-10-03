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

  List<PermissionItemModel> get permissions => _permissions.toList();
  bool get isLoading => _isLoading.value;
  bool get isInitialized => _isInitialized.value;

  /// Returns true if the user has Administrator privileges
  bool get isAdmin {
    if (_isAdmin.value) return true;
    final user = _storageService.getUser();
    if (user != null && user.isAdmin) return true;
    final cachedAdmin = _storageService.getIsAdminPermission();
    if (cachedAdmin == true) return true;
    return false;
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
    if (cached != null) {
      _permissions.assignAll(cached);
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

      // Save to local cache
      await _storageService.saveUserPermissions(response.permissions, response.isAdmin);

      if (kDebugMode) {
        print('[RBAC] Loaded ${response.permissions.length} permissions. IsAdmin: ${response.isAdmin}');
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

    // 2. Find permission entry
    final item = _permissions.firstWhereOrNull(
      (p) =>
          p.moduleCode.toUpperCase() == targetModule &&
          p.subModuleCode.toUpperCase() == targetSubModule,
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

  /// Determines if a parent module should be visible in navigation menus.
  /// Returns true if user is Admin OR has canView == true on ANY submodule in that module.
  bool isModuleVisible(String module) {
    if (isAdmin) return true;
    final targetModule = module.trim().toUpperCase();
    return _permissions.any(
      (p) => p.moduleCode.toUpperCase() == targetModule && p.canView,
    );
  }

  /// Determines if a sub-module should be visible
  bool isSubModuleVisible(String module, String subModule) {
    return canView(module, subModule);
  }
}
