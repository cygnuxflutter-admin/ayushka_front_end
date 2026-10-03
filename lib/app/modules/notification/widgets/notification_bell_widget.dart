import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../notification_controller.dart';
import 'notification_drawer.dart';

/// Interactive App Bar Notification Bell Widget.
/// Displays unread badge counter and opens the slide-over notification drawer.
class NotificationBellWidget extends StatelessWidget {
  final Color? iconColor;

  const NotificationBellWidget({
    super.key,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // Lazily put NotificationController if not registered
    final controller = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController(), permanent: true);

    return Obx(() {
      final unread = controller.unreadCount.value;

      return Tooltip(
        message: unread > 0 ? '$unread unread alerts' : 'Notifications',
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                unread > 0
                    ? PhosphorIconsFill.bell
                    : PhosphorIconsRegular.bell,
                color: unread > 0
                    ? AppColors.primary
                    : (iconColor ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87)),
                size: 21,
              ),
              onPressed: () => NotificationDrawer.show(context),
            ),
            if (unread > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
