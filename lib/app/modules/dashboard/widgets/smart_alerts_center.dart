import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/models/dashboard_alerts_model.dart';
import '../dashboard_controller.dart';
import '../../../routes/app_routes.dart';
import 'administer_dose_quick_dialog.dart';
import 'feed_alert_card.dart';
import 'medical_alert_card.dart';
import 'milk_alert_card.dart';
import 'quick_feed_inward_dialog.dart';
import 'quick_medical_inward_dialog.dart';
import 'treatment_alert_card.dart';

/// Main interactive Smart Alerts Center component with 4 module-wise tabs and inline quick action triggers.
class SmartAlertsCenter extends StatefulWidget {
  final DashboardController controller;

  const SmartAlertsCenter({
    super.key,
    required this.controller,
  });

  @override
  State<SmartAlertsCenter> createState() => _SmartAlertsCenterState();
}

class _SmartAlertsCenterState extends State<SmartAlertsCenter> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _medicalFilterIndex = 0; // 0: All, 1: Low Stock, 2: Expiring

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAdministerDoseDialog(BuildContext context, TreatmentAlertItem alert) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AdministerDoseQuickDialog(
        alert: alert,
        defaultDoctorName: widget.controller.currentUser.value?.name,
        onConfirm: widget.controller.administerTreatmentDose,
      ),
    );
  }

  void _openQuickMedicalInwardDialog(
    BuildContext context, {
    MedicalLowStockAlertItem? lowStockItem,
    MedicalExpiringAlertItem? expiringItem,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuickMedicalInwardDialog(
        lowStockItem: lowStockItem,
        expiringItem: expiringItem,
        onConfirm: widget.controller.quickMedicalInward,
      ),
    );
  }

  void _openQuickFeedInwardDialog(BuildContext context, FeedStockAlertItem alert) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuickFeedInwardDialog(
        alert: alert,
        onConfirm: widget.controller.quickFeedInward,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);

    return Obx(() {
      final selectedTab = widget.controller.selectedTabIndex.value;
      final counts = widget.controller.alertCounts.value;
      final isLoading = widget.controller.isLoadingAlerts.value;

      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Center Header with Title, Live Engine Tag & Refresh Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.bellSimpleRinging,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Smart Alerts & Operations Center',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Automated Telemetry & Health Engine',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: isLoading ? AppColors.primary : null,
                    ),
                    tooltip: 'Refresh Alerts',
                    onPressed: isLoading ? null : widget.controller.fetchAlertsSummary,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Tab Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _AlertsTabButton(
                    label: 'Treatments',
                    count: counts.treatmentDueDoses,
                    isSelected: selectedTab == 0,
                    icon: PhosphorIconsRegular.firstAidKit,
                    badgeColor: const Color(0xFFEF4444),
                    onTap: () {
                      widget.controller.changeTab(0);
                      setState(() => _searchQuery = '');
                      _searchCtrl.clear();
                    },
                  ),
                  const SizedBox(width: 8),
                  _AlertsTabButton(
                    label: 'Milk Variance',
                    count: counts.milkVariances,
                    isSelected: selectedTab == 1,
                    icon: PhosphorIconsRegular.dropHalfBottom,
                    badgeColor: const Color(0xFFF59E0B),
                    onTap: () {
                      widget.controller.changeTab(1);
                      setState(() => _searchQuery = '');
                      _searchCtrl.clear();
                    },
                  ),
                  const SizedBox(width: 8),
                  _AlertsTabButton(
                    label: 'Medical Stock',
                    count: counts.lowMedicalStock + counts.expiringMedicines,
                    isSelected: selectedTab == 2,
                    icon: PhosphorIconsRegular.pill,
                    badgeColor: const Color(0xFF6366F1),
                    onTap: () {
                      widget.controller.changeTab(2);
                      setState(() => _searchQuery = '');
                      _searchCtrl.clear();
                    },
                  ),
                  const SizedBox(width: 8),
                  _AlertsTabButton(
                    label: 'Feed Inventory',
                    count: counts.lowFeedStock,
                    isSelected: selectedTab == 3,
                    icon: PhosphorIconsRegular.plant,
                    badgeColor: const Color(0xFF10B981),
                    onTap: () {
                      widget.controller.changeTab(3);
                      setState(() => _searchQuery = '');
                      _searchCtrl.clear();
                    },
                  ),
                ],
              ),
            ),

            // Filter & Search Toolbar (Desktop / Tablet / Mobile)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  // Search Box
                  Expanded(
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search by tag, cow, illness, or item...',
                          hintStyle: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                  ),

                  // Medical Sub-Filter (shown only on Medical Stock Tab)
                  if (selectedTab == 2 && !isMobile) ...[
                    const SizedBox(width: 10),
                    _buildMedicalSegmentFilter(isDark),
                  ],
                ],
              ),
            ),

            // If mobile and medical tab, display sub-filter on second row
            if (selectedTab == 2 && isMobile)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _buildMedicalSegmentFilter(isDark),
              ),

            // Tab Content Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: isLoading
                  ? _buildLoadingState(isDark)
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.03),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<int>(selectedTab),
                        child: _buildSelectedTabContent(context, selectedTab),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    });
  }

  Widget _buildMedicalSegmentFilter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegmentFilterButton(
            label: 'All',
            isSelected: _medicalFilterIndex == 0,
            isDark: isDark,
            onTap: () => setState(() => _medicalFilterIndex = 0),
          ),
          _SegmentFilterButton(
            label: 'Low Stock',
            isSelected: _medicalFilterIndex == 1,
            isDark: isDark,
            onTap: () => setState(() => _medicalFilterIndex = 1),
          ),
          _SegmentFilterButton(
            label: 'Expiring Soon',
            isSelected: _medicalFilterIndex == 2,
            isDark: isDark,
            onTap: () => setState(() => _medicalFilterIndex = 2),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTabContent(BuildContext context, int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _buildTreatmentsTab(context);
      case 1:
        return _buildMilkTab(context);
      case 2:
        return _buildMedicalTab(context);
      case 3:
        return _buildFeedTab(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTreatmentsTab(BuildContext context) {
    final list = widget.controller.treatmentAlerts.where((t) {
      if (_searchQuery.isEmpty) return true;
      return t.cowTag.toLowerCase().contains(_searchQuery) ||
          (t.calfName?.toLowerCase().contains(_searchQuery) ?? false) ||
          t.diseaseName.toLowerCase().contains(_searchQuery) ||
          (t.shedNumber?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    if (list.isEmpty) {
      return _buildEmptyState(
        icon: PhosphorIconsRegular.firstAidKit,
        statusTag: 'CLINICAL ALL-CLEAR',
        title: 'All Cattle Medically Cleared & Up to Date',
        subtitle: 'Zero treatment doses or veterinary follow-ups are pending for today.',
        actionLabel: 'View Treatment Registry',
        onAction: () => Get.toNamed(AppRoutes.treatments),
      );
    }

    return Column(
      children: list.map((item) {
        return TreatmentAlertCard(
          alert: item,
          onAdminister: () => _openAdministerDoseDialog(context, item),
        );
      }).toList(),
    );
  }

  Widget _buildMilkTab(BuildContext context) {
    final list = widget.controller.milkAlerts.where((m) {
      if (_searchQuery.isEmpty) return true;
      return m.cowTag.toLowerCase().contains(_searchQuery) ||
          m.message.toLowerCase().contains(_searchQuery);
    }).toList();

    if (list.isEmpty) {
      return _buildEmptyState(
        icon: PhosphorIconsRegular.dropHalfBottom,
        statusTag: 'STABLE YIELD',
        title: 'Milk Production Yield is Completely Stable',
        subtitle: 'Morning and evening sessions are flowing within normal 10% tolerance.',
        actionLabel: 'Open Milking Records',
        onAction: () => Get.toNamed(AppRoutes.milk),
      );
    }

    return Column(
      children: list.map((item) {
        return MilkAlertCard(
          alert: item,
          onDismiss: () => widget.controller.dismissMilkAlert(item.notificationId),
        );
      }).toList(),
    );
  }

  Widget _buildMedicalTab(BuildContext context) {
    final lowStock = widget.controller.medicalLowStock.where((i) {
      if (_medicalFilterIndex == 2) return false; // Expiring only
      if (_searchQuery.isEmpty) return true;
      return i.itemName.toLowerCase().contains(_searchQuery) ||
          i.category.toLowerCase().contains(_searchQuery);
    }).toList();

    final expiring = widget.controller.medicalExpiring.where((e) {
      if (_medicalFilterIndex == 1) return false; // Low stock only
      if (_searchQuery.isEmpty) return true;
      return e.itemName.toLowerCase().contains(_searchQuery) ||
          e.batchNumber.toLowerCase().contains(_searchQuery);
    }).toList();

    if (lowStock.isEmpty && expiring.isEmpty) {
      return _buildEmptyState(
        icon: PhosphorIconsRegular.pill,
        statusTag: 'PHARMACY OPTIMAL',
        title: 'Veterinary Pharmacy Stock is Stable',
        subtitle: 'No medicines below safety threshold or approaching expiration.',
        actionLabel: 'Browse Pharmacy Stock',
        onAction: () => Get.toNamed(AppRoutes.medicalStock),
      );
    }

    return Column(
      children: [
        ...lowStock.map((l) => MedicalAlertCard(
              lowStockItem: l,
              onQuickInward: () => _openQuickMedicalInwardDialog(context, lowStockItem: l),
            )),
        ...expiring.map((e) => MedicalAlertCard(
              expiringItem: e,
              onQuickInward: () => _openQuickMedicalInwardDialog(context, expiringItem: e),
            )),
      ],
    );
  }

  Widget _buildFeedTab(BuildContext context) {
    final list = widget.controller.feedAlerts.where((f) {
      if (_searchQuery.isEmpty) return true;
      return f.itemName.toLowerCase().contains(_searchQuery);
    }).toList();

    if (list.isEmpty) {
      return _buildEmptyState(
        icon: PhosphorIconsRegular.plant,
        statusTag: 'BUFFER SAFE',
        title: 'Feed & Fodder Supplies Healthy',
        subtitle: 'Dry fodder, green silage, and mineral reserves are all above buffer target.',
        actionLabel: 'View Feed Inventory',
        onAction: () => Get.toNamed(AppRoutes.feedItems),
      );
    }

    return Column(
      children: list.map((item) {
        return FeedAlertCard(
          alert: item,
          onQuickInward: () => _openQuickFeedInwardDialog(context, item),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String statusTag,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13251A) : const Color(0xFFF4FBF6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.primary.withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // Glowing Circle Emblem
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E462B), const Color(0xFF163520)]
                    : [const Color(0xFFE8F5EC), const Color(0xFFD3EEDC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),

          // Status Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusTag,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // Subtitle
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          // Action Link
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.borderLight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 14),
          Text(
            'Analyzing live telemetry and herd alerts...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsTabButton extends StatefulWidget {
  final String label;
  final int count;
  final bool isSelected;
  final IconData icon;
  final Color badgeColor;
  final VoidCallback onTap;

  const _AlertsTabButton({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.icon,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  State<_AlertsTabButton> createState() => _AlertsTabButtonState();
}

class _AlertsTabButtonState extends State<_AlertsTabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: _isHovered && !widget.isSelected
              ? Matrix4.translationValues(0.0, -1.5, 0.0)
              : Matrix4.identity(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12)
                : (_isHovered
                    ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white)
                    : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9))),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primary
                  : (_isHovered
                      ? widget.badgeColor.withValues(alpha: 0.5)
                      : (isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.05))),
              width: widget.isSelected ? 1.5 : 1.0,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.badgeColor.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isSelected
                      ? AppColors.primary
                      : (_isHovered
                          ? widget.badgeColor
                          : (isDark ? Colors.white70 : const Color(0xFF475569))),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w600,
                  color: widget.isSelected
                      ? (isDark ? Colors.white : AppColors.primary)
                      : (_isHovered
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : (isDark ? Colors.white70 : const Color(0xFF334155))),
                ),
              ),
              if (widget.count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.isSelected ? widget.badgeColor : widget.badgeColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.badgeColor.withValues(alpha: widget.isSelected ? 0.6 : 0.35),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.badgeColor.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: widget.isSelected ? Colors.white : widget.badgeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.count}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: widget.isSelected ? Colors.white : widget.badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentFilterButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _SegmentFilterButton({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SegmentFilterButton> createState() => _SegmentFilterButtonState();
}

class _SegmentFilterButtonState extends State<_SegmentFilterButton> {
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
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? (widget.isDark ? AppColors.primary : Colors.white)
                : (_isHovered
                    ? (widget.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.6))
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
              color: widget.isSelected
                  ? (widget.isDark ? Colors.white : AppColors.primary)
                  : (_isHovered
                      ? (widget.isDark ? Colors.white : AppColors.primary)
                      : (widget.isDark ? Colors.white60 : const Color(0xFF64748B))),
            ),
          ),
        ),
      ),
    );
  }
}
