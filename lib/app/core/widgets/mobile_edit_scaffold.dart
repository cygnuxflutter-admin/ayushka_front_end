import 'package:flutter/material.dart';
import '../values/app_colors.dart';
import 'custom_button.dart';

/// Reusable native-feeling mobile full-screen edit scaffold.
/// Replaces desktop dialogs on mobile viewport (< 768px).
class MobileEditScaffold extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final GlobalKey<FormState>? formKey;
  final List<Widget> children;
  final VoidCallback onSave;
  final VoidCallback? onCancel;
  final bool isSaving;
  final String saveText;
  final String cancelText;
  final Color? headerIconColor;
  final Color? headerIconBg;

  const MobileEditScaffold({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.formKey,
    required this.children,
    required this.onSave,
    this.onCancel,
    this.isSaving = false,
    this.saveText = 'Save Changes',
    this.cancelText = 'Cancel',
    this.headerIconColor,
    this.headerIconBg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = headerIconColor ?? AppColors.primary;
    final bgColor = headerIconBg ?? primaryColor.withValues(alpha: 0.12);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
            onPressed: onCancel ?? () => Navigator.of(context).pop(),
          ),
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: primaryColor, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      subtitle!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Divider(
                          height: 1,
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                        const SizedBox(height: 18),

                        // Form Fields
                        ...children,

                        const SizedBox(height: 24),
                        Divider(
                          height: 1,
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                        const SizedBox(height: 20),

                        // Actions
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: CustomButton(
                                text: cancelText,
                                variant: ButtonVariant.outlined,
                                height: 46,
                                onPressed: onCancel ?? () => Navigator.of(context).pop(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: CustomButton(
                                text: saveText,
                                icon: Icons.check_rounded,
                                isLoading: isSaving,
                                height: 46,
                                onPressed: onSave,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
