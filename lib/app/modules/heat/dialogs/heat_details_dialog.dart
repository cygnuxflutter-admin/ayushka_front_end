import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/models/cow_heat_model.dart';
import '../../mating/dialogs/add_mating_dialog.dart';

/// Modal dialog displaying comprehensive Cow Heat observation details.
class HeatDetailsDialog extends StatelessWidget {
  final CowHeatModel heat;
  final VoidCallback? onHeatUpdated;

  const HeatDetailsDialog({
    super.key,
    required this.heat,
    this.onHeatUpdated,
  });

  static void show(BuildContext context, CowHeatModel heat, {VoidCallback? onHeatUpdated}) {
    showDialog(
      context: context,
      builder: (ctx) => HeatDetailsDialog(heat: heat, onHeatUpdated: onHeatUpdated),
    );
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
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                          'Heat Cycle Observation',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cattle: ${heat.cowTagId} • Cycle #${heat.consecutiveHeatCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: heat.status.bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: heat.status.color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      heat.status.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: heat.status.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // High Alert Banner (if repeat heat)
                  if (heat.isHighAlert) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(PhosphorIconsRegular.warningOctagon, color: Colors.red.shade700, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HIGH ALERT: Repeat Estrus Cycle (${heat.consecutiveHeatCount} Consecutive Cycles)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.red.shade300 : Colors.red.shade800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Cow has repeated heat cycles without conception. Veterinary evaluation for cystic ovaries or uterine infection is strongly advised.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.red.shade200 : Colors.red.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Information Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Cow Tag & Name', '${heat.cowTagId} ${heat.cowCalfName != null ? '(${heat.cowCalfName})' : ''}'),
                        const Divider(height: 16),
                        _buildInfoRow('Shed & Breed', '${heat.cowShedName ?? 'Unassigned Shed'} • ${heat.cowBreedName ?? 'Indigenous'}'),
                        const Divider(height: 16),
                        _buildInfoRow('Observation Date', '${heat.formattedHeatDate} (${heat.heatTime ?? 'N/A'})'),
                        const Divider(height: 16),
                        _buildInfoRow('Heat Stage', heat.heatStage.label),
                        const Divider(height: 16),
                        _buildInfoRow('Intensity', heat.intensity.label),
                        const Divider(height: 16),
                        _buildInfoRow('Observed By', heat.observedByWorkerName ?? 'Farm Worker'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Signs
                  Text(
                    'Clinical Estrus Signs',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (heat.heatSigns.isEmpty)
                    Text(
                      'No specific signs recorded.',
                      style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: heat.heatSigns.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            HeatSignDefinition.getLabel(s),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),

                  // Remarks
                  if (heat.remarks != null && heat.remarks!.isNotEmpty) ...[
                    Text(
                      'Remarks',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      heat.remarks!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Footer Actions
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  if (heat.status != HeatStatus.mated)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        AddMatingDialog.show(
                          context,
                          preselectedHeat: heat,
                        );
                      },
                      icon: const Icon(PhosphorIconsRegular.heartStraight, size: 18),
                      label: const Text('Record Mating For This Cow'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
