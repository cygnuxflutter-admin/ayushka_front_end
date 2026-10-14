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

/// Modal dialog to record Pregnancy Diagnosis (PD) Result for a cow mating.
class RecordPDDialog extends StatefulWidget {
  final CowMatingModel mating;

  const RecordPDDialog({
    super.key,
    required this.mating,
  });

  static Future<bool?> show(BuildContext context, CowMatingModel mating) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RecordPDDialog(mating: mating),
    );
  }

  @override
  State<RecordPDDialog> createState() => _RecordPDDialogState();
}

class _RecordPDDialogState extends State<RecordPDDialog> {
  final _formKey = GlobalKey<FormState>();
  final MatingController _matingController = Get.isRegistered<MatingController>()
      ? Get.find<MatingController>()
      : Get.put(MatingController());

  bool _isSubmitting = false;
  PDResult _pdResult = PDResult.positive;
  DateTime _pdDate = DateTime.now();
  late TextEditingController _performedByController;
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _performedByController = TextEditingController(
      text: widget.mating.inseminatorName ?? widget.mating.pdPerformedBy ?? '',
    );
  }

  @override
  void dispose() {
    _performedByController.dispose();
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

    final initial = _pdDate.isBefore(firstDate)
        ? firstDate
        : (_pdDate.isAfter(lastDate) ? lastDate : _pdDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'SELECT PD EXAMINATION DATE',
    );
    if (picked != null) {
      setState(() => _pdDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final pdDay = DateTime(_pdDate.year, _pdDate.month, _pdDate.day);

    // 1. Cannot be future date
    if (pdDay.isAfter(todayEnd)) {
      CustomSnackbar.showError(
        title: 'Invalid Examination Date',
        message: 'PD examination date cannot be in the future.',
      );
      return;
    }

    // 2. Cannot be on or before mating date
    if (widget.mating.matingDate != null) {
      final matingDay = DateTime(
        widget.mating.matingDate!.year,
        widget.mating.matingDate!.month,
        widget.mating.matingDate!.day,
      );

      if (pdDay.isBefore(matingDay) || DateUtils.isSameDay(pdDay, matingDay)) {
        CustomSnackbar.showError(
          title: 'Invalid PD Check Date',
          message: 'Pregnancy Diagnosis cannot occur on or before the mating date (${DateFormat('dd MMM yyyy').format(matingDay)}).',
        );
        return;
      }

      // 3. Minimum biological window: at least 28 days post-mating
      final diffDays = pdDay.difference(matingDay).inDays;
      if (diffDays < 28) {
        CustomSnackbar.showError(
          title: 'PD Check Too Early ($diffDays Days)',
          message: 'Pregnancy cannot be reliably diagnosed only $diffDays day(s) after mating. Minimum window is 28–45 days (Expected: ${widget.mating.formattedExpectedPDDate}).',
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    final success = await _matingController.updatePDStatus(
      widget.mating.id,
      pdResult: _pdResult.code,
      pdDate: DateFormat('yyyy-MM-dd').format(_pdDate),
      pdPerformedBy: _performedByController.text.trim().isNotEmpty
          ? _performedByController.text.trim()
          : null,
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
    final isPositive = _pdResult == PDResult.positive;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
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
                        color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPositive ? PhosphorIconsRegular.baby : PhosphorIconsRegular.xCircle,
                        color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pregnancy Diagnosis (PD) Check',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cow Tag: ${widget.mating.cowTagId} • Mated on: ${widget.mating.formattedMatingDate}',
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
                    // Early Examination Warning Banner
                    if (widget.mating.matingDate != null && (widget.mating.daysSinceMating ?? 0) < 28) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(PhosphorIconsRegular.warning, color: Colors.amber.shade800, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Premature PD Examination Notice',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Only ${widget.mating.daysSinceMating ?? 0} day(s) have passed since mating (${widget.mating.formattedMatingDate}). Clinical rectal palpation is typically performed at 45–60 days (Expected: ${widget.mating.formattedExpectedPDDate}). Minimum 28 days required.',
                                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Result Chooser: Positive vs Negative
                    Text(
                      'Diagnosis Result *',
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _pdResult = PDResult.positive),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isPositive
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : (isDark ? AppColors.cardDark : AppColors.cardLight),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isPositive
                                      ? Colors.green.shade600
                                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                  width: isPositive ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    PhosphorIconsRegular.checkCircle,
                                    color: isPositive ? Colors.green.shade700 : Colors.grey,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'POSITIVE (Pregnant)',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          'Conception confirmed',
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
                            onTap: () => setState(() => _pdResult = PDResult.negative),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: !isPositive
                                    ? Colors.red.withValues(alpha: 0.12)
                                    : (isDark ? AppColors.cardDark : AppColors.cardLight),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !isPositive
                                      ? Colors.red.shade600
                                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                  width: !isPositive ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    PhosphorIconsRegular.xCircle,
                                    color: !isPositive ? Colors.red.shade700 : Colors.grey,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'NEGATIVE (Failed / Open)',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          'Not pregnant / Open cow',
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

                    // PD Check Date & Performed By
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PD Examination Date *',
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
                                      Text(DateFormat('dd MMM yyyy').format(_pdDate)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: CustomTextField(
                            controller: _performedByController,
                            label: 'Veterinary Examiner',
                            hint: 'Dr. Patel / Vet Officer',
                            prefixIcon: const Icon(PhosphorIconsRegular.stethoscope, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Remarks
                    CustomTextField(
                      controller: _remarksController,
                      label: 'Clinical Examination Notes',
                      hint: isPositive
                          ? 'e.g. Pregnancy confirmed at 60 days via rectal palpation.'
                          : 'e.g. No uterine enlargement detected. Check for estrus in 21 days.',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Workflow explanation card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isPositive ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (isPositive ? Colors.green : Colors.orange).shade300,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isPositive ? PhosphorIconsRegular.info : PhosphorIconsRegular.warning,
                            color: isPositive ? Colors.green.shade800 : Colors.orange.shade800,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isPositive
                                  ? 'Automated Workflow: Confirming POSITIVE updates mating status to PREGNANT, sets cow\'s breeding status to PREGNANT, and calculates expected calving date (~282 days).'
                                  : 'Automated Workflow: Recording NEGATIVE sets mating status to FAILED, reverts cow\'s breeding status to OPEN, and triggers a Repeat Breeder Alert if this is the 3rd failed attempt.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black87,
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
                      text: isPositive ? 'Confirm Pregnancy' : 'Record Failed PD',
                      icon: isPositive ? PhosphorIconsRegular.check : PhosphorIconsRegular.x,
                      backgroundColor: isPositive ? AppColors.primary : Colors.red.shade700,
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
