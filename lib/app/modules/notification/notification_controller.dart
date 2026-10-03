import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/gaushala_session_service.dart';
import '../../data/services/storage_service.dart';
import '../../routes/app_routes.dart';

/// Centralized Controller for In-App Notifications and Real-time Alert Badges.
/// Maintains automatic background polling for live due dose alerts.
class NotificationController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxInt unreadCount = 0.obs;
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isMarkingAllRead = false.obs;
  final RxnBool filterOnlyUnread = RxnBool(null); // null = all, true = only unread

  Timer? _pollingTimer;

  String get _currentGaushalaId => _gaushalaService.selectedGaushalaId;

  @override
  void onInit() {
    super.onInit();
    if (_storageService.hasToken) {
      fetchUnreadCount();
      _startPeriodicPolling();
    }

    // Auto-refresh when active gaushala changes
    ever(_gaushalaService.selectedGaushala, (_) {
      fetchUnreadCount();
      if (notifications.isNotEmpty) {
        fetchNotifications();
      }
    });
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }

  void _startPeriodicPolling() {
    _pollingTimer?.cancel();
    // Poll unread count every 45 seconds to keep alerts synchronized
    _pollingTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (_storageService.hasToken && _currentGaushalaId.isNotEmpty) {
        fetchUnreadCount();
      }
    });
  }

  /// Fetches unread alert count for the app header bell badge
  Future<void> fetchUnreadCount() async {
    final gId = _currentGaushalaId;
    if (gId.isEmpty) return;

    try {
      final count = await _apiService.getNotificationUnreadCount(gaushalaId: gId);
      unreadCount.value = count;
    } catch (e) {
      if (kDebugMode) print('[NotificationController] fetchUnreadCount error: $e');
    }
  }

  /// Fetches notifications list with optional read/unread filter
  Future<void> fetchNotifications({bool isSilent = false}) async {
    final gId = _currentGaushalaId;
    if (gId.isEmpty) return;

    if (!isSilent) isLoading.value = true;

    try {
      final result = await _apiService.getNotifications(
        gaushalaId: gId,
        isRead: filterOnlyUnread.value,
        page: 1,
        limit: 50,
      );

      notifications.assignAll(result.items);
      unreadCount.value = result.unreadCount;
    } catch (e) {
      if (kDebugMode) print('[NotificationController] fetchNotifications error: $e');
    } finally {
      if (!isSilent) isLoading.value = false;
    }
  }

  /// Sets notification filter: all vs unread
  void setFilter(bool? onlyUnread) {
    if (filterOnlyUnread.value == onlyUnread) return;
    filterOnlyUnread.value = onlyUnread;
    fetchNotifications();
  }

  /// Marks a single notification as read and navigates to the treatment case
  Future<void> onNotificationTapped(NotificationModel notification) async {
    // Mark as read immediately if not already read
    if (!notification.isRead) {
      final index = notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        notifications[index] = notification.copyWith(isRead: true, readAt: DateTime.now());
        if (unreadCount.value > 0) unreadCount.value--;
      }
      _apiService.markNotificationAsRead(notification.id);
    }

    // Close open drawer / bottom sheet if currently displayed
    if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
      Get.back();
    }

    // Navigate directly to TreatmentDetailsScreen if treatmentId is present
    if (notification.treatmentId != null && notification.treatmentId!.isNotEmpty) {
      Get.toNamed(
        AppRoutes.treatmentDetails,
        arguments: {'treatmentId': notification.treatmentId},
      );
    } else {
      // General or cow alert -> navigate to treatments list
      Get.toNamed(AppRoutes.treatments);
    }
  }

  /// Marks a single notification as read
  Future<void> markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    final index = notifications.indexWhere((n) => n.id == notification.id);
    if (index != -1) {
      notifications[index] = notification.copyWith(isRead: true, readAt: DateTime.now());
      if (unreadCount.value > 0) unreadCount.value--;
    }

    final success = await _apiService.markNotificationAsRead(notification.id);
    if (!success) {
      fetchUnreadCount();
    }
  }

  /// Marks all notifications for active Gaushala as read
  Future<void> markAllAsRead() async {
    final gId = _currentGaushalaId;
    if (gId.isEmpty) return;

    isMarkingAllRead.value = true;
    try {
      final success = await _apiService.markAllNotificationsAsRead(gId);
      if (success) {
        for (int i = 0; i < notifications.length; i++) {
          notifications[i] = notifications[i].copyWith(isRead: true);
        }
        unreadCount.value = 0;
        CustomSnackbar.showSuccess(
          title: 'Notifications',
          message: 'All notifications marked as read',
        );
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Could not mark all notifications as read',
      );
    } finally {
      isMarkingAllRead.value = false;
    }
  }

  /// Deletes a single notification
  Future<void> deleteNotification(NotificationModel notification) async {
    final wasUnread = !notification.isRead;
    notifications.removeWhere((n) => n.id == notification.id);
    if (wasUnread && unreadCount.value > 0) {
      unreadCount.value--;
    }

    final success = await _apiService.deleteNotification(notification.id);
    if (!success) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to delete notification',
      );
      fetchNotifications(isSilent: true);
    }
  }
}
