import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../models/gaushala_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Centralized Global Gaushala Session Service.
/// Manages active Gaushala selection across all screens in the Ayushka web portal.
/// STRICT ACCESS RULE:
/// - Only Super Administrators can view all gaushalas and switch between stations.
/// - Non-SuperAdmin users (Admin, Staff, Manager, Doctor, etc.) can NEVER switch gaushalas.
///   For non-superadmin accounts, their login gaushala is the ONLY one shown and active
///   throughout the entire app ("teni login mathi je id aave tej show thashe biju kai pan show nahee thay").
class GaushalaSessionService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  /// Master list of all gaushalas from backend (accessible only by Super Admin)
  final RxList<GaushalaModel> _allGaushalas = <GaushalaModel>[].obs;

  /// Visible gaushalas list for dropdowns & selectors across the entire app
  final RxList<GaushalaModel> gaushalas = <GaushalaModel>[].obs;

  /// Active selected Gaushala
  final Rxn<GaushalaModel> selectedGaushala = Rxn<GaushalaModel>();
  final RxBool isLoading = false.obs;

  String get selectedGaushalaId {
    if (selectedGaushala.value != null && selectedGaushala.value!.id.isNotEmpty) {
      return selectedGaushala.value!.id;
    }
    final defaultG = getUserDefaultGaushala();
    if (defaultG != null && defaultG.id.isNotEmpty) {
      return defaultG.id;
    }
    final user = currentUser;
    if (user?.gaushalaId != null && user!.gaushalaId!.isNotEmpty) {
      return user.gaushalaId!;
    }
    return '';
  }

  /// Always returns the human-readable Gaushala Name, never a raw MongoDB ObjectId
  String get selectedGaushalaName {
    if (selectedGaushala.value != null && selectedGaushala.value!.gaushalaName.isNotEmpty) {
      return selectedGaushala.value!.gaushalaName;
    }
    final defaultG = getUserDefaultGaushala();
    if (defaultG != null && defaultG.gaushalaName.isNotEmpty) {
      return defaultG.gaushalaName;
    }
    final user = currentUser;
    if (user?.gaushalaName != null && user!.gaushalaName!.isNotEmpty) {
      return user.gaushalaName!;
    }
    return 'Select Gaushala';
  }

  UserModel? get currentUser => _storageService.getUser();
  bool get isSuperAdmin => currentUser?.isSuperAdmin ?? false;
  bool get canChangeGaushala => isSuperAdmin;

  /// Returns the default Gaushala for the active user session.
  /// Strictly isolates non-superadmin users to their assigned login facility.
  GaushalaModel? getUserDefaultGaushala([UserModel? user]) {
    final activeUser = user ?? currentUser;
    if (activeUser == null) return null;

    final userGId = activeUser.gaushalaId?.trim();
    final userGName = activeUser.gaushalaName?.trim();

    // 1. Try finding in loaded gaushalas list
    final match = findGaushala(userGId) ?? findGaushala(userGName);
    if (match != null) return match;

    // 2. Non-superadmin rule:
    // If not in the list yet, synthesize a valid GaushalaModel using user's login gaushala info.
    // NEVER fall back to ayushka_navsari or any other facility!
    if (!isSuperAdmin) {
      if ((userGId != null && userGId.isNotEmpty) || (userGName != null && userGName.isNotEmpty)) {
        return GaushalaModel(
          id: (userGId != null && userGId.isNotEmpty) ? userGId : (userGName ?? ''),
          gaushalaName: (userGName != null && userGName.isNotEmpty) ? userGName : (userGId ?? ''),
        );
      }
      return null;
    }

    // 3. For Super Admin only: default primary platform gaushala
    final defaultAyushka = findGaushala('ayushka_navsari') ??
        findGaushala('ayushka navsari') ??
        findGaushala('ayushka');
    if (defaultAyushka != null) return defaultAyushka;

    if (_allGaushalas.isNotEmpty) {
      return _allGaushalas.first;
    }
    if (gaushalas.isNotEmpty) {
      return gaushalas.first;
    }
    return null;
  }

  /// Look up a Gaushala by ID, Name, or normalized slug
  GaushalaModel? findGaushala(String? query) {
    if (query == null || query.trim().isEmpty) return null;
    final q = query.trim().toLowerCase();

    final sourceList = _allGaushalas.isNotEmpty ? _allGaushalas : gaushalas;

    // 1. Direct ID match
    var match = sourceList.firstWhereOrNull((g) => g.id.toLowerCase() == q);
    if (match != null) return match;

    // 2. Direct name match
    match = sourceList.firstWhereOrNull((g) => g.gaushalaName.trim().toLowerCase() == q);
    if (match != null) return match;

    // 3. Normalized slug match (e.g. ayushka_navsari vs ayushka navsari)
    final qNorm = q.replaceAll('_', '').replaceAll(' ', '').replaceAll('-', '');
    match = sourceList.firstWhereOrNull((g) {
      final nameNorm = g.gaushalaName.toLowerCase().replaceAll('_', '').replaceAll(' ', '').replaceAll('-', '');
      return nameNorm == qNorm;
    });
    if (match != null) return match;

    // 4. Substring match (length >= 3 to prevent false positive short matches)
    if (q.length >= 3) {
      match = sourceList.firstWhereOrNull((g) =>
          g.gaushalaName.toLowerCase().contains(q) || q.contains(g.gaushalaName.toLowerCase()));
    }
    return match;
  }

  /// Synchronizes the observable [gaushalas] list based on user role permissions:
  /// - Superadmin: gets all gaushalas
  /// - Non-superadmin: gets ONLY their assigned login gaushala
  void _syncGaushalaList() {
    if (isSuperAdmin) {
      gaushalas.assignAll(_allGaushalas);
    } else {
      final target = selectedGaushala.value ?? getUserDefaultGaushala();
      if (target != null) {
        gaushalas.assignAll([target]);
      } else {
        gaushalas.clear();
      }
    }
  }

  /// Fetches gaushalas list from backend
  Future<void> fetchGaushalas({bool forceReload = false}) async {
    if (_allGaushalas.isNotEmpty && !forceReload) {
      _syncGaushalaList();
      return;
    }
    isLoading.value = true;
    try {
      final list = await _apiService.getGaushalas();
      _allGaushalas.assignAll(list);
      _syncGaushalaList();
    } catch (e) {
      if (kDebugMode) {
        print('[GaushalaSessionService] fetchGaushalas error: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Initializes the active gaushala on login or app start/refresh.
  /// Strictly guarantees the user's login gaushala is default and preserved on refresh.
  Future<void> initSession({UserModel? user, bool isLogin = false}) async {
    final activeUser = user ?? currentUser;
    await fetchGaushalas();

    GaushalaModel? target;

    if (!isSuperAdmin) {
      // Non-SuperAdmin (Admin, Staff, etc.): STRICTLY locked to their login gaushala
      target = getUserDefaultGaushala(activeUser);
    } else {
      // Super Admin:
      if (isLogin) {
        target = getUserDefaultGaushala(activeUser);
      } else {
        final storedId = _storageService.getSelectedGaushalaId();
        target = findGaushala(storedId) ?? getUserDefaultGaushala(activeUser);
      }
    }

    if (target != null) {
      selectedGaushala.value = target;
      await _storageService.saveSelectedGaushalaId(target.id);

      // If user profile was missing gaushala info, enrich and persist it
      if (activeUser != null && (activeUser.gaushalaId == null || activeUser.gaushalaName == null)) {
        final updatedUser = activeUser.copyWith(
          gaushalaId: activeUser.gaushalaId ?? target.id,
          gaushalaName: activeUser.gaushalaName ?? target.gaushalaName,
        );
        await _storageService.saveUser(updatedUser);
      }
    }

    _syncGaushalaList();
  }

  /// Switch the active Gaushala globally across the entire app (Super Admin only)
  void setGaushala(GaushalaModel gaushala) {
    if (!canChangeGaushala) {
      CustomSnackbar.showWarning(
        title: 'Access Restricted',
        message: 'Only Super Administrators have permission to switch gaushalas.',
      );
      return;
    }

    if (selectedGaushala.value?.id == gaushala.id) {
      // Re-trigger reactive listeners so module screens syncing to global gaushala can reset their local filters
      selectedGaushala.refresh();
      return;
    }

    selectedGaushala.value = gaushala;
    _storageService.saveSelectedGaushalaId(gaushala.id);
  }

  /// Switch active Gaushala by ID or Name (Super Admin only)
  void setGaushalaById(String query) {
    if (!canChangeGaushala) {
      CustomSnackbar.showWarning(
        title: 'Access Restricted',
        message: 'Only Super Administrators have permission to switch gaushalas.',
      );
      return;
    }
    final match = findGaushala(query);
    if (match != null) {
      setGaushala(match);
    }
  }

  /// Clear session on logout
  void clearSession() {
    selectedGaushala.value = null;
    _allGaushalas.clear();
    gaushalas.clear();
    _storageService.removeSelectedGaushalaId();
  }
}
