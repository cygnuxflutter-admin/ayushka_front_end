import 'package:get/get.dart';
import '../controllers/milk_controller.dart';
import '../services/milk_api_service.dart';

/// GetX Binding for the Milk Module.
/// Lazily injects MilkApiService and MilkController.
class MilkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MilkApiService>(() => MilkApiService());
    Get.lazyPut<MilkController>(() => MilkController());
  }
}
