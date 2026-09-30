import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../values/app_colors.dart';

/// Reusable, responsive pagination bar for Ayushka Admin data tables and lists.
class CustomPagination extends StatelessWidget {
  final int totalItems;
  final int currentPage;
  final int rowsPerPage;
  final List<int> rowsPerPageOptions;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onRowsPerPageChanged;

  const CustomPagination({
    super.key,
    required this.totalItems,
    required this.currentPage,
    required this.rowsPerPage,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
    this.rowsPerPageOptions = const [5, 10, 20, 50],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final int totalPages = (totalItems <= 0) ? 1 : (totalItems / rowsPerPage).ceil();
    final int startItem = (totalItems == 0) ? 0 : ((currentPage - 1) * rowsPerPage) + 1;
    final int endItem = (currentPage * rowsPerPage > totalItems)
        ? totalItems
        : (currentPage * rowsPerPage);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 680;

        final infoText = RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            children: [
              const TextSpan(text: 'Showing '),
              TextSpan(
                text: totalItems == 0 ? '0' : '$startItem',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              if (totalItems > 0) ...[
                const TextSpan(text: ' to '),
                TextSpan(
                  text: '$endItem',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
              const TextSpan(text: ' of '),
              TextSpan(
                text: '$totalItems',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const TextSpan(text: ' entries'),
            ],
          ),
        );

        final rowsDropdown = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rows per page:',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: rowsPerPageOptions.contains(rowsPerPage)
                      ? rowsPerPage
                      : rowsPerPageOptions.first,
                  isDense: true,
                  dropdownColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  items: rowsPerPageOptions.map((opt) {
                    return DropdownMenuItem<int>(
                      value: opt,
                      child: Text(
                        '$opt',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) onRowsPerPageChanged(val);
                  },
                ),
              ),
            ),
          ],
        );

        final pageControls = _buildPageControls(
          context,
          isDark,
          totalPages,
          isCompact,
        );

        if (isCompact) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: infoText),
                    rowsDropdown,
                  ],
                ),
                const SizedBox(height: 12),
                Center(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: pageControls)),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              infoText,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  rowsDropdown,
                  const SizedBox(width: 18),
                  pageControls,
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageControls(
    BuildContext context,
    bool isDark,
    int totalPages,
    bool isCompact,
  ) {
    final bool canGoPrev = currentPage > 1;
    final bool canGoNext = currentPage < totalPages;

    final List<int> pageNumbers = _generatePageNumbers(totalPages);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // First Page Button
        _buildNavButton(
          icon: PhosphorIconsRegular.caretDoubleLeft,
          tooltip: 'First page',
          isEnabled: canGoPrev,
          onTap: () => onPageChanged(1),
          isDark: isDark,
        ),
        const SizedBox(width: 4),

        // Prev Page Button
        _buildNavButton(
          icon: PhosphorIconsRegular.caretLeft,
          tooltip: 'Previous page',
          isEnabled: canGoPrev,
          onTap: () => onPageChanged(currentPage - 1),
          isDark: isDark,
        ),
        const SizedBox(width: 6),

        // Numbered chips
        ...pageNumbers.map((p) {
          if (p == -1) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '…',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
            );
          }

          final bool isSelected = p == currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onPageChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    width: isSelected ? 1.4 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '$p',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                ),
              ),
            ),
          );
        }),

        const SizedBox(width: 6),

        // Next Page Button
        _buildNavButton(
          icon: PhosphorIconsRegular.caretRight,
          tooltip: 'Next page',
          isEnabled: canGoNext,
          onTap: () => onPageChanged(currentPage + 1),
          isDark: isDark,
        ),
        const SizedBox(width: 4),

        // Last Page Button
        _buildNavButton(
          icon: PhosphorIconsRegular.caretDoubleRight,
          tooltip: 'Last page',
          isEnabled: canGoNext,
          onTap: () => onPageChanged(totalPages),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String tooltip,
    required bool isEnabled,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isEnabled ? onTap : null,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Icon(
              icon,
              size: 14,
              color: isEnabled
                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                  : (isDark ? AppColors.textMutedDark.withValues(alpha: 0.3) : AppColors.textMutedLight.withValues(alpha: 0.4)),
            ),
          ),
        ),
      ),
    );
  }

  List<int> _generatePageNumbers(int totalPages) {
    if (totalPages <= 7) {
      return List<int>.generate(totalPages, (i) => i + 1);
    }

    if (currentPage <= 4) {
      return [1, 2, 3, 4, 5, -1, totalPages];
    }

    if (currentPage >= totalPages - 3) {
      return [
        1,
        -1,
        totalPages - 4,
        totalPages - 3,
        totalPages - 2,
        totalPages - 1,
        totalPages,
      ];
    }

    return [
      1,
      -1,
      currentPage - 1,
      currentPage,
      currentPage + 1,
      -1,
      totalPages,
    ];
  }
}
