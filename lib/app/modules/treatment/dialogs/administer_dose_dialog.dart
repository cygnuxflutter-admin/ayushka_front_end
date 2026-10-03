import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/core/values/app_colors.dart';
import '../../../../app/core/widgets/custom_button.dart';
import '../../../../app/core/widgets/custom_snackbar.dart';
import '../../../data/models/treatment_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/storage_service.dart';

class _DoseMedEntry {
  bool isStockItem;
  String? itemId;
  final TextEditingController nameController;
  final TextEditingController dosageController;
  String unit;
  String route;
  final TextEditingController notesController;

  _DoseMedEntry({
    this.isStockItem = false,
    this.itemId,
    String name = '',
    String dosage = '',
    this.unit = 'ML',
    this.route = 'IM',
    String notes = '',
  })  : nameController = TextEditingController(text: name),
        dosageController = TextEditingController(text: dosage),
        notesController = TextEditingController(text: notes);

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    notesController.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'isStockItem': isStockItem,
      if (itemId != null && itemId!.isNotEmpty) 'itemId': itemId,
      'medicineName': nameController.text.trim(),
      'dosage': dosageController.text.trim(),
      'unit': unit,
      'route': route,
      if (notesController.text.trim().isNotEmpty)
        'notes': notesController.text.trim(),
    };
  }
}

/// Dialog to record administration of a scheduled dose (Dose 2, 3, etc.)
class AdministerDoseDialog extends StatefulWidget {
  final CowTreatmentModel treatment;
  final int doseNumber;

  const AdministerDoseDialog({
    super.key,
    required this.treatment,
    required this.doseNumber,
  });

  static Future<bool?> show(
    BuildContext context, {
    required CowTreatmentModel treatment,
    required int doseNumber,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AdministerDoseDialog(
        treatment: treatment,
        doseNumber: doseNumber,
      ),
    );
  }

  @override
  State<AdministerDoseDialog> createState() => _AdministerDoseDialogState();
}

class _AdministerDoseDialogState extends State<AdministerDoseDialog> {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  late DateTime _administeredDateTime;
  late final TextEditingController _administeredByController;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _recoveryNotesController = TextEditingController();

  bool _markCompleted = false;
  bool _isSubmitting = false;

  final List<_DoseMedEntry> _medicines = [];

  final List<String> _units = ['ML', 'BOLUS', 'VIAL', 'TABLET', 'PIECE', 'GM', 'KG', 'TUBE', 'AMPUL'];
  final List<String> _routes = ['IM', 'IV', 'ORAL', 'TOPICAL', 'SC', 'INTRAMAMMARY'];

  bool get isFinalDose => widget.doseNumber >= widget.treatment.totalDoses;

  @override
  void initState() {
    super.initState();
    _administeredDateTime = DateTime.now();

    // Default administeredBy to logged-in user or case doctor
    final user = _storageService.getUser();
    final defaultStaff = user?.name.isNotEmpty == true
        ? user!.name
        : (widget.treatment.doctorName.isNotEmpty ? widget.treatment.doctorName : 'Attending Vet');
    _administeredByController = TextEditingController(text: defaultStaff);

    // If it's the final dose, default _markCompleted to true
    if (isFinalDose) {
      _markCompleted = true;
    }

    // Pre-populate medicines from existing prescribed medicines
    final sourceMeds = widget.treatment.medicines;
    if (sourceMeds.isNotEmpty) {
      for (final m in sourceMeds) {
        _medicines.add(_DoseMedEntry(
          isStockItem: m.isStockItem,
          itemId: m.itemId,
          name: m.medicineName,
          dosage: m.dosage,
          unit: m.unit.isNotEmpty ? m.unit.toUpperCase() : 'ML',
          route: m.route.isNotEmpty ? m.route.toUpperCase() : 'IM',
          notes: m.notes ?? '',
        ));
      }
    } else {
      _medicines.add(_DoseMedEntry(name: 'Prescribed Medicine', dosage: '10 ml'));
    }
  }

  @override
  void dispose() {
    _administeredByController.dispose();
    _notesController.dispose();
    _recoveryNotesController.dispose();
    for (final m in _medicines) {
      m.dispose();
    }
    super.dispose();
  }

  void _addMedicine() {
    setState(() {
      _medicines.add(_DoseMedEntry(name: '', dosage: ''));
    });
  }

  void _removeMedicine(int index) {
    if (_medicines.length <= 1) {
      CustomSnackbar.showWarning(
        title: 'Medicine Required',
        message: 'At least one medicine must be administered with the dose',
      );
      return;
    }
    setState(() {
      _medicines[index].dispose();
      _medicines.removeAt(index);
    });
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _administeredDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 14)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_administeredDateTime),
    );

    if (pickedTime != null) {
      setState(() {
        _administeredDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    } else {
      setState(() {
        _administeredDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _administeredDateTime.hour,
          _administeredDateTime.minute,
        );
      });
    }
  }

  Future<void> _submitAdministerDose() async {
    if (_administeredByController.text.trim().isEmpty) {
      CustomSnackbar.showWarning(
        title: 'Validation',
        message: 'Please specify the name of the staff or doctor administering this dose',
      );
      return;
    }

    // Validate medicines
    for (int i = 0; i < _medicines.length; i++) {
      if (_medicines[i].nameController.text.trim().isEmpty) {
        CustomSnackbar.showWarning(
          title: 'Validation',
          message: 'Please provide medicine name for entry #${i + 1}',
        );
        return;
      }
      if (_medicines[i].dosageController.text.trim().isEmpty) {
        CustomSnackbar.showWarning(
          title: 'Validation',
          message: 'Please specify dosage for entry #${i + 1}',
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'administeredDate': _administeredDateTime.toIso8601String(),
        'administeredBy': _administeredByController.text.trim(),
        'notes': _notesController.text.trim(),
        'recoveryNotes': _recoveryNotesController.text.trim(),
        'markCompleted': _markCompleted,
        'medicines': _medicines.map((m) => m.toJson()).toList(),
      };

      final updatedTreatment = await _apiService.administerDose(
        treatmentId: widget.treatment.id,
        doseNumber: widget.doseNumber,
        data: payload,
      );

      if (updatedTreatment != null) {
        CustomSnackbar.showSuccess(
          title: 'Dose Administered',
          message: 'Dose #${widget.doseNumber} recorded successfully.',
        );
        if (mounted) {
          Navigator.of(context).pop(true);
        } else if (Get.isDialogOpen ?? false) {
          Get.back(result: true);
        }
      } else {
        CustomSnackbar.showError(
          title: 'Error',
          message: 'Failed to record dose administration',
        );
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Error recording dose: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 760),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    child: const Icon(PhosphorIconsRegular.syringe, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Administer Dose #${widget.doseNumber} of ${widget.treatment.totalDoses}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Cow: ${widget.treatment.displayCowTag} (${widget.treatment.displayCowName}) • Disease: ${widget.treatment.diseaseName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
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

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date & Administered By Row
                    Row(
                      children: [
                        // Date & Time Picker
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Administered Date & Time *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _pickDateTime,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.cardDark : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(PhosphorIconsRegular.calendarBlank, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('dd MMM yyyy, hh:mm a').format(_administeredDateTime),
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Administered By Field
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Administered By *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _administeredByController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Dr. Rajesh / Staff Name',
                                  prefixIcon: const Icon(PhosphorIconsRegular.user, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Progress / Clinical Notes
                    const Text('Progress / Clinical Notes for this Dose', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Swelling reduced significantly, cow started eating, normal body temp...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Medicines Administered in this Dose
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Medicines Administered in this Dose',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Pre-filled with treatment protocol; you can adjust dosages or add outside drugs',
                              style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: _addMedicine,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Medicine'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _medicines.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final med = _medicines[idx];
                        final currentUnit = _units.contains(med.unit.toUpperCase()) ? med.unit.toUpperCase() : _units.first;
                        final currentRoute = _routes.contains(med.route.toUpperCase()) ? med.route.toUpperCase() : _routes.first;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : const Color(0xFFF9FAF7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: med.isStockItem
                                          ? AppColors.primary.withValues(alpha: 0.1)
                                          : AppColors.warningBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      med.isStockItem ? 'INVENTORY STOCK' : 'PRESCRIBED DRUG',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: med.isStockItem ? AppColors.primary : AppColors.warning,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Medicine #${idx + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const Spacer(),
                                  if (_medicines.length > 1)
                                    IconButton(
                                      icon: const Icon(PhosphorIconsRegular.trash, size: 16, color: Colors.red),
                                      tooltip: 'Remove',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _removeMedicine(idx),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 560;

                                  final medicineNameField = TextField(
                                    controller: med.nameController,
                                    style: const TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: 'Medicine Name',
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  );

                                  final dosageField = TextField(
                                    controller: med.dosageController,
                                    style: const TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: 'Dosage',
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  );

                                  final unitField = DropdownButtonFormField<String>(
                                    initialValue: currentUnit,
                                    isDense: true,
                                    isExpanded: true,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Unit',
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    items: _units.map((u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u, overflow: TextOverflow.ellipsis),
                                    )).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => med.unit = val);
                                    },
                                  );

                                  final routeField = DropdownButtonFormField<String>(
                                    initialValue: currentRoute,
                                    isDense: true,
                                    isExpanded: true,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Route',
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    items: _routes.map((r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(r, overflow: TextOverflow.ellipsis),
                                    )).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => med.route = val);
                                    },
                                  );

                                  if (isWide) {
                                    return Row(
                                      children: [
                                        Expanded(flex: 4, child: medicineNameField),
                                        const SizedBox(width: 8),
                                        Expanded(flex: 2, child: dosageField),
                                        const SizedBox(width: 8),
                                        Expanded(flex: 2, child: unitField),
                                        const SizedBox(width: 8),
                                        Expanded(flex: 2, child: routeField),
                                      ],
                                    );
                                  }

                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(flex: 3, child: medicineNameField),
                                          const SizedBox(width: 8),
                                          Expanded(flex: 2, child: dosageField),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(child: unitField),
                                          const SizedBox(width: 8),
                                          Expanded(child: routeField),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Completion / Recovery Section
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _markCompleted ? AppColors.successBg : (isDark ? AppColors.cardDark : Colors.grey.shade50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _markCompleted ? AppColors.success.withValues(alpha: 0.3) : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _markCompleted,
                                activeColor: AppColors.success,
                                onChanged: (val) => setState(() => _markCompleted = val ?? false),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _markCompleted = !_markCompleted),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mark Case as Recovered upon this dose',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                          color: _markCompleted ? AppColors.success : null,
                                        ),
                                      ),
                                      Text(
                                        isFinalDose
                                            ? 'Recommended: this is the final dose in the treatment protocol'
                                            : 'Check this if the cow has fully recovered ahead of schedule',
                                        style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_markCompleted) ...[
                            const SizedBox(height: 10),
                            TextField(
                              controller: _recoveryNotesController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'Discharge / Recovery Remarks',
                                hintText: 'e.g. Milk returned to normal quality, normal appetite restored, case closed.',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  CustomButton(
                    text: 'Confirm Administration',
                    icon: PhosphorIconsRegular.checkCircle,
                    width: 220,
                    height: 42,
                    isLoading: _isSubmitting,
                    onPressed: _submitAdministerDose,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
