import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/dashboard_alerts_model.dart';

/// Modal dialog for administering a scheduled treatment dose directly from the dashboard.
class AdministerDoseQuickDialog extends StatefulWidget {
  final TreatmentAlertItem alert;
  final String? defaultDoctorName;
  final Future<void> Function({
    required String treatmentId,
    required int doseNumber,
    required String administeredBy,
    required DateTime administeredDate,
    required String notes,
  }) onConfirm;

  const AdministerDoseQuickDialog({
    super.key,
    required this.alert,
    this.defaultDoctorName,
    required this.onConfirm,
  });

  @override
  State<AdministerDoseQuickDialog> createState() => _AdministerDoseQuickDialogState();
}

class _AdministerDoseQuickDialogState extends State<AdministerDoseQuickDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _doctorCtrl;
  late final TextEditingController _notesCtrl;
  DateTime _administeredDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _doctorCtrl = TextEditingController(
      text: widget.defaultDoctorName?.isNotEmpty == true
          ? widget.defaultDoctorName
          : 'Dr. Veterinary Officer',
    );
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _doctorCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _administeredDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_administeredDate),
    );
    if (!mounted) return;

    setState(() {
      _administeredDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? _administeredDate.hour,
        pickedTime?.minute ?? _administeredDate.minute,
      );
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onConfirm(
        treatmentId: widget.alert.treatmentId,
        doseNumber: widget.alert.dueDoseNumber,
        administeredBy: _doctorCtrl.text.trim(),
        administeredDate: _administeredDate,
        notes: _notesCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // Error handled by caller via snackbar
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.firstAidKit,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Administer Treatment Dose',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Confirm dose delivery for cattle medical record',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Treatment Meta Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : const Color(0xFFF7FAF7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.alert.cowTag,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                if (widget.alert.calfName != null && widget.alert.calfName!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${widget.alert.calfName})',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                                const Spacer(),
                                if (widget.alert.isCritical)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorBg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                                    ),
                                    child: const Text(
                                      'CRITICAL',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.alert.diseaseName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Scheduled Dose: Dose #${widget.alert.dueDoseNumber} of ${widget.alert.totalDoses}'
                              '${widget.alert.shedNumber != null ? " • Barn: ${widget.alert.shedNumber}" : ""}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Form Fields
                CustomTextField(
                  label: 'Administering Doctor / Staff',
                  hint: 'Enter practitioner name',
                  controller: _doctorCtrl,
                  prefixIcon: const Icon(PhosphorIconsRegular.userGear, size: 18),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Practitioner name is required' : null,
                ),
                const SizedBox(height: 14),

                // Date Time Row
                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(PhosphorIconsRegular.calendarBlank, size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Administered Date & Time',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd MMM yyyy, hh:mm a').format(_administeredDate),
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'Clinical Remarks & Observations (Optional)',
                  hint: 'Cow response, temperature, or medication notes...',
                  controller: _notesCtrl,
                  maxLines: 2,
                  prefixIcon: const Icon(PhosphorIconsRegular.notePencil, size: 18),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomButton(
                      text: 'Cancel',
                      variant: ButtonVariant.outlined,
                      height: 42,
                      width: 100,
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    CustomButton(
                      text: 'Confirm Administer',
                      icon: PhosphorIconsRegular.checkCircle,
                      height: 42,
                      width: 180,
                      isLoading: _isSubmitting,
                      onPressed: _handleSubmit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
