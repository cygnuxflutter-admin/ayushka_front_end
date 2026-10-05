import 'package:get/get.dart';
import 'breed_controller.dart';

/// Dependency injection binding for Breed Master module.
class BreedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BreedController>(() => BreedController());
  }
}
