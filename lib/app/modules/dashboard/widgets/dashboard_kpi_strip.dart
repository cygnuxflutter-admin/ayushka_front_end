import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../data/models/dashboard_alerts_model.dart';

/// Top Header KPI Strip displaying 4 operational alert categories with interactive tab switches and smooth hover animations.
class DashboardKpiStrip extends StatelessWidget {
  final DashboardAlertCounts counts;
  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;

  const DashboardKpiStrip({
    super.key,
    required this.counts,
    required this.selectedTabIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final isTablet = ResponsiveLayout.isTablet(context);

    final cards = [
      _KpiCardData(
        index: 0,
        title: 'Treatment Doses Due',
        count: counts.treatmentDueDoses > 0 ? counts.treatmentDueDoses : counts.criticalCases,
        subtitle: counts.criticalCases > 0
            ? '${counts.criticalCases} Critical Condition'
            : (counts.treatmentDueDoses > 0 ? 'Scheduled today' : 'All cattle doses up to date'),
        icon: PhosphorIconsRegular.firstAidKit,
        accentColor: const Color(0xFFEF4444),
        bgColor: const Color(0xFFFEF2F2),
        borderColor: const Color(0xFFFECACA),
        darkBgColor: const Color(0xFF2D1616),
      ),
      _KpiCardData(
        index: 1,
        title: 'Milk Drops Detected',
        count: counts.milkVariances,
        subtitle: counts.milkVariances > 0
            ? '±10% yield drop detected'
            : 'Morning & evening yield stable',
        icon: PhosphorIconsRegular.dropHalfBottom,
        accentColor: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFFFBEB),
        borderColor: const Color(0xFFFDE68A),
        darkBgColor: const Color(0xFF2D2415),
      ),
      _KpiCardData(
        index: 2,
        title: 'Medicines Low / Expiring',
        count: counts.lowMedicalStock + counts.expiringMedicines,
        subtitle: (counts.lowMedicalStock + counts.expiringMedicines) > 0
            ? '${counts.lowMedicalStock} Low • ${counts.expiringMedicines} Expiring'
            : 'Pharmacy inventory healthy',
        icon: PhosphorIconsRegular.pill,
        accentColor: const Color(0xFF6366F1),
        bgColor: const Color(0xFFEEF2FF),
        borderColor: const Color(0xFFC7D2FE),
        darkBgColor: const Color(0xFF1D1E3A),
      ),
      _KpiCardData(
        index: 3,
        title: 'Feed Stock Low',
        count: counts.lowFeedStock,
        subtitle: counts.lowFeedStock > 0
            ? 'Below safety buffer target'
            : 'Fodder reserves sufficient',
        icon: PhosphorIconsRegular.plant,
        accentColor: const Color(0xFF10B981),
        bgColor: const Color(0xFFECFDF5),
        borderColor: const Color(0xFFA7F3D0),
        darkBgColor: const Color(0xFF132A1F),
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _KpiCardItem(
            data: c,
            isSelected: selectedTabIndex == c.index,
            onTap: () => onTabSelected(c.index),
          ),
        )).toList(),
      );
    }

    if (isTablet) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: cards.map((c) => SizedBox(
          width: (MediaQuery.of(context).size.width - 64) / 2,
          child: _KpiCardItem(
            data: c,
            isSelected: selectedTabIndex == c.index,
            onTap: () => onTabSelected(c.index),
          ),
        )).toList(),
      );
    }

    // Desktop: Row of 4 cards
    return Row(
      children: cards.map((c) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: c.index < cards.length - 1 ? 14.0 : 0.0,
            ),
            child: _KpiCardItem(
              data: c,
              isSelected: selectedTabIndex == c.index,
              onTap: () => onTabSelected(c.index),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _KpiCardItem extends StatefulWidget {
  final _KpiCardData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _KpiCardItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_KpiCardItem> createState() => _KpiCardItemState();
}

class _KpiCardItemState extends State<_KpiCardItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = widget.data;
    final isSelected = widget.isSelected;
    final hasAlerts = data.count > 0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: _isHovered
              ? Matrix4.translationValues(0.0, -5.0, 0.0)
              : Matrix4.identity(),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? data.darkBgColor : data.bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? data.accentColor
                  : (_isHovered
                      ? data.accentColor.withValues(alpha: 0.7)
                      : (hasAlerts
                          ? data.accentColor.withValues(alpha: isDark ? 0.45 : 0.35)
                          : (isDark ? data.accentColor.withValues(alpha: 0.15) : data.borderColor))),
              width: isSelected ? 2.0 : (_isHovered ? 1.5 : (hasAlerts ? 1.4 : 1.0)),
            ),
            boxShadow: [
              if (_isHovered || isSelected)
                BoxShadow(
                  color: data.accentColor.withValues(alpha: _isHovered ? 0.28 : 0.20),
                  blurRadius: _isHovered ? 20 : 12,
                  offset: Offset(0, _isHovered ? 8 : 4),
                )
              else if (hasAlerts)
                BoxShadow(
                  color: data.accentColor.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Icon and Status Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedScale(
                    scale: _isHovered ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: data.accentColor.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        data.icon,
                        color: data.accentColor,
                        size: 20,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status Badge (Optimal vs Attention Required)
                      if (!hasAlerts)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF10B981)),
                              SizedBox(width: 4),
                              Text(
                                'ALL CLEAR',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: data.accentColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: data.accentColor.withValues(alpha: 0.45)),
                            boxShadow: [
                              BoxShadow(
                                color: data.accentColor.withValues(alpha: 0.20),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: data.accentColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: data.accentColor.withValues(alpha: 0.6),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'ACTION REQUIRED',
                                style: TextStyle(
                                  color: data.accentColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: data.accentColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Count Number with subtle animated scale
              AnimatedScale(
                scale: _isHovered ? 1.04 : 1.0,
                alignment: Alignment.centerLeft,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  '${data.count}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Title
              Text(
                data.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF334155),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),

              // Subtitle
              Text(
                data.subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.65)
                      : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // Subtle Mini Meter Bar with animated width on hover
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 3.5,
                  width: double.infinity,
                  color: data.accentColor.withValues(alpha: 0.12),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: hasAlerts ? (_isHovered ? 0.95 : 0.85) : 1.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      color: hasAlerts ? data.accentColor : const Color(0xFF10B981),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCardData {
  final int index;
  final String title;
  final int count;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final Color borderColor;
  final Color darkBgColor;

  _KpiCardData({
    required this.index,
    required this.title,
    required this.count,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
    required this.darkBgColor,
  });
}
