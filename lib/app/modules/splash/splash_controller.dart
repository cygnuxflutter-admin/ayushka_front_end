import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';

/// Controller managing application startup and auth check routing.
class SplashController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();

  final RxDouble opacity = 0.0.obs;
  final RxString statusMessage = 'Initializing core...'.obs;

  @override
  void onReady() {
    super.onReady();
    _startAnimationAndNavigate();
  }

  Future<void> _startAnimationAndNavigate() async {
    // If on Web, skip splash completely and navigate immediately
    if (kIsWeb) {
      if (_storageService.hasToken) {
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        Get.offAllNamed(AppRoutes.auth);
      }
      return;
    }

    // Mobile Animation & Flow
    await Future.delayed(const Duration(milliseconds: 200));
    opacity.value = 1.0;

    await Future.delayed(const Duration(milliseconds: 600));
    statusMessage.value = 'Verifying credentials...';

    await Future.delayed(const Duration(milliseconds: 600));
    final bool hasToken = _storageService.hasToken;

    if (hasToken) {
      statusMessage.value = 'Welcome back! Loading workspace...';
      await Future.delayed(const Duration(milliseconds: 400));
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.offAllNamed(AppRoutes.auth);
    }
  }
}
