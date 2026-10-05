import 'package:get/get.dart';
import 'feed_item_controller.dart';

/// Dependency injection binding for Feed Stock Items Master.
class FeedItemBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FeedItemController>(() => FeedItemController());
  }
}
