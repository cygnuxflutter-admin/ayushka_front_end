import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../utils/responsive_layout.dart';
import '../values/app_colors.dart';
import '../values/app_constants.dart';
import 'custom_shimmer.dart';

/// Predefined sizes for the [CustomBrandedSpinner].
enum LoaderSize {
  small(32.0, 16.0, 10.0),
  medium(54.0, 26.0, 13.0),
  large(72.0, 36.0, 15.0);

  final double outerSize;
  final double innerSize;
  final double fontSize;

  const LoaderSize(this.outerSize, this.innerSize, this.fontSize);
}

/// A branded, organic dual-ring spinner with a pulsating center Ayushka icon
/// and animated bouncing loading dots.
class CustomBrandedSpinner extends StatefulWidget {
  final String? message;
  final String? subMessage;
  final LoaderSize size;
  final Color? primaryColor;
  final Color? accentColor;

  const CustomBrandedSpinner({
    super.key,
    this.message,
    this.subMessage,
    this.size = LoaderSize.medium,
    this.primaryColor,
    this.accentColor,
  });

  @override
  State<CustomBrandedSpinner> createState() => _CustomBrandedSpinnerState();
}

class _CustomBrandedSpinnerState extends State<CustomBrandedSpinner>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.90, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = widget.primaryColor ?? AppColors.primary;
    final accent = widget.accentColor ?? AppColors.accent;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size.outerSize,
            height: widget.size.outerSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Rotating Dual Arc
                AnimatedBuilder(
                  animation: _spinController,
                  builder: (context, _) {
                    return Transform.rotate(
                      angle: _spinController.value * 2 * math.pi,
                      child: CustomPaint(
                        size: Size(widget.size.outerSize, widget.size.outerSize),
                        painter: _DualArcPainter(
                          primaryColor: primary,
                          accentColor: accent,
                          strokeWidth: widget.size == LoaderSize.small ? 2.5 : 3.2,
                        ),
                      ),
                    );
                  },
                ),

                // Inner Pulsating Icon Badge
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: widget.size.innerSize,
                    height: widget.size.innerSize,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(widget.size == LoaderSize.small ? 2 : 5),
                    child: Image.asset(
                      AppConstants.logoIconPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        PhosphorIconsRegular.leaf,
                        size: widget.size.innerSize * 0.65,
                        color: primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Message & Animated Dots
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message!,
                  style: TextStyle(
                    fontSize: widget.size.fontSize,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 4),
                _AnimatedLoadingDots(
                  color: primary,
                  size: widget.size.fontSize * 0.35,
                ),
              ],
            ),
          ],

          if (widget.subMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.subMessage!,
              style: TextStyle(
                fontSize: (widget.size.fontSize - 2).clamp(10, 13),
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom painter for the rotating dual-arc loader.
class _DualArcPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final double strokeWidth;

  _DualArcPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final primaryPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Primary Arc (approx 120 degrees)
    canvas.drawArc(rect, 0.0, 2.1, false, primaryPaint);

    // Accent Arc (approx 80 degrees)
    canvas.drawArc(rect, math.pi, 1.4, false, accentPaint);
  }

  @override
  bool shouldRepaint(covariant _DualArcPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Three small dots that gently bounce or fade in sequence.
class _AnimatedLoadingDots extends StatefulWidget {
  final Color color;
  final double size;

  const _AnimatedLoadingDots({
    required this.color,
    required this.size,
  });

  @override
  State<_AnimatedLoadingDots> createState() => _AnimatedLoadingDotsState();
}

class _AnimatedLoadingDotsState extends State<_AnimatedLoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final double delay = index * 0.2;
            final double value = (_controller.value - delay).clamp(0.0, 1.0);
            final double opacity = math.sin(value * math.pi).abs().clamp(0.2, 1.0);

            return Opacity(
              opacity: opacity,
              child: Container(
                width: widget.size,
                height: widget.size,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Compact inline loader widget for search headers, buttons, and badges.
class CustomInlineLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const CustomInlineLoader({
    super.key,
    this.size = 16.0,
    this.color,
    this.strokeWidth = 2.0,
  });

  @override
  State<CustomInlineLoader> createState() => _CustomInlineLoaderState();
}

class _CustomInlineLoaderState extends State<CustomInlineLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;

    return RotationTransition(
      turns: _controller,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: widget.strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

/// Comprehensive List Loader widget.
/// Adapts seamlessly between Web/Desktop tables and Mobile/Tablet card lists during API calls.
class CustomListLoader extends StatelessWidget {
  /// Whether to show the table skeleton (Desktop/Web) or card skeleton (Mobile/App).
  /// If null, automatically determines based on screen width via [ResponsiveLayout].
  final bool? isTable;
  final int itemCount;
  final List<int> columnFlexes;
  final List<String>? headers;
  final String? message;
  final EdgeInsetsGeometry padding;

  const CustomListLoader({
    super.key,
    this.isTable,
    this.itemCount = 6,
    this.columnFlexes = const [6, 6, 5],
    this.headers,
    this.message,
    this.padding = EdgeInsets.zero,
  });

  /// Automatically adapts: Table skeleton on Web/Desktop, Card list skeleton on Mobile/Tablet.
  const CustomListLoader.adaptive({
    super.key,
    this.itemCount = 6,
    this.columnFlexes = const [6, 6, 5],
    this.headers,
    this.message,
    this.padding = EdgeInsets.zero,
  }) : isTable = null;

  /// Factory constructor for Desktop and Web data tables.
  const CustomListLoader.table({
    super.key,
    this.itemCount = 6,
    this.columnFlexes = const [6, 6, 5],
    this.headers,
    this.message,
    this.padding = EdgeInsets.zero,
  }) : isTable = true;

  /// Factory constructor for Mobile and Tablet card lists.
  const CustomListLoader.list({
    super.key,
    this.itemCount = 5,
    this.padding = EdgeInsets.zero,
    this.message,
  })  : isTable = false,
        columnFlexes = const [],
        headers = null;

  /// Factory constructor for Branded Centered Spinner.
  static Widget branded({
    String? message,
    String? subMessage,
    LoaderSize size = LoaderSize.medium,
    EdgeInsetsGeometry padding = const EdgeInsets.all(48.0),
  }) {
    return Padding(
      padding: padding,
      child: CustomBrandedSpinner(
        message: message,
        subMessage: subMessage,
        size: size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final useTable = isTable ?? ResponsiveLayout.isDesktop(context);

    if (useTable) {
      return CustomTableShimmer(
        rowCount: itemCount,
        columnFlexes: columnFlexes,
        headers: headers,
        showHeader: headers == null,
      );
    } else {
      return CustomListShimmer(
        itemCount: itemCount,
        padding: padding,
      );
    }
  }
}
