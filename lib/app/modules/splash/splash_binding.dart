import 'package:get/get.dart';
import 'splash_controller.dart';

/// Dependency injection for the Splash Module
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(() => SplashController());
  }
}
