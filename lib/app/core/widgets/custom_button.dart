import 'package:flutter/material.dart';
import '../values/app_colors.dart';
import '../values/app_constants.dart';

enum ButtonVariant { primary, secondary, outlined, danger }

/// Adaptive, accessible button with hover states and loading spinner support.
class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48.0,
    this.borderRadius = AppConstants.defaultBorderRadius,
    this.padding,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    switch (widget.variant) {
      case ButtonVariant.primary:
        backgroundColor = _isHovered
            ? const Color(0xFF4C6437)
            : AppColors.primary;
        foregroundColor = Colors.white;
        borderSide = BorderSide.none;
        break;
      case ButtonVariant.secondary:
        backgroundColor = _isHovered
            ? AppColors.secondary.withValues(alpha: 0.85)
            : AppColors.secondary;
        foregroundColor = Colors.white;
        borderSide = BorderSide.none;
        break;
      case ButtonVariant.outlined:
        backgroundColor = _isHovered
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent;
        foregroundColor = AppColors.primary;
        borderSide = BorderSide(
          color: _isHovered ? AppColors.primary : AppColors.borderLight,
          width: 1.2,
        );
        break;
      case ButtonVariant.danger:
        backgroundColor = _isHovered
            ? AppColors.error.withValues(alpha: 0.85)
            : AppColors.error;
        foregroundColor = Colors.white;
        borderSide = BorderSide.none;
        break;
    }

    if (widget.backgroundColor != null) {
      backgroundColor = _isHovered
          ? widget.backgroundColor!.withValues(alpha: 0.85)
          : widget.backgroundColor!;
    }

    if (widget.textColor != null) {
      foregroundColor = widget.textColor!;
    }

    if (!isEnabled) {
      backgroundColor = backgroundColor.withValues(alpha: 0.5);
      foregroundColor = foregroundColor.withValues(alpha: 0.7);
    }

    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        width: widget.width,
        height: widget.height,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: borderSide != BorderSide.none
              ? Border.all(color: borderSide.color, width: borderSide.width)
              : null,
          boxShadow: _isHovered && isEnabled && widget.variant != ButtonVariant.outlined
              ? [
                  BoxShadow(
                    color: backgroundColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            onTap: isEnabled ? widget.onPressed : null,
            child: Center(
              widthFactor: widget.width == null ? 1.0 : null,
              child: Padding(
                padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16.0),
                child: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 18, color: foregroundColor),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              widget.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: foregroundColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
