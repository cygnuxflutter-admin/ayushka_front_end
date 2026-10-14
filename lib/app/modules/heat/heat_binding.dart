import 'package:get/get.dart';
import 'heat_controller.dart';

/// GetX dependency injection binding for Cow Heat Module.
class HeatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HeatController>(() => HeatController());
  }
}
