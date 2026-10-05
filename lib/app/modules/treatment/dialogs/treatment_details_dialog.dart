import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/core/values/app_colors.dart';
import '../../../../app/core/widgets/custom_loader.dart';
import '../../../../app/core/widgets/custom_snackbar.dart';
import '../../../data/models/treatment_model.dart';
import '../../../data/services/api_service.dart';
import '../../notification/notification_controller.dart';
import '../treatment_controller.dart';
import '../widgets/dose_timeline_widget.dart';
import '../widgets/print_treatment_summary_dialog.dart';
import 'administer_dose_dialog.dart';
import 'change_status_dialog.dart';

/// Modal dialog displaying comprehensive Treatment Case Details & Multi-Dose Timeline.
/// Avoids opening a separate full screen while keeping full desktop and mobile functionality.
class TreatmentDetailsDialog extends StatefulWidget {
  final CowTreatmentModel? treatment;
  final String? treatmentId;

  const TreatmentDetailsDialog({
    super.key,
    this.treatment,
    this.treatmentId,
  });

  static Future<bool?> show(
    BuildContext context, {
    CowTreatmentModel? treatment,
    String? treatmentId,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TreatmentDetailsDialog(
        treatment: treatment,
        treatmentId: treatmentId ?? treatment?.id,
      ),
    );
  }

  @override
  State<TreatmentDetailsDialog> createState() => _TreatmentDetailsDialogState();
}

class _TreatmentDetailsDialogState extends State<TreatmentDetailsDialog> {
  final ApiService _apiService = Get.find<ApiService>();

  CowTreatmentModel? _currentTreatment;
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _hasChanges = false;
  int _selectedTab = 0; // 0: Timeline, 1: Prescription History

  String get _treatmentId => widget.treatmentId ?? widget.treatment?.id ?? '';

  @override
  void initState() {
    super.initState();
    if (widget.treatment != null) {
      _currentTreatment = widget.treatment;
      // Silently fetch freshest details in background
      _loadTreatmentDetails(silent: true);
    } else if (_treatmentId.isNotEmpty) {
      _loadTreatmentDetails(silent: false);
    }
  }

  Future<void> _loadTreatmentDetails({bool silent = false}) async {
    if (_treatmentId.isEmpty) return;

    if (!silent) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      final t = await _apiService.getTreatmentById(_treatmentId);
      if (t != null && mounted) {
        setState(() {
          _currentTreatment = t;
        });
      }
    } catch (e) {
      if (!silent) {
        CustomSnackbar.showError(
          title: 'Error',
          message: 'Failed to load treatment details',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  void _syncParentController() {
    _hasChanges = true;
    if (Get.isRegistered<TreatmentController>()) {
      Get.find<TreatmentController>().loadAll();
    }
  }

  Future<void> _administerDose(int doseNumber) async {
    final t = _currentTreatment;
    if (t == null) return;

    final updated = await AdministerDoseDialog.show(
      context,
      treatment: t,
      doseNumber: doseNumber,
    );

    if (updated == true) {
      _syncParentController();
      await _loadTreatmentDetails(silent: true);

      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().fetchUnreadCount();
      }
    }
  }

  Future<void> _changeStatus() async {
    final t = _currentTreatment;
    if (t == null) return;

    final updated = await ChangeStatusDialog.show(
      context,
      treatment: t,
    );

    if (updated == true) {
      _syncParentController();
      await _loadTreatmentDetails(silent: true);
    }
  }

  void _printMedicalSummary() {
    final t = _currentTreatment;
    if (t == null) return;
    PrintTreatmentSummaryDialog.show(context, treatment: t);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isMobile = screenWidth < 768;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Can be used if necessary
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 28,
          vertical: isMobile ? 16 : 24,
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 1100,
            maxHeight: screenHeight * 0.92,
          ),
          child: Column(
            children: [
              // Dialog Header
              _buildHeader(context, isDark, isMobile),

              // Dialog Body
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CustomBrandedSpinner(message: 'Loading case medical records...'),
                      )
                    : _currentTreatment == null
                        ? _buildNotFoundView()
                        : _buildDialogContent(context, _currentTreatment!, isDark, isMobile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, bool isDark, bool isMobile) {
    final t = _currentTreatment;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon badge
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(PhosphorIconsRegular.firstAidKit, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        t != null
                            ? 'Case #${t.treatmentNumber.isNotEmpty ? t.treatmentNumber : t.id}'
                            : 'Treatment Case Details',
                        style: TextStyle(
                          fontSize: isMobile ? 15 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (t != null && !isMobile) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: t.status.bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: t.status.color.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          t.status.label,
                          style: TextStyle(
                            color: t.status.color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                              style: TextStyle(
                                color: t.severity.color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  t != null
                      ? 'Disease: ${t.diseaseName} • Started on: ${t.treatmentStartDate != null ? DateFormat('dd MMM yyyy').format(t.treatmentStartDate!) : 'N/A'}'
                      : 'Multi-Dose Schedule & Prescriptions',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12.5,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Actions
          if (t != null) ...[
            IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Refresh Case',
              onPressed: _isRefreshing ? null : () => _loadTreatmentDetails(silent: true),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: _printMedicalSummary,
                icon: const Icon(PhosphorIconsRegular.printer, size: 15),
                label: const Text('Export / Print Summary'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _changeStatus,
                icon: const Icon(PhosphorIconsRegular.arrowsClockwise, size: 15),
                label: const Text('Change Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ] else ...[
              IconButton(
                icon: const Icon(PhosphorIconsRegular.printer, size: 20),
                tooltip: 'Export Summary',
                onPressed: _printMedicalSummary,
              ),
              IconButton(
                icon: const Icon(PhosphorIconsRegular.arrowsClockwise, size: 20),
                tooltip: 'Change Status',
                onPressed: _changeStatus,
              ),
            ],
            const SizedBox(width: 4),
          ],

          // Close button
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(_hasChanges),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BODY CONTENT
  // ---------------------------------------------------------------------------
  Widget _buildDialogContent(
    BuildContext context,
    CowTreatmentModel t,
    bool isDark,
    bool isMobile,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Case Header Cards (Cattle Profile & Attending Doctor)
          _buildCaseHeaderCard(context, t, isDark, isMobile),
          const SizedBox(height: 18),

          // Tabs: Visual Dose Timeline & Prescription History
          _buildViewTabs(context, isDark, isMobile),
          const SizedBox(height: 18),

          // Tab View Content
          if (_selectedTab == 0)
            DoseTimelineWidget(
              treatment: t,
              isMobile: isMobile,
              onAdministerDose: _administerDose,
            )
          else
            _buildPrescriptionHistoryView(context, t, isDark),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CASE HEADER CARD (Cow Profile Summary + Doctor Info + Symptoms)
  // ---------------------------------------------------------------------------
  Widget _buildCaseHeaderCard(
    BuildContext context,
    CowTreatmentModel t,
    bool isDark,
    bool isMobile,
  ) {
    final cowSummaryGrid = Container(
      padding: const EdgeInsets.all(14),
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
              Text(
                'Gender: ${t.cowIsFemale ? 'Female' : 'Male'}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const Divider(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _buildInfoPill('Tag ID', t.displayCowTag, isBold: true),
              _buildInfoPill('Calf Name', t.displayCowName),
              _buildInfoPill('Shed', t.cowShedName ?? 'Unassigned'),
              _buildInfoPill('Breed', t.cowBreedName ?? 'Not specified'),
              if (t.cowWeight != null && t.cowWeight! > 0)
                _buildInfoPill('Weight', '${t.cowWeight} kg'),
            ],
          ),
        ],
      ),
    );

    final doctorInfoCard = Container(
      padding: const EdgeInsets.all(14),
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
          const Divider(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _buildInfoPill('Doctor Name', t.doctorName.isNotEmpty ? t.doctorName : 'In-House Vet', isBold: true),
              _buildInfoPill('Contact', t.doctorContact.isNotEmpty ? t.doctorContact : 'N/A'),
              _buildInfoPill('Doses Progress', '${t.completedDoses} / ${t.totalDoses} doses given'),
            ],
          ),
        ],
      ),
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
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
          if (isMobile) ...[
            // Status row for mobile
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.status.bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.status.color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    t.status.label,
                    style: TextStyle(
                      color: t.status.color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                        style: TextStyle(
                          color: t.severity.color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            cowSummaryGrid,
            const SizedBox(height: 12),
            doctorInfoCard,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cowSummaryGrid),
                const SizedBox(width: 14),
                Expanded(child: doctorInfoCard),
              ],
            ),

          if (t.symptoms.isNotEmpty || (t.diagnosisNotes != null && t.diagnosisNotes!.isNotEmpty)) ...[
            const SizedBox(height: 14),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
  // VIEW TABS (Timeline vs Prescription History)
  // ---------------------------------------------------------------------------
  Widget _buildViewTabs(BuildContext context, bool isDark, bool isMobile) {
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
            label: isMobile ? 'Dose Timeline' : 'Visual Dose Timeline & Administration',
            icon: PhosphorIconsRegular.calendarDots,
            isSelected: _selectedTab == 0,
          ),
          const SizedBox(width: 4),
          _buildTabButton(
            index: 1,
            label: isMobile ? 'Prescriptions' : 'Prescription & Medicine History',
            icon: PhosphorIconsRegular.pill,
            isSelected: _selectedTab == 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              size: 15,
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }



  // ---------------------------------------------------------------------------
  // PRESCRIPTION & MEDICINE HISTORY
  // ---------------------------------------------------------------------------
  Widget _buildPrescriptionHistoryView(
    BuildContext context,
    CowTreatmentModel t,
    bool isDark,
  ) {
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
      padding: const EdgeInsets.all(18),
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
              const Icon(PhosphorIconsRegular.prescription, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Prescription & Medicine Administration History',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${allMeds.length} Prescriptions Logged',
                style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
            ],
          ),
          const Divider(height: 20),

          if (allMeds.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('No medicines recorded in this case.')),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 800),
                child: DataTable(
                  headingRowHeight: 42,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 54,
                  columns: const [
                    DataColumn(label: Text('Dose #', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Dosage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Route', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Inventory / Outside', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Administered By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                  rows: allMeds.map((entry) {
                    final DoseMedicineModel m = entry['medicine'] as DoseMedicineModel;
                    final int doseNum = entry['doseNumber'] as int;
                    final DateTime? dt = entry['date'] as DateTime?;
                    final String staff = entry['administeredBy'] as String;

                    return DataRow(
                      cells: [
                        DataCell(Text('Dose $doseNum', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataCell(
                          Row(
                            children: [
                              Icon(
                                m.isStockItem ? PhosphorIconsRegular.package : PhosphorIconsRegular.pill,
                                size: 15,
                                color: m.isStockItem ? AppColors.primary : AppColors.warning,
                              ),
                              const SizedBox(width: 8),
                              Text(m.medicineName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            ],
                          ),
                        ),
                        DataCell(Text('${m.dosage} ${m.unit}', style: const TextStyle(fontSize: 12))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(m.route, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5)),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: m.isStockItem ? AppColors.primary.withValues(alpha: 0.1) : AppColors.warningBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              m.isStockItem ? 'Stock Item' : 'Outside Drug',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: m.isStockItem ? AppColors.primary : AppColors.warning,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(
                          dt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(dt) : 'Immediate',
                          style: const TextStyle(fontSize: 11.5),
                        )),
                        DataCell(Text(staff, style: const TextStyle(fontSize: 12))),
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

  Widget _buildNotFoundView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(PhosphorIconsRegular.warningCircle, size: 48, color: Colors.orange),
          const SizedBox(height: 12),
          const Text('Treatment Case Not Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
