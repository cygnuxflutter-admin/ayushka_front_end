import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/services/gaushala_session_service.dart';
import '../values/app_colors.dart';

/// Global Gaushala Selector widget displayed across all desktop/web top headers.
/// Allows Admins to switch gaushalas from any screen, while displaying the assigned
/// gaushala with a lock indicator for non-admin users.
class GlobalGaushalaSelector extends StatelessWidget {
  final double width;

  const GlobalGaushalaSelector({
    super.key,
    this.width = 230,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Guard against service not being registered
    if (!Get.isRegistered<GaushalaSessionService>()) {
      return const SizedBox.shrink();
    }

    final gaushalaService = Get.find<GaushalaSessionService>();

    return Obx(() {
      final list = gaushalaService.gaushalas.toList();
      final selectedName = gaushalaService.selectedGaushalaName;
      final canChange = gaushalaService.canChangeGaushala;

      // If user is Admin, render the interactive global dropdown selector
      if (canChange) {
        final items = list.map((g) => g.gaushalaName).toList();

        return SizedBox(
          width: width,
          child: DropdownSearch<String>(
            items: (filter, infiniteScrollProps) {
              if (filter.isEmpty) return items;
              return items
                  .where((item) => item.toLowerCase().contains(filter.toLowerCase()))
                  .toList();
            },
            selectedItem: selectedName,
            compareFn: (i1, i2) => i1 == i2,
            onSelected: (selected) {
              if (selected != null) {
                gaushalaService.setGaushalaById(selected);
              }
            },
            popupProps: PopupProps.menu(
              showSearchBox: items.length > 5,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'Search gaushala...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 16),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                ),
              ),
              menuProps: MenuProps(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                elevation: 8,
              ),
              itemBuilder: (ctx, item, isDisabled, isSelected) {
                final isCurrent = item == selectedName;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  color: isCurrent
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.buildings,
                        size: 15,
                        color: isCurrent ? AppColors.primary : (isDark ? Colors.white70 : Colors.black54),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: isCurrent
                                ? AppColors.primary
                                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          ),
                        ),
                      ),
                      if (isCurrent)
                        const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                    ],
                  ),
                );
              },
            ),
            dropdownBuilder: (context, selectedItem) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      selectedItem ?? 'Select Gaushala',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              );
            },
            suffixProps: DropdownSuffixProps(
              dropdownButtonProps: DropdownButtonProps(
                iconClosed: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
            decoratorProps: DropDownDecoratorProps(
              baseStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : Theme.of(context).cardColor,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 8, right: 6),
                  child: Icon(
                    PhosphorIconsRegular.buildings,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      // If user is Non-Admin, render fixed, locked station badge
      return Tooltip(
        message: 'Assigned Gaushala: $selectedName (Fixed to your account)',
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                PhosphorIconsRegular.buildings,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                PhosphorIconsRegular.lockSimple,
                size: 13,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ],
          ),
        ),
      );
    });
  }
}
