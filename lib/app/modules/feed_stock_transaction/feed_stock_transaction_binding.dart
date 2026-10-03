import 'package:get/get.dart';
import 'feed_stock_transaction_controller.dart';

/// Dependency injection binding for Feed Stock Transactions.
class FeedStockTransactionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FeedStockTransactionController>(() => FeedStockTransactionController());
  }
}
