import 'package:get/get.dart';
import 'type_controller.dart';

/// Dependency injection binding for the Type Master module.
class TypeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TypeController>(() => TypeController());
  }
}
