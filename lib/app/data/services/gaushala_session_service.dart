import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../models/gaushala_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Centralized Global Gaushala Session Service.
/// Manages active Gaushala selection across all screens in the Ayushka web portal.
class GaushalaSessionService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxList<GaushalaModel> gaushalas = <GaushalaModel>[].obs;
  final Rxn<GaushalaModel> selectedGaushala = Rxn<GaushalaModel>();
  final RxBool isLoading = false.obs;

  String get selectedGaushalaId => selectedGaushala.value?.id ?? '';

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
  /// Priority:
  /// 1. The logged-in user's assigned gaushala (by ID, Name, or normalized slug)
  /// 2. Primary platform gaushala (ayushka_navsari or any gaushala containing 'ayushka')
  /// 3. First available gaushala
  GaushalaModel? getUserDefaultGaushala([UserModel? user]) {
    final activeUser = user ?? currentUser;
    if (activeUser != null) {
      final userGId = activeUser.gaushalaId;
      final userGName = activeUser.gaushalaName;
      final found = findGaushala(userGId) ?? findGaushala(userGName);
      if (found != null) return found;
    }

    // Default primary platform gaushala: ayushka_navsari
    final defaultAyushka = findGaushala('ayushka_navsari') ??
        findGaushala('ayushka navsari') ??
        findGaushala('ayushka');
    if (defaultAyushka != null) return defaultAyushka;

    if (gaushalas.isNotEmpty) {
      return gaushalas.first;
    }
    return null;
  }

  /// Look up a Gaushala by ID, Name, or normalized slug
  GaushalaModel? findGaushala(String? query) {
    if (query == null || query.trim().isEmpty) return null;
    final q = query.trim().toLowerCase();

    // 1. Direct ID match
    var match = gaushalas.firstWhereOrNull((g) => g.id.toLowerCase() == q);
    if (match != null) return match;

    // 2. Direct name match
    match = gaushalas.firstWhereOrNull((g) => g.gaushalaName.trim().toLowerCase() == q);
    if (match != null) return match;

    // 3. Normalized slug match (e.g. ayushka_navsari vs ayushka navsari)
    final qNorm = q.replaceAll('_', '').replaceAll(' ', '').replaceAll('-', '');
    match = gaushalas.firstWhereOrNull((g) {
      final nameNorm = g.gaushalaName.toLowerCase().replaceAll('_', '').replaceAll(' ', '').replaceAll('-', '');
      return nameNorm == qNorm;
    });
    if (match != null) return match;

    // 4. Substring match
    match = gaushalas.firstWhereOrNull((g) =>
        g.gaushalaName.toLowerCase().contains(q) || q.contains(g.gaushalaName.toLowerCase()));
    return match;
  }

  /// Fetches gaushalas list from backend
  Future<void> fetchGaushalas({bool forceReload = false}) async {
    if (gaushalas.isNotEmpty && !forceReload) return;
    isLoading.value = true;
    try {
      final list = await _apiService.getGaushalas();
      gaushalas.assignAll(list);
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
    await fetchGaushalas();

    final activeUser = user ?? currentUser;
    final defaultGaushala = getUserDefaultGaushala(activeUser);

    GaushalaModel? target;

    if (isLogin) {
      // Fresh login: strictly reset to user's assigned/default gaushala
      target = defaultGaushala;
    } else {
      // On website refresh or app launch:
      // Always restore the user's default gaushala so refresh maintains the user's assigned facility
      target = defaultGaushala;
      if (target == null) {
        final storedId = _storageService.getSelectedGaushalaId();
        target = findGaushala(storedId) ?? (gaushalas.isNotEmpty ? gaushalas.first : null);
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
  }

  /// Switch the active Gaushala globally across the entire app
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

  /// Switch active Gaushala by ID or Name
  void setGaushalaById(String query) {
    final match = findGaushala(query);
    if (match != null) {
      setGaushala(match);
    }
  }

  /// Clear session on logout
  void clearSession() {
    selectedGaushala.value = null;
    _storageService.removeSelectedGaushalaId();
  }
}
