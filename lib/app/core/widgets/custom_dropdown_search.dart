import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../values/app_colors.dart';
import '../values/app_constants.dart';

/// Enterprise-grade, standardized searchable dropdown component.
/// Matches the design system with external bold label, rounded borders,
/// leading icon, search popup with checkmark highlight, and clear button.
class CustomDropdownSearch<T> extends StatelessWidget {
  final String? label;
  final bool isRequired;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final String hint;
  final T? selectedItem;
  final List<T> items;
  final String Function(T) itemAsString;
  final ValueChanged<T?>? onChanged;
  final VoidCallback? onClear;
  final bool? showClearButton;
  final bool searchable;
  final String? searchHint;
  final bool enabled;
  final FormFieldValidator<T>? validator;
  final bool Function(T, T)? compareFn;
  final double popupMaxHeight;
  final Widget Function(BuildContext context, T item, bool isDisabled, bool isSelected)? customItemBuilder;
  final Widget Function(BuildContext context, T? item)? dropdownBuilder;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;

  const CustomDropdownSearch({
    super.key,
    this.label,
    this.isRequired = false,
    this.prefixIcon,
    this.prefixWidget,
    this.hint = 'Select',
    this.selectedItem,
    required this.items,
    required this.itemAsString,
    this.onChanged,
    this.onClear,
    this.showClearButton,
    this.searchable = false,
    this.searchHint,
    this.enabled = true,
    this.validator,
    this.compareFn,
    this.popupMaxHeight = 280,
    this.customItemBuilder,
    this.dropdownBuilder,
    this.fillColor,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final list = items.toList();
    T? currentItem;
    if (selectedItem != null) {
      for (final item in list) {
        final matches = compareFn != null
            ? compareFn!(item, selectedItem as T)
            : (item == selectedItem || itemAsString(item) == itemAsString(selectedItem as T));
        if (matches) {
          currentItem = item;
          break;
        }
      }
    }

    final Widget dropdownWidget = DropdownSearch<T>(
      key: ValueKey('custom_dropdown_${label ?? hint}_${enabled}_${list.length}'),
      enabled: enabled,
      items: (filter, infiniteScrollProps) {
        if (filter.isEmpty) return list;
        return list
            .where((item) => itemAsString(item).toLowerCase().contains(filter.toLowerCase()))
            .toList();
      },
      itemAsString: (item) => itemAsString(item),
      compareFn: compareFn ?? ((a, b) => a == b || itemAsString(a) == itemAsString(b)),
      selectedItem: currentItem,
      dropdownBuilder: dropdownBuilder != null
          ? (ctx, item) => dropdownBuilder!(ctx, item)
          : (ctx, item) {
              if (item == null) {
                return const SizedBox.shrink();
              }
              return Text(
                itemAsString(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: !enabled
                      ? (isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight)
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              );
            },
      onSelected: enabled
          ? (selected) {
              if (selected != null) {
                onChanged?.call(selected);
              } else {
                if (onClear != null) {
                  onClear!.call();
                } else {
                  onChanged?.call(null);
                }
              }
            }
          : null,
      validator: validator ??
          ((isRequired && enabled)
              ? (selected) {
                  if (selected == null && currentItem == null) {
                    final cleanLabel = (label ?? 'This field').replaceAll('*', '').trim();
                    return '$cleanLabel is required';
                  }
                  return null;
                }
              : null),
      suffixProps: DropdownSuffixProps(
        clearButtonProps: ClearButtonProps(
          isVisible: enabled &&
              (showClearButton ?? (onClear != null && !isRequired)) &&
              currentItem != null,
          icon: Icon(
            Icons.clear_rounded,
            size: 16,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        dropdownButtonProps: DropdownButtonProps(
          isVisible: true,
          iconClosed: Icon(
            enabled ? Icons.keyboard_arrow_down_rounded : Icons.lock_outline_rounded,
            size: enabled ? 20 : 18,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          padding: EdgeInsets.zero,
        ),
      ),
      decoratorProps: DropDownDecoratorProps(
        baseStyle: TextStyle(
          fontSize: 14,
          overflow: TextOverflow.ellipsis,
          color: !enabled
              ? (isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight)
              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 14,
            overflow: TextOverflow.ellipsis,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          prefixIcon: prefixWidget ??
              (prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      size: 18,
                      color: !enabled
                          ? (isDark ? AppColors.textMutedDark.withValues(alpha: 0.6) : AppColors.textMutedLight)
                          : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    )
                  : null),
          prefixIconConstraints: (prefixWidget != null || prefixIcon != null)
              ? const BoxConstraints(minWidth: 40, minHeight: 40)
              : null,
          filled: true,
          fillColor: fillColor ??
              (!enabled
                  ? (isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : const Color(0xFFF1F4EE))
                  : (isDark ? AppColors.cardDark : AppColors.surfaceLight)),
          contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            borderSide: BorderSide(
              color: (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.6),
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
            ),
          ),
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: searchable,
        fit: FlexFit.loose,
        constraints: BoxConstraints(maxHeight: popupMaxHeight),
        menuProps: MenuProps(
          backgroundColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          elevation: 4,
          barrierColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            side: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
        ),
        searchFieldProps: TextFieldProps(
          autofocus: true,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: searchHint ?? (label != null ? 'Search ${label!.replaceAll('*', '').trim()}...' : 'Search...'),
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            prefixIcon: Icon(
              PhosphorIconsRegular.magnifyingGlass,
              size: 16,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        itemBuilder: customItemBuilder ??
            (context, item, isDisabled, isSelected) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                color: isSelected
                    ? AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08)
                    : Colors.transparent,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        itemAsString(item),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        PhosphorIconsRegular.check,
                        size: 16,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              );
            },
      ),
    );

    if (label == null || label!.isEmpty) {
      return dropdownWidget;
    }

    final displayLabel = isRequired && !label!.endsWith('*') ? '$label *' : label!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        dropdownWidget,
      ],
    );
  }
}
