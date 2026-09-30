import 'package:get/get.dart';
import 'user_controller.dart';

/// Dependency injection binding for User Management module.
class UserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserController>(() => UserController());
  }
}
