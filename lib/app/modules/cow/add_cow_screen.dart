import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/values/app_colors.dart';
import '../../core/values/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_dropdown_search.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/global_gaushala_selector.dart';
import '../../core/widgets/header_user_profile_badge.dart';
import '../notification/widgets/notification_bell_widget.dart';
import '../../data/models/breed_model.dart';
import '../../data/models/cow_model.dart';
import '../../data/models/gaushala_model.dart';
import '../../data/models/shed_model.dart';
import '../../data/models/type_model.dart';
import '../../routes/app_routes.dart';
import '../dashboard/widgets/mobile_drawer.dart';
import '../dashboard/widgets/web_sidebar.dart';
import 'add_cow_controller.dart';

/// Screen for adding a new cow (POST /api/v1/cows).
class AddCowScreen extends GetView<AddCowController> {
  const AddCowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileScaffold(context),
      tablet: _buildTabletScaffold(context),
      desktop: _buildDesktopScaffold(context),
    );
  }

  // -------------------------------------------------------------------
  // DESKTOP SCAFFOLD
  // -------------------------------------------------------------------
  Widget _buildDesktopScaffold(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Obx(
            () => WebSidebar(
              isCollapsed: controller.isSidebarCollapsed.value,
              onToggle: controller.toggleSidebar,
              currentUser: controller.currentUser.value,
              onLogout: controller.logout,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _buildDesktopHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildBreadcrumb(context),
                            const SizedBox(height: 24),
                            _buildFormContent(context, crossAxisCount: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // TABLET SCAFFOLD
  // -------------------------------------------------------------------
  Widget _buildTabletScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditMode ? 'Edit Cattle' : 'Add Cow'),
        actions: const [
          NotificationBellWidget(),
        ],
      ),
      drawer: Obx(
        () => MobileDrawer(
          currentUser: controller.currentUser.value,
          onLogout: controller.logout,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: _buildFormContent(context, crossAxisCount: 2),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // MOBILE SCAFFOLD
  // -------------------------------------------------------------------
  Widget _buildMobileScaffold(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(controller.isEditMode ? 'Edit Cattle' : 'Add Cow'),
          actions: const [
            NotificationBellWidget(),
          ],
        ),
        drawer: Obx(
          () => MobileDrawer(
            currentUser: controller.currentUser.value,
            onLogout: controller.logout,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: _buildFormContent(context, crossAxisCount: 1),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // DESKTOP HEADER
  // -------------------------------------------------------------------
  Widget _buildDesktopHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Obx(
                () => IconButton(
                  icon: Icon(
                    controller.isSidebarCollapsed.value
                        ? Icons.menu_open_rounded
                        : Icons.menu_rounded,
                    size: 22,
                  ),
                  tooltip: controller.isSidebarCollapsed.value
                      ? 'Expand Sidebar'
                      : 'Collapse Sidebar',
                  onPressed: controller.toggleSidebar,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'CATTLE',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                controller.isEditMode ? 'Edit Cattle Record' : 'Register New Cow',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            children: [
              const GlobalGaushalaSelector(),
              const SizedBox(width: 8),
              const NotificationBellWidget(),
              const SizedBox(width: 8),
              Obx(() => HeaderUserProfileBadge(user: controller.currentUser.value)),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // BREADCRUMB
  // -------------------------------------------------------------------
  Widget _buildBreadcrumb(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                mouseCursor: SystemMouseCursors.click,
                onTap: () => Get.offNamed(AppRoutes.dashboard),
                child: const Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textSecondaryLight),
            const SizedBox(width: 6),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                mouseCursor: SystemMouseCursors.click,
                onTap: () => Get.offNamed(AppRoutes.cows),
                child: const Text(
                  'Herd & Cattle',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
              ),
            ),

            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textSecondaryLight),
            const SizedBox(width: 6),
            Text(
              controller.isEditMode ? 'Edit Cattle' : 'Add Cow',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          controller.isEditMode ? 'Edit Cattle Record' : 'Add New Cow',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // FORM CONTENT — wrapper around loading/error/form
  // -------------------------------------------------------------------
  Widget _buildFormContent(BuildContext context, {required int crossAxisCount}) {
    return Obx(() {
      // Show loading skeleton while catalogs are loading
      if (controller.isLoadingCatalogs.value) {
        return _buildLoadingState(context);
      }

      // Show retry if catalog loading failed
      if (controller.catalogError.value.isNotEmpty) {
        return _buildErrorState(context);
      }

      // Show form
      return _buildForm(context, crossAxisCount: crossAxisCount);
    });
  }

  Widget _buildLoadingState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: const CustomBrandedSpinner(
        message: 'Loading form data...',
        subMessage: 'Fetching breeds, gaushalas, types and sheds',
        size: LoaderSize.large,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, size: 36, color: AppColors.error),
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to Load Form Data',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Obx(() => Text(
                controller.catalogError.value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
              )),
          const SizedBox(height: 18),
          CustomButton(
            text: 'Retry',
            icon: Icons.refresh_rounded,
            width: 130,
            onPressed: controller.retryCatalogs,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // FORM — the actual form with sectioned fields
  // -------------------------------------------------------------------
  Widget _buildForm(BuildContext context, {required int crossAxisCount}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSingleColumn = crossAxisCount == 1;

    return Form(
      key: controller.formKey,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card header
            Padding(
              padding: EdgeInsets.all(isSingleColumn ? 16.0 : 20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.cow,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.isEditMode ? 'Edit Cattle Record' : 'Cow Registration Form',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          controller.isEditMode
                              ? 'Update the details below for this cattle record.'
                              : 'Fill in the details below to register a new cow in the system.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Form fields
            Padding(
              padding: EdgeInsets.all(isSingleColumn ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION 1: Basic Details
                  _buildSectionHeader(context, 'Basic Details', PhosphorIconsRegular.identificationCard),
                  const SizedBox(height: 16),
                  _buildFieldGrid(
                    isSingleColumn: isSingleColumn,
                    children: [
                      // Tag ID
                      CustomTextField(
                        controller: controller.tagIdController,
                        label: 'Tag ID *',
                        hint: 'e.g. GIR-001',
                        isUpperCase: true,
                        prefixIcon: const Icon(PhosphorIconsRegular.tag, size: 18),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Tag ID is required';
                          }
                          return null;
                        },
                      ),
                      // Calf Name
                      CustomTextField(
                        controller: controller.calfNameController,
                        label: 'Calf Name *',
                        hint: 'e.g. Gauri',
                        prefixIcon: const Icon(PhosphorIconsRegular.textAa, size: 18),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Calf Name is required';
                          }
                          return null;
                        },
                      ),
                      // Gender
                      _buildGenderSelector(context),
                      // Date of Birth
                      _buildDateField(
                        context,
                        label: 'Date of Birth',
                        displayValue: () => controller.dobDisplay,
                        hint: 'Select DOB',
                        icon: PhosphorIconsRegular.calendarBlank,
                        isRequired: true,
                        onTap: () => controller.pickDob(context),
                        onClear: () => controller.dob.value = null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // SECTION 2: Classification
                  _buildSectionHeader(context, 'Classification', PhosphorIconsRegular.listDashes),
                  const SizedBox(height: 16),
                  _buildFieldGrid(
                    isSingleColumn: isSingleColumn,
                    children: [
                      // Breed (Searchable dropdown)
                      _buildBreedDropdown(context),
                      // Gaushala
                      _buildGaushalaDropdown(context),
                      // Cow Type
                      _buildTypeDropdown(context),
                      // Shed
                      _buildShedDropdown(context),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // SECTION 3: Parentage
                  _buildSectionHeader(context, 'Parentage / Lineage', PhosphorIconsRegular.gitFork),
                  const SizedBox(height: 16),
                  _buildFieldGrid(
                    isSingleColumn: isSingleColumn,
                    children: [
                      // Dam (Mother) Dropdown
                      _buildDamDropdown(context),
                      // Sire (Father) Dropdown
                      _buildSireDropdown(context),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // SECTION 4: Physical & Timeline
                  _buildSectionHeader(context, 'Physical & Timeline', PhosphorIconsRegular.clock),
                  const SizedBox(height: 16),
                  _buildFieldGrid(
                    isSingleColumn: isSingleColumn,
                    children: [
                      // Calf Weight
                      CustomTextField(
                        controller: controller.calfWeightController,
                        label: 'Calf Weight (kg) *',
                        hint: 'e.g. 25',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: const Icon(PhosphorIconsRegular.scales, size: 18),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Calf weight is required';
                          }
                          final weight = num.tryParse(val.trim());
                          if (weight == null) {
                            return 'Enter a valid weight';
                          }
                          if (weight <= 0) {
                            return 'Calf weight must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      // Delivery Time
                      _buildDateField(
                        context,
                        label: 'Delivery Time',
                        displayValue: () => controller.deliveryTimeDisplay,
                        hint: 'Select time',
                        icon: PhosphorIconsRegular.clockAfternoon,
                        onTap: () => controller.pickDeliveryTime(context),
                        onClear: () => controller.deliveryTime.value = null,
                      ),
                      // Purchase Date
                      _buildDateField(
                        context,
                        label: 'Purchase Date',
                        displayValue: () => controller.purchaseDateDisplay,
                        hint: 'Select date (optional)',
                        icon: PhosphorIconsRegular.shoppingCart,
                        onTap: () => controller.pickPurchaseDate(context),
                        onClear: () => controller.purchaseDate.value = null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // SECTION 5: Notes & Avatar
                  _buildSectionHeader(context, 'Notes & Avatar', PhosphorIconsRegular.notepad),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: controller.avatarUrlController,
                    label: 'Avatar URL',
                    hint: 'https://example.com/cow.jpg (optional)',
                    prefixIcon: const Icon(PhosphorIconsRegular.image, size: 18),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: controller.remarkController,
                    label: 'Remark',
                    hint: 'Any additional notes about this cow',
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(PhosphorIconsRegular.chatText, size: 18),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ACTION BUTTONS
                  _buildActionButtons(context, isSingleColumn: isSingleColumn),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // SECTION HEADER
  // -------------------------------------------------------------------
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // RESPONSIVE FIELD GRID — 2-column on desktop, 1-column on mobile
  // -------------------------------------------------------------------
  Widget _buildFieldGrid({
    required bool isSingleColumn,
    required List<Widget> children,
  }) {
    if (isSingleColumn) {
      return Column(
        children: children.map((child) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: child,
          );
        }).toList(),
      );
    }

    final List<Widget> rows = [];
    for (int i = 0; i < children.length; i += 2) {
      final Widget left = children[i];
      final Widget? right = (i + 1 < children.length) ? children[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 20),
              Expanded(child: right ?? const SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  // -------------------------------------------------------------------
  // GENDER SELECTOR
  // -------------------------------------------------------------------
  Widget _buildGenderSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        Obx(
          () => Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => controller.setGender(true),
                      child: AnimatedContainer(
                        duration: AppConstants.animationFast,
                        decoration: BoxDecoration(
                          color: controller.isFemale.value
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(AppConstants.defaultBorderRadius - 1),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                PhosphorIconsRegular.genderFemale,
                                size: 16,
                                color: controller.isFemale.value
                                    ? AppColors.primary
                                    : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Female',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: controller.isFemale.value
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: controller.isFemale.value
                                      ? AppColors.primary
                                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => controller.setGender(false),
                      child: AnimatedContainer(
                        duration: AppConstants.animationFast,
                        decoration: BoxDecoration(
                          color: !controller.isFemale.value
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(AppConstants.defaultBorderRadius - 1),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                PhosphorIconsRegular.genderMale,
                                size: 16,
                                color: !controller.isFemale.value
                                    ? AppColors.primary
                                    : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Male',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: !controller.isFemale.value
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: !controller.isFemale.value
                                      ? AppColors.primary
                                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // DATE/TIME PICKER FIELD
  // -------------------------------------------------------------------
  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required String Function() displayValue,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onClear,
    bool isRequired = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FormField<String>(
      validator: isRequired
          ? (_) {
              if (displayValue().isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
      builder: (fieldState) {
        final hasError = fieldState.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRequired && !label.endsWith('*') ? '$label *' : label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Obx(
              () {
                final value = displayValue();
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      onTap();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        fieldState.didChange(displayValue());
                      });
                    },
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        border: Border.all(
                          color: hasError
                              ? (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626))
                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          width: hasError ? 1.2 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: hasError
                                ? (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626))
                                : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              value.isEmpty ? hint : value,
                              style: TextStyle(
                                fontSize: 14,
                                color: value.isEmpty
                                    ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
                                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              ),
                            ),
                          ),
                          if (value.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.clear_rounded, size: 16,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                              onPressed: () {
                                onClear();
                                fieldState.didChange('');
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (hasError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  fieldState.errorText ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------------
  // REUSABLE CUSTOM DROPDOWN FIELD (using dropdown_search)
  // -------------------------------------------------------------------
  Widget _buildDropdownField<T>({
    required BuildContext context,
    required String label,
    required bool isRequired,
    required IconData icon,
    required String hint,
    required T? Function() selectedValue,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T) onSelected,
    VoidCallback? onClear,
    bool searchable = false,
    bool enabled = true,
    bool Function()? isEnabled,
  }) {
    return Obx(() {
      final active = isEnabled != null ? isEnabled() : enabled;
      return CustomDropdownSearch<T>(
        label: label,
        isRequired: isRequired,
        prefixIcon: icon,
        hint: hint,
        enabled: active,
        selectedItem: selectedValue(),
        items: items,
        itemAsString: itemLabel,
        searchable: searchable,
        onChanged: (selected) {
          if (selected != null) {
            onSelected(selected);
          } else {
            onClear?.call();
          }
        },
        onClear: onClear,
      );
    });
  }

  // -------------------------------------------------------------------
  // BREED DROPDOWN
  // -------------------------------------------------------------------
  Widget _buildBreedDropdown(BuildContext context) {
    return _buildDropdownField<BreedModel>(
      context: context,
      label: 'Breed',
      isRequired: true,
      icon: PhosphorIconsRegular.dna,
      hint: 'Select breed',
      searchable: true,
      selectedValue: () => controller.selectedBreed.value,
      items: controller.breeds,
      itemLabel: (b) => b.breedName,
      onSelected: (b) => controller.selectedBreed.value = b,
      onClear: () => controller.selectedBreed.value = null,
    );
  }

  // -------------------------------------------------------------------
  // GAUSHALA DROPDOWN
  // -------------------------------------------------------------------
  Widget _buildGaushalaDropdown(BuildContext context) {
    return _buildDropdownField<GaushalaModel>(
      context: context,
      label: 'Gaushala',
      isRequired: true,
      icon: PhosphorIconsRegular.barn,
      hint: 'Select gaushala',
      searchable: true,
      isEnabled: () => controller.canChangeGaushala,
      selectedValue: () => controller.selectedGaushala.value,
      items: controller.gaushalas,
      itemLabel: (g) => g.gaushalaName,
      onSelected: (g) => controller.selectedGaushala.value = g,
    );
  }

  // -------------------------------------------------------------------
  // TYPE DROPDOWN
  // -------------------------------------------------------------------
  Widget _buildTypeDropdown(BuildContext context) {
    return _buildDropdownField<TypeModel>(
      context: context,
      label: 'Cow Type',
      isRequired: true,
      isEnabled: () => controller.isFemale.value,
      icon: PhosphorIconsRegular.tag,
      hint: 'Select cow type',
      searchable: false,
      selectedValue: () => controller.selectedType.value,
      items: controller.types,
      itemLabel: (t) => t.typeName,
      onSelected: (t) => controller.selectedType.value = t,
      onClear: () => controller.selectedType.value = null,
    );
  }

  // -------------------------------------------------------------------
  // SHED DROPDOWN (required)
  // -------------------------------------------------------------------
  Widget _buildShedDropdown(BuildContext context) {
    return _buildDropdownField<ShedModel>(
      context: context,
      label: 'Shed',
      isRequired: true,
      icon: PhosphorIconsRegular.warehouse,
      hint: 'Select shed',
      searchable: false,
      selectedValue: () => controller.selectedShed.value,
      items: controller.sheds,
      itemLabel: (s) => s.shedNumber.isNotEmpty ? '${s.shedName} (${s.shedNumber})' : s.shedName,
      onSelected: (s) => controller.selectedShed.value = s,
      onClear: () => controller.selectedShed.value = null,
    );
  }

  // -------------------------------------------------------------------
  // DAM / MOTHER DROPDOWN
  // -------------------------------------------------------------------
  Widget _buildDamDropdown(BuildContext context) {
    return _buildDropdownField<CowModel>(
      context: context,
      label: 'Dam / Mother',
      isRequired: false,
      icon: PhosphorIconsRegular.genderFemale,
      hint: 'Select dam / mother (optional)',
      searchable: true,
      selectedValue: () => controller.selectedDam.value,
      items: controller.damCows,
      itemLabel: (c) => c.calfName != null && c.calfName!.trim().isNotEmpty
          ? '${c.tagId} (${c.calfName!.trim()})'
          : c.tagId,
      onSelected: (c) {
        controller.selectedDam.value = c;
        controller.damIdController.text = c.id;
      },
      onClear: () {
        controller.selectedDam.value = null;
        controller.damIdController.clear();
      },
    );
  }

  // -------------------------------------------------------------------
  // SIRE / FATHER DROPDOWN
  // -------------------------------------------------------------------
  Widget _buildSireDropdown(BuildContext context) {
    return _buildDropdownField<CowModel>(
      context: context,
      label: 'Sire / Father',
      isRequired: false,
      icon: PhosphorIconsRegular.genderMale,
      hint: 'Select sire / father (optional)',
      searchable: true,
      selectedValue: () => controller.selectedSire.value,
      items: controller.sireCows,
      itemLabel: (c) => c.calfName != null && c.calfName!.trim().isNotEmpty
          ? '${c.tagId} (${c.calfName!.trim()})'
          : c.tagId,
      onSelected: (c) {
        controller.selectedSire.value = c;
        controller.sireIdController.text = c.id;
      },
      onClear: () {
        controller.selectedSire.value = null;
        controller.sireIdController.clear();
      },
    );
  }

  // -------------------------------------------------------------------
  // ACTION BUTTONS
  // -------------------------------------------------------------------
  Widget _buildActionButtons(BuildContext context, {bool isSingleColumn = false}) {
    if (isSingleColumn) {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: CustomButton(
              text: 'Cancel',
              variant: ButtonVariant.outlined,
              height: 44,
              onPressed: controller.cancelForm,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Obx(
              () => CustomButton(
                text: controller.isEditMode ? 'Update Cattle' : 'Add Cow',
                icon: controller.isEditMode ? PhosphorIconsRegular.check : PhosphorIconsRegular.plus,
                isLoading: controller.isSubmitting.value,
                height: 44,
                onPressed: controller.isSubmitting.value ? null : controller.submitAddCow,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CustomButton(
          text: 'Cancel',
          variant: ButtonVariant.outlined,
          width: 120,
          height: 44,
          onPressed: controller.cancelForm,
        ),
        const SizedBox(width: 16),
        Obx(
          () => CustomButton(
            text: controller.isEditMode ? 'Update Cattle' : 'Add Cow',
            icon: controller.isEditMode ? PhosphorIconsRegular.check : PhosphorIconsRegular.plus,
            isLoading: controller.isSubmitting.value,
            width: 170,
            height: 44,
            onPressed: controller.isSubmitting.value ? null : controller.submitAddCow,
          ),
        ),
      ],
    );
  }
}
