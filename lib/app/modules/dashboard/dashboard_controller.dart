import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/services/gaushala_session_service.dart';
import '../../data/services/storage_service.dart';
import '../cow/cow_controller.dart';
import '../../routes/app_routes.dart';

/// Controller managing Cattle Farm dashboard state and navigation.
class DashboardController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isLoading = false.obs;
  final RxBool isSidebarCollapsed = false.obs;

  // Farm Overview Metrics
  final RxInt totalCattle = 48.obs;
  final RxInt milkingCattle = 32.obs;
  final RxDouble dailyMilkLiters = 420.5.obs;
  final RxInt healthAlerts = 2.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUser();
  }

  void _loadUser() {
    currentUser.value = _storageService.getUser();
  }

  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  Future<void> refreshFarmData() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 300));
    _loadUser();
    isLoading.value = false;
  }

  Future<void> logout() async {
    CowController.clearCache();
    if (Get.isRegistered<GaushalaSessionService>()) {
      Get.find<GaushalaSessionService>().clearSession();
    }
    await _storageService.removeSelectedGaushalaId();
    await _storageService.removeToken();
    await _storageService.removeUser();
    Get.offAllNamed(AppRoutes.auth);
  }
}
