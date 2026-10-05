import 'package:get/get.dart';
import 'dashboard_controller.dart';

/// Dependency injection for the Dashboard Module
class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
  }
}
