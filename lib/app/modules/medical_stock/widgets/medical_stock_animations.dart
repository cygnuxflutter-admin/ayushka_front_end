import 'package:flutter/material.dart';
import '../../../core/values/app_colors.dart';

/// Staggered Entrance Animation Widget
/// Animates opacity and vertical translation with a staggered delay based on [index] or [delay].
class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration? delay;
  final Duration duration;
  final Offset slideOffset;
  final Curve curve;

  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delay,
    this.duration = const Duration(milliseconds: 380),
    this.slideOffset = const Offset(0, 16),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _isScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    final delay = widget.delay ?? Duration(milliseconds: 40 * widget.index);
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      _isScheduled = true;
      Future.delayed(delay, () {
        if (mounted && _isScheduled) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _isScheduled = false;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Animated Number Counter (Count-up Animation)
/// Smoothly animates numbers from 0 or old value to the new value using easing curves.
class AnimatedCountNumber extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final String prefix;
  final String suffix;
  final int decimalPlaces;

  const AnimatedCountNumber({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 650),
    this.curve = Curves.easeOutCubic,
    this.prefix = '',
    this.suffix = '',
    this.decimalPlaces = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, val, child) {
        final formatted = decimalPlaces > 0
            ? val.toStringAsFixed(decimalPlaces)
            : val.round().toString();
        return Text(
          '$prefix$formatted$suffix',
          style: style,
        );
      },
    );
  }
}

/// Hover Lift Card with dynamic shadows, border transition, and subtle zoom
class HoverLiftCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color? accentColor;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double liftDistance;

  const HoverLiftCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.onTap,
    this.accentColor,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.liftDistance = 4.0,
  });

  @override
  State<HoverLiftCard> createState() => _HoverLiftCardState();
}

class _HoverLiftCardState extends State<HoverLiftCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.circular(14);
    final accent = widget.accentColor ?? AppColors.primary;
    final isClickable = widget.onTap != null;

    return MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          0.0,
          _isHovered ? -widget.liftDistance : 0.0,
          0.0,
        ),
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.white,
          borderRadius: br,
          border: Border.all(
            color: _isHovered
                ? accent.withValues(alpha: 0.55)
                : AppColors.borderLight,
            width: _isHovered ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? accent.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.025),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 8 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: br,
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Pulsing Breathing Badge for Alerts (Needs Reorder, Expiry, Critical Risk)
class PulsingBadge extends StatefulWidget {
  final Widget child;
  final bool isPulsing;
  final Duration duration;

  const PulsingBadge({
    super.key,
    required this.child,
    this.isPulsing = true,
    this.duration = const Duration(milliseconds: 1800),
  });

  @override
  State<PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<PulsingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _opacityAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulsingBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPulsing) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Interactive Hoverable Table Row with soft highlight and left indicator
class HoverableTableRow extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? normalColor;
  final Color? hoverColor;
  final Color? activeIndicatorColor;
  final bool isSelected;
  final EdgeInsetsGeometry padding;
  final BoxBorder? border;

  const HoverableTableRow({
    super.key,
    required this.child,
    this.onTap,
    this.normalColor,
    this.hoverColor,
    this.activeIndicatorColor,
    this.isSelected = false,
    this.padding = EdgeInsets.zero,
    this.border,
  });

  @override
  State<HoverableTableRow> createState() => _HoverableTableRowState();
}

class _HoverableTableRowState extends State<HoverableTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveHover = widget.hoverColor ?? const Color(0xFFF6FAF3);
    final effectiveNormal = widget.normalColor ?? Colors.transparent;
    final accentIndicator = widget.activeIndicatorColor ?? AppColors.primary;

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: _isHovered || widget.isSelected ? effectiveHover : effectiveNormal,
          border: widget.border ??
              const Border(bottom: BorderSide(color: AppColors.dividerLight)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            child: Stack(
              children: [
                // Animated Left Accent Indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: (_isHovered || widget.isSelected) ? 3.5 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentIndicator,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: (_isHovered || widget.isSelected) ? 4.0 : 0.0),
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated Sub-Tab Item with hover transition, active pill, and badge counter
class AnimatedModuleTabItem extends StatefulWidget {
  final int index;
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color? iconColor;
  final String? badge;
  final Color? badgeColor;

  const AnimatedModuleTabItem({
    super.key,
    required this.index,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.iconColor,
    this.badge,
    this.badgeColor,
  });

  @override
  State<AnimatedModuleTabItem> createState() => _AnimatedModuleTabItemState();
}

class _AnimatedModuleTabItemState extends State<AnimatedModuleTabItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    final primaryColor = widget.iconColor ?? AppColors.primary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(
            0.0,
            _isHovered && !active ? -1.5 : 0.0,
            0.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? Colors.white
                : (_isHovered ? Colors.white.withValues(alpha: 0.7) : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : (_isHovered ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent),
              width: active ? 1.2 : 1.0,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : (_isHovered
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _isHovered || active ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutBack,
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: active
                      ? AppColors.primary
                      : (_isHovered ? primaryColor : (widget.iconColor ?? AppColors.textSecondaryLight)),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: active ? FontWeight.bold : (_isHovered ? FontWeight.w600 : FontWeight.w500),
                  color: active
                      ? AppColors.textPrimaryLight
                      : (_isHovered ? AppColors.textPrimaryLight : AppColors.textSecondaryLight),
                ),
                child: Text(widget.label),
              ),
              if (widget.badge != null) ...[
                const SizedBox(width: 8),
                AnimatedScale(
                  scale: active ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 160),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: (widget.badgeColor ?? AppColors.primary).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.badge!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.badgeColor ?? AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated View Switcher for smooth tab cross-fades with vertical slide
class AnimatedModuleViewSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const AnimatedModuleViewSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 260),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          fit: StackFit.loose,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (widgetChild, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.015),
              end: Offset.zero,
            ).animate(animation),
            child: widgetChild,
          ),
        );
      },
      child: child,
    );
  }
}

