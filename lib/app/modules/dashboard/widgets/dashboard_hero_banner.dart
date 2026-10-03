import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../data/services/gaushala_session_service.dart';
import '../../../routes/app_routes.dart';
import '../dashboard_controller.dart';

/// Ultra-modern, creative hero banner for Ayushka Smart Dairy Station.
/// Features glassmorphism, organic forest gradients, live telemetry tags, and fast action shortcuts.
class DashboardHeroBanner extends StatelessWidget {
  final DashboardController controller;

  const DashboardHeroBanner({
    super.key,
    required this.controller,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getActiveShift() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) {
      return 'Morning Milking Active';
    } else if (hour >= 16 && hour < 21) {
      return 'Evening Milking Active';
    } else {
      return 'Dairy Rest & Feeding Phase';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);
    final isTablet = ResponsiveLayout.isTablet(context);

    final gaushalaService = Get.isRegistered<GaushalaSessionService>()
        ? Get.find<GaushalaSessionService>()
        : null;

    final userName = controller.currentUser.value?.name ?? 'Supervisor';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF132B1A), const Color(0xFF1A3B24)]
              : [const Color(0xFF1B432A), const Color(0xFF2C633E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B432A).withValues(alpha: isDark ? 0.4 : 0.22),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Background Aesthetic Geometric Ring Decors
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            right: 80,
            bottom: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          // Main Banner Content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 18 : 28,
              vertical: isMobile ? 20 : 26,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Live Telemetry Row
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            'LIVE STATION TELEMETRY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(PhosphorIconsRegular.clockCountdown, size: 12, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 6),
                          Text(
                            _getActiveShift(),
                            style: const TextStyle(
                              color: Color(0xFFFDE68A),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Greeting & Farm Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()}, $userName! 👋',
                            style: TextStyle(
                              fontSize: isMobile ? 22 : 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Obx(
                            () => Text(
                              'Operating under ${gaushalaService?.selectedGaushalaName ?? "Gaushala Base"} • Smart animal wellness active',
                              style: TextStyle(
                                fontSize: isMobile ? 12.5 : 14,
                                color: Colors.white.withValues(alpha: 0.82),
                                height: 1.4,
                              ),
                            ),
                          ),
                          Obx(() {
                            final totalAlerts = controller.alertCounts.value.totalAlerts;
                            final critical = controller.alertCounts.value.criticalCases;
                            if (totalAlerts == 0) return const SizedBox.shrink();

                            return Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFFBBF24).withValues(alpha: 0.7),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFBBF24),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      children: [
                                        const TextSpan(
                                          text: 'ATTENTION REQUIRED: ',
                                          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFDE68A)),
                                        ),
                                        TextSpan(
                                          text: '$totalAlerts active alerts require review',
                                        ),
                                        if (critical > 0)
                                          TextSpan(
                                            text: ' ($critical critical triage)',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFCA5A5)),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    if (!isMobile && !isTablet) ...[
                      const SizedBox(width: 20),
                      // Action Buttons on Desktop
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HeaderActionButton(
                            icon: PhosphorIconsRegular.plusCircle,
                            label: 'Register Cattle',
                            isPrimary: true,
                            onTap: () => Get.toNamed(AppRoutes.addCow),
                          ),
                          const SizedBox(width: 10),
                          _HeaderActionButton(
                            icon: PhosphorIconsRegular.dropHalfBottom,
                            label: 'Milking Log',
                            isPrimary: false,
                            onTap: () => Get.toNamed(AppRoutes.milk),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // Glassmorphic Metric Stat Pills
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    Obx(() => _StatPillItem(
                          icon: PhosphorIconsRegular.cow,
                          label: 'Herd Strength',
                          value: '${controller.registeredCattleCount.value} Cattle',
                          accentColor: const Color(0xFF6EE7B7),
                        )),
                    Obx(() {
                      final totalAlerts = controller.alertCounts.value.totalAlerts;
                      final isHealthy = totalAlerts == 0;
                      return _StatPillItem(
                        icon: isHealthy ? PhosphorIconsRegular.shieldCheck : PhosphorIconsRegular.bellSimpleRinging,
                        label: 'Operational Health',
                        value: isHealthy ? '100% Clear' : '$totalAlerts Pending',
                        accentColor: isHealthy ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                      );
                    }),
                    Obx(() {
                      final critical = controller.alertCounts.value.criticalCases;
                      final doses = controller.alertCounts.value.treatmentDueDoses;
                      final hasUrgency = critical > 0 || doses > 0;
                      return _StatPillItem(
                        icon: hasUrgency ? PhosphorIconsRegular.warningOctagon : PhosphorIconsRegular.shieldCheck,
                        label: 'Clinical Triage',
                        value: hasUrgency ? '$critical Critical • $doses Due' : 'All Clear',
                        accentColor: hasUrgency ? const Color(0xFFF87171) : const Color(0xFF6EE7B7),
                      );
                    }),
                  ],
                ),

                // If mobile or tablet, show action buttons below stat pills
                if (isMobile || isTablet) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _HeaderActionButton(
                          icon: PhosphorIconsRegular.plusCircle,
                          label: 'Register Cattle',
                          isPrimary: true,
                          onTap: () => Get.toNamed(AppRoutes.addCow),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HeaderActionButton(
                          icon: PhosphorIconsRegular.dropHalfBottom,
                          label: 'Milking Log',
                          isPrimary: false,
                          onTap: () => Get.toNamed(AppRoutes.milk),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPillItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _StatPillItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  State<_StatPillItem> createState() => _StatPillItemState();
}

class _StatPillItemState extends State<_StatPillItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: _isHovered
            ? Matrix4.translationValues(0.0, -2.5, 0.0)
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? widget.accentColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.12),
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 16, color: widget.accentColor),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                Text(
                  widget.value,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_HeaderActionButton> createState() => _HeaderActionButtonState();
}

class _HeaderActionButtonState extends State<_HeaderActionButton> {
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
              ? Matrix4.translationValues(0.0, -3.0, 0.0)
              : Matrix4.identity(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? (_isHovered ? const Color(0xFFF1FDF4) : Colors.white)
                : (_isHovered
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.12)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isPrimary
                  ? Colors.white
                  : (_isHovered ? Colors.white : Colors.white.withValues(alpha: 0.25)),
              width: 1.2,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                )
              else if (widget.isPrimary)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isPrimary ? const Color(0xFF1B432A) : Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: widget.isPrimary ? const Color(0xFF1B432A) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
