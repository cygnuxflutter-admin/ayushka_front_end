import 'package:get/get.dart';
import 'shed_controller.dart';

/// Dependency injection binding for Shed Module.
class ShedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShedController>(() => ShedController());
  }
}
