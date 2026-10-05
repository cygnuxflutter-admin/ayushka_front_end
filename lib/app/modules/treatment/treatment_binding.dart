import 'package:get/get.dart';
import '../notification/notification_controller.dart';
import 'treatment_controller.dart';

class TreatmentBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<NotificationController>()) {
      Get.put(NotificationController(), permanent: true);
    }
    Get.lazyPut<TreatmentController>(() => TreatmentController());
  }
}
