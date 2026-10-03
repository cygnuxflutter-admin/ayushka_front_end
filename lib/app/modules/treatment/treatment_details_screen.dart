import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/utils/responsive_layout.dart';
import '../../core/values/app_colors.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/widgets/header_user_profile_badge.dart';
import '../../data/models/treatment_model.dart';
import '../dashboard/widgets/mobile_drawer.dart';
import '../dashboard/widgets/web_sidebar.dart';
import '../notification/widgets/notification_bell_widget.dart';
import 'treatment_details_controller.dart';
import 'widgets/dose_timeline_widget.dart';

/// Screen 3: Treatment Details & Chronological Dose Timeline Stepper Screen
class TreatmentDetailsScreen extends GetView<TreatmentDetailsController> {
  const TreatmentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBuilder: (context) => _buildMobileScaffold(context),
      tabletBuilder: (context) => _buildTabletScaffold(context),
      desktopBuilder: (context) => _buildDesktopScaffold(context),
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP SCAFFOLD
  // ---------------------------------------------------------------------------
  Widget _buildDesktopScaffold(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Web Sidebar
          Obx(
            () => WebSidebar(
              isCollapsed: controller.isSidebarCollapsed.value,
              onToggle: controller.toggleSidebar,
              currentUser: controller.currentUser.value,
              onLogout: controller.logout,
            ),
          ),

          // Main Workspace
          Expanded(
            child: Column(
              children: [
                _buildDesktopHeader(context),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CustomBrandedSpinner(message: 'Loading case medical records...'));
                    }

                    final t = controller.treatment.value;
                    if (t == null) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(PhosphorIconsRegular.warningCircle, size: 48, color: Colors.orange),
                            const SizedBox(height: 12),
                            const Text('Treatment Case Not Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: controller.backToTreatments,
                              child: const Text('Back to Treatments'),
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCaseHeaderCard(context, t),
                          const SizedBox(height: 20),
                          _buildViewTabs(context),
                          const SizedBox(height: 20),
                          _buildSelectedTabView(context, t),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TABLET SCAFFOLD
  // ---------------------------------------------------------------------------
  Widget _buildTabletScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: controller.backToTreatments,
        ),
        title: const Text('Treatment Case Details'),
        actions: [
          const NotificationBellWidget(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.refreshDetails,
          ),
        ],
      ),
      drawer: Obx(
        () => MobileDrawer(
          currentUser: controller.currentUser.value,
          onLogout: controller.logout,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CustomInlineLoader(size: 32));
        }
        final t = controller.treatment.value;
        if (t == null) {
          return const Center(child: Text('Treatment case not found.'));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCaseHeaderCard(context, t, isCompact: true),
              const SizedBox(height: 16),
              _buildViewTabs(context),
              const SizedBox(height: 16),
              _buildSelectedTabView(context, t),
            ],
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE SCAFFOLD
  // ---------------------------------------------------------------------------
  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: controller.backToTreatments,
        ),
        title: const Text('Treatment Case'),
        actions: [
          const NotificationBellWidget(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.refreshDetails,
          ),
        ],
      ),
      drawer: Obx(
        () => MobileDrawer(
          currentUser: controller.currentUser.value,
          onLogout: controller.logout,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CustomInlineLoader(size: 32));
        }
        final t = controller.treatment.value;
        if (t == null) {
          return const Center(child: Text('Treatment case not found.'));
        }
        return RefreshIndicator(
          onRefresh: controller.refreshDetails,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCaseHeaderCard(context, t, isCompact: true),
                const SizedBox(height: 14),
                _buildViewTabs(context),
                const SizedBox(height: 14),
                _buildSelectedTabView(context, t),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP TOP HEADER
  // ---------------------------------------------------------------------------
  Widget _buildDesktopHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                tooltip: 'Back to Treatments',
                onPressed: controller.backToTreatments,
              ),
              const SizedBox(width: 8),
              const Text(
                'Treatment Details & Multi-Dose Timeline',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            children: [
              const NotificationBellWidget(),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Refresh Case',
                onPressed: controller.refreshDetails,
              ),
              const SizedBox(width: 8),
              Obx(() => HeaderUserProfileBadge(user: controller.currentUser.value)),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => controller.printMedicalSummary(context),
                icon: const Icon(PhosphorIconsRegular.printer, size: 16),
                label: const Text('Export / Print Summary'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => controller.changeStatus(context),
                icon: const Icon(PhosphorIconsRegular.arrowsClockwise, size: 16),
                label: const Text('Change Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CASE HEADER CARD (Case #, Badges, Cow Profile, Doctor Info)
  // ---------------------------------------------------------------------------
  Widget _buildCaseHeaderCard(BuildContext context, CowTreatmentModel t, {bool isCompact = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final caseHeader = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(PhosphorIconsRegular.firstAidKit, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Case #${t.treatmentNumber.isNotEmpty ? t.treatmentNumber : t.id}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.status.bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: t.status.color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      t.status.label,
                      style: TextStyle(color: t.status.color, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.severity.bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: t.severity.color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.severity.icon, size: 12, color: t.severity.color),
                        const SizedBox(width: 4),
                        Text(
                          t.severity.label,
                          style: TextStyle(color: t.severity.color, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Disease: ${t.diseaseName} • Started on: ${t.treatmentStartDate != null ? DateFormat('dd MMM yyyy').format(t.treatmentStartDate!) : 'N/A'}',
                style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
            ],
          ),
        ),
      ],
    );

    final cowSummaryGrid = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : const Color(0xFFF9FAF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsRegular.cow, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Cattle Profile Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Text('Gender: ${t.cowIsFemale ? 'Female' : 'Male'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const Divider(height: 18),
          Row(
            children: [
              _buildInfoPill('Tag ID', t.displayCowTag, isBold: true),
              const SizedBox(width: 20),
              _buildInfoPill('Calf Name', t.displayCowName),
              const SizedBox(width: 20),
              _buildInfoPill('Shed', t.cowShedName ?? 'Unassigned'),
              const SizedBox(width: 20),
              _buildInfoPill('Breed', t.cowBreedName ?? 'Not specified'),
              if (t.cowWeight != null && t.cowWeight! > 0) ...[
                const SizedBox(width: 20),
                _buildInfoPill('Weight', '${t.cowWeight} kg'),
              ],
            ],
          ),
        ],
      ),
    );

    final doctorInfoCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : const Color(0xFFF9FAF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsRegular.stethoscope, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Attending Veterinary Doctor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  t.doctorType.label,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            children: [
              _buildInfoPill('Doctor Name', t.doctorName.isNotEmpty ? t.doctorName : 'In-House Vet', isBold: true),
              const SizedBox(width: 20),
              _buildInfoPill('Contact', t.doctorContact.isNotEmpty ? t.doctorContact : 'N/A'),
              const SizedBox(width: 20),
              _buildInfoPill('Doses Progress', '${t.completedDoses} / ${t.totalDoses} doses given'),
            ],
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          caseHeader,
          const SizedBox(height: 18),
          if (isCompact) ...[
            cowSummaryGrid,
            const SizedBox(height: 12),
            doctorInfoCard,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cowSummaryGrid),
                const SizedBox(width: 16),
                Expanded(child: doctorInfoCard),
              ],
            ),
          if (t.symptoms.isNotEmpty || (t.diagnosisNotes != null && t.diagnosisNotes!.isNotEmpty)) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : const Color(0xFFF3F7EF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (t.symptoms.isNotEmpty)
                    Row(
                      children: [
                        const Text('Symptoms: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Expanded(
                          child: Text(
                            t.symptoms.join(', '),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  if (t.diagnosisNotes != null && t.diagnosisNotes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Diagnosis Remarks: ${t.diagnosisNotes}',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoPill(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW TABS (Dose Stepper Timeline vs Prescription History)
  // ---------------------------------------------------------------------------
  Widget _buildViewTabs(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final tab = controller.selectedViewTab.value;
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : const Color(0xFFF0F4EC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabButton(
              index: 0,
              label: 'Visual Dose Timeline & Administration',
              icon: PhosphorIconsRegular.calendarDots,
              isSelected: tab == 0,
            ),
            const SizedBox(width: 4),
            _buildTabButton(
              index: 1,
              label: 'Prescription & Medicine History',
              icon: PhosphorIconsRegular.pill,
              isSelected: tab == 1,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => controller.selectedViewTab.value = index,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTabView(BuildContext context, CowTreatmentModel t) {
    return Obx(() {
      final tab = controller.selectedViewTab.value;
      if (tab == 0) {
        return DoseTimelineWidget(
          treatment: t,
          onAdministerDose: (doseNumber) => controller.administerDose(context, doseNumber),
        );
      } else {
        return _buildPrescriptionHistoryView(context, t);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // PRESCRIPTION & MEDICINE HISTORY TAB (Requirement Screen 3)
  // ---------------------------------------------------------------------------
  Widget _buildPrescriptionHistoryView(BuildContext context, CowTreatmentModel t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Collect all medicines administered across all doses
    final List<Map<String, dynamic>> allMeds = [];

    for (final dose in t.doses) {
      for (final med in dose.medicines) {
        allMeds.add({
          'doseNumber': dose.doseNumber,
          'doseStatus': dose.status,
          'date': dose.administeredDate ?? dose.scheduledDate,
          'administeredBy': dose.administeredBy ?? t.doctorName,
          'medicine': med,
        });
      }
    }

    // Fallback if no specific dose medicines recorded yet
    if (allMeds.isEmpty && t.medicines.isNotEmpty) {
      for (final med in t.medicines) {
        allMeds.add({
          'doseNumber': 1,
          'doseStatus': DoseStatus.given,
          'date': t.treatmentStartDate,
          'administeredBy': t.doctorName,
          'medicine': med,
        });
      }
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsRegular.prescription, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Prescription & Medicine Administration History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${allMeds.length} Prescriptions Logged',
                style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
            ],
          ),
          const Divider(height: 24),

          if (allMeds.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('No medicines recorded in this case.')),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 900),
                child: DataTable(
                  headingRowHeight: 44,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 58,
                  columns: const [
                    DataColumn(label: Text('Dose #', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Dosage', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Route', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Inventory / Outside', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Administered By', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: allMeds.map((entry) {
                    final DoseMedicineModel m = entry['medicine'] as DoseMedicineModel;
                    final int doseNum = entry['doseNumber'] as int;
                    final DateTime? dt = entry['date'] as DateTime?;
                    final String staff = entry['administeredBy'] as String;

                    return DataRow(
                      cells: [
                        DataCell(Text('Dose $doseNum', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(
                          Row(
                            children: [
                              Icon(
                                m.isStockItem ? PhosphorIconsRegular.package : PhosphorIconsRegular.pill,
                                size: 16,
                                color: m.isStockItem ? AppColors.primary : AppColors.warning,
                              ),
                              const SizedBox(width: 8),
                              Text(m.medicineName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        DataCell(Text('${m.dosage} ${m.unit}')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(m.route, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: m.isStockItem ? AppColors.primary.withValues(alpha: 0.1) : AppColors.warningBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              m.isStockItem ? 'Stock Item' : 'Outside Drug',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: m.isStockItem ? AppColors.primary : AppColors.warning,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(dt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(dt) : 'Immediate')),
                        DataCell(Text(staff)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
