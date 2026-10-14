import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dropdown_search.dart';
import '../../../core/widgets/custom_loader.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/breed_model.dart';
import '../../../data/models/cow_heat_model.dart';
import '../../../data/models/cow_mating_model.dart';
import '../../../data/models/cow_model.dart';
import '../../../data/models/worker_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/gaushala_session_service.dart';
import '../mating_controller.dart';

/// Modal dialog to record Natural Service or Artificial Insemination (AI) Mating.
class AddMatingDialog extends StatefulWidget {
  final CowModel? preselectedCow;
  final CowHeatModel? preselectedHeat;

  const AddMatingDialog({
    super.key,
    this.preselectedCow,
    this.preselectedHeat,
  });

  static Future<bool?> show(
    BuildContext context, {
    CowModel? preselectedCow,
    CowHeatModel? preselectedHeat,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddMatingDialog(
        preselectedCow: preselectedCow,
        preselectedHeat: preselectedHeat,
      ),
    );
  }

  @override
  State<AddMatingDialog> createState() => _AddMatingDialogState();
}

class _AddMatingDialogState extends State<AddMatingDialog> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = Get.find<ApiService>();
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();
  final MatingController _matingController = Get.isRegistered<MatingController>()
      ? Get.find<MatingController>()
      : Get.put(MatingController());

  bool _isLoadingDropdowns = true;
  bool _isSubmitting = false;

  List<CowModel> _femaleCows = [];
  List<CowModel> _bulls = [];
  List<BreedModel> _breeds = [];
  List<WorkerModel> _workers = [];
  List<CowHeatModel> _activeHeats = [];

  CowModel? _selectedCow;
  CowHeatModel? _selectedHeat;
  MatingType _selectedType = MatingType.artificial;
  DateTime _matingDate = DateTime.now();
  String _matingTime = 'morning';

  // Natural mating fields
  CowModel? _selectedBull;
  final TextEditingController _bullNameController = TextEditingController();

  // Artificial mating fields
  final TextEditingController _strawCodeController = TextEditingController();
  BreedModel? _selectedSemenBreed;
  final TextEditingController _semenSourceController = TextEditingController(text: 'BAIF');

  // Personnel & remarks
  final TextEditingController _inseminatorController = TextEditingController();
  WorkerModel? _selectedInseminatorWorker;
  final TextEditingController _remarksController = TextEditingController();

  final List<String> _quickSources = ['BAIF', 'SAG', 'ABS India', 'NDDB', 'Govt Center'];

  @override
  void initState() {
    super.initState();
    _selectedCow = widget.preselectedCow;
    _selectedHeat = widget.preselectedHeat;
    _semenSourceController.addListener(_onSemenSourceChanged);
    _loadOptions();
  }

  void _onSemenSourceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _semenSourceController.removeListener(_onSemenSourceChanged);
    _bullNameController.dispose();
    _strawCodeController.dispose();
    _semenSourceController.dispose();
    _inseminatorController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    final gId = _gaushalaService.selectedGaushalaId;
    if (gId.isEmpty) return;

    try {
      setState(() => _isLoadingDropdowns = true);
      final cowsResponse = await _apiService.getCows(gaushalaId: gId, gender: 'female');
      final bullsResponse = await _apiService.getCows(gaushalaId: gId, gender: 'male');
      final breedsList = await _apiService.getBreedTypes();
      final workersResult = await _apiService.getWorkers(gaushalaId: gId, limit: 100);
      final activeHeatsList = await _apiService.getActiveHeatAlerts(gaushalaId: gId);

      if (mounted) {
        setState(() {
          _femaleCows = cowsResponse.female.where((c) => !c.isDead && !c.isDeleted).toList();
          _bulls = (bullsResponse.male.isNotEmpty ? bullsResponse.male : bullsResponse.allCows)
              .where((c) => !c.isDead && !c.isDeleted)
              .toList();
          _breeds = breedsList;
          _workers = workersResult.items.where((w) => w.isActive).toList();
          _activeHeats = activeHeatsList;

          if (widget.preselectedHeat != null) {
            _selectedHeat = widget.preselectedHeat;
            _selectedCow = _femaleCows.firstWhereOrNull((c) => c.id == widget.preselectedHeat!.cowId);
          } else if (widget.preselectedCow != null) {
            _selectedCow = _femaleCows.firstWhereOrNull((c) => c.id == widget.preselectedCow!.id) ?? widget.preselectedCow;
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingDropdowns = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = today.subtract(const Duration(days: 365));
    final lastDate = today;

    final initial = _matingDate.isBefore(firstDate)
        ? firstDate
        : (_matingDate.isAfter(lastDate) ? lastDate : _matingDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'SELECT MATING DATE',
    );
    if (picked != null) {
      setState(() => _matingDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCow == null) {
      CustomSnackbar.showError(
        title: 'Validation',
        message: 'Please select a cow for mating.',
      );
      return;
    }

    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final matingDay = DateTime(_matingDate.year, _matingDate.month, _matingDate.day);

    // 1. Mating date cannot be in the future
    if (matingDay.isAfter(todayEnd)) {
      CustomSnackbar.showError(
        title: 'Invalid Date',
        message: 'Mating date cannot be in the future.',
      );
      return;
    }

    // 2. Cannot mate an already pregnant cow
    final activePregnant = _matingController.matings.firstWhereOrNull(
      (m) => m.cowId == _selectedCow!.id && m.status == MatingStatus.pregnant,
    );
    if (activePregnant != null) {
      CustomSnackbar.showError(
        title: 'Cow Already Pregnant',
        message: 'Cow ${_selectedCow!.tagId} is currently confirmed Pregnant (Mating on ${activePregnant.formattedMatingDate}, Expected Calving: ${activePregnant.formattedExpectedCalvingDate}). She cannot be mated while pregnant.',
      );
      return;
    }

    // 3. Natural Service requires Bull
    if (_selectedType == MatingType.natural) {
      if (_selectedBull == null && _bullNameController.text.trim().isEmpty) {
        CustomSnackbar.showError(
          title: 'Sire Bull Required',
          message: 'Please select a Sire Bull or enter a Bull tag / name for Natural Service.',
        );
        return;
      }
    }

    // 4. Artificial Insemination requires Semen Straw Code
    if (_selectedType == MatingType.artificial) {
      if (_strawCodeController.text.trim().isEmpty) {
        CustomSnackbar.showError(
          title: 'Semen Straw Code Required',
          message: 'Please enter the Semen Straw Code for Artificial Insemination.',
        );
        return;
      }
    }

    final gId = _gaushalaService.selectedGaushalaId;
    final body = <String, dynamic>{
      'gaushalaId': gId,
      'cowId': _selectedCow!.id,
      if (_selectedHeat != null) 'heatId': _selectedHeat!.id,
      'matingDate': DateFormat('yyyy-MM-dd').format(_matingDate),
      'matingTime': _matingTime,
      'matingType': _selectedType.code,
      if (_selectedType == MatingType.natural) ...{
        if (_selectedBull != null) 'bullId': _selectedBull!.id,
        if (_bullNameController.text.trim().isNotEmpty)
          'bullNameOrTag': _bullNameController.text.trim()
        else if (_selectedBull != null)
          'bullNameOrTag': _selectedBull!.tagId,
      } else ...{
        if (_strawCodeController.text.trim().isNotEmpty)
          'semenStrawCode': _strawCodeController.text.trim(),
        if (_selectedSemenBreed != null)
          'semenBreedId': _selectedSemenBreed!.id,
        if (_semenSourceController.text.trim().isNotEmpty)
          'semenSource': _semenSourceController.text.trim(),
      },
      if (_inseminatorController.text.trim().isNotEmpty)
        'inseminatorName': _inseminatorController.text.trim()
      else if (_selectedInseminatorWorker != null)
        'inseminatorName': _selectedInseminatorWorker!.name,
      if (_selectedInseminatorWorker != null)
        'inseminatorWorkerId': _selectedInseminatorWorker!.id,
      if (_remarksController.text.trim().isNotEmpty)
        'remarks': _remarksController.text.trim(),
    };

    setState(() => _isSubmitting = true);
    final success = await _matingController.createMating(body);
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 820),
        child: _isLoadingDropdowns
            ? SizedBox(
                height: 320,
                child: Center(
                  child: CustomBrandedSpinner(message: 'Loading cattle and breeding records...'),
                ),
              )
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              PhosphorIconsRegular.heartStraight,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Record Cow Insemination / Mating',
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Natural Service or Artificial Insemination (AI) with Pregnancy Diagnosis tracking.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Cow Selection
                            CustomDropdownSearch<CowModel>(
                              label: 'Select Cow (Female Cattle)',
                              isRequired: true,
                              prefixIcon: PhosphorIconsRegular.cow,
                              items: _femaleCows,
                              selectedItem: _selectedCow,
                              itemAsString: (c) => '${c.tagId}${c.calfName != null ? ' (${c.calfName})' : ''} • Shed: ${c.shed?.shedNumber ?? 'N/A'}',
                              searchable: true,
                              searchHint: 'Search cow tag...',
                              compareFn: (a, b) => a.id == b.id,
                              onChanged: (val) {
                                setState(() {
                                  _selectedCow = val;
                                  _selectedHeat = null;
                                });
                              },
                              validator: (val) => val == null ? 'Cow is required' : null,
                            ),
                            const SizedBox(height: 16),

                            // 2. Link to Active Heat Record (Optional)
                            if (_activeHeats.isNotEmpty) ...[
                              CustomDropdownSearch<CowHeatModel>(
                                label: 'Link to Active Heat Cycle (Optional)',
                                prefixIcon: PhosphorIconsRegular.fire,
                                items: _selectedCow == null
                                    ? _activeHeats
                                    : _activeHeats.where((h) => h.cowId == _selectedCow!.id).toList(),
                                selectedItem: _selectedHeat,
                                itemAsString: (h) => '${h.cowTagId} • Observed: ${h.formattedHeatDate} (${h.heatStage.label})',
                                compareFn: (a, b) => a.id == b.id,
                                onChanged: (val) {
                                  setState(() {
                                    _selectedHeat = val;
                                    if (val != null && _selectedCow == null) {
                                      _selectedCow = _femaleCows.firstWhereOrNull((c) => c.id == val.cowId);
                                    }
                                  });
                                },
                                onClear: () => setState(() => _selectedHeat = null),
                                showClearButton: true,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Note: Linking marks the corresponding Heat cycle as "MATED" automatically.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // 3. Mating Date & Time
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mating / Insemination Date *',
                                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: _pickDate,
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(PhosphorIconsRegular.calendar, size: 18, color: AppColors.primary),
                                              const SizedBox(width: 8),
                                              Text(DateFormat('dd MMM yyyy').format(_matingDate)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Time of Service',
                                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          ChoiceChip(
                                            label: const Text('Morning'),
                                            selected: _matingTime == 'morning',
                                            onSelected: (sel) {
                                              if (sel) setState(() => _matingTime = 'morning');
                                            },
                                            selectedColor: AppColors.primary,
                                            checkmarkColor: Colors.white,
                                            labelStyle: TextStyle(
                                              fontSize: 12,
                                              fontWeight: _matingTime == 'morning' ? FontWeight.w600 : FontWeight.normal,
                                              color: _matingTime == 'morning' ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ChoiceChip(
                                            label: const Text('Evening'),
                                            selected: _matingTime == 'evening',
                                            onSelected: (sel) {
                                              if (sel) setState(() => _matingTime = 'evening');
                                            },
                                            selectedColor: AppColors.primary,
                                            checkmarkColor: Colors.white,
                                            labelStyle: TextStyle(
                                              fontSize: 12,
                                              fontWeight: _matingTime == 'evening' ? FontWeight.w600 : FontWeight.normal,
                                              color: _matingTime == 'evening' ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // 4. Mating Type Selector (Natural vs Artificial)
                            Text(
                              'Mating Type *',
                              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => _selectedType = MatingType.artificial),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: _selectedType == MatingType.artificial
                                            ? AppColors.primary.withValues(alpha: 0.1)
                                            : (isDark ? AppColors.cardDark : AppColors.cardLight),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _selectedType == MatingType.artificial
                                              ? AppColors.primary
                                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                          width: _selectedType == MatingType.artificial ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            PhosphorIconsRegular.syringe,
                                            color: _selectedType == MatingType.artificial
                                                ? AppColors.primary
                                                : Colors.grey,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 10),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Artificial Insemination (AI)',
                                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                ),
                                                Text(
                                                  'Cryo straw & breed genetics',
                                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => _selectedType = MatingType.natural),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: _selectedType == MatingType.natural
                                            ? AppColors.primary.withValues(alpha: 0.1)
                                            : (isDark ? AppColors.cardDark : AppColors.cardLight),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _selectedType == MatingType.natural
                                              ? AppColors.primary
                                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                          width: _selectedType == MatingType.natural ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            PhosphorIconsRegular.cow,
                                            color: _selectedType == MatingType.natural
                                                ? AppColors.primary
                                                : Colors.grey,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 10),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Natural Service',
                                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                ),
                                                Text(
                                                  'Sire bull in herd / pen',
                                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // 5. Conditional fields based on Mating Type
                            if (_selectedType == MatingType.natural) ...[
                              CustomDropdownSearch<CowModel>(
                                label: 'Select Bull (Sire in Gaushala)',
                                prefixIcon: PhosphorIconsRegular.cow,
                                items: _bulls,
                                selectedItem: _selectedBull,
                                itemAsString: (b) => '${b.tagId}${b.calfName != null ? ' (${b.calfName})' : ''} • Breed: ${b.breed?.breedName ?? 'Sire'}',
                                searchable: true,
                                searchHint: 'Search bull tag...',
                                compareFn: (a, b) => a.id == b.id,
                                onChanged: (val) => setState(() => _selectedBull = val),
                              ),
                              const SizedBox(height: 14),
                              CustomTextField(
                                controller: _bullNameController,
                                label: 'Bull Tag / Name (If outside bull)',
                                hint: 'e.g. Nandi Bull #04',
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: _strawCodeController,
                                      label: 'Semen Straw Code',
                                      hint: 'e.g. GIR-2026-X88',
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: CustomDropdownSearch<BreedModel>(
                                      label: 'Semen Breed',
                                      items: _breeds,
                                      selectedItem: _selectedSemenBreed,
                                      itemAsString: (b) => b.breedName,
                                      searchable: true,
                                      compareFn: (a, b) => a.id == b.id,
                                      onChanged: (val) => setState(() => _selectedSemenBreed = val),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              CustomTextField(
                                controller: _semenSourceController,
                                label: 'Semen Source / Agency',
                                hint: 'e.g. BAIF, SAG, ABS India',
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                children: _quickSources.map((s) {
                                  final isSelected = _semenSourceController.text.trim().toLowerCase() == s.toLowerCase();
                                  return ChoiceChip(
                                    label: Text(s),
                                    selected: isSelected,
                                    showCheckmark: false,
                                    onSelected: (selected) {
                                      setState(() {
                                        _semenSourceController.text = selected ? s : '';
                                      });
                                    },
                                    selectedColor: AppColors.primary,
                                    checkmarkColor: Colors.white,
                                    labelStyle: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            const SizedBox(height: 18),

                            // 6. Inseminator Personnel
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: _inseminatorController,
                                    label: 'Inseminator / Veterinarian Name',
                                    hint: 'e.g. Dr. Sharma or A.I. Technician',
                                    prefixIcon: const Icon(PhosphorIconsRegular.user, size: 18),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: CustomDropdownSearch<WorkerModel>(
                                    label: 'Assigned Worker (Optional)',
                                    items: _workers,
                                    selectedItem: _selectedInseminatorWorker,
                                    itemAsString: (w) => w.name,
                                    searchable: true,
                                    compareFn: (a, b) => a.id == b.id,
                                    onChanged: (val) => setState(() => _selectedInseminatorWorker = val),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // 7. Remarks
                            CustomTextField(
                              controller: _remarksController,
                              label: 'Remarks / Clinical Notes',
                              hint: 'Notes on cervical mucus, ease of entry, straw quality...',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),

                            // 8. Workflow Automation Banner
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade300),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(PhosphorIconsRegular.info, color: Colors.blue.shade700, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Expected PD Date: A Pregnancy Diagnosis alert will automatically activate at ~45-60 days post-mating. If 3 or more attempts fail, the cow will be highlighted as a Repeat Breeder.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actions Footer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          CustomButton(
                            text: 'Record Mating',
                            icon: PhosphorIconsRegular.check,
                            isLoading: _isSubmitting,
                            onPressed: _submit,
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
