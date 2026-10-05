import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../dashboard_controller.dart';

/// Modal dialog allowing developers and testers to create real backend records
/// that immediately trigger alerts across treatments, milk yield, medical stock, and feed inventory.
class TestAlertGeneratorDialog extends StatefulWidget {
  final DashboardController controller;

  const TestAlertGeneratorDialog({
    super.key,
    required this.controller,
  });

  static Future<void> show(BuildContext context, DashboardController controller) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TestAlertGeneratorDialog(controller: controller),
    );
  }

  @override
  State<TestAlertGeneratorDialog> createState() => _TestAlertGeneratorDialogState();
}

class _TestAlertGeneratorDialogState extends State<TestAlertGeneratorDialog> {
  int? _loadingIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                      PhosphorIconsRegular.flask,
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
                          'Live API Alert Simulator',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Generate real test records via backend APIs to verify alert detection & inline actions.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Simulation Options Grid
              _buildOptionTile(
                index: 0,
                icon: PhosphorIconsRegular.firstAidKit,
                title: 'Critical Treatment Case & Dose',
                description: 'Creates a treatment record marked CRITICAL with today\'s dose due for immediate triage testing.',
                color: const Color(0xFFEF4444),
                isDark: isDark,
                onTrigger: () async {
                  setState(() => _loadingIndex = 0);
                  await widget.controller.generateTestTreatmentAlert();
                  setState(() => _loadingIndex = null);
                },
              ),
              const SizedBox(height: 10),

              _buildOptionTile(
                index: 1,
                icon: PhosphorIconsRegular.dropHalfBottom,
                title: 'Milk Variance Notification',
                description: 'Sends a milk production alert (-14.8% drop) to verify the milk tab and dismissal workflow.',
                color: const Color(0xFFF59E0B),
                isDark: isDark,
                onTrigger: () async {
                  setState(() => _loadingIndex = 1);
                  await widget.controller.generateTestMilkAlert();
                  setState(() => _loadingIndex = null);
                },
              ),
              const SizedBox(height: 10),

              _buildOptionTile(
                index: 2,
                icon: PhosphorIconsRegular.pill,
                title: 'Low Medical Stock & Expiring Batch',
                description: 'Registers an antibiotic SKU with 5 vials remaining (threshold: 50) and expiry within 18 days.',
                color: const Color(0xFF6366F1),
                isDark: isDark,
                onTrigger: () async {
                  setState(() => _loadingIndex = 2);
                  await widget.controller.generateTestMedicalAlert();
                  setState(() => _loadingIndex = null);
                },
              ),
              const SizedBox(height: 10),

              _buildOptionTile(
                index: 3,
                icon: PhosphorIconsRegular.plant,
                title: 'Low Feed Stock Shortfall',
                description: 'Inserts green fodder with 35 KG in stock against a 500 KG minimum safety buffer.',
                color: const Color(0xFF10B981),
                isDark: isDark,
                onTrigger: () async {
                  setState(() => _loadingIndex = 3);
                  await widget.controller.generateTestFeedAlert();
                  setState(() => _loadingIndex = null);
                },
              ),
              const SizedBox(height: 22),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  CustomButton(
                    text: 'Generate All 4 Alerts',
                    icon: PhosphorIconsRegular.lightning,
                    height: 40,
                    width: 210,
                    isLoading: _loadingIndex == 99,
                    onPressed: () async {
                      setState(() => _loadingIndex = 99);
                      await widget.controller.generateAllTestAlerts();
                      setState(() => _loadingIndex = null);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required int index,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isDark,
    required VoidCallback onTrigger,
  }) {
    final isLoading = _loadingIndex == index;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CustomButton(
            text: 'Add Alert',
            icon: PhosphorIconsRegular.plus,
            height: 32,
            width: 105,
            variant: ButtonVariant.outlined,
            isLoading: isLoading,
            onPressed: onTrigger,
          ),
        ],
      ),
    );
  }
}
