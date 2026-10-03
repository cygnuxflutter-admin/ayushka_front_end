import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_loader.dart';
import '../../../data/models/notification_model.dart';
import '../notification_controller.dart';

/// Clean slide-over drawer / modal sheet for In-App Notifications
class NotificationDrawer extends StatelessWidget {
  const NotificationDrawer({super.key});

  static void show(BuildContext context) {
    final controller = Get.find<NotificationController>();
    controller.fetchNotifications();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 700;

    if (isDesktop) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Notifications',
        barrierColor: Colors.black.withValues(alpha: 0.35),
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (ctx, anim1, anim2) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 440,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(-4, 0),
                    ),
                  ],
                ),
                child: const NotificationDrawer(),
              ),
            ),
          );
        },
        transitionBuilder: (ctx, anim1, anim2, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const NotificationDrawer(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Top Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  PhosphorIconsRegular.bellRinging,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Obx(() {
                final unread = controller.unreadCount.value;
                if (unread <= 0) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unread new',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
              const Spacer(),
              // Mark all as read button
              Obx(() {
                if (controller.unreadCount.value <= 0) return const SizedBox.shrink();
                return TextButton.icon(
                  onPressed: controller.isMarkingAllRead.value ? null : controller.markAllAsRead,
                  icon: controller.isMarkingAllRead.value
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(PhosphorIconsRegular.checks, size: 16),
                  label: const Text(
                    'Mark all read',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                );
              }),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // Filter chips bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : const Color(0xFFF9FAF7),
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 0.8,
              ),
            ),
          ),
          child: Obx(() {
            final onlyUnread = controller.filterOnlyUnread.value;
            return Row(
              children: [
                _buildFilterChip(
                  context,
                  label: 'All Alerts',
                  isSelected: onlyUnread == null,
                  onTap: () => controller.setFilter(null),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Unread Only',
                  badgeCount: controller.unreadCount.value,
                  isSelected: onlyUnread == true,
                  onTap: () => controller.setFilter(true),
                ),
              ],
            );
          }),
        ),

        // Notifications List Body
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CustomInlineLoader(size: 28),
              );
            }

            final items = controller.notifications;
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.bellSimpleSlash,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'No Alerts or Notifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        controller.filterOnlyUnread.value == true
                            ? 'You have read all pending dose notifications!'
                            : 'All cow treatments and multi-dose schedules are currently up-to-date.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.fetchNotifications(isSilent: true),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: items.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final notif = items[index];
                  return _NotificationCard(
                    notification: notif,
                    onTap: () => controller.onNotificationTapped(notif),
                    onDelete: () => controller.deleteNotification(notif),
                    onMarkRead: () => controller.markAsRead(notif),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
            if (badgeCount != null && badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onMarkRead;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
    required this.onMarkRead,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final notif = widget.notification;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnread = !notif.isRead;

    // Detect dose alert vs general alert
    final bool isDoseAlert = notif.title.toLowerCase().contains('dose') ||
        notif.message.toLowerCase().contains('dose');

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUnread
                ? (isDark
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : const Color(0xFFF3F7EF))
                : (isDark ? AppColors.cardDark : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnread
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : (_isHovered
                      ? (isDark ? AppColors.borderDark : AppColors.borderLight)
                      : (isDark ? AppColors.borderDark.withValues(alpha: 0.5) : const Color(0xFFEDF2E8))),
              width: isUnread ? 1.4 : 1.0,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isDoseAlert
                      ? (isUnread ? AppColors.warningBg : Colors.grey.shade100)
                      : (isUnread ? AppColors.infoBg : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDoseAlert ? PhosphorIconsRegular.syringe : PhosphorIconsRegular.firstAid,
                  size: 18,
                  color: isDoseAlert ? AppColors.warning : AppColors.info,
                ),
              ),
              const SizedBox(width: 12),

              // Title, Message, Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          PhosphorIconsRegular.clock,
                          size: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notif.timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                        if (notif.treatmentId != null && notif.treatmentId!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• View Case →',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (_isHovered) ...[
                          InkWell(
                            onTap: widget.onDelete,
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.all(2.0),
                              child: Icon(
                                PhosphorIconsRegular.trash,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
