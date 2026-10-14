import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/cow_mating_model.dart';
import '../mating_controller.dart';

/// Modal dialog to record successful Calving for a pregnant cow.
class RecordCalvingDialog extends StatefulWidget {
  final CowMatingModel mating;

  const RecordCalvingDialog({
    super.key,
    required this.mating,
  });

  static Future<bool?> show(BuildContext context, CowMatingModel mating) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RecordCalvingDialog(mating: mating),
    );
  }

  @override
  State<RecordCalvingDialog> createState() => _RecordCalvingDialogState();
}

class _RecordCalvingDialogState extends State<RecordCalvingDialog> {
  final _formKey = GlobalKey<FormState>();
  final MatingController _matingController = Get.isRegistered<MatingController>()
      ? Get.find<MatingController>()
      : Get.put(MatingController());

  bool _isSubmitting = false;
  DateTime _calvingDate = DateTime.now();
  final TextEditingController _remarksController = TextEditingController(
    text: 'Healthy calf born. Normal unassisted delivery.',
  );

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matingDate = widget.mating.matingDate != null
        ? DateTime(widget.mating.matingDate!.year, widget.mating.matingDate!.month, widget.mating.matingDate!.day)
        : null;

    final minAllowed = matingDate != null
        ? matingDate.add(const Duration(days: 1))
        : today.subtract(const Duration(days: 365));
    final firstDate = minAllowed.isBefore(today) ? minAllowed : today;
    final lastDate = today;

    final initial = _calvingDate.isBefore(firstDate)
        ? firstDate
        : (_calvingDate.isAfter(lastDate) ? lastDate : _calvingDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'SELECT ACTUAL CALVING DATE',
    );
    if (picked != null) {
      setState(() => _calvingDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. Status Check: Cow must be confirmed pregnant
    if (!widget.mating.isPregnant) {
      CustomSnackbar.showError(
        title: 'Cow Not Pregnant',
        message: 'Calving can only be recorded for cows confirmed Pregnant (PD Positive). Current status is ${widget.mating.status.label}.',
      );
      return;
    }

    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final calvingDay = DateTime(_calvingDate.year, _calvingDate.month, _calvingDate.day);

    // 2. Future date check
    if (calvingDay.isAfter(todayEnd)) {
      CustomSnackbar.showError(
        title: 'Invalid Calving Date',
        message: 'Actual calving date cannot be in the future.',
      );
      return;
    }

    // 3. Mating date & gestation period checks
    if (widget.mating.matingDate != null) {
      final matingDay = DateTime(
        widget.mating.matingDate!.year,
        widget.mating.matingDate!.month,
        widget.mating.matingDate!.day,
      );

      if (calvingDay.isBefore(matingDay) || DateUtils.isSameDay(calvingDay, matingDay)) {
        CustomSnackbar.showError(
          title: 'Invalid Calving Date',
          message: 'Calving date cannot be on or before the mating date (${DateFormat('dd MMM yyyy').format(matingDay)}).',
        );
        return;
      }

      final gestationDays = calvingDay.difference(matingDay).inDays;
      if (gestationDays < 240) {
        CustomSnackbar.showError(
          title: 'Gestation Period Too Short ($gestationDays Days)',
          message: 'Normal bovine gestation is ~282 days (minimum viable pre-term is 240–260 days). Expected calving is ${widget.mating.formattedExpectedCalvingDate}. For early pregnancy loss, update status to Aborted.',
        );
        return;
      }
    }

    // 4. Pregnancy diagnosis check date comparison
    if (widget.mating.pdDate != null) {
      final pdDay = DateTime(
        widget.mating.pdDate!.year,
        widget.mating.pdDate!.month,
        widget.mating.pdDate!.day,
      );
      if (calvingDay.isBefore(pdDay)) {
        CustomSnackbar.showError(
          title: 'Invalid Date Sequence',
          message: 'Calving date cannot be before the Pregnancy Diagnosis examination date (${DateFormat('dd MMM yyyy').format(pdDay)}).',
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    final success = await _matingController.recordCalving(
      widget.mating.id,
      actualCalvingDate: DateFormat('yyyy-MM-dd').format(_calvingDate),
      remarks: _remarksController.text.trim().isNotEmpty
          ? _remarksController.text.trim()
          : null,
    );

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
        constraints: const BoxConstraints(maxWidth: 560),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                        color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.sparkle,
                        color: Color(0xFF0D9488),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Record Calving Event',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cow: ${widget.mating.cowTagId} • Expected: ${widget.mating.formattedExpectedCalvingDate}',
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

              // Form Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gestation Progress / Warning Banner
                    if (widget.mating.matingDate != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (widget.mating.daysSinceMating ?? 0) < 240
                              ? Colors.amber.withValues(alpha: 0.12)
                              : const Color(0xFF0D9488).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (widget.mating.daysSinceMating ?? 0) < 240
                                ? Colors.amber.shade400
                                : const Color(0xFF0D9488).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              (widget.mating.daysSinceMating ?? 0) < 240
                                  ? PhosphorIconsRegular.warning
                                  : PhosphorIconsRegular.calendarCheck,
                              color: (widget.mating.daysSinceMating ?? 0) < 240
                                  ? Colors.amber.shade800
                                  : const Color(0xFF0D9488),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gestation Progress: Day ${widget.mating.daysSinceMating ?? 0} of ~282',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: (widget.mating.daysSinceMating ?? 0) < 240
                                          ? Colors.amber.shade900
                                          : const Color(0xFF0D9488),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (widget.mating.daysSinceMating ?? 0) < 240
                                        ? 'Expected calving date is ${widget.mating.formattedExpectedCalvingDate}. Bovine full term is ~282 days. Viable calving cannot be recorded before 240+ days of gestation. For pregnancy loss, record status as Aborted.'
                                        : 'Full-term calving window reached. Enter the delivery date and calf remarks below.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: (widget.mating.daysSinceMating ?? 0) < 240
                                          ? Colors.amber.shade900
                                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Calving Date Picker
                    Text(
                      'Actual Calving Date *',
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
                            Text(DateFormat('dd MMM yyyy').format(_calvingDate)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Delivery & Calf Remarks
                    CustomTextField(
                      controller: _remarksController,
                      label: 'Delivery & Calf Details',
                      hint: 'e.g. Healthy female calf born, weight 22kg, unassisted delivery.',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Information Notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(PhosphorIconsRegular.info, color: Color(0xFF0D9488), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Automated Lifecycle Update: Submitting calving marks this mating cycle as CALVED and updates the cow\'s breeding status to CALVED.',
                              style: TextStyle(fontSize: 12, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                      text: 'Record Calving',
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
