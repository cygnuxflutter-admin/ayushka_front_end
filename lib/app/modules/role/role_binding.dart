import 'package:get/get.dart';
import 'role_controller.dart';

/// Dependency injection binding for Role Master module.
class RoleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RoleController>(() => RoleController());
  }
}
