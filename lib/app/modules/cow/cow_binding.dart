import 'package:get/get.dart';
import 'cow_controller.dart';

/// Dependency injection binding for Herd & Cattle (Cow List) module.
class CowBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CowController>(() => CowController());
  }
}
