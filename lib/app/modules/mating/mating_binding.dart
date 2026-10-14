import 'package:get/get.dart';
import 'mating_controller.dart';

/// GetX dependency injection binding for Cow Mating Module.
class MatingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MatingController>(() => MatingController());
  }
}
