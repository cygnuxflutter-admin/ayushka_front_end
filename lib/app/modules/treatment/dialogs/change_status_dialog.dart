import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/core/values/app_colors.dart';
import '../../../../app/core/widgets/custom_button.dart';
import '../../../../app/core/widgets/custom_snackbar.dart';
import '../../../data/models/treatment_model.dart';
import '../../../data/services/api_service.dart';

/// Modal dialog to quickly update the treatment case status
class ChangeStatusDialog extends StatefulWidget {
  final CowTreatmentModel treatment;

  const ChangeStatusDialog({
    super.key,
    required this.treatment,
  });

  static Future<bool?> show(
    BuildContext context, {
    required CowTreatmentModel treatment,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ChangeStatusDialog(treatment: treatment),
    );
  }

  @override
  State<ChangeStatusDialog> createState() => _ChangeStatusDialogState();
}

class _ChangeStatusDialogState extends State<ChangeStatusDialog> {
  final ApiService _apiService = Get.find<ApiService>();

  late TreatmentStatus _selectedStatus;
  final TextEditingController _notesController = TextEditingController();
  bool _markCowDied = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.treatment.status;
    if (widget.treatment.recoveryNotes != null) {
      _notesController.text = widget.treatment.recoveryNotes!;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitStatus() async {
    setState(() => _isSubmitting = true);

    try {
      final success = await _apiService.updateTreatmentStatus(
        treatmentId: widget.treatment.id,
        status: _selectedStatus.code,
        recoveryNotes: _notesController.text.trim(),
        markCowDied: _selectedStatus == TreatmentStatus.deceased && _markCowDied,
      );

      if (success) {
        CustomSnackbar.showSuccess(
          title: 'Status Updated',
          message: 'Treatment case status changed to ${_selectedStatus.label}',
        );
        if (mounted) {
          Navigator.of(context).pop(true);
        } else if (Get.isDialogOpen ?? false) {
          Get.back(result: true);
        }
      } else {
        CustomSnackbar.showError(
          title: 'Error',
          message: 'Failed to update treatment status',
        );
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Error updating status: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final availableStatuses = [
      TreatmentStatus.underTreatment,
      TreatmentStatus.recovered,
      TreatmentStatus.critical,
      TreatmentStatus.closed,
      TreatmentStatus.deceased,
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(PhosphorIconsRegular.arrowsClockwise, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update Case Status',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Case #${widget.treatment.treatmentNumber} • Cow: ${widget.treatment.displayCowTag}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const Divider(height: 24),

              const Text('Select New Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Status Radios
              Column(
                children: availableStatuses.map((st) {
                  final isSelected = _selectedStatus == st;
                  return InkWell(
                    onTap: () => setState(() => _selectedStatus = st),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? st.bgColor
                            : (isDark ? AppColors.cardDark : Colors.grey.shade50),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? st.color : (isDark ? AppColors.borderDark : Colors.grey.shade200),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(st.icon, size: 18, color: st.color),
                          const SizedBox(width: 12),
                          Text(
                            st.label,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? st.color : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded, size: 18, color: st.color),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // If Deceased, show Mark Cow Died Checkbox
              if (_selectedStatus == TreatmentStatus.deceased) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _markCowDied,
                        activeColor: Colors.red,
                        onChanged: (val) => setState(() => _markCowDied = val ?? false),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _markCowDied = !_markCowDied),
                          child: const Text(
                            'Mark cow as officially died in livestock register',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Remarks
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Remarks / Clinical Notes',
                  hintText: 'e.g. Complete recovery achieved, animal eating well.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  CustomButton(
                    text: 'Save Status',
                    icon: PhosphorIconsRegular.floppyDisk,
                    width: 140,
                    height: 40,
                    isLoading: _isSubmitting,
                    onPressed: _submitStatus,
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
