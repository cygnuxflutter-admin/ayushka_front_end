import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_loader.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/cow_model.dart';
import '../../../data/models/shed_model.dart';
import '../dashboard_controller.dart';

/// Interactive Modal Dialog for quickly allocating a shed to unassigned cattle.
class QuickAssignShedDialog extends StatefulWidget {
  final List<CowModel> unassignedCows;
  final CowModel? initialSelectedCow;
  final DashboardController controller;

  const QuickAssignShedDialog({
    super.key,
    required this.unassignedCows,
    this.initialSelectedCow,
    required this.controller,
  });

  static Future<bool?> show({
    required BuildContext context,
    required List<CowModel> unassignedCows,
    CowModel? initialSelectedCow,
    required DashboardController controller,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuickAssignShedDialog(
        unassignedCows: unassignedCows,
        initialSelectedCow: initialSelectedCow,
        controller: controller,
      ),
    );
  }

  @override
  State<QuickAssignShedDialog> createState() => _QuickAssignShedDialogState();
}

class _QuickAssignShedDialogState extends State<QuickAssignShedDialog> {
  final Set<String> _selectedCowIds = <String>{};
  final List<ShedModel> _sheds = <ShedModel>[];
  ShedModel? _selectedShed;

  bool _isLoadingSheds = true;
  bool _isSubmitting = false;

  late final TextEditingController _reasonController;
  DateTime _transferDate = DateTime.now();

  final List<String> _quickReasons = const [
    'Initial Shed Allocation',
    'Moved to milking shed',
    'Dry period segregation',
    'Medical quarantine',
    'Routine relocation',
  ];

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(text: 'Initial Shed Allocation');

    if (widget.initialSelectedCow != null) {
      _selectedCowIds.add(widget.initialSelectedCow!.id);
    } else if (widget.unassignedCows.isNotEmpty) {
      // If multiple, select the first one by default
      _selectedCowIds.add(widget.unassignedCows.first.id);
    }

    _loadSheds();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadSheds() async {
    setState(() => _isLoadingSheds = true);
    try {
      final list = await widget.controller.fetchActiveSheds();
      if (mounted) {
        setState(() {
          _sheds.assignAll(list);
          if (_sheds.isNotEmpty) {
            _selectedShed = _sheds.first;
          }
          _isLoadingSheds = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSheds = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transferDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Allocation Date',
    );
    if (picked != null && mounted) {
      setState(() => _transferDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedCowIds.isEmpty) {
      CustomSnackbar.showError(
        title: 'Validation',
        message: 'Please select at least one cattle to assign.',
      );
      return;
    }
    if (_selectedShed == null) {
      CustomSnackbar.showError(
        title: 'Validation',
        message: 'Please select a destination shed.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final ok = await widget.controller.assignCowToShed(
      cowIds: _selectedCowIds.toList(),
      targetShedId: _selectedShed!.id,
      reason: _reasonController.text.trim().isNotEmpty
          ? _reasonController.text.trim()
          : 'Initial Shed Allocation',
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (ok) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMultiCow = widget.unassignedCows.length > 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      PhosphorIconsFill.warehouse,
                      color: Color(0xFFD97706),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Allocate Shed to Cattle',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Assign unhoused cattle to an active shelter shed',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close',
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Scrollable Form Body
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Cattle Selection Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isMultiCow ? 'SELECT CATTLE (${_selectedCowIds.length}/${widget.unassignedCows.length})' : 'TARGET CATTLE',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                          if (isMultiCow)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (_selectedCowIds.length == widget.unassignedCows.length) {
                                    _selectedCowIds.clear();
                                    if (widget.unassignedCows.isNotEmpty) {
                                      _selectedCowIds.add(widget.unassignedCows.first.id);
                                    }
                                  } else {
                                    _selectedCowIds.addAll(widget.unassignedCows.map((c) => c.id));
                                  }
                                });
                              },
                              child: Text(
                                _selectedCowIds.length == widget.unassignedCows.length ? 'Deselect All' : 'Select All',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Cow Cards
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: Column(
                          children: widget.unassignedCows.map((cow) {
                            final isSelected = _selectedCowIds.contains(cow.id);
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setState(() {
                                  if (isMultiCow) {
                                    if (isSelected) {
                                      if (_selectedCowIds.length > 1) {
                                        _selectedCowIds.remove(cow.id);
                                      }
                                    } else {
                                      _selectedCowIds.add(cow.id);
                                    }
                                  } else {
                                    _selectedCowIds.clear();
                                    _selectedCowIds.add(cow.id);
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF2E2211) : const Color(0xFFFEF3C7))
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFF59E0B)
                                        : (isDark ? AppColors.borderDark.withValues(alpha: 0.3) : AppColors.borderLight),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                      size: 18,
                                      color: isSelected ? const Color(0xFFD97706) : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        cow.tagId,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cow.calfName != null && cow.calfName!.isNotEmpty
                                                ? cow.calfName!
                                                : (cow.breed?.breedName ?? 'Cattle'),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${cow.isFemale ? "Female" : "Male"}${cow.breed != null ? " • ${cow.breed!.breedName}" : ""}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'No Shed',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 2. Target Shed Dropdown
                      Text(
                        'DESTINATION SHED *',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_isLoadingSheds)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              CustomInlineLoader(size: 16),
                              SizedBox(width: 8),
                              Text('Loading active sheds...', style: TextStyle(fontSize: 12.5)),
                            ],
                          ),
                        )
                      else if (_sheds.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No sheds found for this Gaushala. Please create sheds in Shed Master first.',
                                  style: TextStyle(fontSize: 12.5, color: Color(0xFF991B1B)),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ShedModel>(
                              value: _selectedShed,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                              items: _sheds.map((s) {
                                return DropdownMenuItem<ShedModel>(
                                  value: s,
                                  child: Row(
                                    children: [
                                      const Icon(PhosphorIconsRegular.warehouse, size: 18, color: AppColors.primary),
                                      const SizedBox(width: 10),
                                      Text(
                                        s.shedNumber.isNotEmpty
                                            ? '${s.shedName} (${s.shedNumber})'
                                            : s.shedName,
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedShed = val);
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),

                      // 3. Reason Field & Quick Chips
                      CustomTextField(
                        label: 'Allocation Reason',
                        controller: _reasonController,
                        hint: 'e.g. Initial Shed Allocation',
                        prefixIcon: const Icon(PhosphorIconsRegular.notePencil, size: 18),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _quickReasons.map((r) {
                          return ActionChip(
                            label: Text(r, style: const TextStyle(fontSize: 11)),
                            backgroundColor: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
                            onPressed: () {
                              _reasonController.text = r;
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // 4. Date Picker
                      Text(
                        'ALLOCATION DATE',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(PhosphorIconsRegular.calendar, size: 18, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('dd MMM yyyy').format(_transferDate),
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              Text(
                                'Change',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.primary : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    text: 'Cancel',
                    variant: ButtonVariant.outlined,
                    height: 42,
                    width: 90,
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  CustomButton(
                    text: _isSubmitting ? 'Allocating...' : 'Assign Shed (${_selectedCowIds.length})',
                    icon: PhosphorIconsRegular.checkCircle,
                    height: 42,
                    isLoading: _isSubmitting,
                    onPressed: (_isSubmitting || _sheds.isEmpty || _selectedCowIds.isEmpty)
                        ? null
                        : _handleSubmit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
