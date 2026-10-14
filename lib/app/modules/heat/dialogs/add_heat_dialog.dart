import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dropdown_search.dart';
import '../../../core/widgets/custom_loader.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/cow_heat_model.dart';
import '../../../data/models/cow_model.dart';
import '../../../data/models/worker_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/gaushala_session_service.dart';
import '../heat_controller.dart';

/// Interactive dialog for recording a new Cow Heat (Estrus) cycle.
class AddHeatDialog extends StatefulWidget {
  final CowModel? preselectedCow;

  const AddHeatDialog({
    super.key,
    this.preselectedCow,
  });

  static Future<bool?> show(BuildContext context, {CowModel? preselectedCow}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddHeatDialog(preselectedCow: preselectedCow),
    );
  }

  @override
  State<AddHeatDialog> createState() => _AddHeatDialogState();
}

class _AddHeatDialogState extends State<AddHeatDialog> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = Get.find<ApiService>();
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();
  final HeatController _heatController = Get.isRegistered<HeatController>()
      ? Get.find<HeatController>()
      : Get.put(HeatController());

  bool _isLoadingDropdowns = true;
  bool _isSubmitting = false;

  List<CowModel> _cows = [];
  List<WorkerModel> _workers = [];

  CowModel? _selectedCow;
  WorkerModel? _selectedWorker;

  DateTime _heatDate = DateTime.now();
  String _heatTime = 'morning';
  final TextEditingController _customTimeController = TextEditingController();
  HeatStage _selectedStage = HeatStage.standing;
  HeatIntensity _selectedIntensity = HeatIntensity.moderate;
  HeatStatus _selectedStatus = HeatStatus.readyForMating;
  final Set<String> _selectedSigns = {'MOUNTING', 'MUCUS_DISCHARGE'};
  final TextEditingController _remarksController = TextEditingController();

  final List<String> _quickTimeSlots = ['morning', 'evening', 'custom'];

  @override
  void initState() {
    super.initState();
    _selectedCow = widget.preselectedCow;
    _loadOptions();
  }

  @override
  void dispose() {
    _customTimeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    final gId = _gaushalaService.selectedGaushalaId;
    if (gId.isEmpty) return;

    try {
      setState(() => _isLoadingDropdowns = true);
      final cowsResponse = await _apiService.getCows(gaushalaId: gId, gender: 'female');
      final workersResult = await _apiService.getWorkers(gaushalaId: gId, limit: 100);

      if (mounted) {
        setState(() {
          _cows = (cowsResponse.female.isNotEmpty ? cowsResponse.female : cowsResponse.allCows)
              .where((c) => !c.isDead && !c.isDeleted)
              .toList();
          _workers = workersResult.items.where((w) => w.isActive).toList();
          if (widget.preselectedCow != null) {
            _selectedCow = _cows.firstWhereOrNull((c) => c.id == widget.preselectedCow!.id) ?? widget.preselectedCow;
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingDropdowns = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _heatDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _heatDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCow == null) {
      Get.snackbar('Validation', 'Please select a cow to record heat.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white);
      return;
    }

    final gId = _gaushalaService.selectedGaushalaId;
    final finalTime = _heatTime == 'custom'
        ? _customTimeController.text.trim()
        : _heatTime;

    final body = {
      'gaushalaId': gId,
      'cowId': _selectedCow!.id,
      'heatDate': DateFormat('yyyy-MM-dd').format(_heatDate),
      'heatTime': finalTime.isNotEmpty ? finalTime : 'morning',
      'heatStage': _selectedStage.code,
      'heatSigns': _selectedSigns.toList(),
      'intensity': _selectedIntensity.code,
      'status': _selectedStatus.code,
      if (_selectedWorker != null) 'observedByWorkerId': _selectedWorker!.id,
      if (_remarksController.text.trim().isNotEmpty) 'remarks': _remarksController.text.trim(),
    };

    setState(() => _isSubmitting = true);
    final success = await _heatController.createHeat(body);
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
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
        child: _isLoadingDropdowns
            ? SizedBox(height: 300, child: Center(child: CustomBrandedSpinner(message: 'Loading cattle and staff...')))
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
                              PhosphorIconsRegular.fire,
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
                                  'Record Cow Heat Cycle',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Log detected estrus signs and schedule for natural or artificial mating.',
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

                    // Scrollable Form Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Cow Selector
                            CustomDropdownSearch<CowModel>(
                              label: 'Select Cow (Female Cattle)',
                              isRequired: true,
                              prefixIcon: PhosphorIconsRegular.cow,
                              items: _cows,
                              selectedItem: _selectedCow,
                              itemAsString: (c) => '${c.tagId}${c.calfName != null ? ' (${c.calfName})' : ''} • Shed: ${c.shed?.shedNumber ?? 'N/A'}',
                              searchable: true,
                              searchHint: 'Search tag or calf name...',
                              compareFn: (a, b) => a.id == b.id,
                              onChanged: (val) => setState(() => _selectedCow = val),
                              validator: (val) => val == null ? 'Cow is required' : null,
                            ),
                            const SizedBox(height: 18),

                            // 2. Date and Time Row
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Observation Date *',
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
                                              Text(
                                                DateFormat('dd MMM yyyy').format(_heatDate),
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Time / Shift',
                                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: _quickTimeSlots.map((slot) {
                                          final isSelected = _heatTime == slot;
                                          final label = slot == 'morning'
                                              ? 'Morning'
                                              : (slot == 'evening' ? 'Evening' : 'Custom');
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 6),
                                            child: ChoiceChip(
                                              label: Text(label),
                                              selected: isSelected,
                                              onSelected: (sel) {
                                                if (sel) setState(() => _heatTime = slot);
                                              },
                                              selectedColor: AppColors.primary,
                                              checkmarkColor: Colors.white,
                                              labelStyle: TextStyle(
                                                color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                fontSize: 12,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_heatTime == 'custom') ...[
                              const SizedBox(height: 10),
                              CustomTextField(
                                controller: _customTimeController,
                                hint: 'e.g. 07:30 AM or 14:00',
                                label: 'Specific Heat Observation Time',
                              ),
                            ],
                            const SizedBox(height: 18),

                            // 3. Estrus Stage & Intensity Row
                            Row(
                              children: [
                                Expanded(
                                  child: CustomDropdownSearch<HeatStage>(
                                    label: 'Heat Stage',
                                    isRequired: true,
                                    items: HeatStage.values,
                                    selectedItem: _selectedStage,
                                    itemAsString: (s) => s.label,
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedStage = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: CustomDropdownSearch<HeatIntensity>(
                                    label: 'Intensity',
                                    isRequired: true,
                                    items: HeatIntensity.values,
                                    selectedItem: _selectedIntensity,
                                    itemAsString: (i) => i.label,
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedIntensity = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // 4. Clinical Estrus Signs (Multi-select Chips)
                            Text(
                              'Observed Heat Signs',
                              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: HeatSignDefinition.all.map((def) {
                                final isSelected = _selectedSigns.contains(def.code);
                                return FilterChip(
                                  label: Text(def.label),
                                  selected: isSelected,
                                  onSelected: (sel) {
                                    setState(() {
                                      if (sel) {
                                        _selectedSigns.add(def.code);
                                      } else {
                                        _selectedSigns.remove(def.code);
                                      }
                                    });
                                  },
                                  selectedColor: AppColors.primary,
                                  checkmarkColor: Colors.white,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 18),

                            // 5. Initial Status & Observed Worker
                            Row(
                              children: [
                                Expanded(
                                  child: CustomDropdownSearch<HeatStatus>(
                                    label: 'Heat Status',
                                    isRequired: true,
                                    items: HeatStatus.values,
                                    selectedItem: _selectedStatus,
                                    itemAsString: (s) => s.label,
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedStatus = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: CustomDropdownSearch<WorkerModel>(
                                    label: 'Observed By (Worker)',
                                    prefixIcon: PhosphorIconsRegular.user,
                                    items: _workers,
                                    selectedItem: _selectedWorker,
                                    itemAsString: (w) => '${w.name}${w.departmentName != null ? ' (${w.departmentName})' : ''}',
                                    searchable: true,
                                    compareFn: (a, b) => a.id == b.id,
                                    onChanged: (val) => setState(() => _selectedWorker = val),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // 6. Remarks
                            CustomTextField(
                              controller: _remarksController,
                              label: 'Remarks / Notes',
                              hint: 'Additional estrus behavior or mating recommendation notes...',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),

                            // 7. Automated Smart Alert Callout
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(PhosphorIconsRegular.info, color: Colors.amber.shade800, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Smart Detection Notice: The system automatically tracks cycle intervals. If this is the 3rd consecutive cycle without conception, a high-priority Repeat Heat Alert will be issued to the Veterinary Admin.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
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
                            text: 'Record Heat Cycle',
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
