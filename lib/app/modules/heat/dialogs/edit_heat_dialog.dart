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
import '../../../data/models/worker_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/gaushala_session_service.dart';
import '../heat_controller.dart';

/// Dialog to update an existing Cow Heat observation record.
class EditHeatDialog extends StatefulWidget {
  final CowHeatModel heat;

  const EditHeatDialog({
    super.key,
    required this.heat,
  });

  static Future<bool?> show(BuildContext context, CowHeatModel heat) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EditHeatDialog(heat: heat),
    );
  }

  @override
  State<EditHeatDialog> createState() => _EditHeatDialogState();
}

class _EditHeatDialogState extends State<EditHeatDialog> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = Get.find<ApiService>();
  final GaushalaSessionService _gaushalaService = Get.find<GaushalaSessionService>();
  final HeatController _heatController = Get.isRegistered<HeatController>()
      ? Get.find<HeatController>()
      : Get.put(HeatController());

  bool _isLoadingDropdowns = true;
  bool _isSubmitting = false;

  List<WorkerModel> _workers = [];
  WorkerModel? _selectedWorker;

  late DateTime _heatDate;
  late String _heatTime;
  final TextEditingController _customTimeController = TextEditingController();
  late HeatStage _selectedStage;
  late HeatIntensity _selectedIntensity;
  late HeatStatus _selectedStatus;
  late Set<String> _selectedSigns;
  late TextEditingController _remarksController;

  final List<String> _quickTimeSlots = ['morning', 'evening', 'custom'];

  @override
  void initState() {
    super.initState();
    _heatDate = widget.heat.heatDate ?? DateTime.now();
    _heatTime = widget.heat.heatTime?.toLowerCase() ?? 'morning';
    if (_heatTime != 'morning' && _heatTime != 'evening') {
      _customTimeController.text = widget.heat.heatTime ?? '';
      _heatTime = 'custom';
    }
    _selectedStage = widget.heat.heatStage;
    _selectedIntensity = widget.heat.intensity;
    _selectedStatus = widget.heat.status;
    _selectedSigns = Set<String>.from(widget.heat.heatSigns);
    _remarksController = TextEditingController(text: widget.heat.remarks ?? '');
    _loadWorkers();
  }

  @override
  void dispose() {
    _customTimeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkers() async {
    final gId = widget.heat.gaushalaId.isNotEmpty
        ? widget.heat.gaushalaId
        : _gaushalaService.selectedGaushalaId;

    try {
      setState(() => _isLoadingDropdowns = true);
      final workersResult = await _apiService.getWorkers(gaushalaId: gId, limit: 100);
      if (mounted) {
        setState(() {
          _workers = workersResult.items.where((w) => w.isActive).toList();
          if (widget.heat.observedByWorkerId != null) {
            _selectedWorker = _workers.firstWhereOrNull((w) => w.id == widget.heat.observedByWorkerId);
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
    );
    if (picked != null) {
      setState(() => _heatDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final finalTime = _heatTime == 'custom'
        ? _customTimeController.text.trim()
        : _heatTime;

    final body = {
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
    final success = await _heatController.updateHeat(widget.heat.id, body);
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
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
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
                                  'Update Heat Record',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tag: ${widget.heat.cowTagId} • Cycle #${widget.heat.consecutiveHeatCount}',
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
                            // Date and Time Row
                            Row(
                              children: [
                                Expanded(
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
                                              Text(DateFormat('dd MMM yyyy').format(_heatDate)),
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
                                label: 'Specific Time',
                              ),
                            ],
                            const SizedBox(height: 18),

                            // Stage & Intensity Row
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

                            // Estrus Signs (Multi-select)
                            Text(
                              'Observed Signs',
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

                            // Status & Worker
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

                            // Remarks
                            CustomTextField(
                              controller: _remarksController,
                              label: 'Remarks / Notes',
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
                            text: 'Update Record',
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
