import 'package:flutter/material.dart';
import '../values/app_colors.dart';
import 'custom_loader.dart';

/// Reusable mobile bottom loader indicator displayed during infinite scrolling.
class MobileListBottomLoader extends StatelessWidget {
  final bool hasMore;
  final bool isLoading;
  final int totalCount;

  const MobileListBottomLoader({
    super.key,
    required this.hasMore,
    this.isLoading = false,
    this.totalCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading || hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomInlineLoader(size: 16, strokeWidth: 2),
              const SizedBox(width: 10),
              Text(
                'Loading more records...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (totalCount > 5) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text(
            'Showing all $totalCount records',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ),
      );
    }

    return const SizedBox(height: 16);
  }
}
