import 'package:get/get.dart';
import 'auth_controller.dart';

/// Dependency injection for the Auth Module
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
  }
}
