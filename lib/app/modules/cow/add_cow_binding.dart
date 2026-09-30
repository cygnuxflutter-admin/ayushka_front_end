import 'package:get/get.dart';
import 'add_cow_controller.dart';

/// Dependency injection binding for Add Cow module.
class AddCowBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddCowController>(() => AddCowController());
  }
}
