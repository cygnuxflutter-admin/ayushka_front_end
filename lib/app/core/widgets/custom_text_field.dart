import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../values/app_colors.dart';
import '../values/app_constants.dart';

/// Formatter that automatically converts all entered text to uppercase.
class UpperCaseTextFormatter extends TextInputFormatter {
  const UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// Standard form input field designed for seamless mobile touch and desktop keyboard interaction.
class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final int maxLines;
  final FocusNode? focusNode;
  final bool isUpperCase;
  final TextCapitalization? textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool? isDense;
  final EdgeInsetsGeometry? contentPadding;
  final BoxConstraints? prefixIconConstraints;
  final bool? enabled;
  final bool floatingLabel;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.maxLines = 1,
    this.focusNode,
    this.isUpperCase = false,
    this.textCapitalization,
    this.inputFormatters,
    this.isDense,
    this.contentPadding,
    this.prefixIconConstraints,
    this.enabled,
    this.floatingLabel = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _ensureUppercase();
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureUppercase();
  }

  void _ensureUppercase() {
    if (widget.isUpperCase && widget.controller != null && widget.controller!.text.isNotEmpty) {
      final upper = widget.controller!.text.toUpperCase();
      if (upper != widget.controller!.text) {
        widget.controller!.value = widget.controller!.value.copyWith(
          text: upper,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveCapitalization = widget.textCapitalization ??
        (widget.isUpperCase ? TextCapitalization.characters : TextCapitalization.none);

    final List<TextInputFormatter> effectiveFormatters = [
      if (widget.inputFormatters != null)
        ...widget.inputFormatters!
      else ...[
        if (widget.keyboardType == TextInputType.phone)
          FilteringTextInputFormatter.digitsOnly
        else if (widget.keyboardType.decimal == true)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        else if (widget.keyboardType == TextInputType.number ||
            widget.keyboardType == const TextInputType.numberWithOptions())
          FilteringTextInputFormatter.digitsOnly,
      ],
      if (widget.isUpperCase) const UpperCaseTextFormatter(),
    ];

    final showExternalLabel = widget.label != null && !widget.floatingLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showExternalLabel) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          validator: widget.validator,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: effectiveCapitalization,
          inputFormatters: effectiveFormatters.isNotEmpty ? effectiveFormatters : null,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          readOnly: widget.readOnly,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            isDense: widget.isDense ?? true,
            labelText: widget.floatingLabel ? widget.label : null,
            floatingLabelBehavior: widget.floatingLabel ? FloatingLabelBehavior.auto : FloatingLabelBehavior.never,
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            floatingLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            prefixIcon: widget.prefixIcon,
            prefixIconConstraints: widget.prefixIconConstraints ??
                (widget.prefixIcon != null ? const BoxConstraints(minWidth: 40, minHeight: 40) : null),
            suffixIcon: widget.isPassword
                ? MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    ),
                  )
                : widget.suffixIcon,
            suffixIconConstraints: (widget.suffixIcon != null || widget.isPassword)
                ? const BoxConstraints(minWidth: 40, minHeight: 40)
                : null,
            filled: true,
            fillColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
            contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.8,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              borderSide: BorderSide(
                color: (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
