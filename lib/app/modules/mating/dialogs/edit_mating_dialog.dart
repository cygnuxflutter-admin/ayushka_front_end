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
import '../../../data/models/cow_mating_model.dart';
import '../../../data/models/cow_model.dart';
import '../../../data/models/worker_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/gaushala_session_service.dart';
import '../mating_controller.dart';

/// Modal dialog to edit an existing Cow Mating record.
class EditMatingDialog extends StatefulWidget {
  final CowMatingModel mating;

  const EditMatingDialog({
    super.key,
    required this.mating,
  });

  static Future<bool?> show(BuildContext context, CowMatingModel mating) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EditMatingDialog(mating: mating),
    );
  }

  @override
  State<EditMatingDialog> createState() => _EditMatingDialogState();
}

class _EditMatingDialogState extends State<EditMatingDialog> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = Get.find<ApiService>();
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();
  final MatingController _matingController = Get.isRegistered<MatingController>()
      ? Get.find<MatingController>()
      : Get.put(MatingController());

  bool _isLoadingDropdowns = true;
  bool _isSubmitting = false;

  List<CowModel> _bulls = [];
  List<BreedModel> _breeds = [];
  List<WorkerModel> _workers = [];

  late DateTime _matingDate;
  late String _matingTime;
  late MatingType _selectedType;
  late MatingStatus _selectedStatus;

  CowModel? _selectedBull;
  late TextEditingController _bullNameController;
  late TextEditingController _strawCodeController;
  BreedModel? _selectedSemenBreed;
  late TextEditingController _semenSourceController;
  late TextEditingController _inseminatorController;
  WorkerModel? _selectedInseminatorWorker;
  late TextEditingController _remarksController;
  final List<String> _quickSources = ['BAIF', 'SAG', 'ABS India', 'NDDB', 'Govt Center'];

  @override
  void initState() {
    super.initState();
    _matingDate = widget.mating.matingDate ?? DateTime.now();
    _matingTime = widget.mating.matingTime?.toLowerCase() == 'evening' ? 'evening' : 'morning';
    _selectedType = widget.mating.matingType;
    _selectedStatus = widget.mating.status;

    _bullNameController = TextEditingController(text: widget.mating.bullNameOrTag ?? '');
    _strawCodeController = TextEditingController(text: widget.mating.semenStrawCode ?? '');
    _semenSourceController = TextEditingController(text: widget.mating.semenSource ?? '');
    _semenSourceController.addListener(_onSemenSourceChanged);
    _inseminatorController = TextEditingController(text: widget.mating.inseminatorName ?? '');
    _remarksController = TextEditingController(text: widget.mating.remarks ?? '');

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
    final gId = widget.mating.gaushalaId.isNotEmpty
        ? widget.mating.gaushalaId
        : _gaushalaService.selectedGaushalaId;

    try {
      setState(() => _isLoadingDropdowns = true);
      final bullsResponse = await _apiService.getCows(gaushalaId: gId, gender: 'male');
      final breedsList = await _apiService.getBreedTypes();
      final workersResult = await _apiService.getWorkers(gaushalaId: gId, limit: 100);

      if (mounted) {
        setState(() {
          _bulls = (bullsResponse.male.isNotEmpty ? bullsResponse.male : bullsResponse.allCows)
              .where((c) => !c.isDead && !c.isDeleted)
              .toList();
          _breeds = breedsList;
          _workers = workersResult.items.where((w) => w.isActive).toList();

          if (widget.mating.bullId != null) {
            _selectedBull = _bulls.firstWhereOrNull((b) => b.id == widget.mating.bullId);
          }
          if (widget.mating.semenBreedId != null) {
            _selectedSemenBreed = _breeds.firstWhereOrNull((b) => b.id == widget.mating.semenBreedId);
          }
          if (widget.mating.inseminatorWorkerId != null) {
            _selectedInseminatorWorker = _workers.firstWhereOrNull((w) => w.id == widget.mating.inseminatorWorkerId);
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

    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final matingDay = DateTime(_matingDate.year, _matingDate.month, _matingDate.day);

    // 1. Future date check
    if (matingDay.isAfter(todayEnd)) {
      CustomSnackbar.showError(
        title: 'Invalid Date',
        message: 'Mating date cannot be in the future.',
      );
      return;
    }

    // 2. Cannot be after existing PD check date
    if (widget.mating.pdDate != null) {
      final pdDay = DateTime(
        widget.mating.pdDate!.year,
        widget.mating.pdDate!.month,
        widget.mating.pdDate!.day,
      );
      if (matingDay.isAfter(pdDay)) {
        CustomSnackbar.showError(
          title: 'Date Inconsistency',
          message: 'Mating date cannot be after the recorded PD examination date (${DateFormat('dd MMM yyyy').format(pdDay)}).',
        );
        return;
      }
    }

    // 3. Cannot be after existing Calving date
    if (widget.mating.actualCalvingDate != null) {
      final calvingDay = DateTime(
        widget.mating.actualCalvingDate!.year,
        widget.mating.actualCalvingDate!.month,
        widget.mating.actualCalvingDate!.day,
      );
      if (matingDay.isAfter(calvingDay)) {
        CustomSnackbar.showError(
          title: 'Date Inconsistency',
          message: 'Mating date cannot be after the recorded Calving date (${DateFormat('dd MMM yyyy').format(calvingDay)}).',
        );
        return;
      }
    }

    // 4. Natural Service requires Bull
    if (_selectedType == MatingType.natural) {
      if (_selectedBull == null && _bullNameController.text.trim().isEmpty) {
        CustomSnackbar.showError(
          title: 'Sire Bull Required',
          message: 'Please select a Sire Bull or enter a Bull tag / name for Natural Service.',
        );
        return;
      }
    }

    // 5. Artificial Insemination requires Semen Straw Code
    if (_selectedType == MatingType.artificial) {
      if (_strawCodeController.text.trim().isEmpty) {
        CustomSnackbar.showError(
          title: 'Semen Straw Code Required',
          message: 'Please enter the Semen Straw Code for Artificial Insemination.',
        );
        return;
      }
    }

    final body = <String, dynamic>{
      'matingDate': DateFormat('yyyy-MM-dd').format(_matingDate),
      'matingTime': _matingTime,
      'matingType': _selectedType.code,
      'status': _selectedStatus.code,
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
    final success = await _matingController.updateMating(widget.mating.id, body);
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
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 800),
        child: _isLoadingDropdowns
            ? SizedBox(height: 300, child: Center(child: CustomBrandedSpinner(message: 'Loading details...')))
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
                              PhosphorIconsRegular.pencilSimple,
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
                                  'Update Mating Record',
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Cow Tag: ${widget.mating.cowTagId} • Attempt #${widget.mating.attemptCount}',
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
                            // Date & Time
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mating Date *',
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
                                        'Shift',
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

                            // Mating Type
                            Text('Mating Type', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                ChoiceChip(
                                  avatar: Icon(
                                    PhosphorIconsRegular.syringe,
                                    size: 16,
                                    color: _selectedType == MatingType.artificial ? Colors.white : AppColors.primary,
                                  ),
                                  label: const Text('Artificial Insemination (AI)'),
                                  selected: _selectedType == MatingType.artificial,
                                  onSelected: (sel) {
                                    if (sel) setState(() => _selectedType = MatingType.artificial);
                                  },
                                  selectedColor: AppColors.primary,
                                  checkmarkColor: Colors.white,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _selectedType == MatingType.artificial ? FontWeight.w600 : FontWeight.normal,
                                    color: _selectedType == MatingType.artificial ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ChoiceChip(
                                  avatar: Icon(
                                    PhosphorIconsRegular.cow,
                                    size: 16,
                                    color: _selectedType == MatingType.natural ? Colors.white : AppColors.primary,
                                  ),
                                  label: const Text('Natural Service'),
                                  selected: _selectedType == MatingType.natural,
                                  onSelected: (sel) {
                                    if (sel) setState(() => _selectedType = MatingType.natural);
                                  },
                                  selectedColor: AppColors.primary,
                                  checkmarkColor: Colors.white,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _selectedType == MatingType.natural ? FontWeight.w600 : FontWeight.normal,
                                    color: _selectedType == MatingType.natural ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Conditional Mating Fields
                            if (_selectedType == MatingType.natural) ...[
                              CustomDropdownSearch<CowModel>(
                                label: 'Sire Bull (Gaushala)',
                                prefixIcon: PhosphorIconsRegular.cow,
                                items: _bulls,
                                selectedItem: _selectedBull,
                                itemAsString: (b) => '${b.tagId}${b.calfName != null ? ' (${b.calfName})' : ''}',
                                searchable: true,
                                compareFn: (a, b) => a.id == b.id,
                                onChanged: (val) => setState(() => _selectedBull = val),
                              ),
                              const SizedBox(height: 14),
                              CustomTextField(
                                controller: _bullNameController,
                                label: 'Bull Tag / Name',
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: _strawCodeController,
                                      label: 'Semen Straw Code',
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
                                label: 'Semen Source',
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

                            // Inseminator
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: _inseminatorController,
                                    label: 'Inseminator / Vet Name',
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: CustomDropdownSearch<WorkerModel>(
                                    label: 'Assigned Worker',
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

                            // Status Dropdown
                            CustomDropdownSearch<MatingStatus>(
                              label: 'Mating Status',
                              items: MatingStatus.values,
                              selectedItem: _selectedStatus,
                              itemAsString: (s) => s.label,
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedStatus = val);
                              },
                            ),
                            const SizedBox(height: 18),

                            // Remarks
                            CustomTextField(
                              controller: _remarksController,
                              label: 'Remarks',
                              maxLines: 2,
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
                            text: 'Update Mating',
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
