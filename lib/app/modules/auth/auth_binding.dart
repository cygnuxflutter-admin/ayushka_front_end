import 'package:get/get.dart';
import 'auth_controller.dart';

/// Dependency injection for the Auth Module
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<AuthController>()) {
      Get.delete<AuthController>(force: true);
    }
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}
