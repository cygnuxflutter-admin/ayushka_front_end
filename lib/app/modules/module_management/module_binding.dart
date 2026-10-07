import 'package:get/get.dart';
import 'module_controller.dart';

/// Dependency injection binding for Module Management module.
class ModuleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ModuleController>(() => ModuleController());
  }
}
