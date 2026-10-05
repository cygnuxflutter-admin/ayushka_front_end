import 'package:get/get.dart';
import 'gaushala_controller.dart';

/// Dependency injection binding for Gaushala Master module.
class GaushalaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GaushalaController>(() => GaushalaController());
  }
}
