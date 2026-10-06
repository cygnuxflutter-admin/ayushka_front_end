import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/core/values/app_colors.dart';
import '../../../../app/core/values/app_constants.dart';
import '../../../../app/core/widgets/custom_button.dart';
import '../../../../app/core/widgets/custom_dropdown_search.dart';
import '../../../../app/core/widgets/custom_loader.dart';
import '../../../../app/core/widgets/custom_snackbar.dart';
import '../../../../app/core/widgets/custom_text_field.dart';
import '../../../data/models/cow_model.dart';
import '../../../data/models/medical_item_model.dart';
import '../../../data/models/treatment_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/gaushala_session_service.dart';

class _MedicineDraft {
  bool isStockItem = true;
  MedicalItemModel? selectedStockItem;
  final TextEditingController medicineNameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController(text: '10 ml');
  String unit = 'ML';
  String route = 'IM';
  final TextEditingController notesController = TextEditingController();

  _MedicineDraft({bool stock = true}) {
    isStockItem = stock;
  }

  void dispose() {
    medicineNameController.dispose();
    dosageController.dispose();
    notesController.dispose();
  }

  String get finalMedicineName => isStockItem
      ? (selectedStockItem?.itemName ?? '')
      : medicineNameController.text.trim();

  Map<String, dynamic> toJson() {
    return {
      'isStockItem': isStockItem,
      'itemId': isStockItem ? selectedStockItem?.id : null,
      'medicineName': finalMedicineName,
      'dosage': dosageController.text.trim(),
      'unit': unit,
      'route': route,
      if (notesController.text.trim().isNotEmpty)
        'notes': notesController.text.trim(),
    };
  }
}

/// Comprehensive Multi-Step Dialog to Create a New Cow Treatment Case
class AddTreatmentDialog extends StatefulWidget {
  const AddTreatmentDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AddTreatmentDialog(),
    );
  }

  @override
  State<AddTreatmentDialog> createState() => _AddTreatmentDialogState();
}

class _AddTreatmentDialogState extends State<AddTreatmentDialog> {
  final ApiService _apiService = Get.find<ApiService>();
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();

  int _currentStep = 0; // 0: Cow & Case Info, 1: Multi-Dose Scheduling, 2: Prescribed Medicines
  bool _isLoadingDropdowns = true;
  bool _isSubmitting = false;

  // Dropdown options
  List<CowModel> _cows = [];
  List<MedicalItemModel> _stockItems = [];

  // Form Fields - Step 1: Cow & Case Info
  CowModel? _selectedCow;
  final TextEditingController _cowSearchController = TextEditingController();
  final TextEditingController _diseaseController = TextEditingController();
  final List<String> _selectedSymptoms = [];
  final TextEditingController _symptomInputController = TextEditingController();
  TreatmentSeverity _selectedSeverity = TreatmentSeverity.moderate;
  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _doctorContactController = TextEditingController();
  DoctorType _selectedDoctorType = DoctorType.inHouse;
  DateTime _treatmentStartDate = DateTime.now();
  final TextEditingController _diagnosisNotesController = TextEditingController();

  // Form Fields - Step 2: Multi-Dose Scheduling
  final TextEditingController _totalDosesController = TextEditingController(text: '3');
  final TextEditingController _doseIntervalController = TextEditingController(text: '1');

  // Form Fields - Step 3: Prescribed Medicines
  final List<_MedicineDraft> _medicineDrafts = [];

  // Disease Suggestions
  final List<String> _commonDiseases = [
    'Acute Bovine Mastitis',
    'Subclinical Mastitis',
    'Foot and Mouth Disease (FMD)',
    'Bovine Respiratory Disease (BRD)',
    'Milk Fever (Hypocalcemia)',
    'Ruminal Bloat / Tympany',
    'Bovine Ketosis',
    'Foot Rot / Lameness',
    'Severe Wound / Laceration',
    'Metritis / Endometritis',
    'Pneumonia',
    'Ephemeral Fever',
  ];

  // Common Symptoms
  final List<String> _suggestedSymptoms = [
    'Swollen / Hard Udder',
    'High Fever (>103°F)',
    'Loss of Appetite (Off Feed)',
    'Reduced Milk Yield',
    'Nasal Discharge',
    'Labored Breathing',
    'Lameness / Limping',
    'Severe Lethargy / Dullness',
    'Excessive Salivation',
    'Abdominal Swelling',
    'Diarrhea / Scours',
    'Dehydration',
  ];

  final List<String> _medicineUnits = [
    'ML',
    'BOLUS',
    'VIAL',
    'TABLET',
    'PIECE',
    'GM',
    'KG',
    'TUBE',
    'AMPUL',
  ];

  final List<String> _medicineRoutes = [
    'IM',
    'IV',
    'ORAL',
    'TOPICAL',
    'SC',
    'INTRAMAMMARY',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialDropdowns();

    // Default 1 initial medicine draft (From Inventory)
    _medicineDrafts.add(_MedicineDraft(stock: true));
  }

  @override
  void dispose() {
    _cowSearchController.dispose();
    _diseaseController.dispose();
    _symptomInputController.dispose();
    _doctorNameController.dispose();
    _doctorContactController.dispose();
    _diagnosisNotesController.dispose();
    _totalDosesController.dispose();
    _doseIntervalController.dispose();
    for (final draft in _medicineDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialDropdowns() async {
    final gId = _gaushalaService.selectedGaushalaId;
    if (gId.isEmpty) {
      setState(() => _isLoadingDropdowns = false);
      return;
    }

    try {
      final results = await Future.wait([
        _apiService.getCows(gaushalaId: gId),
        _apiService.getMedicalItems(gaushalaId: gId, limit: 100),
      ]);

      final cowRes = results[0] as CowListResponse;
      final medRes = results[1] as MedicalItemPaginatedResult;

      setState(() {
        _cows = cowRes.allCows.where((c) => !c.isDelete && !c.isDead).toList();
        _stockItems = medRes.items;
        _isLoadingDropdowns = false;
      });
    } catch (e) {
      setState(() => _isLoadingDropdowns = false);
    }
  }

  void _addMedicineDraft({bool fromStock = true}) {
    setState(() {
      _medicineDrafts.add(_MedicineDraft(stock: fromStock));
    });
  }

  void _removeMedicineDraft(int index) {
    if (_medicineDrafts.length <= 1) {
      CustomSnackbar.showWarning(
        title: 'Medicine Required',
        message: 'A treatment case must have at least one prescribed medicine',
      );
      return;
    }
    setState(() {
      _medicineDrafts[index].dispose();
      _medicineDrafts.removeAt(index);
    });
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  void _addCustomSymptom() {
    final text = _symptomInputController.text.trim();
    if (text.isNotEmpty && !_selectedSymptoms.contains(text)) {
      setState(() {
        _selectedSymptoms.add(text);
        _symptomInputController.clear();
      });
    }
  }

  bool _validateStep1() {
    if (_selectedCow == null) {
      CustomSnackbar.showWarning(title: 'Validation', message: 'Please select a cow');
      return false;
    }
    if (_diseaseController.text.trim().isEmpty) {
      CustomSnackbar.showWarning(title: 'Validation', message: 'Please enter or select a disease name');
      return false;
    }
    if (_doctorNameController.text.trim().isEmpty) {
      CustomSnackbar.showWarning(title: 'Validation', message: 'Please provide treating doctor name');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    final doses = int.tryParse(_totalDosesController.text.trim()) ?? 0;
    if (doses < 1 || doses > 15) {
      CustomSnackbar.showWarning(
        title: 'Validation',
        message: 'Total doses must be between 1 and 15',
      );
      return false;
    }
    final interval = int.tryParse(_doseIntervalController.text.trim()) ?? 0;
    if (interval < 1 || interval > 90) {
      CustomSnackbar.showWarning(
        title: 'Validation',
        message: 'Dose interval must be between 1 and 90 days',
      );
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    if (_medicineDrafts.isEmpty) {
      CustomSnackbar.showWarning(title: 'Validation', message: 'Please add at least one medicine');
      return false;
    }
    for (int i = 0; i < _medicineDrafts.length; i++) {
      final draft = _medicineDrafts[i];
      if (draft.isStockItem && draft.selectedStockItem == null) {
        CustomSnackbar.showWarning(
          title: 'Validation',
          message: 'Please choose an inventory medicine for row #${i + 1}',
        );
        return false;
      }
      if (!draft.isStockItem && draft.medicineNameController.text.trim().isEmpty) {
        CustomSnackbar.showWarning(
          title: 'Validation',
          message: 'Please enter medicine name for row #${i + 1}',
        );
        return false;
      }
      if (draft.dosageController.text.trim().isEmpty) {
        CustomSnackbar.showWarning(
          title: 'Validation',
          message: 'Please specify dosage for row #${i + 1}',
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _submitTreatment() async {
    if (!_validateStep1() || !_validateStep2() || !_validateStep3()) return;

    setState(() => _isSubmitting = true);

    try {
      final gId = _gaushalaService.selectedGaushalaId;
      final totalDoses = int.tryParse(_totalDosesController.text.trim()) ?? 1;
      final intervalDays = int.tryParse(_doseIntervalController.text.trim()) ?? 1;

      final payload = {
        'gaushalaId': gId,
        'cowId': _selectedCow!.id,
        if (_selectedCow!.shed?.id != null && _selectedCow!.shed!.id.isNotEmpty)
          'shedId': _selectedCow!.shed!.id,
        'diseaseName': _diseaseController.text.trim(),
        'symptoms': _selectedSymptoms,
        'diagnosisNotes': _diagnosisNotesController.text.trim(),
        'severity': _selectedSeverity.code,
        'doctorName': _doctorNameController.text.trim(),
        'doctorContact': _doctorContactController.text.trim(),
        'doctorType': _selectedDoctorType.code,
        'treatmentStartDate': _treatmentStartDate.toIso8601String(),
        'totalDoses': totalDoses,
        'doseIntervalDays': intervalDays,
        'medicines': _medicineDrafts.map((d) => d.toJson()).toList(),
      };

      final created = await _apiService.createTreatment(payload);

      if (created != null) {
        CustomSnackbar.showSuccess(
          title: 'Treatment Created',
          message: 'Treatment case created. Dose 1 marked as given automatically.',
        );
        if (mounted) {
          Navigator.of(context).pop(true);
        } else if (Get.isDialogOpen ?? false) {
          Get.back(result: true);
        }
      } else {
        CustomSnackbar.showError(
          title: 'Submission Failed',
          message: 'Could not create treatment case. Please verify the entries.',
        );
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to create treatment: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 16 : 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840, maxHeight: 760),
        child: Column(
          children: [
            // Dialog Header
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 14 : 18,
              ),
              decoration: BoxDecoration(
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
                    child: const Icon(PhosphorIconsRegular.plusCircle, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create Cow Treatment Case',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Register medical case, configure multi-dose schedule & prescribe medicines',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),

            // Step Indicator Tabs
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : const Color(0xFFFBFDF9),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 0.8,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStepTab(
                      index: 0,
                      label: '1. Cow & Case Info',
                      icon: PhosphorIconsRegular.cow,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    _buildStepTab(
                      index: 1,
                      label: '2. Multi-Dose Schedule',
                      icon: PhosphorIconsRegular.calendarCheck,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    _buildStepTab(
                      index: 2,
                      label: '3. Prescribed Medicines',
                      icon: PhosphorIconsRegular.pill,
                    ),
                  ],
                ),
              ),
            ),

            // Step Content
            Expanded(
              child: _isLoadingDropdowns
                  ? const Center(child: CustomBrandedSpinner(message: 'Loading farm herd & stock items...'))
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                      child: _buildCurrentStepContent(context),
                    ),
            ),

            // Dialog Footer / Actions
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 24,
                vertical: isMobile ? 12 : 16,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _currentStep--),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  if (_currentStep < 2)
                    CustomButton(
                      text: 'Next Step →',
                      width: isMobile ? 110 : 130,
                      height: 42,
                      onPressed: () {
                        if (_currentStep == 0 && _validateStep1()) {
                          setState(() => _currentStep = 1);
                        } else if (_currentStep == 1 && _validateStep2()) {
                          setState(() => _currentStep = 2);
                        }
                      },
                    )
                  else
                    CustomButton(
                      text: isMobile ? 'Create Case' : 'Create Treatment Case',
                      icon: PhosphorIconsRegular.check,
                      width: isMobile ? 140 : 200,
                      height: 42,
                      isLoading: _isSubmitting,
                      onPressed: _submitTreatment,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTab({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _currentStep == index;
    final isPassed = _currentStep > index;

    return InkWell(
      onTap: () {
        if (index == 0) {
          setState(() => _currentStep = 0);
        } else if (index == 1 && _validateStep1()) {
          setState(() => _currentStep = 1);
        } else if (index == 2 && _validateStep1() && _validateStep2()) {
          setState(() => _currentStep = 2);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isPassed ? AppColors.successBg : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPassed ? Icons.check_circle_rounded : icon,
              size: 16,
              color: isSelected
                  ? AppColors.primary
                  : (isPassed ? AppColors.success : Colors.grey),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : (isPassed ? AppColors.success : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildStep1CowAndCase(context);
      case 1:
        return _buildStep2Scheduling(context);
      case 2:
        return _buildStep3Medicines(context);
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // HERD & CATTLE DATE FIELD (Matching AddCowScreen date field design)
  // ---------------------------------------------------------------------------
  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required String displayValue,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    bool isRequired = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayValue.isEmpty ? hint : displayValue,
                    style: TextStyle(
                      fontSize: 14,
                      color: displayValue.isEmpty
                          ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1: COW & CASE INFO
  // ---------------------------------------------------------------------------
  Widget _buildStep1CowAndCase(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cow Selection Dropdown
        CustomDropdownSearch<CowModel>(
          label: 'Select Cattle / Cow',
          isRequired: true,
          prefixIcon: PhosphorIconsRegular.cow,
          hint: 'Search & Pick Cow (Tag ID / Calf Name)',
          searchable: true,
          searchHint: 'Type Tag ID, Calf Name, or Shed...',
          items: _cows,
          selectedItem: _selectedCow,
          itemAsString: (cow) {
            final tag = cow.tagId;
            final name = cow.calfName != null && cow.calfName!.trim().isNotEmpty
                ? cow.calfName!.trim()
                : 'Unnamed';
            final shed = cow.shed?.shedName ?? 'Unassigned';
            return '$tag • $name (Shed: $shed)';
          },
          compareFn: (a, b) => a.id == b.id,
          onChanged: (val) => setState(() => _selectedCow = val),
          customItemBuilder: (ctx, cow, isDisabled, isSelected) {
            final tag = cow.tagId;
            final name = cow.calfName != null && cow.calfName!.trim().isNotEmpty
                ? cow.calfName!.trim()
                : 'Unnamed';
            final shed = cow.shed?.shedName ?? 'Unassigned';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(PhosphorIconsRegular.cow, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$tag • $name',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gender: ${cow.isFemale ? 'Female' : 'Male'} • Shed: $shed',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
                ],
              ),
            );
          },
        ),

        // Selected Cow Quick Preview Badge
        if (_selectedCow != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsRegular.cow, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Selected: ${_selectedCow!.tagId} (${_selectedCow!.calfName ?? 'Cattle'})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  'Gender: ${_selectedCow!.isFemale ? 'Female' : 'Male'} • Shed: ${_selectedCow!.shed?.shedName ?? 'None'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Disease Name
        CustomTextField(
          label: 'Disease / Clinical Condition *',
          hint: 'e.g. Acute Bovine Mastitis, FMD, Fever, Bloat...',
          controller: _diseaseController,
          prefixIcon: const Icon(PhosphorIconsRegular.firstAid, size: 18),
        ),
        const SizedBox(height: 8),
        // Common disease suggestion chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _commonDiseases.map((d) {
            return ActionChip(
              label: Text(d, style: const TextStyle(fontSize: 11)),
              backgroundColor: isDark ? AppColors.cardDark : const Color(0xFFF3F7EF),
              side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              onPressed: () {
                setState(() => _diseaseController.text = d);
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Symptoms Multi-Select Tags
        Text(
          'Observed Symptoms',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _suggestedSymptoms.map((sym) {
            final isSelected = _selectedSymptoms.contains(sym);
            return FilterChip(
              selected: isSelected,
              label: Text(sym, style: const TextStyle(fontSize: 11.5)),
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => _toggleSymptom(sym),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _symptomInputController,
          hint: 'Add custom symptom (e.g. Subnormal temperature)...',
          prefixIcon: const Icon(PhosphorIconsRegular.plusCircle, size: 18),
          suffixIcon: IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: _addCustomSymptom,
            tooltip: 'Add Symptom',
          ),
          onSubmitted: (_) => _addCustomSymptom(),
        ),

        const SizedBox(height: 20),

        // Severity & Date Row
        if (MediaQuery.of(context).size.width < 650) ...[
          CustomDropdownSearch<TreatmentSeverity>(
            label: 'Severity Level',
            isRequired: true,
            prefixIcon: PhosphorIconsRegular.warning,
            hint: 'Select severity level',
            items: TreatmentSeverity.values,
            selectedItem: _selectedSeverity,
            itemAsString: (s) => s.label,
            onChanged: (val) {
              if (val != null) setState(() => _selectedSeverity = val);
            },
            customItemBuilder: (ctx, sev, isDisabled, isSelected) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                child: Row(
                  children: [
                    Icon(sev.icon, size: 16, color: sev.color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sev.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: sev.color,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _buildDateField(
            context: context,
            label: 'Treatment Start Date',
            isRequired: true,
            displayValue: DateFormat('dd MMM yyyy').format(_treatmentStartDate),
            hint: 'Select Start Date',
            icon: PhosphorIconsRegular.calendarBlank,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _treatmentStartDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) setState(() => _treatmentStartDate = picked);
            },
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Severity Dropdown
              Expanded(
                child: CustomDropdownSearch<TreatmentSeverity>(
                  label: 'Severity Level',
                  isRequired: true,
                  prefixIcon: PhosphorIconsRegular.warning,
                  hint: 'Select severity level',
                  items: TreatmentSeverity.values,
                  selectedItem: _selectedSeverity,
                  itemAsString: (s) => s.label,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSeverity = val);
                  },
                  customItemBuilder: (ctx, sev, isDisabled, isSelected) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          Icon(sev.icon, size: 16, color: sev.color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              sev.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: sev.color,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Start Date Picker
              Expanded(
                child: _buildDateField(
                  context: context,
                  label: 'Treatment Start Date',
                  isRequired: true,
                  displayValue: DateFormat('dd MMM yyyy').format(_treatmentStartDate),
                  hint: 'Select Start Date',
                  icon: PhosphorIconsRegular.calendarBlank,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _treatmentStartDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) setState(() => _treatmentStartDate = picked);
                  },
                ),
              ),
            ],
          ),

        const SizedBox(height: 20),

        // Doctor Name & Contact & Type
        if (MediaQuery.of(context).size.width < 650) ...[
          CustomTextField(
            label: 'Doctor / Treating Vet Name *',
            hint: 'e.g. Dr. Rajesh Sharma',
            controller: _doctorNameController,
            prefixIcon: const Icon(PhosphorIconsRegular.stethoscope, size: 18),
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Vet Contact #',
            hint: 'e.g. 9876543210',
            controller: _doctorContactController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(15),
            ],
            prefixIcon: const Icon(PhosphorIconsRegular.phone, size: 18),
          ),
          const SizedBox(height: 14),
          CustomDropdownSearch<DoctorType>(
            label: 'Doctor Type',
            prefixIcon: PhosphorIconsRegular.userGear,
            hint: 'Doctor Type',
            items: DoctorType.values,
            selectedItem: _selectedDoctorType,
            itemAsString: (d) => d.label,
            onChanged: (val) {
              if (val != null) setState(() => _selectedDoctorType = val);
            },
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: CustomTextField(
                  label: 'Doctor / Treating Vet Name *',
                  hint: 'e.g. Dr. Rajesh Sharma',
                  controller: _doctorNameController,
                  prefixIcon: const Icon(PhosphorIconsRegular.stethoscope, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: CustomTextField(
                  label: 'Vet Contact #',
                  hint: 'e.g. 9876543210',
                  controller: _doctorContactController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  prefixIcon: const Icon(PhosphorIconsRegular.phone, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: CustomDropdownSearch<DoctorType>(
                  label: 'Doctor Type',
                  prefixIcon: PhosphorIconsRegular.userGear,
                  hint: 'Doctor Type',
                  items: DoctorType.values,
                  selectedItem: _selectedDoctorType,
                  itemAsString: (d) => d.label,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDoctorType = val);
                  },
                ),
              ),
            ],
          ),

        const SizedBox(height: 20),

        // Clinical / Diagnosis Notes
        CustomTextField(
          label: 'Diagnosis & Clinical Examination Notes',
          hint: 'e.g. Cow exhibits udder swelling on right rear quarter with watery milk, mild pain response...',
          controller: _diagnosisNotesController,
          maxLines: 2,
          prefixIcon: const Icon(PhosphorIconsRegular.notepad, size: 18),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: MULTI-DOSE SCHEDULING
  // ---------------------------------------------------------------------------
  Widget _buildStep2Scheduling(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final parsedDoses = int.tryParse(_totalDosesController.text.trim()) ?? 0;
    // Strictly clamp preview between 0 and 15 so UI never hangs
    final totalDoses = parsedDoses.clamp(0, 15);
    final parsedInterval = int.tryParse(_doseIntervalController.text.trim()) ?? 1;
    final intervalDays = parsedInterval > 0 ? parsedInterval : 1;

    // Calculate preview dates
    final List<DateTime> scheduleDates = [];
    if (totalDoses > 0) {
      for (int i = 0; i < totalDoses; i++) {
        scheduleDates.add(_treatmentStartDate.add(Duration(days: i * intervalDays)));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.infoBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(PhosphorIconsRegular.info, color: AppColors.info, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Automated Multi-Dose Scheduler: Set total dosage cycles (1 - 15) and day intervals. Dose 1 will be marked as GIVEN immediately upon case creation.',
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimaryLight),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (MediaQuery.of(context).size.width < 650) ...[
          CustomTextField(
            label: 'Total Doses Required * (Max 15)',
            hint: '1 - 15 doses',
            controller: _totalDosesController,
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(PhosphorIconsRegular.hash, size: 18),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TextInputFormatter.withFunction((oldValue, newValue) {
                if (newValue.text.isEmpty) return newValue;
                final val = int.tryParse(newValue.text);
                if (val == null || val < 1 || val > 15) {
                  return oldValue;
                }
                return newValue;
              }),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Dose Interval (Days) *',
            hint: 'e.g. 1 (Daily) or 2 (Alternate)',
            controller: _doseIntervalController,
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(PhosphorIconsRegular.hourglass, size: 18),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TextInputFormatter.withFunction((oldValue, newValue) {
                if (newValue.text.isEmpty) return newValue;
                final val = int.tryParse(newValue.text);
                if (val == null || val < 1 || val > 90) {
                  return oldValue;
                }
                return newValue;
              }),
            ],
            onChanged: (_) => setState(() {}),
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Total Doses Required * (Max 15)',
                  hint: '1 - 15 doses',
                  controller: _totalDosesController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(PhosphorIconsRegular.hash, size: 18),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isEmpty) return newValue;
                      final val = int.tryParse(newValue.text);
                      if (val == null || val < 1 || val > 15) {
                        return oldValue;
                      }
                      return newValue;
                    }),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Dose Interval (Days) *',
                  hint: 'e.g. 1 (Daily) or 2 (Alternate)',
                  controller: _doseIntervalController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(PhosphorIconsRegular.hourglass, size: 18),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isEmpty) return newValue;
                      final val = int.tryParse(newValue.text);
                      if (val == null || val < 1 || val > 90) {
                        return oldValue;
                      }
                      return newValue;
                    }),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        const SizedBox(height: 10),

        // Quick Dose Selection Chips
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Quick Select:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            ...[1, 2, 3, 5, 7, 10, 15].map((d) {
              final isSelected = _totalDosesController.text.trim() == '$d';
              return InkWell(
                onTap: () {
                  setState(() {
                    _totalDosesController.text = '$d';
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.surfaceDark : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                  ),
                  child: Text(
                    '$d ${d == 1 ? "Dose" : "Doses"}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),

        const SizedBox(height: 24),

        // Visual Schedule Preview
        const Text(
          'Generated Multi-Dose Timeline Preview:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : const Color(0xFFF9FAF7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: scheduleDates.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Please enter total doses (1 - 15) to preview timeline.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: List.generate(scheduleDates.length, (idx) {
              final doseNum = idx + 1;
              final date = scheduleDates[idx];
              final isFirst = idx == 0;
              final isLast = idx == scheduleDates.length - 1;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isFirst
                            ? AppColors.success
                            : (isDark ? AppColors.surfaceDark : Colors.white),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isFirst ? AppColors.success : AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$doseNum',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isFirst ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Dose $doseNum ${isFirst ? "(Immediate - Today)" : ""}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isFirst ? AppColors.success : null,
                                ),
                              ),
                              if (isFirst) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.successBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'AUTO-GIVEN',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              if (isLast && !isFirst) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'FINAL DOSE',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEEE, dd MMMM yyyy').format(date),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      isFirst ? 'Administered Now' : 'Scheduled Alert',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isFirst ? AppColors.success : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: PRESCRIBED MEDICINES (HYBRID SELECTOR)
  // ---------------------------------------------------------------------------
  Widget _buildStep3Medicines(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Initial Prescribed Medicines *',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Prescribe inventory medicines or custom outside doctor drugs',
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _addMedicineDraft(fromStock: true),
                  icon: const Icon(PhosphorIconsRegular.plus, size: 16),
                  label: const Text('From Inventory'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _addMedicineDraft(fromStock: false),
                  icon: const Icon(PhosphorIconsRegular.arrowSquareOut, size: 16),
                  label: const Text('Outside Medicine'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                    side: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // List of Medicine Draft Cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _medicineDrafts.length,
          separatorBuilder: (_, index) => const SizedBox(height: 12),
          itemBuilder: (ctx, index) {
            final draft = _medicineDrafts[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : const Color(0xFFFAFBFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: draft.isStockItem
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : AppColors.warningBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              draft.isStockItem ? 'INVENTORY STOCK' : "DOCTOR'S OUTSIDE DRUG",
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: draft.isStockItem ? AppColors.primary : AppColors.warning,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Medicine #${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Stock Item', style: TextStyle(fontSize: 12)),
                          Switch(
                            value: draft.isStockItem,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() => draft.isStockItem = val);
                            },
                          ),
                          IconButton(
                            icon: const Icon(PhosphorIconsRegular.trash, size: 18, color: Colors.red),
                            tooltip: 'Remove',
                            onPressed: () => _removeMedicineDraft(index),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 16),

                  // Medicine Selector or Text Field
                  if (MediaQuery.of(context).size.width < 650) ...[
                    draft.isStockItem
                        ? CustomDropdownSearch<MedicalItemModel>(
                            label: 'Select Medical Inventory Item *',
                            hint: 'Choose medicine from stock',
                            prefixIcon: PhosphorIconsRegular.pill,
                            searchable: true,
                            searchHint: 'Search medicine name...',
                            items: _stockItems,
                            selectedItem: draft.selectedStockItem,
                            itemAsString: (item) => '${item.itemName} (${item.category} • Stock: ${item.totalStock.toStringAsFixed(0)} ${item.unit})',
                            compareFn: (a, b) => a.id == b.id,
                            onChanged: (val) {
                              setState(() {
                                draft.selectedStockItem = val;
                                if (val != null) {
                                  draft.unit = val.unit;
                                }
                              });
                            },
                          )
                        : CustomTextField(
                            label: 'Medicine Name *',
                            hint: 'e.g. Melonex Plus Bolus, Intacef 3g',
                            controller: draft.medicineNameController,
                            prefixIcon: const Icon(PhosphorIconsRegular.pill, size: 18),
                          ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: CustomTextField(
                            label: 'Dosage *',
                            hint: 'e.g. 15 ml',
                            controller: draft.dosageController,
                            prefixIcon: const Icon(PhosphorIconsRegular.scales, size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: CustomDropdownSearch<String>(
                            label: 'Unit',
                            hint: 'Unit',
                            prefixIcon: PhosphorIconsRegular.ruler,
                            items: _medicineUnits,
                            selectedItem: draft.unit,
                            itemAsString: (u) => u,
                            onChanged: (val) {
                              if (val != null) setState(() => draft.unit = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: CustomDropdownSearch<String>(
                            label: 'Route',
                            hint: 'Route',
                            prefixIcon: PhosphorIconsRegular.arrowsSplit,
                            items: _medicineRoutes,
                            selectedItem: draft.route,
                            itemAsString: (r) => r,
                            onChanged: (val) {
                              if (val != null) setState(() => draft.route = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: draft.isStockItem
                              ? CustomDropdownSearch<MedicalItemModel>(
                                  label: 'Select Medical Inventory Item *',
                                  hint: 'Choose medicine from stock',
                                  prefixIcon: PhosphorIconsRegular.pill,
                                  searchable: true,
                                  searchHint: 'Search medicine name...',
                                  items: _stockItems,
                                  selectedItem: draft.selectedStockItem,
                                  itemAsString: (item) => '${item.itemName} (${item.category} • Stock: ${item.totalStock.toStringAsFixed(0)} ${item.unit})',
                                  compareFn: (a, b) => a.id == b.id,
                                  onChanged: (val) {
                                    setState(() {
                                      draft.selectedStockItem = val;
                                      if (val != null) {
                                        draft.unit = val.unit;
                                      }
                                    });
                                  },
                                )
                              : CustomTextField(
                                  label: 'Medicine Name *',
                                  hint: 'e.g. Melonex Plus Bolus, Intacef 3g',
                                  controller: draft.medicineNameController,
                                  prefixIcon: const Icon(PhosphorIconsRegular.pill, size: 18),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            label: 'Dosage *',
                            hint: 'e.g. 15 ml, 2 Bolus',
                            controller: draft.dosageController,
                            prefixIcon: const Icon(PhosphorIconsRegular.scales, size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: CustomDropdownSearch<String>(
                            label: 'Unit',
                            hint: 'Unit',
                            prefixIcon: PhosphorIconsRegular.ruler,
                            items: _medicineUnits,
                            selectedItem: draft.unit,
                            itemAsString: (u) => u,
                            onChanged: (val) {
                              if (val != null) setState(() => draft.unit = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: CustomDropdownSearch<String>(
                            label: 'Route',
                            hint: 'Route',
                            prefixIcon: PhosphorIconsRegular.arrowsSplit,
                            items: _medicineRoutes,
                            selectedItem: draft.route,
                            itemAsString: (r) => r,
                            onChanged: (val) {
                              if (val != null) setState(() => draft.route = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Administration Notes / Instructions',
                    hint: 'e.g. Post feeding, Deep IM injection, Wash udder before application',
                    controller: draft.notesController,
                    prefixIcon: const Icon(PhosphorIconsRegular.note, size: 18),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
