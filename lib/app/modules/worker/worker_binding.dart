import 'package:get/get.dart';
import 'department_controller.dart';
import 'worker_controller.dart';

/// Dependency injection binding for Department & Worker Management module.
class WorkerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DepartmentController>(() => DepartmentController());
    Get.lazyPut<WorkerController>(() => WorkerController());
  }
}
