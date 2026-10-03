import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/services/gaushala_session_service.dart';
import '../../../routes/app_routes.dart';
import '../dashboard_controller.dart';

/// Side panel widget displaying real-time herd telemetry, milking shift status, and 1-click farm actions.
class DashboardFarmTelemetryCard extends StatelessWidget {
  final DashboardController controller;

  const DashboardFarmTelemetryCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final gaushalaService = Get.isRegistered<GaushalaSessionService>()
        ? Get.find<GaushalaSessionService>()
        : null;

    return Column(
      children: [
        // 1. Cattle Herd Demographics Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.cow,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Herd Demographics',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Get.toNamed(AppRoutes.cows),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Total Herd Big Metric
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Obx(
                    () => Text(
                      '${controller.registeredCattleCount.value}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Active Cattle in ${gaushalaService?.selectedGaushalaName ?? "Farm"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Ratio Bar (Female vs Male)
              Obx(() {
                final total = controller.registeredCattleCount.value;
                final females = controller.femaleCattleCount.value;
                final males = controller.maleCattleCount.value;

                if (total == 0) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsRegular.info, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No cattle registered in this Gaushala yet.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final femalePct = (females / total).clamp(0.0, 1.0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: (femalePct * 100).toInt().clamp(1, 100),
                            child: Container(
                              height: 8,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          Expanded(
                            flex: ((1.0 - femalePct) * 100).toInt().clamp(1, 100),
                            child: Container(
                              height: 8,
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('Females: $females', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('Males/Calves: $males', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Milking Shift & Collection Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.dropHalfBottom,
                          color: Color(0xFFF59E0B),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Milking Telemetry',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Get.toNamed(AppRoutes.milk),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'View Log',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Live Total Milk Produced Today
              Obx(() {
                final totalMilk = controller.todayMilkProduced.value;
                final morning = controller.todayMorningProduced.value;
                final evening = controller.todayEveningProduced.value;
                final fridge = controller.fridgeMilkAvailable.value;
                final isMorningActive = DateTime.now().hour >= 4 && DateTime.now().hour < 12;
                final isEveningActive = DateTime.now().hour >= 16 && DateTime.now().hour < 21;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${totalMilk.toStringAsFixed(1)} L',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total Yield Today',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Morning vs Evening Shift Rows
                    _buildShiftMetricRow(
                      shiftName: 'Morning Shift',
                      yieldAmount: '${morning.toStringAsFixed(1)} L',
                      isActive: isMorningActive,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildShiftMetricRow(
                      shiftName: 'Evening Shift',
                      yieldAmount: '${evening.toStringAsFixed(1)} L',
                      isActive: isEveningActive,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // Fridge Storage Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(PhosphorIconsRegular.snowflake, size: 14, color: Color(0xFF3B82F6)),
                              const SizedBox(width: 6),
                              Text(
                                'Fridge Cold Storage',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${fridge.toStringAsFixed(1)} L Available',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),

              // Action button to record milk
              InkWell(
                onTap: () => Get.toNamed(AppRoutes.milk),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Center(
                    child: Text(
                      'Open Milking Log & Yield Records →',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Fast Farm Actions Hub
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Direct Farm Actions',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _QuickActionTile(
                icon: PhosphorIconsRegular.plusCircle,
                title: 'Register New Cattle',
                subtitle: 'Add tag, breed, and health baseline',
                accentColor: AppColors.primary,
                isDark: isDark,
                onTap: () => Get.toNamed(AppRoutes.addCow),
              ),
              const SizedBox(height: 8),
              _QuickActionTile(
                icon: PhosphorIconsRegular.firstAidKit,
                title: 'Schedule Treatment',
                subtitle: 'Prescribe doses or log vet checkup',
                accentColor: const Color(0xFFEF4444),
                isDark: isDark,
                onTap: () => Get.toNamed(AppRoutes.treatments),
              ),
              const SizedBox(height: 8),
              _QuickActionTile(
                icon: PhosphorIconsRegular.plant,
                title: 'Restock Fodder & Feed',
                subtitle: 'Manage bulk feed items & inward logs',
                accentColor: const Color(0xFF10B981),
                isDark: isDark,
                onTap: () => Get.toNamed(AppRoutes.feedItems),
              ),
              const SizedBox(height: 8),
              _QuickActionTile(
                icon: PhosphorIconsRegular.warehouse,
                title: 'Barn Sheds & Transfers',
                subtitle: 'Shed capacity & cattle movements',
                accentColor: const Color(0xFF3B82F6),
                isDark: isDark,
                onTap: () => Get.toNamed(AppRoutes.sheds),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShiftMetricRow({
    required String shiftName,
    required String yieldAmount,
    required bool isActive,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? const Color(0xFF282312) : const Color(0xFFFEF3C7))
            : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? const Color(0xFFF59E0B) : Colors.transparent,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFF59E0B) : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                shiftName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? const Color(0xFFB45309) : null,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                  ),
                ),
              ],
            ],
          ),
          Text(
            yieldAmount,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

}

class _QuickActionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: _isHovered
              ? Matrix4.translationValues(3.0, 0.0, 0.0)
              : Matrix4.identity(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isDark
                ? (_isHovered ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.03))
                : (_isHovered ? Colors.white : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? widget.accentColor.withValues(alpha: 0.5)
                  : (widget.isDark ? AppColors.borderDark : AppColors.borderLight),
              width: _isHovered ? 1.2 : 1.0,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.10),
                      blurRadius: 10,
                      offset: const Offset(2, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? widget.accentColor.withValues(alpha: 0.18)
                      : widget.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnimatedScale(
                  scale: _isHovered ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(widget.icon, size: 16, color: widget.accentColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: _isHovered && !widget.isDark ? widget.accentColor : null,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AnimatedSlide(
                offset: _isHovered ? const Offset(0.25, 0.0) : Offset.zero,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: _isHovered
                      ? widget.accentColor
                      : (widget.isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
