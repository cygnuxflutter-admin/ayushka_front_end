import 'package:get/get.dart';
import '../notification/notification_controller.dart';
import 'treatment_details_controller.dart';

class TreatmentDetailsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<NotificationController>()) {
      Get.put(NotificationController(), permanent: true);
    }
    Get.lazyPut<TreatmentDetailsController>(() => TreatmentDetailsController());
  }
}
