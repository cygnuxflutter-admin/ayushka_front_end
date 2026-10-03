import 'package:get/get.dart';
import 'medical_stock_controller.dart';

/// Dependency injection binding for Veterinary / Medical Stock Management module
class MedicalStockBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MedicalStockController>(() => MedicalStockController());
  }
}
