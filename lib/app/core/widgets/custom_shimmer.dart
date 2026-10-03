import 'package:flutter/material.dart';
import '../values/app_colors.dart';

/// Shimmer animation widget using ShaderMask and a sliding gradient transform.
/// Provides a fluid, GPU-accelerated skeleton shimmer effect across Web and Mobile.
class CustomShimmer extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const CustomShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<CustomShimmer> createState() => _CustomShimmerState();
}

class _CustomShimmerState extends State<CustomShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Organic brand-aligned shimmer tones
    final Color base = widget.baseColor ??
        (isDark ? const Color(0xFF1E2D1C) : const Color(0xFFE8EFE5));
    final Color highlight = widget.highlightColor ??
        (isDark ? const Color(0xFF2C4029) : const Color(0xFFF7FAF5));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              stops: const [0.15, 0.5, 0.85],
              colors: [base, highlight, base],
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0.0,
      0.0,
    );
  }
}

/// A placeholder shape (box or circle) rendered inside a [CustomShimmer].
class ShimmerPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;

  const ShimmerPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 6.0,
    this.shape = BoxShape.rectangle,
    this.margin,
  });

  const ShimmerPlaceholder.circle({
    super.key,
    required double size,
    this.margin,
  })  : width = size,
        height = size,
        borderRadius = 0,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: shape,
        borderRadius:
            shape == BoxShape.rectangle ? BorderRadius.circular(borderRadius) : null,
      ),
    );
  }
}

/// Shimmer Skeleton Table for Web and Desktop Master Screens.
/// Replicates the exact layout of data tables with realistic placeholders.
class CustomTableShimmer extends StatelessWidget {
  final int rowCount;
  final List<int> columnFlexes;
  final bool showHeader;
  final List<String>? headers;

  const CustomTableShimmer({
    super.key,
    this.rowCount = 6,
    this.columnFlexes = const [6, 6, 5],
    this.showHeader = true,
    this.headers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget buildHeaderRow() {
      if (!showHeader && headers == null) return const SizedBox.shrink();

      if (headers != null && headers!.isNotEmpty) {
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withValues(alpha: 0.6)
                : const Color(0xFFF9FAFB),
            border: const Border(
              left: BorderSide(color: Colors.transparent, width: 3.5),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56.5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Text(
                    headers![0],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
              ...columnFlexes.asMap().entries.map((entry) {
                final colIndex = entry.key + 1;
                final flex = entry.value;
                final title = colIndex < headers!.length ? headers![colIndex] : '';
                return Expanded(
                  flex: flex,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }

      return CustomShimmer(
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withValues(alpha: 0.6)
                : const Color(0xFFF9FAFB),
            border: const Border(
              left: BorderSide(color: Colors.transparent, width: 3.5),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 56.5,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: ShimmerPlaceholder(width: 18, height: 12),
                ),
              ),
              ...columnFlexes.map((flex) {
                return Expanded(
                  flex: flex,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ShimmerPlaceholder(width: 90, height: 12),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    final rows = CustomShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...List.generate(rowCount, (index) {
          return Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 0.6,
                ),
                left: const BorderSide(color: Colors.transparent, width: 3.5),
              ),
            ),
              child: Row(
                children: [
                  // Row Index #
                  SizedBox(
                    width: 56.5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      child: ShimmerPlaceholder(
                        width: index > 8 ? 20 : 14,
                        height: 14,
                        borderRadius: 3,
                      ),
                    ),
                  ),

                  // Col 1: Main Title badge with icon
                  Expanded(
                    flex: columnFlexes.isNotEmpty ? columnFlexes[0] : 6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ShimmerPlaceholder(width: 14, height: 14, borderRadius: 3),
                                SizedBox(width: 8),
                                ShimmerPlaceholder(width: 85, height: 13, borderRadius: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Col 2: System ID / Code
                  if (columnFlexes.length > 1)
                    Expanded(
                      flex: columnFlexes[1],
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: ShimmerPlaceholder(
                              width: 140,
                              height: 13,
                              borderRadius: 4,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Col 3: Date / Status
                  if (columnFlexes.length > 2)
                    Expanded(
                      flex: columnFlexes[2],
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: ShimmerPlaceholder(
                              width: 105,
                              height: 13,
                              borderRadius: 4,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Remaining columns if any
                  if (columnFlexes.length > 3)
                    ...columnFlexes.sublist(3).map((flex) {
                      return Expanded(
                        flex: flex,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: ShimmerPlaceholder(
                                width: 80,
                                height: 13,
                                borderRadius: 4,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          }),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildHeaderRow(),
        rows,
      ],
    );
  }
}

/// Shimmer Skeleton List for Mobile and Tablet Views.
/// Matches the card layout with circular icon, title line, and subtitle details.
class CustomListShimmer extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const CustomListShimmer({
    super.key,
    this.itemCount = 5,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: CustomShimmer(
        child: Column(
          children: List.generate(itemCount, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 0.8,
                ),
              ),
              child: const Row(
                children: [
                  // Leading avatar
                  ShimmerPlaceholder.circle(size: 42),
                  SizedBox(width: 14),

                  // Title & multi-line subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerPlaceholder(width: 130, height: 15, borderRadius: 4),
                        SizedBox(height: 8),
                        ShimmerPlaceholder(width: 190, height: 11, borderRadius: 3),
                        SizedBox(height: 6),
                        ShimmerPlaceholder(width: 110, height: 11, borderRadius: 3),
                      ],
                    ),
                  ),

                  SizedBox(width: 8),
                  // Trailing indicator pill
                  ShimmerPlaceholder(width: 18, height: 18, borderRadius: 4),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
