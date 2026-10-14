import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/cow_model.dart';
import '../../../routes/app_routes.dart';
import '../dashboard_controller.dart';
import 'quick_assign_shed_dialog.dart';

/// Production-ready Warning Alert Card displayed prominently on the Dashboard
/// when cattle are registered without an assigned housing shed.
class UnassignedShedAlertCard extends StatelessWidget {
  final DashboardController controller;
  final bool isCompact;

  const UnassignedShedAlertCard({
    super.key,
    required this.controller,
    this.isCompact = false,
  });

  void _openAssignDialog(BuildContext context, [CowModel? specificCow]) {
    final cows = controller.unassignedShedCows;
    if (cows.isEmpty) return;

    QuickAssignShedDialog.show(
      context: context,
      unassignedCows: cows.toList(),
      initialSelectedCow: specificCow,
      controller: controller,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final unassigned = controller.unassignedShedCows;
      if (unassigned.isEmpty) return const SizedBox.shrink();

      final count = unassigned.length;
      final headline = count == 1
          ? '1 Cattle requires Shed Assignment'
          : '$count Cattle registered without Shed';

      final description = count == 1
          ? 'Cattle "${unassigned.first.tagId}" is registered without an allocated shed. Assign a shed for shelter, daily diet, and health tracking.'
          : '$count animals need shed allocation to ensure proper stall housing, feeding rations, and veterinary schedules.';

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16 : 22,
          vertical: isCompact ? 14 : 18,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isDark ? const Color(0xFF261D0C) : const Color(0xFFFFFBEB),
          border: Border.all(
            color: isDark ? const Color(0xFF78450A) : const Color(0xFFFDE68A),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Badge, Title & Dismiss / Count
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning Icon Avatar
                Container(
                  width: isCompact ? 36 : 42,
                  height: isCompact ? 36 : 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    PhosphorIconsFill.warning,
                    color: Color(0xFFD97706),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Headline & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'HOUSING ALERT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$count Unassigned',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        headline,
                        style: TextStyle(
                          fontSize: isCompact ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFFEF3C7) : const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: isCompact ? 11.5 : 12.5,
                          color: isDark ? const Color(0xFFFDE68A).withValues(alpha: 0.85) : const Color(0xFFB45309),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Cattle Pills Strip
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: unassigned.take(8).map((cow) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _openAssignDialog(context, cow),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF382A12) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cow.isFemale ? PhosphorIconsRegular.genderFemale : PhosphorIconsRegular.genderMale,
                              size: 14,
                              color: cow.isFemale ? const Color(0xFFEC4899) : const Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cow.tagId,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            if (cow.calfName != null && cow.calfName!.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${cow.calfName})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: Color(0xFFD97706),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // Action Buttons
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                CustomButton(
                  text: 'Assign Shed Now',
                  icon: PhosphorIconsRegular.warehouse,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: () => _openAssignDialog(context),
                ),
                CustomButton(
                  text: 'View Cattle Herd',
                  icon: PhosphorIconsRegular.arrowRight,
                  variant: ButtonVariant.outlined,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  onPressed: () => Get.toNamed(AppRoutes.cows),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
